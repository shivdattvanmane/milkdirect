import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/l10n.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/api.dart';

class MyMilkTab extends StatefulWidget {
  const MyMilkTab({super.key});

  @override
  State<MyMilkTab> createState() => _MyMilkTabState();
}

class _MyMilkTabState extends State<MyMilkTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  late Future<List<Json>> _future = Api.mySubscriptions();

  void _reload() {
    setState(() => _future = Api.mySubscriptions());
  }

  void _showVacationDialog(Json sub) {
    DateTimeRange? range;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t(ctx, 'vacation_mode')),
        content: const Text('Select a date range during which your milk delivery will be paused.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t(ctx, 'cancel'))),
          FilledButton(
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: ctx,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (picked != null) {
                range = picked;
                final List<String> currentSkips = List<String>.from(sub['skip_dates'] ?? []);
                for (var d = range!.start; d.isBefore(range!.end.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
                  final str = iso(d);
                  if (!currentSkips.contains(str)) currentSkips.add(str);
                }
                await Api.setSkipDates(sub['id'], currentSkips);
                if (ctx.mounted) Navigator.pop(ctx);
                _reload();
                if (mounted) toast(context, 'Vacation dates paused successfully');
              }
            },
            child: const Text('Select Dates'),
          ),
        ],
      ),
    );
  }

  void _showQuantityDialog(Json sub) {
    double qty = (sub['quantity_l'] as num).toDouble();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Change Daily Quantity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QuantityStepper(value: qty, onChanged: (v) => setD(() => qty = v)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t(ctx, 'cancel'))),
            FilledButton(
              onPressed: () async {
                await Api.updateSubscriptionQuantity(sub['id'], qty);
                if (ctx.mounted) Navigator.pop(ctx);
                _reload();
                if (mounted) toast(context, 'Quantity updated');
              },
              child: Text(t(ctx, 'save')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<Json>>(
      future: _future,
      builder: (context, subs) {
        if (subs.isEmpty) {
          return EmptyView(
            message: 'No active milk subscriptions',
            subtitle: 'Subscribe to local dairy farmers for daily morning farm fresh milk.',
            buttonLabel: 'Explore Suppliers',
            onButton: () {
              // Switch tab
            },
          );
        }

        // Collect all skip dates from subscriptions
        final allSkips = <String>{};
        for (final s in subs) {
          final skips = List<String>.from(s['skip_dates'] ?? []);
          allSkips.addAll(skips);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Calendar Widget
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 30)),
                lastDay: DateTime.now().add(const Duration(days: 60)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (sel, foc) => setState(() {
                  _selectedDay = sel;
                  _focusedDay = foc;
                }),
                calendarFormat: CalendarFormat.month,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                calendarStyle: CalendarStyle(
                  selectedDecoration: const BoxDecoration(color: MilkColors.primaryGreen, shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(color: MilkColors.primaryGreenLight, shape: BoxShape.circle),
                  todayTextStyle: const TextStyle(color: MilkColors.primaryGreenDark, fontWeight: FontWeight.w800),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    final str = iso(date);
                    if (allSkips.contains(str)) {
                      return Positioned(
                        bottom: 4,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: MilkColors.warning, shape: BoxShape.circle),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            SectionHeader(title: 'Active Subscriptions (${subs.length})'),
            const SizedBox(height: 12),

            ...subs.map((s) {
              final status = s['status'] as String;
              final isActive = status == 'active';
              final supplierName = s['supplier_profiles']?['shop_name'] ?? s['supplier_profiles']?['profiles']?['name'] ?? 'Supplier';
              final skips = List<String>.from(s['skip_dates'] ?? []);
              final tomorrow = iso(DateTime.now().add(const Duration(days: 1)));
              final skippedTomorrow = skips.contains(tomorrow);
              final slot = s['slot'] ?? 'morning_5_8';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: MilkColors.cream,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.local_drink, color: MilkColors.primaryGreen, size: 22),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${t(context, s['products']?['milk_type'] ?? 'other')} • ${fmtQty(s['quantity_l'])} L',
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                                  ),
                                  Text(
                                    '$supplierName • ${t(context, s['frequency'] ?? 'daily')}',
                                    style: const TextStyle(fontSize: 13, color: MilkColors.charcoalLight),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          StatusBadge(status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 16, color: MilkColors.charcoalLight),
                          const SizedBox(width: 6),
                          Text(t(context, slot), style: const TextStyle(fontSize: 13, color: MilkColors.charcoalLight)),
                        ],
                      ),
                      const Divider(height: 20),

                      // Quick Actions row
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (isActive) ...[
                            OutlinedButton.icon(
                              icon: Icon(skippedTomorrow ? Icons.undo : Icons.skip_next, size: 16),
                              label: Text(skippedTomorrow ? 'Undo Skip' : t(context, 'skip_tomorrow')),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 36),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                              ),
                              onPressed: () async {
                                if (skippedTomorrow) {
                                  skips.remove(tomorrow);
                                } else {
                                  skips.add(tomorrow);
                                }
                                await Api.setSkipDates(s['id'], skips);
                                _reload();
                              },
                            ),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.flight_takeoff, size: 16),
                              label: Text(t(context, 'vacation_mode')),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 36),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                              ),
                              onPressed: () => _showVacationDialog(s),
                            ),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Qty'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 36),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                              ),
                              onPressed: () => _showQuantityDialog(s),
                            ),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.pause, size: 16),
                              label: Text(t(context, 'pause')),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 36),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                              ),
                              onPressed: () async {
                                await Api.setSubscriptionStatus(s['id'], 'paused');
                                _reload();
                              },
                            ),
                          ] else if (status == 'paused') ...[
                            FilledButton.icon(
                              icon: const Icon(Icons.play_arrow, size: 16),
                              label: Text(t(context, 'resume')),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 36),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              onPressed: () async {
                                await Api.setSubscriptionStatus(s['id'], 'active');
                                _reload();
                              },
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
