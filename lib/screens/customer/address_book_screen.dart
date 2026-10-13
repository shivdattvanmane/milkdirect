import 'package:flutter/material.dart';
import '../../core/l10n.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/api.dart';

class AddressBookScreen extends StatefulWidget {
  const AddressBookScreen({super.key});

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  late Future<List<Address>> _future = Api.myAddresses();

  void _reload() {
    setState(() => _future = Api.myAddresses());
  }

  void _showAddDialog() {
    String label = 'Home';
    final line = TextEditingController();
    final landmark = TextEditingController();
    final pin = TextEditingController();
    final phone = TextEditingController();
    bool isDefault = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                t(ctx, 'add_address'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: MilkColors.charcoal),
              ),
              const SizedBox(height: 16),
              Row(
                children: ['Home', 'Work', 'Other'].map((l) {
                  final isSelected = label == l;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(l),
                      selected: isSelected,
                      onSelected: (_) => setD(() => label = l),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: line,
                maxLines: 2,
                decoration: InputDecoration(labelText: t(ctx, 'house_flat')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: landmark,
                decoration: InputDecoration(labelText: t(ctx, 'landmark')),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: pin,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(labelText: t(ctx, 'pincode'), counterText: ''),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: const InputDecoration(labelText: 'Contact Phone', counterText: ''),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: isDefault,
                onChanged: (v) => setD(() => isDefault = v ?? false),
                title: Text(t(ctx, 'set_default'), style: const TextStyle(fontSize: 14)),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 16),
              AppButton(
                label: t(ctx, 'save'),
                onPressed: () async {
                  if (line.text.trim().isEmpty || pin.text.trim().length != 6) {
                    toast(ctx, 'Please enter address and 6-digit PIN code', isError: true);
                    return;
                  }
                  await Api.addAddress(
                    label: label,
                    line: line.text.trim(),
                    landmark: landmark.text.trim().isEmpty ? null : landmark.text.trim(),
                    pincode: pin.text.trim(),
                    contactPhone: phone.text.trim().isEmpty ? null : phone.text.trim(),
                    isDefault: isDefault,
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
      backgroundColor: MilkColors.milkWhite,
      appBar: AppBar(title: const Text('My Addresses')),
      body: AsyncView<List<Address>>(
        future: _future,
        builder: (context, list) {
          if (list.isEmpty) {
            return EmptyView(
              message: 'No delivery addresses saved',
              subtitle: 'Add your house or apartment address for daily fresh milk deliveries.',
              buttonLabel: t(context, 'add_address'),
              onButton: _showAddDialog,
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final a in list)
                Padding(
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
                                Icon(
                                  a.label == 'Work' ? Icons.work_outline : Icons.home_outlined,
                                  color: MilkColors.primaryGreen,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  a.label,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                ),
                                if (a.isDefault) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: MilkColors.primaryGreenLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Default',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: MilkColors.primaryGreenDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (v == 'default') {
                                  await Api.setDefaultAddress(a.id);
                                  _reload();
                                } else if (v == 'delete') {
                                  await Api.deleteAddress(a.id);
                                  _reload();
                                }
                              },
                              itemBuilder: (_) => [
                                if (!a.isDefault)
                                  const PopupMenuItem(value: 'default', child: Text('Set as Default')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete')),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(a.line, style: const TextStyle(fontSize: 15, color: MilkColors.charcoal)),
                        if (a.landmark != null && a.landmark!.isNotEmpty)
                          Text('Landmark: ${a.landmark}', style: const TextStyle(fontSize: 13, color: MilkColors.charcoalLight)),
                        const SizedBox(height: 4),
                        Text('PIN: ${a.pincode}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MilkColors.charcoalLight)),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: MilkColors.primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(t(context, 'add_address'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
