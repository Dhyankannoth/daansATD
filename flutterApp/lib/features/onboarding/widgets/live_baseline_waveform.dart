import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/pulse_colors.dart';

/// Animated physiological pulse waveform illustrating baseline learning.
class LiveBaselineWaveform extends StatefulWidget {
  final double height;
  final bool showEnvelope;

  const LiveBaselineWaveform({
    super.key,
    this.height = 140,
    this.showEnvelope = true,
  });

  @override
  State<LiveBaselineWaveform> createState() => _LiveBaselineWaveformState();
}

class _LiveBaselineWaveformState extends State<LiveBaselineWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
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
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: PulseColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PulseColors.divider, width: 1.2),
        boxShadow: const [PulseColors.cardShadow],
      ),
      child: AnimatedBuilder(
        animation: _animCtrl,
        builder: (context, _) {
          return CustomPaint(
            painter: _BaselinePainter(
              phase: _animCtrl.value * 2 * math.pi,
              showEnvelope: widget.showEnvelope,
            ),
          );
        },
      ),
    );
  }
}

class _BaselinePainter extends CustomPainter {
  final double phase;
  final bool showEnvelope;

  _BaselinePainter({
    required this.phase,
    required this.showEnvelope,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height * 0.50;
    final w = size.width;

    // 1. Draw learned baseline normal range envelope (shaded band ± 2 SD)
    if (showEnvelope) {
      final envelopeTop = size.height * 0.28;
      final envelopeBottom = size.height * 0.72;

      final envelopePaint = Paint()
        ..color = PulseColors.tintEmeraldBg.withValues(alpha: 0.65)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(16, envelopeTop, w - 16, envelopeBottom),
          const Radius.circular(12),
        ),
        envelopePaint,
      );

      // Subtle dashed normal range borders
      final dashPaint = Paint()
        ..color = PulseColors.riskNormal.withValues(alpha: 0.35)
        ..strokeWidth = 1.0;

      for (double x = 20; x < w - 20; x += 8) {
        canvas.drawLine(Offset(x, envelopeTop), Offset(x + 4, envelopeTop), dashPaint);
        canvas.drawLine(Offset(x, envelopeBottom), Offset(x + 4, envelopeBottom), dashPaint);
      }
    }

    // 2. Draw smooth physiological PPG wave
    final path = Path();
    const pointsCount = 100;
    final stepX = w / pointsCount;

    for (int i = 0; i <= pointsCount; i++) {
      final x = i * stepX;
      // Synthesize realistic PPG pulse with dicrotic notch
      final t = (i / pointsCount) * 4 * math.pi - phase;
      final wave = math.sin(t) * 0.65 + math.sin(2 * t) * 0.25;
      final y = midY - wave * (size.height * 0.22);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Wave stroke paint with gradient
    final strokePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          PulseColors.tintEmeraldIcon.withValues(alpha: 0.2),
          PulseColors.tintEmeraldIcon.withValues(alpha: 0.7),
          PulseColors.tintEmeraldIcon,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);

    // Glowing leading indicator dot
    final tEnd = 4 * math.pi - phase;
    final lastY = midY - (math.sin(tEnd) * 0.65 + math.sin(2 * tEnd) * 0.25) * (size.height * 0.22);
    final dotPos = Offset(w - 12, lastY);

    final glowPaint = Paint()
      ..color = PulseColors.tintEmeraldIcon.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(dotPos, 8, glowPaint);

    final dotPaint = Paint()..color = PulseColors.tintEmeraldIcon;
    canvas.drawCircle(dotPos, 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _BaselinePainter oldDelegate) =>
      oldDelegate.phase != phase;
}
