import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/api.dart';
import '../supplier/supplier_home.dart';

class VerificationPendingScreen extends StatefulWidget {
  const VerificationPendingScreen({super.key});

  @override
  State<VerificationPendingScreen> createState() => _VerificationPendingScreenState();
}

class _VerificationPendingScreenState extends State<VerificationPendingScreen> {
  bool _loading = false;

  Future<void> _checkStatus() async {
    setState(() => _loading = true);
    await context.read<AppState>().refresh();
    if (mounted) setState(() => _loading = false);
  }

  Widget _buildStepItem({
    required int stepNumber,
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isActive,
    required bool isRejected,
    required bool isLast,
  }) {
    Color iconBg;
    Color iconColor;
    IconData icon;

    if (isRejected) {
      iconBg = const Color(0xFFFFEBEE);
      iconColor = MilkColors.error;
      icon = Icons.cancel_rounded;
    } else if (isDone) {
      iconBg = MilkColors.primaryGreenLight;
      iconColor = MilkColors.primaryGreen;
      icon = Icons.check_circle_rounded;
    } else if (isActive) {
      iconBg = MilkColors.cream;
      iconColor = MilkColors.butterYellowDark;
      icon = Icons.hourglass_top_rounded;
    } else {
      iconBg = MilkColors.milkWhite;
      iconColor = MilkColors.charcoalMuted;
      icon = Icons.radio_button_unchecked_rounded;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isRejected
                      ? MilkColors.error
                      : isActive
                          ? MilkColors.butterYellow
                          : isDone
                              ? MilkColors.primaryGreen
                              : MilkColors.border,
                  width: 2,
                ),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            if (!isLast)
              Container(
                width: 3,
                height: 48,
                color: isDone ? MilkColors.primaryGreen : MilkColors.border,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isRejected
                        ? MilkColors.error
                        : isActive
                            ? MilkColors.charcoal
                            : isDone
                                ? MilkColors.primaryGreenDark
                                : MilkColors.charcoalMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isRejected ? MilkColors.error : MilkColors.charcoalLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final supplier = state.supplierData;
    final status = (supplier?['verification_status'] ?? 'pending').toString().toLowerCase();
    final isVerified = status == 'approved' || status == 'verified';
    final isRejected = status == 'rejected';
    final rejectionReason = supplier?['rejection_reason'] as String?;

    return Scaffold(
      backgroundColor: MilkColors.milkWhite,
      appBar: AppBar(
        title: Text(t(context, 'verif_pending_title')),
        actions: [
          IconButton(
            icon: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _checkStatus,
            tooltip: 'Refresh Status',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await Api.signOut();
              if (context.mounted) {
                Navigator.popUntil(context, (r) => r.isFirst);
              }
            },
            tooltip: t(context, 'sign_out'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Status Icon Header
            Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: isRejected
                      ? const Color(0xFFFFEBEE)
                      : isVerified
                          ? MilkColors.primaryGreenLight
                          : MilkColors.cream,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isRejected
                        ? MilkColors.error
                        : isVerified
                            ? MilkColors.primaryGreen
                            : MilkColors.butterYellow,
                    width: 2,
                  ),
                ),
                child: Icon(
                  isRejected
                      ? Icons.error_outline_rounded
                      : isVerified
                          ? Icons.verified_rounded
                          : Icons.access_time_rounded,
                  size: 48,
                  color: isRejected
                      ? MilkColors.error
                      : isVerified
                          ? MilkColors.primaryGreen
                          : MilkColors.butterYellowDark,
                ),
              ),
            ),
            const SizedBox(height: 18),

            Text(
              isRejected
                  ? t(context, 'verif_step_rejected')
                  : isVerified
                      ? t(context, 'verif_step_verified')
                      : t(context, 'verif_pending_title'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: isRejected ? MilkColors.error : MilkColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              t(context, 'verif_pending_desc'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: MilkColors.charcoalLight,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            // Stepper Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: MilkColors.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: MilkColors.primaryGreen.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildStepItem(
                    stepNumber: 1,
                    title: t(context, 'verif_step_submitted'),
                    subtitle: 'Farm details and service PIN codes registered',
                    isDone: true,
                    isActive: false,
                    isRejected: false,
                    isLast: false,
                  ),
                  _buildStepItem(
                    stepNumber: 2,
                    title: t(context, 'verif_step_review'),
                    subtitle: isRejected
                        ? 'Admin review completed'
                        : isVerified
                            ? 'Verification approved'
                            : 'Admin is reviewing your profile',
                    isDone: isVerified || isRejected,
                    isActive: !isVerified && !isRejected,
                    isRejected: false,
                    isLast: false,
                  ),
                  _buildStepItem(
                    stepNumber: 3,
                    title: isRejected
                        ? t(context, 'verif_step_rejected')
                        : t(context, 'verif_step_verified'),
                    subtitle: isRejected
                        ? (rejectionReason ?? 'Documents could not be verified')
                        : isVerified
                            ? 'Your milk listings are now visible to all customers'
                            : 'Pending final approval',
                    isDone: isVerified,
                    isActive: false,
                    isRejected: isRejected,
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            AppButton(
              label: t(context, 'goto_dashboard'),
              icon: Icons.dashboard_rounded,
              color: MilkColors.primaryGreen,
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SupplierHome()),
                );
              },
            ),
            const SizedBox(height: 14),

            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Check Verification Status', style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: _checkStatus,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
