import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/models/baseline.dart';
import '../core/models/emergency_contact.dart';
import '../detection/baseline_service.dart' show CalibrationSessionResult;

const _kBaselineKey = 'pulseguard.baseline';
const _kContactKey = 'pulseguard.contact';
const _kCalibrationHistoryKey = 'pulseguard.calibration_history';

Map<String, dynamic> _sessionToJson(CalibrationSessionResult s) => {
  'success': s.success,
  'failure_reason': s.failureReason,
  'hr_median': s.hrMedian,
  'hr_std': s.hrStd,
  'hrv_median': s.hrvMedian,
  'hrv_std': s.hrvStd,
  'rr_median': s.rrMedian,
  'rr_std': s.rrStd,
  'timestamp': s.timestamp,
};

CalibrationSessionResult _sessionFromJson(Map<String, dynamic> j) =>
    CalibrationSessionResult(
      success: j['success'] as bool,
      failureReason: j['failure_reason'] as String?,
      hrMedian: (j['hr_median'] as num?)?.toDouble(),
      hrStd: (j['hr_std'] as num?)?.toDouble(),
      hrvMedian: (j['hrv_median'] as num?)?.toDouble(),
      hrvStd: (j['hrv_std'] as num?)?.toDouble(),
      rrMedian: (j['rr_median'] as num?)?.toDouble(),
      rrStd: (j['rr_std'] as num?)?.toDouble(),
      timestamp: j['timestamp'] as int,
    );

/// Persists the baseline, emergency contact, and calibration session
/// history as JSON via `shared_preferences`.
class EngineStore {
  EngineStore({required this.prefs});

  final SharedPreferences prefs;

  static Future<EngineStore> create() async =>
      EngineStore(prefs: await SharedPreferences.getInstance());

  Baseline? loadBaseline() {
    final raw = prefs.getString(_kBaselineKey);
    if (raw == null) return null;
    return Baseline.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveBaseline(Baseline baseline) =>
      prefs.setString(_kBaselineKey, jsonEncode(baseline.toJson()));

  Future<void> clearBaseline() => prefs.remove(_kBaselineKey);

  EmergencyContact? loadContact() {
    final raw = prefs.getString(_kContactKey);
    if (raw == null) return null;
    return EmergencyContact.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveContact(EmergencyContact contact) =>
      prefs.setString(_kContactKey, jsonEncode(contact.toJson()));

  /// Successful calibration sessions, oldest first, capped at the last 10.
  List<CalibrationSessionResult> loadCalibrationHistory() {
    final raw = prefs.getString(_kCalibrationHistoryKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => _sessionFromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> appendCalibrationSession(
    CalibrationSessionResult session,
  ) async {
    final history = loadCalibrationHistory()..add(session);
    final capped = history.length > 10
        ? history.sublist(history.length - 10)
        : history;
    await prefs.setString(
      _kCalibrationHistoryKey,
      jsonEncode(capped.map(_sessionToJson).toList()),
    );
  }

  Future<void> clearCalibrationHistory() =>
      prefs.remove(_kCalibrationHistoryKey);
}
