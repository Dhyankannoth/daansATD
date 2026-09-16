import 'package:flutter/material.dart';
import '../../../core/theme/pulse_colors.dart';
import '../../../core/theme/pulse_typography.dart';

/// Cal AI-style connection animation widget showing the link: User ──⚡── Emergency Contact.
class PulseConnectingIndicator extends StatefulWidget {
  final String userName;
  final String contactName;

  const PulseConnectingIndicator({
    super.key,
    this.userName = 'You',
    this.contactName = 'Contact',
  });

  @override
  State<PulseConnectingIndicator> createState() =>
      _PulseConnectingIndicatorState();
}

class _PulseConnectingIndicatorState extends State<PulseConnectingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: PulseColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PulseColors.divider, width: 1.2),
        boxShadow: const [PulseColors.cardShadow],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // User Icon Avatar
          _buildNode(
            icon: Icons.person_rounded,
            label: widget.userName.isNotEmpty ? widget.userName : 'You',
            bgColor: PulseColors.surfaceDark,
            iconColor: Colors.white,
          ),

          // Connecting Signal Line
          Expanded(
            child: AnimatedBuilder(
              animation: _animCtrl,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ConnectPainter(progress: _animCtrl.value),
                  child: const SizedBox(height: 36),
                );
              },
            ),
          ),

          // Contact Icon Avatar
          _buildNode(
            icon: Icons.shield_rounded,
            label: widget.contactName.isNotEmpty ? widget.contactName : 'Contact',
            bgColor: PulseColors.tintEmeraldBg,
            iconColor: PulseColors.tintEmeraldIcon,
          ),
        ],
      ),
    );
  }

  Widget _buildNode({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 26),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 76,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: PulseTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: PulseColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConnectPainter extends CustomPainter {
  final double progress;

  _ConnectPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final w = size.width;

    // Base subtle track
    final trackPaint = Paint()
      ..color = PulseColors.borderSubtle
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(8, midY), Offset(w - 8, midY), trackPaint);

    // Animated signal pulse dot moving from left to right
    final pulseX = 8 + (w - 16) * progress;

    final pulseGlow = Paint()
      ..color = PulseColors.tintEmeraldIcon.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(Offset(pulseX, midY), 6, pulseGlow);

    final pulseDot = Paint()..color = PulseColors.tintEmeraldIcon;
    canvas.drawCircle(Offset(pulseX, midY), 3.5, pulseDot);
  }

  @override
  bool shouldRepaint(covariant _ConnectPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
