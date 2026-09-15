import 'package:flutter_test/flutter_test.dart';
import 'package:pulseguard/engine/acquisition/sample_buffer.dart';
import 'package:pulseguard/engine/core/models/frame_sample.dart';

FrameSample _s(double t) =>
    FrameSample(t: t, r: 1, g: 1, b: 1, valid: true, fingerPresent: true);

void main() {
  test('drops samples older than the window', () {
    final buf = SampleBuffer(windowS: 5);
    buf.add(_s(0));
    buf.add(_s(4));
    buf.add(_s(6)); // window is now [1, 6]; t=0 should be dropped
    expect(buf.samples.map((s) => s.t), [4.0, 6.0]);
  });

  test('clear empties the buffer', () {
    final buf = SampleBuffer(windowS: 5);
    buf.add(_s(0));
    buf.clear();
    expect(buf.samples, isEmpty);
  });
}
