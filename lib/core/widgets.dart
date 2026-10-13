import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'l10n.dart';
import 'models.dart';
import 'state.dart';
import 'theme.dart';

void toast(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
      ),
      backgroundColor: isError ? MilkColors.error : MilkColors.charcoal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ),
  );
}

/// Primary / Secondary / Outlined Button
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final bool outlined;
  final IconData? icon;
  final Color? color;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.busy = false,
    this.outlined = false,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton(
        onPressed: busy ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color ?? MilkColors.primaryGreen, width: 1.5),
          foregroundColor: color ?? MilkColors.primaryGreen,
        ),
        child: _buildChild(),
      );
    }
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: color != null ? FilledButton.styleFrom(backgroundColor: color) : null,
      child: _buildChild(),
    );
  }

  Widget _buildChild() {
    if (busy) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
    }
    return Text(label);
  }
}

/// Legacy alias for BigButton
class BigButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  const BigButton({super.key, required this.label, this.onPressed, this.busy = false});
  @override
  Widget build(BuildContext context) => AppButton(label: label, onPressed: onPressed, busy: busy);
}

/// Card with subtle shadow and border
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MilkColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Status Pill Badge
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label = t(context, 'st_$status');

    switch (status) {
      case 'active':
      case 'delivered':
      case 'paid':
      case 'verified':
      case 'resolved':
        bg = MilkColors.primaryGreenLight;
        fg = MilkColors.primaryGreenDark;
        break;
      case 'pending':
      case 'rescheduled':
      case 'paused':
      case 'open':
        bg = MilkColors.butterYellowLight;
        fg = const Color(0xFFB7791F);
        break;
      case 'missed':
      case 'cancelled':
      case 'rejected':
        bg = const Color(0xFFFFEBEE);
        fg = MilkColors.error;
        break;
      default:
        bg = const Color(0xFFF0F4F8);
        fg = MilkColors.charcoalLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Legacy alias for StatusChip
class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});
  @override
  Widget build(BuildContext context) => StatusBadge(status);
}

/// Section Header
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: MilkColors.charcoal,
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: MilkColors.primaryGreen,
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
      ],
    );
  }
}

/// Stat Dashboard Tile (for Farmer/Milkman/Admin)
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final Color? bgColor;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? MilkColors.primaryGreen;
    final bg = bgColor ?? MilkColors.primaryGreenLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MilkColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: c, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: MilkColors.charcoal),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: MilkColors.charcoalLight, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Quantity Stepper
class QuantityStepper extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double step;
  final double min;
  final double max;

  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.step = 0.5,
    this.min = 0.5,
    this.max = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MilkColors.creamLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MilkColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: MilkColors.primaryGreen),
            onPressed: value > min ? () => onChanged((value - step).clamp(min, max)) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${fmtQty(value)} L',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: MilkColors.charcoal),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: MilkColors.primaryGreen),
            onPressed: value < max ? () => onChanged((value + step).clamp(min, max)) : null,
          ),
        ],
      ),
    );
  }
}

/// Time Slot Picker
class TimeSlotPicker extends StatelessWidget {
  final String selectedSlot;
  final ValueChanged<String> onSelected;

  const TimeSlotPicker({super.key, required this.selectedSlot, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final slots = [
      {'id': 'morning_5_8', 'icon': Icons.wb_sunny_outlined, 'title': t(context, 'morning_5_8')},
      {'id': 'morning_8_10', 'icon': Icons.wb_twilight_outlined, 'title': t(context, 'morning_8_10')},
      {'id': 'evening_5_8', 'icon': Icons.nights_stay_outlined, 'title': t(context, 'evening_5_8')},
    ];

    return Column(
      children: slots.map((s) {
        final isSelected = selectedSlot == s['id'];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => onSelected(s['id'] as String),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? MilkColors.primaryGreenLight : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? MilkColors.primaryGreen : MilkColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    s['icon'] as IconData,
                    color: isSelected ? MilkColors.primaryGreenDark : MilkColors.charcoalLight,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s['title'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? MilkColors.primaryGreenDark : MilkColors.charcoal,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: MilkColors.primaryGreen, size: 20),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Star Rating Bar
class RatingBarView extends StatelessWidget {
  final double rating;
  final int count;
  final double size;

  const RatingBarView({super.key, required this.rating, this.count = 0, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: MilkColors.charcoal),
        ),
        if (count > 0)
          Text(
            ' ($count)',
            style: const TextStyle(fontSize: 12, color: MilkColors.charcoalMuted),
          ),
      ],
    );
  }
}

/// Empty State with Friendly Design
class EmptyView extends StatelessWidget {
  final String? message;
  final String? subtitle;
  final IconData icon;
  final String? buttonLabel;
  final VoidCallback? onButton;

  const EmptyView({
    super.key,
    this.message,
    this.subtitle,
    this.icon = Icons.local_drink_outlined,
    this.buttonLabel,
    this.onButton,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: MilkColors.cream,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 54, color: MilkColors.primaryGreen),
            ),
            const SizedBox(height: 20),
            Text(
              message ?? t(context, 'no_data'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: MilkColors.charcoal),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: MilkColors.charcoalLight),
              ),
            ],
            if (buttonLabel != null && onButton != null) ...[
              const SizedBox(height: 20),
              AppButton(label: buttonLabel!, onPressed: onButton),
            ],
          ],
        ),
      ),
    );
  }
}

/// Language Dropdown Menu
class LangMenu extends StatelessWidget {
  const LangMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    const langs = {'en': 'English', 'hi': 'हिंदी', 'mr': 'मराठी'};

    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: MilkColors.creamLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MilkColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: state.lang,
          icon: const Icon(Icons.language, size: 18, color: MilkColors.primaryGreen),
          style: const TextStyle(
            color: MilkColors.charcoal,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          onChanged: (l) {
            if (l != null) state.setLang(l);
          },
          items: langs.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
        ),
      ),
    );
  }
}

/// Async Loader Wrapper
class AsyncView<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final Widget? loading;

  const AsyncView({super.key, required this.future, required this.builder, this.loading});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (c, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return loading ??
              Padding(
                padding: const EdgeInsets.all(16),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey.shade200,
                  highlightColor: Colors.grey.shade50,
                  child: Column(
                    children: List.generate(
                      4,
                      (_) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
              );
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: MilkColors.error),
                  const SizedBox(height: 12),
                  Text('${snap.error}', textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }
        return builder(c, snap.data as T);
      },
    );
  }
}

/// Password strength level and meter
enum PasswordStrength { none, weak, fair, strong }

class PasswordStrengthMeter extends StatelessWidget {
  final String password;

  const PasswordStrengthMeter({super.key, required this.password});

  static PasswordStrength evaluate(String p) {
    if (p.isEmpty) return PasswordStrength.none;
    int score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[a-zA-Z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[^a-zA-Z0-9]').hasMatch(p) || p.length >= 12) score++;

    if (score <= 1) return PasswordStrength.weak;
    if (score <= 3) return PasswordStrength.fair;
    return PasswordStrength.strong;
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final strength = evaluate(password);
    Color color;
    String label;
    int activeBars;

    switch (strength) {
      case PasswordStrength.weak:
        color = MilkColors.error;
        label = 'Weak (Needs 8+ chars, letters & numbers)';
        activeBars = 1;
        break;
      case PasswordStrength.fair:
        color = const Color(0xFFD97706);
        label = 'Fair (Good mix of characters)';
        activeBars = 2;
        break;
      case PasswordStrength.strong:
        color = MilkColors.primaryGreen;
        label = 'Strong password';
        activeBars = 3;
        break;
      case PasswordStrength.none:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(3, (i) {
              final active = i < activeBars;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: active ? color : MilkColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

