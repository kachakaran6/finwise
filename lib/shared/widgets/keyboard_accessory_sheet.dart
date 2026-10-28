import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../app/theme/tokens.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// Compact, contextual keyboard accessory sheet that displays relevant
/// suggestions immediately above the on-screen numeric keyboard.
class KeyboardAccessorySheet extends StatelessWidget {
  const KeyboardAccessorySheet({
    super.key,
    required this.fieldLabel,
    required this.presets,
    required this.currentValue,
    required this.formatLabel,
    required this.onSelect,
  });

  final String fieldLabel;
  final List<num> presets;
  final String? currentValue;
  final String Function(num value) formatLabel;
  final ValueChanged<num> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: 46,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151C28) : const Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(
            color: p.outline.withValues(alpha: 0.8),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
      child: Row(
        children: [
          // Context indicator icon & label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PhosphorIconsRegular.sparkle,
                  size: 13,
                  color: p.primary,
                ),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 88),
                  child: Text(
                    fieldLabel,
                    style: TextStyle(
                      fontFamily: AppType.sans,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: p.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 20,
            color: p.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          // Scrollable chips row
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: presets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final v = presets[i];
                final isCurrent = currentValue == v.toString() ||
                    (double.tryParse(currentValue ?? '') == v.toDouble());
                final label = formatLabel(v);

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onSelect(v);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? p.primary
                            : (isDark ? const Color(0xFF1E2638) : Colors.white),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: isCurrent ? p.primary : p.outline,
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: AppType.mono,
                          fontSize: 12,
                          fontWeight:
                              isCurrent ? FontWeight.w700 : FontWeight.w600,
                          color: isCurrent ? p.onPrimary : p.ink,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
