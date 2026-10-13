import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/api.dart';
import 'address_book_screen.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  void _showEditProfile(BuildContext context, dynamic profile) {
    final name = TextEditingController(text: profile?.name ?? '');
    final altPhone = TextEditingController(text: profile?.alternatePhone ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: altPhone,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(labelText: 'Alternate Phone', counterText: ''),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t(ctx, 'cancel'))),
          FilledButton(
            onPressed: () async {
              if (name.text.trim().isNotEmpty) {
                await Api.updateProfile(
                  name: name.text.trim(),
                  alternatePhone: altPhone.text.trim().isEmpty ? null : altPhone.text.trim(),
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  context.read<AppState>().refresh();
                }
              }
            },
            child: Text(t(ctx, 'save')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = state.profile;
    final name = p?.name ?? 'Customer';
    final phone = p?.phone ?? '—';
    final role = p?.role ?? 'customer';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // User Info Card
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 36,
                backgroundColor: MilkColors.primaryGreenLight,
                child: Icon(Icons.person, size: 40, color: MilkColors.primaryGreen),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: MilkColors.charcoal),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phone,
                      style: const TextStyle(fontSize: 14, color: MilkColors.charcoalLight, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: MilkColors.dairyBlueLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        t(context, role),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: MilkColors.dairyBlue),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: MilkColors.primaryGreen),
                onPressed: () => _showEditProfile(context, p),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const SectionHeader(title: 'Settings & Preferences'),
        const SizedBox(height: 12),

        // Settings items
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.location_on_outlined, color: MilkColors.primaryGreen),
                title: const Text('Saved Addresses', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Manage home, office delivery locations'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddressBookScreen()),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.language_outlined, color: MilkColors.dairyBlue),
                title: const Text('App Language', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  state.lang == 'hi' ? 'हिंदी (Hindi)' : (state.lang == 'mr' ? 'मराठी (Marathi)' : 'English'),
                ),
                trailing: const LangMenu(),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.support_agent_outlined, color: Color(0xFFD97706)),
                title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Contact support, report service complaints'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  toast(context, 'For support, please call or WhatsApp your supplier directly.');
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: MilkColors.error),
                title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700, color: MilkColors.error)),
                onTap: () => context.read<AppState>().signOutAndChangeRole(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
