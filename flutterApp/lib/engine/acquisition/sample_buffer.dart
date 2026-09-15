import '../core/models/frame_sample.dart';

/// Ring buffer of [FrameSample]s covering the last `windowS` seconds.
class SampleBuffer {
  SampleBuffer({required double windowS}) : _windowS = windowS;

  final double _windowS;
  final List<FrameSample> _samples = [];

  void add(FrameSample sample) {
    _samples.add(sample);
    final cutoff = sample.t - _windowS;
    while (_samples.isNotEmpty && _samples.first.t < cutoff) {
      _samples.removeAt(0);
    }
  }

  List<FrameSample> get samples => List.unmodifiable(_samples);

  void clear() => _samples.clear();
}
