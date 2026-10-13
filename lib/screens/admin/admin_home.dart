import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n.dart';
import '../../core/models.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/api.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: MilkColors.milkWhite,
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: MilkColors.primaryGreenLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, color: MilkColors.primaryGreen, size: 20),
              ),
              const SizedBox(width: 8),
              Text(t(context, 'admin_dashboard')),
            ],
          ),
          actions: [
            const LangMenu(),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => context.read<AppState>().signOutAndChangeRole(),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: MilkColors.primaryGreenDark,
            indicatorColor: MilkColors.primaryGreen,
            tabs: [
              const Tab(text: 'Overview'),
              Tab(text: t(context, 'verify_suppliers')),
              Tab(text: t(context, 'complaints')),
              Tab(text: t(context, 'user_management')),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AdminOverviewTab(),
            _VerifyTab(),
            _ComplaintsTab(),
            _UsersTab(),
          ],
        ),
      ),
    );
  }
}

// ---------------- 1. OVERVIEW TAB ----------------
class _AdminOverviewTab extends StatefulWidget {
  const _AdminOverviewTab();

  @override
  State<_AdminOverviewTab> createState() => _AdminOverviewTabState();
}

class _AdminOverviewTabState extends State<_AdminOverviewTab> {
  final Future<Map<String, dynamic>> _statsFuture = Api.adminStats();

  @override
  Widget build(BuildContext context) {
    return AsyncView<Map<String, dynamic>>(
      future: _statsFuture,
      builder: (context, stats) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                StatTile(
                  label: t(context, 'total_customers'),
                  value: '${stats['customers'] ?? 0}',
                  icon: Icons.people_outline,
                  color: MilkColors.dairyBlue,
                  bgColor: MilkColors.dairyBlueLight,
                ),
                StatTile(
                  label: t(context, 'total_suppliers'),
                  value: '${stats['suppliers'] ?? 0}',
                  icon: Icons.agriculture_outlined,
                  color: MilkColors.primaryGreen,
                  bgColor: MilkColors.primaryGreenLight,
                ),
                StatTile(
                  label: t(context, 'active_subs'),
                  value: '${stats['active_subs'] ?? 0}',
                  icon: Icons.autorenew,
                  color: const Color(0xFFD97706),
                  bgColor: MilkColors.cream,
                ),
                StatTile(
                  label: t(context, 'open_complaints'),
                  value: '${stats['open_complaints'] ?? 0}',
                  icon: Icons.report_problem_outlined,
                  color: MilkColors.error,
                  bgColor: const Color(0xFFFFEBEE),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const AppCard(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Quick System Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  SizedBox(height: 12),
                  Text('• Review pending supplier applications in the Verification tab.'),
                  SizedBox(height: 6),
                  Text('• Track and resolve customer delivery complaints with notes.'),
                  SizedBox(height: 6),
                  Text('• Search and manage customer/supplier account access.'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------- 2. SUPPLIER VERIFICATION TAB ----------------
class _VerifyTab extends StatefulWidget {
  const _VerifyTab();
  @override
  State<_VerifyTab> createState() => _VerifyTabState();
}

class _VerifyTabState extends State<_VerifyTab> {
  late Future<List<Json>> _future = Api.pendingSuppliers();

  void _reload() {
    setState(() => _future = Api.pendingSuppliers());
  }

  Future<void> _verify(String id, String status, [String? reason]) async {
    try {
      await Api.setVerification(id, status, reason);
      _reload();
    } catch (e) {
      if (mounted) toast(context, '$e', isError: true);
    }
  }

  void _promptReject(String id) {
    final reason = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Supplier Application'),
        content: TextField(
          controller: reason,
          decoration: const InputDecoration(labelText: 'Rejection Reason / Missing Docs'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t(ctx, 'cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: MilkColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              _verify(id, 'rejected', reason.text.trim());
            },
            child: Text(t(ctx, 'reject')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<Json>>(
      future: _future,
      builder: (context, list) {
        if (list.isEmpty) {
          return const EmptyView(
            message: 'No pending supplier verifications',
            subtitle: 'All dairy farmers and milkmen applications have been reviewed.',
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: list.map((s) {
            final name = s['shop_name'] ?? s['profiles']?['name'] ?? 'Supplier';
            final phone = s['profiles']?['phone'] ?? '—';
            final village = s['village'] ?? '';
            final pin = s['pincode'] ?? '';
            final type = s['type'] ?? 'farmer';
            final upi = s['upi_id'] ?? '—';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        StatusBadge(s['verification_status'] ?? 'pending'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('$village (PIN: $pin) • ${t(context, type)}', style: const TextStyle(color: MilkColors.charcoalLight)),
                    Text('Phone: $phone • UPI: $upi', style: const TextStyle(color: MilkColors.charcoalLight, fontSize: 13)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _verify(s['id'], 'verified'),
                            child: Text(t(context, 'approve')),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _promptReject(s['id']),
                            style: OutlinedButton.styleFrom(foregroundColor: MilkColors.error, side: const BorderSide(color: MilkColors.error)),
                            child: Text(t(context, 'reject')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ---------------- 3. COMPLAINTS TAB ----------------
class _ComplaintsTab extends StatefulWidget {
  const _ComplaintsTab();
  @override
  State<_ComplaintsTab> createState() => _ComplaintsTabState();
}

class _ComplaintsTabState extends State<_ComplaintsTab> {
  late Future<List<Json>> _future = Api.complaints();

  void _reload() {
    setState(() => _future = Api.complaints());
  }

  void _promptResolve(String id) {
    final notes = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Complaint'),
        content: TextField(
          controller: notes,
          decoration: const InputDecoration(labelText: 'Resolution Notes / Action taken'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t(ctx, 'cancel'))),
          FilledButton(
            onPressed: () async {
              await Api.resolveComplaint(id, notes.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              _reload();
            },
            child: Text(t(ctx, 'resolve')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<Json>>(
      future: _future,
      builder: (context, list) {
        if (list.isEmpty) {
          return const EmptyView(
            message: 'No open complaints',
            subtitle: 'Customer issues and delivery dispute tickets will appear here.',
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: list.map((x) {
            final custName = x['customer']?['name'] ?? 'Customer';
            final custPhone = x['customer']?['phone'] ?? '—';
            final issueType = x['issue_type'] ?? 'quality';
            final issue = x['issue'] ?? '';
            final status = x['resolution_status'] ?? 'open';
            final isOpen = status == 'open';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(custName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        StatusBadge(status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('Phone: $custPhone • Issue: ${t(context, 'iss_$issueType')}', style: const TextStyle(fontSize: 13, color: MilkColors.charcoalLight)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: MilkColors.creamLight, borderRadius: BorderRadius.circular(10)),
                      child: Text(issue, style: const TextStyle(fontSize: 14)),
                    ),
                    if (isOpen) ...[
                      const SizedBox(height: 12),
                      AppButton(
                        label: t(context, 'resolve'),
                        onPressed: () => _promptResolve(x['id']),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ---------------- 4. USERS MANAGEMENT TAB ----------------
class _UsersTab extends StatefulWidget {
  const _UsersTab();
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final _search = TextEditingController();
  late Future<List<Json>> _future = Api.allUsers();

  void _reload() {
    setState(() => _future = Api.allUsers(query: _search.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _search,
            onSubmitted: (_) => _reload(),
            decoration: InputDecoration(
              hintText: 'Search users by name...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(icon: const Icon(Icons.send), onPressed: _reload),
            ),
          ),
        ),
        Expanded(
          child: AsyncView<List<Json>>(
            future: _future,
            builder: (context, users) {
              if (users.isEmpty) {
                return const EmptyView(message: 'No users found');
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: users.length,
                itemBuilder: (context, i) {
                  final u = users[i];
                  final isBlocked = u['is_blocked'] == true;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: MilkColors.primaryGreenLight,
                          child: Icon(
                            u['role'] == 'supplier' ? Icons.agriculture : Icons.person,
                            color: MilkColors.primaryGreenDark,
                          ),
                        ),
                        title: Text(u['name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text('${u['phone'] ?? ''} • Role: ${u['role']}'),
                        trailing: IconButton(
                          icon: Icon(
                            isBlocked ? Icons.lock : Icons.lock_open,
                            color: isBlocked ? MilkColors.error : MilkColors.primaryGreen,
                          ),
                          onPressed: () async {
                            await Api.setBlockUser(u['id'], !isBlocked);
                            _reload();
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
