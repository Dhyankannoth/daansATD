import 'package:flutter/material.dart';
import '../../../core/theme/pulse_colors.dart';
import '../../../core/theme/pulse_typography.dart';

/// Clean, medical-grade standard AppBar with optional subtitle and actions.
class PulseAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  const PulseAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(subtitle != null ? 68.0 : 56.0);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: PulseColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: PulseTypography.headingMedium),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: PulseTypography.caption.copyWith(
                color: PulseColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
      actions: actions != null ? [...actions!, const SizedBox(width: 8)] : null,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1.0),
        child: Divider(height: 1, thickness: 1, color: PulseColors.divider),
      ),
    );
  }
}
