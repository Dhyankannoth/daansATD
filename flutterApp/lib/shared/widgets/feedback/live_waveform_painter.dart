import 'package:flutter/material.dart';
import '../../../core/theme/pulse_colors.dart';
import '../../../engine/api/events.dart';

/// Renders real-time photoplethysmography (PPG) pulse waves (~30 Hz) with
/// smooth bezier curves and trailing gradient glow.
class LiveWaveformWidget extends StatefulWidget {
  final Stream<WaveformSample>? waveformStream;
  final double height;
  final Color? waveColor;
  final bool isMeasuring;

  const LiveWaveformWidget({
    super.key,
    required this.waveformStream,
    this.height = 100,
    this.waveColor,
    this.isMeasuring = true,
  });

  @override
  State<LiveWaveformWidget> createState() => _LiveWaveformWidgetState();
}

class _LiveWaveformWidgetState extends State<LiveWaveformWidget> {
  final List<double> _samples = [];
  static const int _maxSamples = 120; // ~4 seconds at 30 Hz

  @override
  void initState() {
    super.initState();
    widget.waveformStream?.listen((sample) {
      if (!mounted) return;
      setState(() {
        _samples.add(sample.value);
        if (_samples.length > _maxSamples) {
          _samples.removeAt(0);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.waveColor ?? PulseColors.primary;

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: PulseColors.surfaceDim,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PulseColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _WaveformPainter(
          samples: _samples,
          color: color,
          isMeasuring: widget.isMeasuring,
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> samples;
  final Color color;
  final bool isMeasuring;

  _WaveformPainter({
    required this.samples,
    required this.color,
    required this.isMeasuring,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw horizontal center grid line
    final gridPaint = Paint()
      ..color = PulseColors.divider.withValues(alpha: 0.6)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      gridPaint,
    );

    if (samples.length < 2 || !isMeasuring) {
      // Draw subtle resting line if no samples yet
      final restPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..strokeWidth = 2.0;
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        restPaint,
      );
      return;
    }

    final wavePath = Path();
    final stepX = size.width / (samples.length - 1);
    final midY = size.height / 2;
    final amp = size.height * 0.40;

    // Convert samples (-1.0 to 1.0) into canvas coordinates
    final points = <Offset>[];
    for (int i = 0; i < samples.length; i++) {
      final x = i * stepX;
      final y = (midY - (samples[i] * amp)).clamp(4.0, size.height - 4.0);
      points.add(Offset(x, y));
    }

    wavePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlPoint = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      wavePath.quadraticBezierTo(
        p0.dx,
        p0.dy,
        controlPoint.dx,
        controlPoint.dy,
      );
    }
    wavePath.lineTo(points.last.dx, points.last.dy);

    // Gradient stroke
    final strokePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0.1),
          color.withValues(alpha: 0.5),
          color,
        ],
        stops: const [0.0, 0.3, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(wavePath, strokePaint);

    // Leading live dot
    final lastPoint = points.last;
    final dotGlow = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(lastPoint, 6.0, dotGlow);

    final dotPaint = Paint()..color = color;
    canvas.drawCircle(lastPoint, 3.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) => true;
}
