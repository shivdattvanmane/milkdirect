import 'package:flutter/material.dart';
import '../../core/l10n.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/api.dart';
import 'address_book_screen.dart';
import 'customer_profile_screen.dart';
import 'my_milk_tab.dart';
import 'orders_billing_tab.dart';
import 'supplier_detail.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const SuppliersExploreTab(),
      const MyMilkTab(),
      const OrdersBillingTab(),
      const CustomerProfileScreen(),
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
              child: const Icon(Icons.local_drink_rounded, color: MilkColors.primaryGreen, size: 20),
            ),
            const SizedBox(width: 8),
            Text(t(context, 'app')),
          ],
        ),
        actions: const [
          LangMenu(),
        ],
      ),
      body: pages[_tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.storefront_outlined),
            selectedIcon: const Icon(Icons.storefront_rounded),
            label: t(context, 'suppliers'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.autorenew_outlined),
            selectedIcon: const Icon(Icons.autorenew_rounded),
            label: t(context, 'my_milk'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long_rounded),
            label: t(context, 'billing'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: t(context, 'profile'),
          ),
        ],
      ),
    );
  }
}

// ---------------- Suppliers Explore Tab ----------------
class SuppliersExploreTab extends StatefulWidget {
  const SuppliersExploreTab({super.key});

  @override
  State<SuppliersExploreTab> createState() => _SuppliersExploreTabState();
}

class _SuppliersExploreTabState extends State<SuppliersExploreTab> {
  String _selectedType = 'all';
  String _searchQuery = '';
  Address? _currentAddress;
  late Future<List<Json>> _suppliersFuture = _load();
  late Future<Json?> _todayDeliveryFuture = Api.todayDelivery();

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    final a = await Api.myAddress();
    if (mounted) setState(() => _currentAddress = a);
  }

  Future<List<Json>> _load() async {
    final a = await Api.myAddress();
    return Api.suppliers(
      pincode: a?.pincode,
      milkType: _selectedType == 'all' ? null : _selectedType,
    );
  }

  void _reload() {
    setState(() {
      _suppliersFuture = _load();
      _todayDeliveryFuture = Api.todayDelivery();
    });
  }

  @override
  Widget build(BuildContext context) {
    final addressText = _currentAddress != null
        ? '${_currentAddress!.label} • ${_currentAddress!.pincode}'
        : 'Select Address';

    return RefreshIndicator(
      onRefresh: () async => _reload(),
      color: MilkColors.primaryGreen,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Address Selector Bar
          InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddressBookScreen()),
              );
              _loadAddress();
              _reload();
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: MilkColors.creamLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: MilkColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: MilkColors.primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t(context, 'delivering_to'),
                          style: const TextStyle(fontSize: 11, color: MilkColors.charcoalMuted, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          addressText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: MilkColors.charcoal),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: MilkColors.charcoalLight),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Search Box
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: t(context, 'search_hint'),
              prefixIcon: const Icon(Icons.search, color: MilkColors.charcoalLight),
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          // Filter Chips (All, Cow, Buffalo, Other)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                {'id': 'all', 'label': t(context, 'all')},
                {'id': 'cow', 'label': t(context, 'cow')},
                {'id': 'buffalo', 'label': t(context, 'buffalo')},
                {'id': 'other', 'label': t(context, 'other')},
              ].map((f) {
                final isSel = _selectedType == f['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f['label']!),
                    selected: isSel,
                    onSelected: (_) {
                      setState(() {
                        _selectedType = f['id']!;
                        _suppliersFuture = _load();
                      });
                    },
                    selectedColor: MilkColors.primaryGreen,
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : MilkColors.charcoal,
                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Today's Delivery Card
          FutureBuilder<Json?>(
            future: _todayDeliveryFuture,
            builder: (context, snap) {
              if (snap.data != null) {
                final order = snap.data!;
                final status = order['status'] as String;
                final qty = (order['quantity_l'] as num).toDouble();
                final type = order['products']?['milk_type'] ?? 'cow';
                final supplierName = order['supplier']?['shop_name'] ?? order['supplier']?['profiles']?['name'] ?? 'Supplier';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: AppCard(
                    color: MilkColors.cream,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.delivery_dining_rounded, color: MilkColors.primaryGreen, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t(context, 'today_delivery'),
                                style: const TextStyle(fontSize: 13, color: MilkColors.charcoalLight, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '${fmtQty(qty)} L ${t(context, type)} • $supplierName',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: MilkColors.charcoal),
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(status),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Nearby Suppliers Section
          SectionHeader(title: t(context, 'near_you')),
          const SizedBox(height: 12),

          AsyncView<List<Json>>(
            future: _suppliersFuture,
            builder: (context, list) {
              var filtered = list;
              if (_searchQuery.isNotEmpty) {
                filtered = list.where((s) {
                  final name = (s['shop_name'] ?? s['profiles']?['name'] ?? '').toString().toLowerCase();
                  final village = (s['village'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) || village.contains(_searchQuery);
                }).toList();
              }

              if (filtered.isEmpty) {
                return EmptyView(
                  message: 'No verified suppliers in this area',
                  subtitle: 'Try changing your search or explore suppliers serving other PIN codes.',
                  buttonLabel: 'View All Suppliers',
                  onButton: () {
                    setState(() {
                      _selectedType = 'all';
                      _searchQuery = '';
                      _suppliersFuture = Api.suppliers();
                    });
                  },
                );
              }

              return Column(
                children: filtered.map((s) {
                  final name = s['shop_name'] ?? s['profiles']?['name'] ?? 'Local Dairy';
                  final village = s['village'] ?? '';
                  final rating = (s['rating_avg'] as num?)?.toDouble() ?? 5.0;
                  final ratingCount = (s['rating_count'] as num?)?.toInt() ?? 0;
                  final type = s['type'] ?? 'farmer';
                  final products = (s['products'] as List?)?.cast<Json>() ?? [];
                  final availableProducts = products.where((p) => p['available'] == true).toList();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: AppCard(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SupplierDetailScreen(supplier: s)),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: MilkColors.primaryGreenLight,
                                child: Icon(
                                  type == 'farmer' ? Icons.agriculture_rounded : Icons.two_wheeler_rounded,
                                  color: MilkColors.primaryGreenDark,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: MilkColors.charcoal),
                                          ),
                                        ),
                                        RatingBarView(rating: rating, count: ratingCount),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$village • ${t(context, type)}',
                                      style: const TextStyle(fontSize: 13, color: MilkColors.charcoalLight, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: MilkColors.primaryGreenLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.verified_rounded, size: 12, color: MilkColors.primaryGreenDark),
                                          const SizedBox(width: 4),
                                          Text(
                                            t(context, 'verified'),
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: MilkColors.primaryGreenDark),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (availableProducts.isNotEmpty) ...[
                            const Divider(height: 20),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: availableProducts.map((p) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: MilkColors.creamLight,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: MilkColors.border),
                                  ),
                                  child: Text(
                                    '${t(context, p['milk_type'])}: ${money(p['price_per_litre'])}/L',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: MilkColors.charcoal),
                                  ),
                                );
                              }).toList(),
                            ),
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
    );
  }
}
