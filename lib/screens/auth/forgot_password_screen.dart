import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/api.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;
  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _emailController;
  bool _busy = false;
  bool _sent = false;
  int _timerSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _timerSeconds = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        t.cancel();
      }
    });
  }

  Future<void> _handleReset() async {
    final email = _emailController.text.trim().toLowerCase();
    final valid = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(email);
    if (!valid) {
      toast(context, 'Please enter a valid email address', isError: true);
      return;
    }

    setState(() => _busy = true);
    try {
      await Api.sendPasswordReset(email);
      if (mounted) {
        setState(() => _sent = true);
        _startTimer();
      }
    } catch (e) {
      if (mounted) toast(context, '$e', isError: true);
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
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [LangMenu()],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: MilkColors.cream,
                  shape: BoxShape.circle,
                  border: Border.all(color: MilkColors.butterYellow, width: 2),
                ),
                child: const Icon(Icons.lock_reset_rounded, size: 44, color: MilkColors.charcoal),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              t(context, 'forgot_password'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: MilkColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your registered email address and we will send you a secure link to reset your password.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: MilkColors.charcoalLight,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),

            if (_sent) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: MilkColors.primaryGreenLight,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: MilkColors.primaryGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.mark_email_read_rounded, color: MilkColors.primaryGreen, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reset Link Sent!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: MilkColors.primaryGreenDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'We sent instructions to ${_emailController.text.trim().toLowerCase()}. Check your spam folder if you do not see it within a minute.',
                            style: const TextStyle(fontSize: 13, color: MilkColors.charcoalLight, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: MilkColors.border, width: 1.5),
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
                      prefixIcon: const Icon(Icons.email_outlined),
                      hintText: t(context, 'email_hint'),
                    ),
                    onSubmitted: (_) => _handleReset(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_sent && _timerSeconds > 0)
              Center(
                child: Text(
                  'Resend link available in ${_timerSeconds}s',
                  style: const TextStyle(color: MilkColors.charcoalMuted, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              )
            else
              AppButton(
                label: _sent ? 'Resend Reset Link' : 'Send Reset Link',
                icon: Icons.send_rounded,
                onPressed: _handleReset,
                busy: _busy,
                color: MilkColors.charcoal,
              ),
            const SizedBox(height: 20),

            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back to Login', style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
