import 'biquad.dart';
import 'stats.dart' show mean;

/// Zero-phase band-pass filter: mean removal, mirror padding, a forward
/// high-pass -> low-pass cascade run forward then backward (so net phase
/// shift is zero), with the padding stripped afterward.
List<double> bandpass(
  List<double> x,
  double fs, {
  required double lowHz,
  required double highHz,
  required double padS,
}) {
  if (x.length < 2) return List<double>.filled(x.length, 0);

  final m = mean(x);
  final centered = x.map((v) => v - m).toList();

  final padLen = ((padS * fs).round()).clamp(0, x.length - 1);
  final padded = _mirrorPad(centered, padLen);

  final hp = highPassCoeffs(lowHz, fs);
  final lp = lowPassCoeffs(highHz, fs);

  List<double> cascade(List<double> input) => applyBiquad(applyBiquad(input, hp), lp);

  final stage1 = cascade(padded);
  final reversed1 = stage1.reversed.toList();
  final stage2 = cascade(reversed1);
  final reversed2 = stage2.reversed.toList();

  if (padLen == 0) return reversed2;
  return reversed2.sublist(padLen, reversed2.length - padLen);
}

/// Reflect padding that excludes the edge sample itself, e.g. for
/// `[a, b, c, d]` with `padLen=2`: left pad `[c, b]`, right pad `[c, b]`.
List<double> _mirrorPad(List<double> x, int padLen) {
  if (padLen == 0) return x;
  final left = <double>[for (var i = padLen; i >= 1; i--) x[i]];
  final n = x.length;
  final right = <double>[for (var i = 0; i < padLen; i++) x[n - 2 - i]];
  return [...left, ...x, ...right];
}
