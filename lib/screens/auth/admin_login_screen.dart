import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/l10n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/api.dart';
import '../admin/admin_home.dart';
import 'forgot_password_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
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
      setState(() => _errorMessage = 'Please enter both admin email and password.');
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

      // Check role strictly from database
      final profile = await Api.fetchProfile();

      if (profile == null || profile.role != 'admin') {
        // Not an admin! Immediately sign out
        await Api.signOut();
        setState(() {
          _errorMessage = tn(context, 'role_err_not_admin');
        });
        return;
      }

      if (profile.isBlocked) {
        await Api.signOut();
        setState(() {
          _errorMessage = tn(context, 'acc_blocked');
        });
        return;
      }

      // Valid admin
      await state.setSelectedRole('admin');
      await state.refresh();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminHome()),
          (r) => false,
        );
      }
    } on AuthException catch (e) {
      setState(() {
        if (e.message.toLowerCase().contains('invalid') || e.code == 'invalid_credentials') {
          _errorMessage = 'Invalid email or password. Please try again.';
        } else if (e.message.toLowerCase().contains('rate limit') || e.code == 'over_request_rate_limit') {
          _errorMessage = 'Too many attempts. Please wait a few minutes before trying again.';
        } else {
          _errorMessage = e.message;
        }
      });
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
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: MilkColors.charcoalLight),
            ),
          ),
          const LangMenu(),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          children: [
            // Admin Shield Header
            Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: MilkColors.charcoal.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: MilkColors.charcoal.withValues(alpha: 0.2), width: 2),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, size: 48, color: MilkColors.charcoal),
              ),
            ),
            const SizedBox(height: 18),

            Text(
              t(context, 'admin_login_title'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: MilkColors.charcoal,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t(context, 'admin_login_sub'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
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
                    color: MilkColors.charcoal.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t(context, 'admin_email'),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: MilkColors.charcoal),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: MilkColors.charcoal),
                    decoration: const InputDecoration(
                      hintText: 'admin@milkdirect.com',
                      prefixIcon: Icon(Icons.email_outlined),
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
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: MilkColors.charcoalLight),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            AppButton(
              label: t(context, 'admin_login_btn'),
              icon: Icons.login_rounded,
              color: MilkColors.charcoal,
              onPressed: _handleSignIn,
              busy: _busy,
            ),
            const SizedBox(height: 24),

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

            // Security Note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: MilkColors.creamLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: MilkColors.butterYellow.withValues(alpha: 0.6)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined, color: MilkColors.butterYellowDark, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t(context, 'admin_security_note'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: MilkColors.charcoalLight,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
