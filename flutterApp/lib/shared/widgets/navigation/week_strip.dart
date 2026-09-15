import 'package:flutter/material.dart';
import '../../../core/theme/pulse_colors.dart';
import '../../../core/theme/pulse_typography.dart';

/// Cal AI-style horizontal week calendar strip with circular day badges.
class WeekStrip extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onDateSelected;

  const WeekStrip({
    super.key,
    this.selectedDate,
    this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = selectedDate ?? DateTime.now();
    // Generate 7 days centered on today
    final days = List.generate(7, (index) {
      return now.subtract(Duration(days: 3 - index));
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: days.map((date) {
            final isSelected = date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;

            final dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
            final dayLetter = dayLetters[(date.weekday - 1) % 7];

            return Flexible(
              child: GestureDetector(
                onTap: () => onDateSelected?.call(date),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Circular day letter badge
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? PulseColors.surfaceDark
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? PulseColors.surfaceDark
                                : PulseColors.borderSubtle,
                            width: isSelected ? 2.0 : 1.2,
                          ),
                        ),
                        child: Text(
                          dayLetter,
                          style: PulseTypography.caption.copyWith(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13,
                            color: isSelected
                                ? Colors.white
                                : PulseColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Day number
                      Text(
                        '${date.day}',
                        style: PulseTypography.caption.copyWith(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                          color: isSelected
                              ? PulseColors.textPrimary
                              : PulseColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
