// Deterministic (seeded) generator for assets/traces/*.json and
// assets/demo/baseline.json. Run with: dart run tool/generate_traces.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

final _rng = math.Random(1337);

/// Box-Muller standard-normal sample.
double _gauss() {
  final u1 = 1 - _rng.nextDouble();
  final u2 = _rng.nextDouble();
  return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
}

double _noisy(double mean, double sd) => mean + _gauss() * sd;

Map<String, dynamic> _tick({
  required double t,
  required double? hr,
  required double? hrv,
  required double? rr,
  required double quality,
  required double rrQuality,
  required bool fingerPresent,
  required String motion,
}) {
  return {
    't': double.parse(t.toStringAsFixed(2)),
    'hr': hr == null ? null : double.parse(hr.toStringAsFixed(2)),
    'hrv': hrv == null ? null : double.parse(hrv.toStringAsFixed(2)),
    'rr': rr == null ? null : double.parse(rr.toStringAsFixed(2)),
    'quality': double.parse(quality.toStringAsFixed(3)),
    'rr_quality': double.parse(rrQuality.toStringAsFixed(3)),
    'finger_present': fingerPresent,
    'motion': motion,
  };
}

double _clamp01(double x) => x < 0 ? 0 : (x > 1 ? 1 : x);

List<Map<String, dynamic>> _reactionTicks({required int lastTickCount, double? cutoffT}) {
  final ticks = <Map<String, dynamic>>[];
  for (var i = 0; i < lastTickCount; i++) {
    final t = i.toDouble();
    if (cutoffT != null && t >= cutoffT) {
      ticks.add(_tick(
        t: t,
        hr: null,
        hrv: null,
        rr: null,
        quality: 0,
        rrQuality: 0,
        fingerPresent: false,
        motion: 'still',
      ));
      continue;
    }

    double hr, hrv, rr;
    if (t < 30) {
      hr = _noisy(72, 1.5);
      hrv = _noisy(45, 4);
      rr = _noisy(14, 0.6);
    } else {
      final hrProgress = _clamp01((t - 30) / 90);
      final rrProgress = _clamp01((t - 20) / 90); // RR leads by ~10s
      final holding = t >= 120;
      hr = _noisy(holding ? 120 : 72 + hrProgress * (120 - 72), 1.5);
      hrv = _noisy(holding ? 18 : 45 + hrProgress * (18 - 45), 4);
      rr = _noisy(holding ? 26 : 14 + rrProgress * (26 - 14), 0.6);
    }
    final quality = 0.85 + _rng.nextDouble() * 0.10;
    ticks.add(_tick(
      t: t,
      hr: hr,
      hrv: hrv,
      rr: rr,
      quality: quality,
      rrQuality: quality,
      fingerPresent: true,
      motion: 'still',
    ));
  }
  return ticks;
}

void _writeTrace(String path, String name, List<Map<String, dynamic>> ticks) {
  final json = {
    'version': 1,
    'name': name,
    'time_since_exercise_s': null,
    'ticks': ticks,
  };
  File(path).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(json));
  stdout.writeln('wrote $path (${ticks.length} ticks)');
}

void main() {
  Directory('assets/traces').createSync(recursive: true);
  Directory('assets/demo').createSync(recursive: true);

  // normal.json: 180 ticks of steady resting vitals.
  final normalTicks = <Map<String, dynamic>>[];
  for (var i = 0; i < 180; i++) {
    final quality = 0.85 + _rng.nextDouble() * 0.10;
    normalTicks.add(_tick(
      t: i.toDouble(),
      hr: _noisy(72, 1.5),
      hrv: _noisy(45, 4),
      rr: _noisy(14, 0.6),
      quality: quality,
      rrQuality: quality,
      fingerPresent: true,
      motion: 'still',
    ));
  }
  _writeTrace('assets/traces/normal.json', 'normal', normalTicks);

  // reaction.json: normal for 30s, then a 90s ramp to a reaction pattern, then hold.
  _writeTrace('assets/traces/reaction.json', 'reaction', _reactionTicks(lastTickCount: 180));

  // signal_loss.json: same reaction ramp, but the finger is lost at t=100.
  _writeTrace(
    'assets/traces/signal_loss.json',
    'signal_loss',
    _reactionTicks(lastTickCount: 180, cutoffT: 100),
  );

  // demo/baseline.json
  final demoBaseline = {
    'hr': {
      'mean': 72.0,
      'sd': 5.0,
      'variance': 25.0,
      'sd_floor_applied': true,
      'session_count': 3,
      'updated_at': 0,
    },
    'hrv': {
      'mean': 45.0,
      'sd': 11.25,
      'variance': 126.5625,
      'sd_floor_applied': true,
      'session_count': 3,
      'updated_at': 0,
    },
    'rr': {
      'mean': 14.0,
      'sd': 2.0,
      'variance': 4.0,
      'sd_floor_applied': true,
      'session_count': 3,
      'updated_at': 0,
    },
    'activity_state': 'resting',
    'is_demo': true,
  };
  File('assets/demo/baseline.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(demoBaseline));
  stdout.writeln('wrote assets/demo/baseline.json');
}
