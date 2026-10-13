import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/l10n.dart';
import '../../core/models.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/api.dart';

class SupplierHome extends StatefulWidget {
  const SupplierHome({super.key});

  @override
  State<SupplierHome> createState() => _SupplierHomeState();
}

class _SupplierHomeState extends State<SupplierHome> {
  late Future<Json> _profileFuture = Api.mySupplier();
  int _tabIndex = 0;

  void _reloadProfile() {
    setState(() => _profileFuture = Api.mySupplier());
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<Json>(
      future: _profileFuture,
      builder: (context, sp) {
        final pages = [
          SupplierTodayTab(supplier: sp),
          SupplierMilkTab(supplier: sp),
          SupplierBusinessProfileTab(supplier: sp, onProfileUpdated: _reloadProfile),
        ];

        return Scaffold(
          backgroundColor: MilkColors.milkWhite,
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: MilkColors.primaryGreenLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.agriculture_rounded, color: MilkColors.primaryGreen, size: 20),
                ),
                const SizedBox(width: 8),
                Text(sp['shop_name'] ?? sp['profiles']?['name'] ?? t(context, 'app')),
              ],
            ),
            actions: const [LangMenu()],
          ),
          body: Column(
            children: [
              if (sp['verification_status'] != 'verified')
                Container(
                  width: double.infinity,
                  color: MilkColors.cream,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFFB7791F), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          sp['verification_status'] == 'rejected'
                              ? 'Verification rejected: ${sp['rejection_reason'] ?? 'Please review your farm details'}'
                              : 'Account pending admin verification. Customers will see your listing once approved.',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFB7791F)),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(child: pages[_tabIndex]),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tabIndex,
            onDestinationSelected: (i) => setState(() => _tabIndex = i),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.today_outlined),
                selectedIcon: const Icon(Icons.today_rounded),
                label: t(context, 'today'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.local_drink_outlined),
                selectedIcon: const Icon(Icons.local_drink_rounded),
                label: t(context, 'my_milk'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.storefront_outlined),
                selectedIcon: const Icon(Icons.storefront_rounded),
                label: 'Farm Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------- TODAY'S DELIVERIES TAB ----------------
class SupplierTodayTab extends StatefulWidget {
  final Json supplier;
  const SupplierTodayTab({super.key, required this.supplier});

  @override
  State<SupplierTodayTab> createState() => _SupplierTodayTabState();
}

class _SupplierTodayTabState extends State<SupplierTodayTab> {
  DateTime _date = DateTime.now();
  late Future<List<Json>> _ordersFuture = Api.todayOrders(widget.supplier['id'], _date);

  void _reload() {
    setState(() => _ordersFuture = Api.todayOrders(widget.supplier['id'], _date));
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<Json>>(
      future: _ordersFuture,
      builder: (context, orders) {
        // Summary metrics
        double totalLitres = 0;
        int pending = 0;
        double sales = 0;
        double toCollect = 0;

        for (final o in orders) {
          final q = (o['quantity_l'] as num).toDouble();
          final amt = (o['amount'] as num).toDouble();
          final status = o['status'] as String;
          final payments = (o['payments'] as List?) ?? [];

          totalLitres += q;
          if (status == 'pending') pending++;
          if (status == 'delivered') {
            sales += amt;
            if (payments.isEmpty) toCollect += amt;
          }
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Date Switcher Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  fmtDate(_date),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: MilkColors.charcoal),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          _date = _date.subtract(const Duration(days: 1));
                          _ordersFuture = Api.todayOrders(widget.supplier['id'], _date);
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today, size: 20),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (picked != null) {
                          setState(() {
                            _date = picked;
                            _ordersFuture = Api.todayOrders(widget.supplier['id'], _date);
                          });
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setState(() {
                          _date = _date.add(const Duration(days: 1));
                          _ordersFuture = Api.todayOrders(widget.supplier['id'], _date);
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Big Stat Tiles
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.45,
              children: [
                StatTile(
                  label: t(context, 'litres_needed'),
                  value: '${fmtQty(totalLitres)} L',
                  icon: Icons.local_drink_rounded,
                  color: MilkColors.primaryGreen,
                  bgColor: MilkColors.primaryGreenLight,
                ),
                StatTile(
                  label: t(context, 'pending_deliveries'),
                  value: '$pending / ${orders.length}',
                  icon: Icons.pending_actions_rounded,
                  color: const Color(0xFFD97706),
                  bgColor: MilkColors.cream,
                ),
                StatTile(
                  label: t(context, 'sales_today'),
                  value: money(sales),
                  icon: Icons.payments_rounded,
                  color: MilkColors.dairyBlue,
                  bgColor: MilkColors.dairyBlueLight,
                ),
                StatTile(
                  label: t(context, 'to_collect'),
                  value: money(toCollect),
                  icon: Icons.account_balance_wallet_rounded,
                  color: MilkColors.error,
                  bgColor: const Color(0xFFFFEBEE),
                ),
              ],
            ),
            const SizedBox(height: 24),

            SectionHeader(title: '${t(context, 'orders_today')} (${orders.length})'),
            const SizedBox(height: 12),

            if (orders.isEmpty)
              const EmptyView(
                message: 'No delivery orders for this date',
                subtitle: 'Active subscriptions will automatically generate orders daily.',
              )
            else
              ...orders.map((o) {
                final status = o['status'] as String;
                final cust = o['customer'] ?? {};
                final custName = cust['name'] ?? 'Customer';
                final custPhone = cust['phone'] as String?;
                final qty = (o['quantity_l'] as num).toDouble();
                final amount = (o['amount'] as num).toDouble();
                final address = o['address'] ?? '';
                final instructions = o['instructions'] as String?;
                final payments = (o['payments'] as List?) ?? [];
                final isPaid = payments.isNotEmpty;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                custName,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                              ),
                            ),
                            StatusBadge(status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${fmtQty(qty)} L • ${t(context, o['products']?['milk_type'] ?? 'other')} • ${money(amount)}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: MilkColors.charcoal),
                        ),
                        if (address.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 15, color: MilkColors.charcoalLight),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(address, style: const TextStyle(fontSize: 13, color: MilkColors.charcoalLight)),
                              ),
                            ],
                          ),
                        ],
                        if (instructions != null && instructions.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Note: $instructions', style: const TextStyle(fontSize: 12, color: Color(0xFFB7791F), fontStyle: FontStyle.italic)),
                        ],
                        const SizedBox(height: 12),

                        // Contact Buttons
                        Row(
                          children: [
                            if (custPhone != null && custPhone.isNotEmpty) ...[
                              OutlinedButton.icon(
                                icon: const Icon(Icons.call, size: 16),
                                label: Text(t(context, 'call')),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 36),
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                ),
                                onPressed: () => _launchUrl('tel:$custPhone'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.chat, size: 16, color: Color(0xFF25D366)),
                                label: Text(t(context, 'whatsapp'), style: const TextStyle(color: Color(0xFF25D366))),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF25D366)),
                                  minimumSize: const Size(0, 36),
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                ),
                                onPressed: () {
                                  final num = custPhone.replaceAll('+', '').replaceAll(' ', '');
                                  _launchUrl('https://wa.me/$num?text=Hello%20$custName,%20your%20milk%20is%20out%20for%20delivery!');
                                },
                              ),
                            ],
                          ],
                        ),
                        const Divider(height: 20),

                        // Delivery Actions
                        if (status == 'pending') ...[
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: () async {
                                    await Api.markOrder(o['id'], 'delivered', qty);
                                    _reload();
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: MilkColors.primaryGreen,
                                    minimumSize: const Size(0, 42),
                                  ),
                                  child: Text(t(context, 'mark_delivered')),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    await Api.markOrder(o['id'], 'missed', 0);
                                    _reload();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: MilkColors.error,
                                    side: const BorderSide(color: MilkColors.error),
                                    minimumSize: const Size(0, 42),
                                  ),
                                  child: Text(t(context, 'mark_missed')),
                                ),
                              ),
                            ],
                          ),
                        ] else if (status == 'delivered' && !isPaid) ...[
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.money, size: 16),
                                  label: Text(t(context, 'cash_received')),
                                  onPressed: () async {
                                    await Api.recordPayment(o['id'], amount, 'cash');
                                    _reload();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.qr_code, size: 16),
                                  label: Text(t(context, 'upi_received')),
                                  onPressed: () async {
                                    await Api.recordPayment(o['id'], amount, 'upi');
                                    _reload();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ] else if (isPaid) ...[
                          Row(
                            children: [
                              const Icon(Icons.check_circle, color: MilkColors.primaryGreen, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                '${t(context, 'st_paid')} (${money(amount)})',
                                style: const TextStyle(fontWeight: FontWeight.w700, color: MilkColors.primaryGreenDark),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }
}

// ---------------- MY MILK LISTING TAB ----------------
class SupplierMilkTab extends StatefulWidget {
  final Json supplier;
  const SupplierMilkTab({super.key, required this.supplier});

  @override
  State<SupplierMilkTab> createState() => _SupplierMilkTabState();
}

class _SupplierMilkTabState extends State<SupplierMilkTab> {
  late Future<List<Json>> _productsFuture = Api.myProducts(widget.supplier['id']);

  void _reload() {
    setState(() => _productsFuture = Api.myProducts(widget.supplier['id']));
  }

  void _showAddProductDialog() {
    String type = 'cow';
    final price = TextEditingController(text: '65');
    final qty = TextEditingController(text: '20');
    final fat = TextEditingController();
    final snf = TextEditingController();
    String source = 'own_cattle';
    String processing = 'raw';
    final deliveryCharge = TextEditingController(text: '0');

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
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                t(ctx, 'add_milk'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: InputDecoration(labelText: t(ctx, 'milk_type')),
                items: ['cow', 'buffalo', 'other']
                    .map((m) => DropdownMenuItem(value: m, child: Text(t(ctx, m))))
                    .toList(),
                onChanged: (v) => setD(() => type = v!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: price,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: t(ctx, 'price_per_litre')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: qty,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: t(ctx, 'daily_capacity')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: fat,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Fat % (Optional)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: snf,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'SNF % (Optional)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: source,
                decoration: InputDecoration(labelText: t(ctx, 'source')),
                items: [
                  DropdownMenuItem(value: 'own_cattle', child: Text(t(ctx, 'own_cattle'))),
                  DropdownMenuItem(value: 'collected', child: Text(t(ctx, 'collected'))),
                ],
                onChanged: (v) => setD(() => source = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: processing,
                decoration: InputDecoration(labelText: t(ctx, 'processing')),
                items: [
                  DropdownMenuItem(value: 'raw', child: Text(t(ctx, 'raw'))),
                  DropdownMenuItem(value: 'boiled', child: Text(t(ctx, 'boiled'))),
                  DropdownMenuItem(value: 'pasteurised', child: Text(t(ctx, 'pasteurised'))),
                ],
                onChanged: (v) => setD(() => processing = v!),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: t(ctx, 'save'),
                onPressed: () async {
                  final p = double.tryParse(price.text) ?? 0;
                  final q = double.tryParse(qty.text) ?? 0;
                  if (p <= 0) return;

                  await Api.addProduct(
                    supplierId: widget.supplier['id'],
                    type: type,
                    price: p,
                    dailyQty: q,
                    fatPercent: double.tryParse(fat.text),
                    snfPercent: double.tryParse(snf.text),
                    source: source,
                    processing: processing,
                    deliveryCharge: double.tryParse(deliveryCharge.text) ?? 0,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _reload();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AsyncView<List<Json>>(
        future: _productsFuture,
        builder: (context, products) {
          if (products.isEmpty) {
            return EmptyView(
              message: 'No milk products listed',
              subtitle: 'Add Cow or Buffalo milk listings with prices and daily capacity.',
              buttonLabel: t(context, 'add_milk'),
              onButton: _showAddProductDialog,
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionHeader(
                title: 'Milk Listings (${products.length})',
                actionLabel: '+ Add Milk',
                onAction: _showAddProductDialog,
              ),
              const SizedBox(height: 12),
              ...products.map((p) {
                final isAvail = p['available'] == true;
                final fat = (p['fat_percent'] as num?)?.toDouble();
                final snf = (p['snf_percent'] as num?)?.toDouble();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: MilkColors.creamLight, borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.water_drop, color: MilkColors.dairyBlue, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t(context, p['milk_type']),
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                    ),
                                    Text(
                                      '${money(p['price_per_litre'])}/L • ${fmtQty(p['daily_quantity_l'])} L/day',
                                      style: const TextStyle(fontSize: 14, color: MilkColors.charcoalLight, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Switch(
                              value: isAvail,
                              activeThumbColor: MilkColors.primaryGreen,
                              onChanged: (v) async {
                                await Api.setProductAvailable(p['id'], v);
                                _reload();
                              },
                            ),
                          ],
                        ),
                        if (fat != null || snf != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (fat != null) Text('Fat: ${fat.toStringAsFixed(1)}%   ', style: const TextStyle(fontSize: 13, color: MilkColors.charcoalLight)),
                              if (snf != null) Text('SNF: ${snf.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 13, color: MilkColors.charcoalLight)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductDialog,
        backgroundColor: MilkColors.primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(t(context, 'add_milk'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ---------------- FARM / BUSINESS PROFILE TAB ----------------
class SupplierBusinessProfileTab extends StatelessWidget {
  final Json supplier;
  final VoidCallback onProfileUpdated;

  const SupplierBusinessProfileTab({super.key, required this.supplier, required this.onProfileUpdated});

  void _showEditProfile(BuildContext context) {
    final shop = TextEditingController(text: supplier['shop_name'] ?? '');
    final about = TextEditingController(text: supplier['about'] ?? '');
    final upi = TextEditingController(text: supplier['upi_id'] ?? '');
    final bankAcc = TextEditingController(text: supplier['bank_account_no'] ?? '');
    final ifsc = TextEditingController(text: supplier['bank_ifsc'] ?? '');
    final fssai = TextEditingController(text: supplier['fssai_no'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            const Text('Edit Farm / Business Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(controller: shop, decoration: const InputDecoration(labelText: 'Shop / Farm Name')),
            const SizedBox(height: 12),
            TextField(controller: about, maxLines: 2, decoration: const InputDecoration(labelText: 'About Farm / Description')),
            const SizedBox(height: 12),
            TextField(controller: upi, decoration: const InputDecoration(labelText: 'UPI ID (for payments)')),
            const SizedBox(height: 12),
            TextField(controller: bankAcc, decoration: const InputDecoration(labelText: 'Bank Account No.')),
            const SizedBox(height: 12),
            TextField(controller: ifsc, decoration: const InputDecoration(labelText: 'Bank IFSC Code')),
            const SizedBox(height: 12),
            TextField(controller: fssai, decoration: const InputDecoration(labelText: 'FSSAI License / Registration No.')),
            const SizedBox(height: 20),
            AppButton(
              label: t(ctx, 'save'),
              onPressed: () async {
                await Api.updateSupplierProfile(
                  shopName: shop.text.trim().isEmpty ? null : shop.text.trim(),
                  about: about.text.trim().isEmpty ? null : about.text.trim(),
                  upiId: upi.text.trim().isEmpty ? null : upi.text.trim(),
                  bankAccountNo: bankAcc.text.trim().isEmpty ? null : bankAcc.text.trim(),
                  bankIfsc: ifsc.text.trim().isEmpty ? null : ifsc.text.trim(),
                  fssaiNo: fssai.text.trim().isEmpty ? null : fssai.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                onProfileUpdated();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = supplier['shop_name'] ?? supplier['profiles']?['name'] ?? 'Dairy Farm';
    final status = supplier['verification_status'] ?? 'pending';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: MilkColors.primaryGreen),
                    onPressed: () => _showEditProfile(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  StatusBadge(status),
                  const SizedBox(width: 8),
                  Text('${supplier['village'] ?? ''} • PIN: ${supplier['pincode'] ?? ''}'),
                ],
              ),
              if (supplier['upi_id'] != null) ...[
                const SizedBox(height: 10),
                Text('UPI: ${supplier['upi_id']}', style: const TextStyle(fontWeight: FontWeight.w700, color: MilkColors.dairyBlue)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.logout, color: MilkColors.error),
                title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700, color: MilkColors.error)),
                onTap: () => context.read<AppState>().signOutAndChangeRole(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
