import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  Widget _buildRoleCard({
    required BuildContext context,
    required String titleKey,
    required String descKey,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: MilkColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t(context, titleKey),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: MilkColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t(context, descKey),
                    style: const TextStyle(
                      fontSize: 14,
                      color: MilkColors.charcoalLight,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: MilkColors.milkWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: const [LangMenu()],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          children: [
            // Logo & Header
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: MilkColors.cream,
                  shape: BoxShape.circle,
                  border: Border.all(color: MilkColors.butterYellow, width: 2),
                ),
                child: const Icon(Icons.local_drink_rounded, size: 48, color: MilkColors.primaryGreen),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              t(context, 'app'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: MilkColors.charcoal,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t(context, 'tagline'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: MilkColors.charcoalLight, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 28),

            // Error Message Banner (e.g. wrong role login attempt)
            if (state.roleErrorMessage != null) ...[
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
                        t(context, state.roleErrorMessage!),
                        style: const TextStyle(color: MilkColors.error, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: MilkColors.error),
                      onPressed: state.clearRoleError,
                    ),
                  ],
                ),
              ),
            ],

            Text(
              t(context, 'role_select_sub'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: MilkColors.charcoal),
            ),
            const SizedBox(height: 16),

            // 1. Customer Card
            _buildRoleCard(
              context: context,
              titleKey: 'i_am_customer_card',
              descKey: 'customer_card_desc',
              icon: Icons.person_pin_circle_rounded,
              color: MilkColors.dairyBlue,
              onTap: () {
                state.setSelectedRole('customer');
              },
            ),

            // 2. Farmer / Milkman Card
            _buildRoleCard(
              context: context,
              titleKey: 'i_am_supplier_card',
              descKey: 'supplier_card_desc',
              icon: Icons.agriculture_rounded,
              color: MilkColors.primaryGreen,
              onTap: () {
                state.setSelectedRole('supplier');
              },
            ),
            const SizedBox(height: 24),

            // 3. Admin Login link (small at bottom)
            Center(
              child: TextButton(
                onPressed: () {
                  state.setSelectedRole('admin');
                },
                child: Text(
                  t(context, 'admin_login_link'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: MilkColors.charcoalLight,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
