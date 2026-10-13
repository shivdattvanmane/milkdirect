import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/l10n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/api.dart';
import 'customer_register_screen.dart';
import 'forgot_password_screen.dart';
import 'verify_email_screen.dart';

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key});

  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _busy = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _cleanEmail => _emailController.text.trim().toLowerCase();

  Future<void> _handleSignIn() async {
    final email = _cleanEmail;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both your email address and password.');
      return;
    }

    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    final state = context.read<AppState>();

    try {
      final res = await Api.signInWithPassword(email, password);

      if (res.user == null) {
        throw Exception('Login failed. Please check your credentials.');
      }

      // Check user profile in DB
      final profile = await Api.fetchProfile();

      if (profile != null) {
        if (profile.isBlocked) {
          await Api.signOut();
          state.setRoleError('acc_blocked');
          await state.clearRole();
          return;
        }

        // Strict Role Enforcement
        if (profile.role != 'customer') {
          await Api.signOut();
          if (profile.role == 'supplier') {
            state.setRoleError('role_err_supplier_to_customer');
          } else {
            state.setRoleError('role_err_not_admin');
          }
          await state.clearRole();
          return;
        }

        // Valid Customer Profile
        await state.setSelectedRole('customer');
        await state.refresh();
      } else {
        // User has auth account but no profile record yet
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CustomerRegisterScreen()),
          );
        }
      }
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('email not confirmed')) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VerifyEmailScreen(email: email, role: 'customer'),
            ),
          );
        }
      } else if (e.message.toLowerCase().contains('invalid login credentials') || e.code == 'invalid_credentials') {
        setState(() => _errorMessage = 'Invalid email or password. Please try again.');
      } else {
        setState(() => _errorMessage = e.message);
      }
    } catch (e) {
      setState(() => _errorMessage = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MilkColors.milkWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: MilkColors.charcoal),
          onPressed: () => context.read<AppState>().clearRole(),
        ),
        actions: [
          TextButton(
            onPressed: () => context.read<AppState>().clearRole(),
            child: Text(
              t(context, 'change_role'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: MilkColors.dairyBlue),
            ),
          ),
          const LangMenu(),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          children: [
            // Header Illustration
            Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: MilkColors.dairyBlueLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: MilkColors.dairyBlue.withValues(alpha: 0.2), width: 2),
                ),
                child: const Icon(Icons.person_pin_circle_rounded, size: 48, color: MilkColors.dairyBlue),
              ),
            ),
            const SizedBox(height: 18),

            Text(
              t(context, 'customer_login_title'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: MilkColors.charcoal,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sign in with your email and password to manage daily milk drops',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: MilkColors.charcoalLight,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 28),

            // Error Banner
            if (_errorMessage != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MilkColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: MilkColors.error, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: MilkColors.error, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Login Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: MilkColors.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: MilkColors.dairyBlue.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t(context, 'email_address'),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: MilkColors.charcoal),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: MilkColors.charcoal),
                    decoration: InputDecoration(
                      hintText: t(context, 'email_hint'),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Text(
                    t(context, 'admin_password'),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: MilkColors.charcoal),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: MilkColors.charcoal),
                    decoration: InputDecoration(
                      hintText: '••••••••••••',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: MilkColors.charcoalLight,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    onSubmitted: (_) => _handleSignIn(),
                  ),
                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ForgotPasswordScreen(initialEmail: _cleanEmail),
                          ),
                        );
                      },
                      child: Text(
                        t(context, 'forgot_password'),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: MilkColors.dairyBlue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            AppButton(
              label: 'Sign In as Customer',
              icon: Icons.login_rounded,
              color: MilkColors.dairyBlue,
              onPressed: _handleSignIn,
              busy: _busy,
            ),
            const SizedBox(height: 20),

            // Register Link
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? ", style: TextStyle(color: MilkColors.charcoalLight, fontWeight: FontWeight.w600)),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CustomerRegisterScreen()),
                      );
                    },
                    child: const Text('Register Here', style: TextStyle(fontWeight: FontWeight.w800, color: MilkColors.dairyBlue)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: Text(
                  t(context, 'change_role'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: MilkColors.charcoalLight),
                ),
                onPressed: () => context.read<AppState>().clearRole(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
