import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config.dart';
import 'core/l10n.dart';
import 'core/state.dart';
import 'core/theme.dart';
import 'screens/admin/admin_home.dart';
import 'screens/auth/admin_login_screen.dart';
import 'screens/auth/customer_login_screen.dart';
import 'screens/auth/customer_register_screen.dart';
import 'screens/auth/role_select_screen.dart';
import 'screens/auth/supplier_login_screen.dart';
import 'screens/auth/supplier_register_wizard.dart';
import 'screens/auth/verification_pending_screen.dart';
import 'screens/customer/customer_home.dart';
import 'screens/supplier/supplier_home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: const MilkDirectApp(),
    ),
  );
}

class MilkDirectApp extends StatelessWidget {
  const MilkDirectApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'MilkDirect',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const AuthGate(),
      );
}

/// Routes strictly by auth state and role:
/// 1. Unauthenticated -> RoleSelectScreen or remembered Role Login (Customer/Supplier/Admin)
/// 2. Authenticated without profile -> Setup Wizard (CustomerRegisterScreen or SupplierRegisterWizard)
/// 3. Authenticated with profile -> CustomerHome / SupplierHome (or VerificationPending) / AdminHome
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    t(context, 'app'); // keep subscribed to language changes

    if (s.loading) {
      return Scaffold(
        backgroundColor: MilkColors.milkWhite,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: MilkColors.cream,
                  shape: BoxShape.circle,
                  border: Border.all(color: MilkColors.butterYellow, width: 2),
                ),
                child: const Icon(Icons.local_drink_rounded, size: 40, color: MilkColors.primaryGreen),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: MilkColors.primaryGreen),
            ],
          ),
        ),
      );
    }

    // 1. Unauthenticated Flow
    if (!s.signedIn) {
      switch (s.selectedRole) {
        case 'customer':
          return const CustomerLoginScreen();
        case 'supplier':
          return const SupplierLoginScreen();
        case 'admin':
          return const AdminLoginScreen();
        default:
          return const RoleSelectScreen();
      }
    }

    // 2. Authenticated but Profile Not Yet Created
    final p = s.profile;
    if (p == null) {
      if (s.selectedRole == 'supplier') {
        return const SupplierRegisterWizard();
      }
      return const CustomerRegisterScreen();
    }

    // 3. Authenticated Role-Based Routing
    switch (p.role) {
      case 'supplier':
        final status = (s.supplierData?['verification_status'] ?? 'pending').toString().toLowerCase();
        if (status == 'pending' || status == 'rejected') {
          return const VerificationPendingScreen();
        }
        return const SupplierHome();

      case 'admin':
        return const AdminHome();

      case 'customer':
      default:
        return const CustomerHome();
    }
  }
}
