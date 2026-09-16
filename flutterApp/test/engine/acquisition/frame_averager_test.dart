import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/engine/acquisition/frame_averager.dart';

void main() {
  final averager = FrameAverager(roiFraction: 1.0, pixelStep: 1, satPixel: 250);

  test('averageBgra8888 recovers a known solid color within +/-2', () {
    const width = 4, height = 4;
    final bytes = Uint8List(width * height * 4);
    for (var i = 0; i < width * height; i++) {
      bytes[i * 4 + 0] = 30; // B
      bytes[i * 4 + 1] = 60; // G
      bytes[i * 4 + 2] = 200; // R
      bytes[i * 4 + 3] = 255; // A
    }
    final avg = averager.averageBgra8888(
      bytes: bytes,
      bytesPerRow: width * 4,
      width: width,
      height: height,
    );
    expect(avg.r, closeTo(200, 2));
    expect(avg.g, closeTo(60, 2));
    expect(avg.b, closeTo(30, 2));
    expect(avg.satFrac, 0);
  });

  test(
    'averageBgra8888 saturation fraction counts pixels at/above sat_pixel',
    () {
      const width = 2, height = 1;
      final bytes = Uint8List(width * height * 4);
      // pixel 0: R=255 (saturated); pixel 1: R=100 (not saturated)
      bytes[2] = 255;
      bytes[6] = 100;
      final avg = averager.averageBgra8888(
        bytes: bytes,
        bytesPerRow: width * 4,
        width: width,
        height: height,
      );
      expect(avg.satFrac, closeTo(0.5, 1e-9));
    },
  );

  test(
    'averageYuv420 (planar, pixel stride 1) recovers known RGB within +/-2',
    () {
      // Solid mid-gray-ish color via known YUV -> RGB conversion.
      const width = 4, height = 4;
      // Choose Y=150, U=140, V=160 and verify against the same BT.601 formula.
      const y = 150.0, u = 140.0, v = 160.0;
      final expectedR = y + 1.402 * (v - 128);
      final expectedG = y - 0.344 * (u - 128) - 0.714 * (v - 128);
      final expectedB = y + 1.772 * (u - 128);

      final yPlane = Uint8List(width * height)
        ..fillRange(0, width * height, 150);
      final uvW = width ~/ 2, uvH = height ~/ 2;
      final uPlane = Uint8List(uvW * uvH)..fillRange(0, uvW * uvH, 140);
      final vPlane = Uint8List(uvW * uvH)..fillRange(0, uvW * uvH, 160);

      final avg = averager.averageYuv420(
        yPlane: yPlane,
        yRowStride: width,
        uPlane: uPlane,
        uRowStride: uvW,
        uPixelStride: 1,
        vPlane: vPlane,
        vRowStride: uvW,
        vPixelStride: 1,
        width: width,
        height: height,
      );

      expect(avg.r, closeTo(expectedR, 2));
      expect(avg.g, closeTo(expectedG, 2));
      expect(avg.b, closeTo(expectedB, 2));
    },
  );

  test('averageYuv420 (semi-planar, pixel stride 2 / interleaved UV)', () {
    const width = 4, height = 4;
    const y = 100.0, v = 130.0;
    final expectedR = y + 1.402 * (v - 128);

    final yPlane = Uint8List(width * height)..fillRange(0, width * height, 100);
    final uvW = width ~/ 2, uvH = height ~/ 2;
    // Interleaved single buffer: U,V,U,V,...
    final uvPlane = Uint8List(uvW * uvH * 2);
    for (var i = 0; i < uvW * uvH; i++) {
      uvPlane[i * 2] = 120; // U
      uvPlane[i * 2 + 1] = 130; // V
    }

    final avg = averager.averageYuv420(
      yPlane: yPlane,
      yRowStride: width,
      uPlane: uvPlane, // U starts at offset 0
      uRowStride: uvW * 2,
      uPixelStride: 2,
      vPlane: Uint8List.sublistView(uvPlane, 1), // V starts at offset 1
      vRowStride: uvW * 2,
      vPixelStride: 2,
      width: width,
      height: height,
    );

    expect(avg.r, closeTo(expectedR, 2));
  });
}
