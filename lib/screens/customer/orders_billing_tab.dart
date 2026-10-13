import 'package:flutter/material.dart';
import '../../core/l10n.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/api.dart';
import 'complaint_sheet.dart';
import 'rating_sheet.dart';

class OrdersBillingTab extends StatefulWidget {
  const OrdersBillingTab({super.key});

  @override
  State<OrdersBillingTab> createState() => _OrdersBillingTabState();
}

class _OrdersBillingTabState extends State<OrdersBillingTab> {
  late Future<List<Json>> _future = Api.myOrders();

  void _reload() {
    setState(() => _future = Api.myOrders());
  }

  Future<void> _openComplaint(String orderId) async {
    final res = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ComplaintSheet(orderId: orderId),
    );
    if (res == true) _reload();
  }

  Future<void> _openRating(Json order) async {
    final supplierId = order['supplier_id'];
    final supplierName = order['supplier_profiles']?['shop_name'] ?? order['supplier_profiles']?['profiles']?['name'] ?? 'Supplier';
    final res = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => RatingSheet(supplierId: supplierId, supplierName: supplierName),
    );
    if (res == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<Json>>(
      future: _future,
      builder: (context, orders) {
        if (orders.isEmpty) {
          return const EmptyView(
            message: 'No orders recorded yet',
            subtitle: 'Daily deliveries from your subscriptions and one-time orders will appear here.',
          );
        }

        // Calculate totals for month
        double totalSpend = 0;
        int deliveredCount = 0;
        for (final o in orders) {
          if (o['status'] == 'delivered') {
            totalSpend += (o['amount'] as num?)?.toDouble() ?? 0;
            deliveredCount++;
          }
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Billing Summary Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [MilkColors.primaryGreen, MilkColors.primaryGreenDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: MilkColors.primaryGreen.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Delivery & Billing Summary', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(money(totalSpend), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                        child: Text('$deliveredCount Deliveries', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      const Text('Recent 60 days', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SectionHeader(title: 'Order History (${orders.length})'),
            const SizedBox(height: 12),

            ...orders.map((o) {
              final status = o['status'] as String;
              final amount = (o['amount'] as num?)?.toDouble() ?? 0;
              final qty = (o['quantity_l'] as num?)?.toDouble() ?? 0;
              final deliveredQty = (o['delivered_quantity'] as num?)?.toDouble();
              final supplierName = o['supplier_profiles']?['shop_name'] ?? o['supplier_profiles']?['profiles']?['name'] ?? 'Supplier';
              final isDelivered = status == 'delivered';

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            o['delivery_date'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          StatusBadge(status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${fmtQty(isDelivered ? (deliveredQty ?? qty) : qty)} L • ${t(context, o['products']?['milk_type'] ?? 'other')} • ${money(amount)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: MilkColors.charcoal),
                      ),
                      Text(
                        supplierName,
                        style: const TextStyle(fontSize: 13, color: MilkColors.charcoalLight),
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.report_problem_outlined, size: 16, color: MilkColors.error),
                            label: Text(t(context, 'report_issue'), style: const TextStyle(color: MilkColors.error, fontSize: 13)),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 30)),
                            onPressed: () => _openComplaint(o['id']),
                          ),
                          if (isDelivered)
                            TextButton.icon(
                              icon: const Icon(Icons.star_outline_rounded, size: 16, color: Color(0xFFD97706)),
                              label: Text(t(context, 'rate_supplier'), style: const TextStyle(color: Color(0xFFD97706), fontSize: 13)),
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 30)),
                              onPressed: () => _openRating(o),
                            ),
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
