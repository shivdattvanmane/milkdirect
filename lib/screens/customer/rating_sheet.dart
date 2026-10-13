import 'package:flutter/material.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/api.dart';

class RatingSheet extends StatefulWidget {
  final String supplierId;
  final String supplierName;

  const RatingSheet({super.key, required this.supplierId, required this.supplierName});

  @override
  State<RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<RatingSheet> {
  int _rating = 5;
  final _comment = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await Api.addReview(
        supplierId: widget.supplierId,
        rating: _rating,
        comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context, true);
        toast(context, 'Thank you for your rating!');
      }
    } catch (e) {
      if (mounted) toast(context, '$e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t(context, 'rate_supplier'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: MilkColors.charcoal),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.supplierName,
            style: const TextStyle(fontSize: 15, color: MilkColors.charcoalLight, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return IconButton(
                iconSize: 36,
                icon: Icon(
                  star <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: const Color(0xFFF59E0B),
                ),
                onPressed: () => setState(() => _rating = star),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _comment,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: t(context, 'your_review'),
              hintText: 'Share feedback about delivery punctuality, milk quality...',
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: t(context, 'submit_rating'),
            onPressed: _submit,
            busy: _busy,
          ),
        ],
      ),
    );
  }
}
