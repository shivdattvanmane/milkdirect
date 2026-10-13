import 'package:flutter/material.dart';
import '../../core/l10n.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/api.dart';

class SubscribeSheet extends StatefulWidget {
  final Json supplier;
  final List<Json> products;
  final Address? defaultAddress;

  const SubscribeSheet({
    super.key,
    required this.supplier,
    required this.products,
    this.defaultAddress,
  });

  @override
  State<SubscribeSheet> createState() => _SubscribeSheetState();
}

class _SubscribeSheetState extends State<SubscribeSheet> {
  late String _selectedProductId = widget.products.first['id'] as String;
  double _quantity = 1.0;
  String _frequency = 'daily';
  final List<int> _customWeekdays = [1, 2, 3, 4, 5, 6, 7];
  String _slot = 'morning_5_8';
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime? _endDate;
  final _instructions = TextEditingController();
  String _paymentMode = 'cash';
  bool _busy = false;

  Json get _selectedProduct =>
      widget.products.firstWhere((p) => p['id'] == _selectedProductId);

  double get _pricePerLitre =>
      (_selectedProduct['price_per_litre'] as num).toDouble();

  double get _deliveryCharge =>
      ((_selectedProduct['delivery_charge'] as num?) ?? 0).toDouble();

  double get _dailyTotal => (_quantity * _pricePerLitre) + _deliveryCharge;

  double get _monthlyEstimate => _dailyTotal * 30;

  @override
  void dispose() {
    _instructions.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final addr = widget.defaultAddress?.line ?? widget.supplier['village'] ?? '';
    if (addr.isEmpty) {
      toast(context, 'Please add a delivery address first', isError: true);
      return;
    }

    setState(() => _busy = true);
    try {
      await Api.createSubscription(
        supplierId: widget.supplier['id'],
        productId: _selectedProductId,
        qty: _quantity,
        start: _startDate,
        end: _endDate,
        frequency: _frequency,
        weekdays: _customWeekdays,
        slot: _slot,
        address: addr,
        instructions: _instructions.text.trim().isEmpty ? null : _instructions.text.trim(),
        paymentMode: _paymentMode,
        deliveryCharge: _deliveryCharge,
      );
      if (mounted) {
        Navigator.pop(context, true);
        toast(context, 'Subscription activated successfully!');
      }
    } catch (e) {
      if (mounted) toast(context, '$e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t(context, 'subscribe'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: MilkColors.charcoal),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),

          // Product Selector
          Text(
            t(context, 'milk_type'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: MilkColors.charcoal),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: widget.products.map((p) {
              final isSel = p['id'] == _selectedProductId;
              return ChoiceChip(
                label: Text('${t(context, p['milk_type'])} • ${money(p['price_per_litre'])}/L'),
                selected: isSel,
                onSelected: (_) => setState(() => _selectedProductId = p['id']),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Quantity Stepper
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Quantity',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: MilkColors.charcoal),
              ),
              QuantityStepper(
                value: _quantity,
                onChanged: (v) => setState(() => _quantity = v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [0.5, 1.0, 1.5, 2.0].map((q) {
              return ActionChip(
                label: Text('${fmtQty(q)} L'),
                onPressed: () => setState(() => _quantity = q),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Frequency
          Text(
            t(context, 'frequency'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: MilkColors.charcoal),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              {'id': 'daily', 'name': t(context, 'freq_daily')},
              {'id': 'alternate', 'name': t(context, 'freq_alternate')},
              {'id': 'custom', 'name': t(context, 'freq_custom')},
            ].map((f) {
              final isSel = _frequency == f['id'];
              return ChoiceChip(
                label: Text(f['name']!),
                selected: isSel,
                onSelected: (_) => setState(() => _frequency = f['id']!),
              );
            }).toList(),
          ),

          if (_frequency == 'custom') ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                {'day': 1, 'name': 'M'},
                {'day': 2, 'name': 'T'},
                {'day': 3, 'name': 'W'},
                {'day': 4, 'name': 'T'},
                {'day': 5, 'name': 'F'},
                {'day': 6, 'name': 'S'},
                {'day': 7, 'name': 'S'},
              ].map((d) {
                final dayNum = d['day'] as int;
                final isChecked = _customWeekdays.contains(dayNum);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isChecked && _customWeekdays.length > 1) {
                        _customWeekdays.remove(dayNum);
                      } else {
                        _customWeekdays.add(dayNum);
                      }
                    });
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isChecked ? MilkColors.primaryGreen : MilkColors.creamLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: isChecked ? MilkColors.primaryGreen : MilkColors.border),
                    ),
                    child: Text(
                      d['name'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isChecked ? Colors.white : MilkColors.charcoal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 20),

          // Delivery Slot
          Text(
            t(context, 'delivery_slots'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: MilkColors.charcoal),
          ),
          const SizedBox(height: 8),
          TimeSlotPicker(
            selectedSlot: _slot,
            onSelected: (s) => setState(() => _slot = s),
          ),
          const SizedBox(height: 16),

          // Start Date
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined, color: MilkColors.primaryGreen),
            title: Text(t(context, 'start_date')),
            subtitle: Text(fmtDate(_startDate), style: const TextStyle(fontWeight: FontWeight.w700)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _startDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (picked != null) setState(() => _startDate = picked);
            },
          ),
          const SizedBox(height: 12),

          // Delivery Instructions
          TextField(
            controller: _instructions,
            decoration: InputDecoration(
              labelText: t(context, 'delivery_instructions'),
              prefixIcon: const Icon(Icons.note_alt_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // Payment Mode
          Text(
            t(context, 'payment_mode'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: MilkColors.charcoal),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _paymentMode,
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
            items: [
              DropdownMenuItem(value: 'cash', child: Text(t(context, 'pay_cash'))),
              DropdownMenuItem(value: 'upi', child: Text(t(context, 'pay_upi'))),
              DropdownMenuItem(value: 'monthly', child: Text(t(context, 'pay_monthly'))),
            ],
            onChanged: (v) => setState(() => _paymentMode = v!),
          ),
          const SizedBox(height: 24),

          // Price Summary Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MilkColors.cream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MilkColors.butterYellow),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${fmtQty(_quantity)} L × ${money(_pricePerLitre)}', style: const TextStyle(fontSize: 15)),
                    Text(money(_quantity * _pricePerLitre), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                if (_deliveryCharge > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Delivery Charge', style: TextStyle(fontSize: 14, color: MilkColors.charcoalLight)),
                      Text(money(_deliveryCharge), style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ],
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Daily Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    Text(money(_dailyTotal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: MilkColors.primaryGreenDark)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Estimated Month (30 days)', style: TextStyle(fontSize: 13, color: MilkColors.charcoalLight)),
                    Text('~${money(_monthlyEstimate)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: MilkColors.charcoalLight)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          AppButton(
            label: t(context, 'confirm'),
            onPressed: _submit,
            busy: _busy,
          ),
        ],
      ),
    );
  }
}
