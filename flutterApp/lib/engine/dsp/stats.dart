import 'dart:math' as math;

/// Basic descriptive statistics used throughout the DSP and vitals layers.
/// Pure Dart — no Flutter imports.
double mean(List<double> xs) {
  if (xs.isEmpty) return 0;
  var sum = 0.0;
  for (final x in xs) {
    sum += x;
  }
  return sum / xs.length;
}

double median(List<double> xs) {
  if (xs.isEmpty) return 0;
  final sorted = [...xs]..sort();
  final n = sorted.length;
  if (n.isOdd) return sorted[n ~/ 2];
  return (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2;
}

/// Population standard deviation (divides by n, not n-1).
double std(List<double> xs) {
  if (xs.isEmpty) return 0;
  final m = mean(xs);
  var sumSq = 0.0;
  for (final x in xs) {
    final d = x - m;
    sumSq += d * d;
  }
  return math.sqrt(sumSq / xs.length);
}

/// Linear-interpolated percentile, `p` in [0, 100].
double percentile(List<double> xs, double p) {
  if (xs.isEmpty) return 0;
  final sorted = [...xs]..sort();
  if (sorted.length == 1) return sorted[0];
  final rank = (p / 100) * (sorted.length - 1);
  final lo = rank.floor();
  final hi = rank.ceil();
  if (lo == hi) return sorted[lo];
  final frac = rank - lo;
  return sorted[lo] * (1 - frac) + sorted[hi] * frac;
}

/// Least-squares slope of `ys` against `xs` (e.g. minutes), i.e. the `b` in
/// `y = a + b*x`.
double lsqSlope(List<double> xs, List<double> ys) {
  final n = xs.length;
  if (n < 2 || n != ys.length) return 0;
  final mx = mean(xs);
  final my = mean(ys);
  var num = 0.0;
  var den = 0.0;
  for (var i = 0; i < n; i++) {
    final dx = xs[i] - mx;
    num += dx * (ys[i] - my);
    den += dx * dx;
  }
  if (den == 0) return 0;
  return num / den;
}

/// Pearson correlation coefficient between two equal-length series.
double pearson(List<double> xs, List<double> ys) {
  final n = xs.length;
  if (n < 2 || n != ys.length) return 0;
  final mx = mean(xs);
  final my = mean(ys);
  var num = 0.0;
  var dx2 = 0.0;
  var dy2 = 0.0;
  for (var i = 0; i < n; i++) {
    final dx = xs[i] - mx;
    final dy = ys[i] - my;
    num += dx * dy;
    dx2 += dx * dx;
    dy2 += dy * dy;
  }
  final den = math.sqrt(dx2 * dy2);
  if (den == 0) return 0;
  return num / den;
}
