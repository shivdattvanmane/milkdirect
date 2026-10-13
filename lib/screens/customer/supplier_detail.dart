import 'package:flutter/material.dart';
import '../../core/l10n.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/api.dart';
import 'rating_sheet.dart';
import 'subscribe_sheet.dart';

class SupplierDetailScreen extends StatefulWidget {
  final Json supplier;
  const SupplierDetailScreen({super.key, required this.supplier});

  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> {
  Address? _defaultAddress;
  late Future<List<Json>> _reviewsFuture = Api.supplierReviews(widget.supplier['id']);

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    final a = await Api.myAddress();
    if (mounted) setState(() => _defaultAddress = a);
  }

  void _showOrderOnceDialog(Json prod) {
    double qty = 1.0;
    DateTime date = DateTime.now().add(const Duration(days: 1));
    String slot = 'morning_5_8';
    final instructions = TextEditingController();
    bool busy = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t(ctx, 'one_time'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Text(
                '${t(ctx, prod['milk_type'])} • ${money(prod['price_per_litre'])}/L',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: MilkColors.primaryGreenDark),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Quantity', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  QuantityStepper(value: qty, onChanged: (v) => setD(() => qty = v)),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined, color: MilkColors.primaryGreen),
                title: Text(t(ctx, 'start_date')),
                subtitle: Text(fmtDate(date), style: const TextStyle(fontWeight: FontWeight.w700)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: date,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) setD(() => date = picked);
                },
              ),
              const SizedBox(height: 12),
              TimeSlotPicker(
                selectedSlot: slot,
                onSelected: (s) => setD(() => slot = s),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: instructions,
                decoration: InputDecoration(labelText: t(ctx, 'delivery_instructions')),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: '${t(ctx, 'confirm_order')} (${money(qty * (prod['price_per_litre'] as num))})',
                busy: busy,
                onPressed: () async {
                  final addr = _defaultAddress?.line ?? widget.supplier['village'] ?? '';
                  setD(() => busy = true);
                  try {
                    await Api.placeOrder(
                      supplierId: widget.supplier['id'],
                      productId: prod['id'],
                      qty: qty,
                      date: date,
                      slot: slot,
                      address: addr,
                      instructions: instructions.text.trim().isEmpty ? null : instructions.text.trim(),
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      toast(ctx, 'One-time order placed successfully!');
                    }
                  } catch (e) {
                    if (ctx.mounted) toast(ctx, '$e', isError: true);
                  } finally {
                    if (ctx.mounted) setD(() => busy = false);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSubscribe(List<Json> availableProducts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubscribeSheet(
        supplier: widget.supplier,
        products: availableProducts,
        defaultAddress: _defaultAddress,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.supplier;
    final name = s['shop_name'] ?? s['profiles']?['name'] ?? 'Dairy Farm';
    final village = s['village'] ?? '';
    final rating = (s['rating_avg'] as num?)?.toDouble() ?? 5.0;
    final ratingCount = (s['rating_count'] as num?)?.toInt() ?? 0;
    final type = s['type'] ?? 'farmer';
    final about = s['about'] as String?;
    final products = (s['products'] as List?)?.cast<Json>() ?? [];
    final availableProducts = products.where((p) => p['available'] == true).toList();

    return Scaffold(
      backgroundColor: MilkColors.milkWhite,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [MilkColors.primaryGreen, MilkColors.primaryGreenDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    type == 'farmer' ? Icons.agriculture_rounded : Icons.two_wheeler_rounded,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Supplier Meta
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: MilkColors.cream,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: MilkColors.butterYellow),
                        ),
                        child: Text(
                          t(context, type),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFFB7791F)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: MilkColors.primaryGreenLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, size: 14, color: MilkColors.primaryGreenDark),
                            const SizedBox(width: 4),
                            Text(
                              t(context, 'verified'),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: MilkColors.primaryGreenDark),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: MilkColors.charcoalLight),
                      const SizedBox(width: 4),
                      Text(village, style: const TextStyle(fontSize: 15, color: MilkColors.charcoalLight, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      RatingBarView(rating: rating, count: ratingCount, size: 20),
                    ],
                  ),
                  if (about != null && about.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(about, style: const TextStyle(fontSize: 14, color: MilkColors.charcoalLight, height: 1.4)),
                  ],
                  const SizedBox(height: 24),

                  // Products Listing
                  SectionHeader(title: 'Milk Products (${availableProducts.length})'),
                  const SizedBox(height: 12),

                  if (availableProducts.isEmpty)
                    const EmptyView(message: 'No milk products currently available')
                  else
                    ...availableProducts.map((p) {
                      final fat = (p['fat_percent'] as num?)?.toDouble();
                      final snf = (p['snf_percent'] as num?)?.toDouble();
                      final source = p['source'] ?? 'own_cattle';
                      final processing = p['processing'] ?? 'raw';
                      final price = (p['price_per_litre'] as num).toDouble();

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
                                          color: MilkColors.creamLight,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.water_drop_rounded, color: MilkColors.dairyBlue, size: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            t(context, p['milk_type'] ?? 'other'),
                                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                                          ),
                                          Text(
                                            '${t(context, processing)} • ${t(context, source)}',
                                            style: const TextStyle(fontSize: 12, color: MilkColors.charcoalLight),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${money(price)}/L',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: MilkColors.primaryGreenDark),
                                  ),
                                ],
                              ),
                              if (fat != null || snf != null) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    if (fat != null)
                                      Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: MilkColors.cream, borderRadius: BorderRadius.circular(8)),
                                        child: Text('Fat: ${fat.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                      ),
                                    if (snf != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: MilkColors.cream, borderRadius: BorderRadius.circular(8)),
                                        child: Text('SNF: ${snf.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                      ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _showOrderOnceDialog(p),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(0, 42),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: Text(t(context, 'one_time')),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: () => _openSubscribe([p]),
                                      style: FilledButton.styleFrom(
                                        minimumSize: const Size(0, 42),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: Text(t(context, 'subscribe')),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 24),

                  // Reviews & Ratings
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SectionHeader(title: t(context, 'reviews')),
                      TextButton.icon(
                        icon: const Icon(Icons.rate_review_outlined, size: 18),
                        label: Text(t(context, 'rate_supplier')),
                        onPressed: () async {
                          final ok = await showModalBottomSheet<bool>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                            builder: (_) => RatingSheet(supplierId: widget.supplier['id'], supplierName: name),
                          );
                          if (ok == true) {
                            setState(() => _reviewsFuture = Api.supplierReviews(widget.supplier['id']));
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  AsyncView<List<Json>>(
                    future: _reviewsFuture,
                    builder: (context, reviews) {
                      if (reviews.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('No reviews yet. Be the first to review!', style: TextStyle(color: MilkColors.charcoalMuted)),
                        );
                      }
                      return Column(
                        children: reviews.map((r) {
                          final cName = r['customer']?['name'] ?? 'Verified Customer';
                          final stars = (r['rating'] as num?)?.toInt() ?? 5;
                          final comment = r['comment'] as String?;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: AppCard(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(cName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                      Row(
                                        children: List.generate(
                                          5,
                                          (i) => Icon(
                                            i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                                            size: 16,
                                            color: const Color(0xFFF59E0B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (comment != null && comment.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(comment, style: const TextStyle(fontSize: 13, color: MilkColors.charcoalLight)),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: availableProducts.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
              ),
              child: SafeArea(
                child: AppButton(
                  label: t(context, 'subscribe'),
                  onPressed: () => _openSubscribe(availableProducts),
                ),
              ),
            )
          : null,
    );
  }
}
