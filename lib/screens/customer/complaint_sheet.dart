import 'package:flutter/material.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/api.dart';

class ComplaintSheet extends StatefulWidget {
  final String orderId;
  const ComplaintSheet({super.key, required this.orderId});

  @override
  State<ComplaintSheet> createState() => _ComplaintSheetState();
}

class _ComplaintSheetState extends State<ComplaintSheet> {
  String _issueType = 'quality';
  final _comment = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_comment.text.trim().isEmpty) {
      toast(context, 'Please describe the issue', isError: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await Api.fileComplaint(
        orderId: widget.orderId,
        issueType: _issueType,
        issue: _comment.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context, true);
        toast(context, 'Complaint registered successfully');
      }
    } catch (e) {
      if (mounted) toast(context, '$e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final issues = [
      {'id': 'missed', 'name': t(context, 'iss_missed')},
      {'id': 'late', 'name': t(context, 'iss_late')},
      {'id': 'quantity', 'name': t(context, 'iss_quantity')},
      {'id': 'quality', 'name': t(context, 'iss_quality')},
      {'id': 'other', 'name': t(context, 'iss_other')},
    ];

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t(context, 'report_issue'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: MilkColors.charcoal),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            t(context, 'issue_type'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: MilkColors.charcoal),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _issueType,
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
            items: issues
                .map((i) => DropdownMenuItem(value: i['id'], child: Text(i['name']!)))
                .toList(),
            onChanged: (v) => setState(() => _issueType = v!),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _comment,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Details / Description',
              hintText: 'Describe the problem so admin can help resolve it...',
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Submit Complaint',
            onPressed: _submit,
            busy: _busy,
            color: MilkColors.error,
          ),
        ],
      ),
    );
  }
}
