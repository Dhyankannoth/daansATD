import 'dart:convert';
import 'dart:io';

import '../api/events.dart' show RecordingResult, RiskAssessment;
import '../core/models/activity_state.dart';
import '../core/models/feature_row.dart';
import '../core/models/vitals_reading.dart';

const kRecordModeLabels = ['normal_rest', 'recovery', 'stress', 'artifact', 'reaction'];

String _csvCell(Object? v) {
  if (v == null) return '';
  if (v is bool) return v ? 'true' : 'false';
  if (v is double) return v.toStringAsFixed(4);
  return v.toString();
}

String _csvRow(List<Object?> cells) => cells.map(_csvCell).join(',');

/// Writes record-mode CSVs (and a small meta.json) for ML training data,
/// per §7.14. The documents directory is injected so tests can use a temp
/// directory instead of the real `path_provider` path.
class RecordModeWriter {
  RecordModeWriter({
    required Future<Directory> Function() documentsDirProvider,
    required List<String> featureNames,
  }) : _documentsDirProvider = documentsDirProvider,
       _featureNames = featureNames;

  final Future<Directory> Function() _documentsDirProvider;
  final List<String> _featureNames;

  IOSink? _sink;
  IOSink? _rawSink;
  String? _csvPath;
  String? _rawCsvPath;
  String? _metaPath;
  String? _sessionId;
  String? _personId;
  String? _label;
  String? _deviceLabel;
  bool _includeRaw = false;

  bool get isRecording => _sink != null;

  Future<void> start({
    required String label,
    required String personId,
    String deviceLabel = '',
    bool includeRawSamples = false,
    required int nowMs,
    required Map<String, dynamic> meta,
  }) async {
    if (!kRecordModeLabels.contains(label)) {
      throw ArgumentError.value(
        label,
        'label',
        'must be one of $kRecordModeLabels',
      );
    }
    final docsDir = await _documentsDirProvider();
    final recordingsDir = Directory('${docsDir.path}/recordings');
    await recordingsDir.create(recursive: true);

    final ts = DateTime.fromMillisecondsSinceEpoch(nowMs, isUtc: true);
    final stamp = _formatStamp(ts);
    final base = '${personId}_${label}_$stamp';
    _sessionId = '${personId}_${label}_$nowMs';
    _personId = personId;
    _label = label;
    _deviceLabel = deviceLabel;
    _includeRaw = includeRawSamples;

    _csvPath = '${recordingsDir.path}/$base.csv';
    _sink = File(_csvPath!).openWrite();
    _sink!.writeln(_header().join(','));

    if (includeRawSamples) {
      _rawCsvPath = '${recordingsDir.path}/${base}_raw.csv';
      _rawSink = File(_rawCsvPath!).openWrite();
      _rawSink!.writeln('t,r,g,b,sat_frac,valid,finger_present,motion_std');
    }

    _metaPath = '${recordingsDir.path}/${base}_meta.json';
    await File(_metaPath!).writeAsString(jsonEncode(meta));
  }

  List<String> _header() => [
    'session_id',
    'person_id',
    'label',
    'device_label',
    'timestamp',
    'hr',
    'hrv',
    'rr',
    'spo2',
    'ox_trend',
    'quality',
    'rr_quality',
    'finger_present',
    'activity',
    'activity_confidence',
    'row_valid',
    ..._featureNames,
    'anomaly_score',
    'risk_probability',
    'risk_level',
    'cardio_dev',
    'resp_dev',
    'auto_dev',
  ];

  void writeTick({
    required VitalsReading vitals,
    required ActivityState activity,
    required FeatureRow featureRow,
    required RiskAssessment risk,
  }) {
    final sink = _sink;
    if (sink == null) return;

    final cardio = risk.flags
        .where((f) => f.system.name == 'cardiovascular')
        .firstOrNull;
    final resp = risk.flags
        .where((f) => f.system.name == 'respiratory')
        .firstOrNull;
    final auto = risk.flags
        .where((f) => f.system.name == 'autonomic')
        .firstOrNull;

    final row = <Object?>[
      _sessionId,
      _personId,
      _label,
      _deviceLabel,
      vitals.timestamp,
      vitals.hr,
      vitals.hrv,
      vitals.rr,
      vitals.spo2,
      vitals.oxTrend,
      vitals.quality,
      vitals.rrQuality,
      vitals.fingerPresent,
      activity.state.name,
      activity.confidence,
      featureRow.valid,
      for (var i = 0; i < _featureNames.length; i++)
        featureRow.valid && i < featureRow.values.length
            ? featureRow.values[i]
            : null,
      risk.anomalyScore,
      risk.riskProbability,
      risk.level.name,
      cardio?.deviating,
      resp?.deviating,
      auto?.deviating,
    ];
    sink.writeln(_csvRow(row));
  }

  void writeRawSample({
    required double t,
    required double r,
    required double g,
    required double b,
    required double satFrac,
    required bool valid,
    required bool fingerPresent,
    required double motionStd,
  }) {
    final sink = _rawSink;
    if (sink == null) return;
    sink.writeln(
      _csvRow([t, r, g, b, satFrac, valid, fingerPresent, motionStd]),
    );
  }

  Future<RecordingResult> stop() async {
    await _sink?.flush();
    await _sink?.close();
    await _rawSink?.flush();
    await _rawSink?.close();
    final result = RecordingResult(
      csvPath: _csvPath!,
      rawCsvPath: _includeRaw ? _rawCsvPath : null,
      metaPath: _metaPath!,
    );
    _sink = null;
    _rawSink = null;
    return result;
  }

  String _formatStamp(DateTime ts) {
    String p2(int n) => n.toString().padLeft(2, '0');
    return '${ts.year}${p2(ts.month)}${p2(ts.day)}_${p2(ts.hour)}${p2(ts.minute)}${p2(ts.second)}';
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
