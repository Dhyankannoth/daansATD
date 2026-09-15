import 'dart:math' as math;

/// RBJ (Robert Bristow-Johnson) biquad filter coefficients, already
/// normalized so `a0 == 1`.
class BiquadCoeffs {
  const BiquadCoeffs(this.b0, this.b1, this.b2, this.a1, this.a2);
  final double b0;
  final double b1;
  final double b2;

  /// Normalized (a0 divided out); applied as `+a1*y[n-1] + a2*y[n-2]`.
  final double a1;
  final double a2;
}

const double _q = 0.7071067811865476; // 1/sqrt(2), Butterworth Q

BiquadCoeffs _rbj(double f0, double fs, {required bool highPass}) {
  final w = 2 * math.pi * f0 / fs;
  final cosW = math.cos(w);
  final alpha = math.sin(w) / (2 * _q);
  final a0 = 1 + alpha;
  final double b0Raw, b1Raw, b2Raw;
  if (highPass) {
    b0Raw = (1 + cosW) / 2;
    b1Raw = -(1 + cosW);
    b2Raw = (1 + cosW) / 2;
  } else {
    b0Raw = (1 - cosW) / 2;
    b1Raw = 1 - cosW;
    b2Raw = (1 - cosW) / 2;
  }
  final a1Raw = -2 * cosW;
  final a2Raw = 1 - alpha;
  return BiquadCoeffs(
    b0Raw / a0,
    b1Raw / a0,
    b2Raw / a0,
    -a1Raw / a0, // stored so difference eq. is y += a1*y[n-1] + a2*y[n-2]
    -a2Raw / a0,
  );
}

BiquadCoeffs highPassCoeffs(double f0, double fs) => _rbj(f0, fs, highPass: true);

BiquadCoeffs lowPassCoeffs(double f0, double fs) => _rbj(f0, fs, highPass: false);

/// Applies a biquad filter in a single (forward) pass:
/// `y[n] = b0*x[n] + b1*x[n-1] + b2*x[n-2] + a1*y[n-1] + a2*y[n-2]`.
List<double> applyBiquad(List<double> x, BiquadCoeffs c) {
  final y = List<double>.filled(x.length, 0);
  double x1 = 0, x2 = 0, y1 = 0, y2 = 0;
  for (var n = 0; n < x.length; n++) {
    final xn = x[n];
    final yn = c.b0 * xn + c.b1 * x1 + c.b2 * x2 + c.a1 * y1 + c.a2 * y2;
    y[n] = yn;
    x2 = x1;
    x1 = xn;
    y2 = y1;
    y1 = yn;
  }
  return y;
}
