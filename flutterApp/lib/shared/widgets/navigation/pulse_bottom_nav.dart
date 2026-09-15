import 'package:flutter/material.dart';
import '../../../core/theme/pulse_colors.dart';
import '../../../core/theme/pulse_typography.dart';

/// Cal AI-style Bottom Navigation Bar with main navigation items
/// and a prominent dark circular Scan / Action button on the right.
class PulseBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback? onScanPressed;

  const PulseBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.onScanPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: PulseColors.divider, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Left Navigation Destinations
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                  _buildNavItem(1, Icons.tune_outlined, Icons.tune_rounded, 'Baseline'),
                  _buildNavItem(2, Icons.history_rounded, Icons.history_rounded, 'History'),
                  _buildNavItem(3, Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
                ],
              ),
            ),

            if (onScanPressed != null) ...[
              const SizedBox(width: 8),
              // Cal AI prominent dark circular '+' FAB
              GestureDetector(
                onTap: onScanPressed,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: PulseColors.surfaceDark,
                    boxShadow: const [PulseColors.fabShadow],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData selectedIcon, String label) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              size: 24,
              color: isSelected ? PulseColors.textPrimary : PulseColors.textTertiary,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: PulseTypography.caption.copyWith(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? PulseColors.textPrimary : PulseColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
