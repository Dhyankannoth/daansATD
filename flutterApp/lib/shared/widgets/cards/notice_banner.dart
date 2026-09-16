import 'package:flutter/material.dart';
import '../../../core/theme/pulse_colors.dart';
import '../../../core/theme/pulse_typography.dart';

/// Cal AI-style notice notification banner with icon, message text, and dismiss button.
class NoticeBanner extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final VoidCallback? onDismiss;

  const NoticeBanner({
    super.key,
    this.title = 'System Notice',
    required this.message,
    this.icon = Icons.notifications_none_rounded,
    this.iconColor,
    this.backgroundColor,
    this.onDismiss,
  });

  @override
  State<NoticeBanner> createState() => _NoticeBannerState();
}

class _NoticeBannerState extends State<NoticeBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final bg = widget.backgroundColor ?? PulseColors.surface;
    final icColor = widget.iconColor ?? PulseColors.textSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PulseColors.borderSubtle, width: 1.0),
        boxShadow: const [PulseColors.cardShadow],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(widget.icon, size: 20, color: icColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.message,
              style: PulseTypography.caption.copyWith(
                fontSize: 12,
                color: PulseColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              setState(() => _dismissed = true);
              widget.onDismiss?.call();
            },
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: PulseColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
