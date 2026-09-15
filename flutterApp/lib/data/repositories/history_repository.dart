import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/measurement_record.dart';

const _kMeasurementHistoryKey = 'pulseguard.measurement_history';

/// Persists and manages the spot measurement history using SharedPreferences.
class HistoryRepository {
  final SharedPreferences prefs;
  List<MeasurementRecord>? _cached;

  HistoryRepository({required this.prefs});

  static Future<HistoryRepository> create() async {
    final sp = await SharedPreferences.getInstance();
    return HistoryRepository(prefs: sp);
  }

  List<MeasurementRecord> loadRecords() {
    if (_cached != null) return List.unmodifiable(_cached!);

    final raw = prefs.getString(_kMeasurementHistoryKey);
    if (raw == null) {
      _cached = [];
      return [];
    }

    try {
      final list = jsonDecode(raw) as List;
      _cached = list
          .map((e) => MeasurementRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      // Sort newest first
      _cached!.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return List.unmodifiable(_cached!);
    } catch (_) {
      _cached = [];
      return [];
    }
  }

  Future<void> saveRecord(MeasurementRecord record) async {
    final list = List<MeasurementRecord>.from(loadRecords());
    list.insert(0, record);
    // Keep last 100
    if (list.length > 100) list.removeRange(100, list.length);
    _cached = list;
    await prefs.setString(
      _kMeasurementHistoryKey,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> clearRecords() async {
    _cached = [];
    await prefs.remove(_kMeasurementHistoryKey);
  }
}
