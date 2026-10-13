import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/api.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  final String role; // 'customer' | 'supplier'
  const VerifyEmailScreen({super.key, required this.email, required this.role});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  int _timerSeconds = 30;
  Timer? _timer;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleResend() async {
    try {
      await Api.resendConfirmationEmail(widget.email);
      if (mounted) {
        toast(context, 'Confirmation email resent to ${widget.email}');
        _startTimer();
      }
    } catch (e) {
      if (mounted) toast(context, '$e', isError: true);
    }
  }

  Future<void> _checkConfirmation() async {
    setState(() => _busy = true);
    final state = context.read<AppState>();
    try {
      await state.refresh();
      if (state.signedIn && state.profile != null) {
        if (mounted) {
          Navigator.popUntil(context, (r) => r.isFirst);
        }
      } else {
        if (mounted) {
          toast(context, 'Please click the confirmation link sent to ${widget.email} first, then sign in.', isError: true);
        }
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
        title: const Text('Verify Your Email'),
        actions: const [LangMenu()],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          children: [
            Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: MilkColors.dairyBlueLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: MilkColors.dairyBlue.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.mark_email_unread_rounded, size: 48, color: MilkColors.dairyBlue),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Check Your Inbox',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: MilkColors.charcoal,
              ),
            ),
            const SizedBox(height: 10),

            Text(
              'We sent a verification link to:\n${widget.email}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: MilkColors.dairyBlue,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),

            const Text(
              'Click the link in the email to activate your account. Once verified, return here to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: MilkColors.charcoalLight,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 36),

            AppButton(
              label: 'I Have Verified My Email',
              icon: Icons.check_circle_outline,
              onPressed: _checkConfirmation,
              busy: _busy,
              color: MilkColors.primaryGreen,
            ),
            const SizedBox(height: 16),

            if (_timerSeconds > 0)
              Center(
                child: Text(
                  'Resend email in ${_timerSeconds}s',
                  style: const TextStyle(color: MilkColors.charcoalMuted, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              )
            else
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text(
                    'Resend Verification Email',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: MilkColors.primaryGreen),
                  ),
                  onPressed: _handleResend,
                ),
              ),
            const SizedBox(height: 24),

            Center(
              child: TextButton(
                onPressed: () {
                  context.read<AppState>().clearRole();
                  Navigator.popUntil(context, (r) => r.isFirst);
                },
                child: Text(
                  t(context, 'change_role'),
                  style: const TextStyle(fontWeight: FontWeight.w700, color: MilkColors.charcoalLight),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
