import 'dart:typed_data';

class FrameAverage {
  const FrameAverage({
    required this.r,
    required this.g,
    required this.b,
    required this.satFrac,
  });
  final double r;
  final double g;
  final double b;

  /// Fraction of sampled pixels at/above the saturation threshold.
  final double satFrac;
}

/// Averages the central ROI of a camera frame, sampling every `pixelStep`
/// pixel in both directions. Allocation-free per call.
class FrameAverager {
  FrameAverager({
    required this.roiFraction,
    required this.pixelStep,
    required this.satPixel,
  });

  final double roiFraction;
  final int pixelStep;
  final double satPixel;

  /// YUV420 (Android). `uvPixelStride` is 1 for fully-planar U/V, 2 for
  /// semi-planar/interleaved (e.g. NV21/NV12-style) layouts.
  FrameAverage averageYuv420({
    required Uint8List yPlane,
    required int yRowStride,
    required Uint8List uPlane,
    required int uRowStride,
    required int uPixelStride,
    required Uint8List vPlane,
    required int vRowStride,
    required int vPixelStride,
    required int width,
    required int height,
  }) {
    final roiW = (width * roiFraction).round();
    final roiH = (height * roiFraction).round();
    final left = (width - roiW) ~/ 2;
    final top = (height - roiH) ~/ 2;

    var sumR = 0.0, sumG = 0.0, sumB = 0.0;
    var satCount = 0;
    var n = 0;

    for (var row = top; row < top + roiH; row += pixelStep) {
      final yRowBase = row * yRowStride;
      final uvRow = row >> 1;
      final uRowBase = uvRow * uRowStride;
      final vRowBase = uvRow * vRowStride;
      for (var col = left; col < left + roiW; col += pixelStep) {
        final y = yPlane[yRowBase + col].toDouble();
        final uvCol = col >> 1;
        final u = uPlane[uRowBase + uvCol * uPixelStride].toDouble() - 128;
        final v = vPlane[vRowBase + uvCol * vPixelStride].toDouble() - 128;

        final r = y + 1.402 * v;
        final g = y - 0.344 * u - 0.714 * v;
        final b = y + 1.772 * u;

        sumR += r;
        sumG += g;
        sumB += b;
        if (y + 1.402 * v >= satPixel) satCount++;
        n++;
      }
    }

    if (n == 0) return const FrameAverage(r: 0, g: 0, b: 0, satFrac: 0);
    return FrameAverage(
      r: sumR / n,
      g: sumG / n,
      b: sumB / n,
      satFrac: satCount / n,
    );
  }

  /// BGRA8888 (iOS). 4 bytes/pixel, order B, G, R, A.
  FrameAverage averageBgra8888({
    required Uint8List bytes,
    required int bytesPerRow,
    required int width,
    required int height,
  }) {
    final roiW = (width * roiFraction).round();
    final roiH = (height * roiFraction).round();
    final left = (width - roiW) ~/ 2;
    final top = (height - roiH) ~/ 2;

    var sumR = 0.0, sumG = 0.0, sumB = 0.0;
    var satCount = 0;
    var n = 0;

    for (var row = top; row < top + roiH; row += pixelStep) {
      final rowBase = row * bytesPerRow;
      for (var col = left; col < left + roiW; col += pixelStep) {
        final idx = rowBase + col * 4;
        final b = bytes[idx].toDouble();
        final g = bytes[idx + 1].toDouble();
        final r = bytes[idx + 2].toDouble();
        sumR += r;
        sumG += g;
        sumB += b;
        if (r >= satPixel) satCount++;
        n++;
      }
    }

    if (n == 0) return const FrameAverage(r: 0, g: 0, b: 0, satFrac: 0);
    return FrameAverage(
      r: sumR / n,
      g: sumG / n,
      b: sumB / n,
      satFrac: satCount / n,
    );
  }
}
