import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory;

import 'alerts/alert_controller.dart';
import 'alerts/alert_effects.dart';
import 'api/engine_snapshot.dart';
import 'api/engine_strings.dart';
import 'api/events.dart';
import 'api/pulseguard_api.dart';
import 'core/clock.dart';
import 'core/config/feature_spec.dart';
import 'core/config/thresholds.dart';
import 'core/models/activity_state.dart';
import 'core/models/baseline.dart';
import 'core/models/deviation_flag.dart';
import 'core/models/emergency_contact.dart';
import 'core/models/escalation_payload.dart';
import 'core/models/vitals_reading.dart';
import 'detection/activity_gate.dart';
import 'detection/baseline_service.dart';
import 'detection/deviation_engine.dart';
import 'detection/fusion_engine.dart';
import 'detection/trends.dart';
import 'dsp/stats.dart' show median;
import 'ml/activity_classifier.dart';
import 'ml/feature_builder.dart';
import 'ml/isolation_forest.dart';
import 'ml/random_forest.dart';
import 'ml/risk_engine.dart';
import 'ml/tree_model.dart';
import 'record/record_mode_writer.dart';
import 'sources/camera_vitals_source.dart';
import 'sources/replay_vitals_source.dart';
import 'sources/vitals_source.dart';
import 'storage/engine_store.dart';

/// Orchestrates the full PulseGuard pipeline and implements [PulseGuardApi].
/// This is the only class the UI should construct directly.
class PulseGuardEngine implements PulseGuardApi {
  PulseGuardEngine({
    Clock? clock,
    AssetBundleLike? bundle,
    VitalsSource? cameraSource,
    AlertEffects? alertEffects,
  }) : clock = clock ?? SystemClock(),
       _bundle = bundle ?? _RootBundleAdapter(),
       _cameraSourceOverride = cameraSource,
       _alertEffects = alertEffects;

  final Clock clock;
  final AssetBundleLike _bundle;
  final VitalsSource? _cameraSourceOverride;
  late final VitalsSource _cameraSource =
      _cameraSourceOverride ??
      CameraVitalsSource(thresholds: thresholds, clock: clock);
  final AlertEffects? _alertEffects;

  late Thresholds thresholds;
  late FeatureSpec featureSpec;
  late Trends _trends;
  late DeviationEngine _deviationEngine;
  late FusionEngine _fusionEngine;
  late ActivityGate _activityGate;
  late RiskEngine _riskEngine;
  late FeatureBuilder _featureBuilder;
  late AlertController _alertController;
  late BaselineService _baselineService;

  IsolationForest? _iforest;
  TreeModel? _iforestModel;
  RandomForest? _riskRf;
  // TODO(phase-8): wire into CameraVitalsSource's motion classification.
  // ignore: unused_field
  ActivityClassifier? _activityClassifier;

  EngineStore? _store;
  RecordModeWriter? _recordWriter;
  bool _recording = false;
  Baseline? _baseline;
  Baseline? _replayBaselineOverride;
  EmergencyContact? _contact;

  final _snapshotNotifier = ValueNotifier<EngineSnapshot>(
    const EngineSnapshot(),
  );
  final _vitalsCtrl = StreamController<VitalsReading>.broadcast();
  final _waveformCtrl = StreamController<WaveformSample>.broadcast();
  final _placementCtrl = StreamController<PlacementHint>.broadcast();
  final _activityCtrl = StreamController<ActivityState>.broadcast();
  final _riskCtrl = StreamController<RiskAssessment>.broadcast();
  final _scanFinishedCtrl = StreamController<ScanSummary>.broadcast();
  final _calibrationCtrl = StreamController<CalibrationProgress>.broadcast();

  EnginePhase _phase = EnginePhase.uninitialized;
  String? _errorMessage;

  VitalsSource? _activeSource;
  StreamSubscription<TickInput>? _tickSub;

  bool _isReplay = false;
  bool _isCalibration = false;
  double? _timeSinceExerciseS;
  double? _scanStartS;
  double? _noSignalSinceS;
  RiskLevel _maxLevel = RiskLevel.normal;
  final List<double> _hrTrusted = [];
  final List<double> _hrvTrusted = [];
  final List<double> _rrTrusted = [];
  int _totalTicks = 0;
  int _restingTicks = 0;
  ScanSummary? _lastSummary;

  /// The most recently completed scan's summary, if any (debug-page use).
  ScanSummary? get lastSummary => _lastSummary;

  final List<double> _calHr = [];
  final List<double> _calHrv = [];
  final List<double> _calRr = [];

  // ===== lifecycle =====

  @override
  Future<void> initialize() async {
    thresholds = await Thresholds.load(bundle: _bundle);
    featureSpec = await FeatureSpec.load(bundle: _bundle);

    _trends = Trends(
      windowS: thresholds.windowsS.trend,
      trendMinPoints: thresholds.trend.minPoints,
      mlMetricMinPoints: thresholds.ml.metricMinPoints,
    );
    _deviationEngine = DeviationEngine(thresholds: thresholds);
    _fusionEngine = FusionEngine(thresholds: thresholds);
    _activityGate = ActivityGate(thresholds: thresholds);
    _riskEngine = RiskEngine(thresholds: thresholds);
    _featureBuilder = FeatureBuilder(thresholds: thresholds);
    _alertController = AlertController(
      thresholds: thresholds,
      effects: _alertEffects,
    );
    _baselineService = BaselineService(thresholds: thresholds);

    await _tryLoadModels();

    try {
      _store = await EngineStore.create();
      _baseline = _store!.loadBaseline();
      _contact = _store!.loadContact();
    } catch (_) {
      _store = null; // e.g. no platform channels in a pure-Dart test host
    }

    _phase = EnginePhase.idle;
    _updateSnapshot();
  }

  Future<void> _tryLoadModels() async {
    try {
      final raw = await _bundle.loadString('assets/models/iforest.json');
      final model = TreeModel.tryParse(
        raw,
        expectedFeatureSpecVersion: featureSpec.version,
      );
      if (model != null) {
        _iforestModel = model;
        _iforest = IsolationForest(model);
      }
    } catch (_) {}
    try {
      final raw = await _bundle.loadString('assets/models/risk_rf.json');
      final model = TreeModel.tryParse(
        raw,
        expectedFeatureSpecVersion: featureSpec.version,
      );
      if (model != null) _riskRf = RandomForest(model);
    } catch (_) {}
    try {
      final raw = await _bundle.loadString('assets/models/activity_tree.json');
      final model = TreeModel.tryParse(
        raw,
        expectedFeatureSpecVersion: featureSpec.version,
      );
      if (model != null) _activityClassifier = ActivityClassifier(model);
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    await _tickSub?.cancel();
    await _activeSource?.stop();
    _alertController.dispose();
    await _vitalsCtrl.close();
    await _waveformCtrl.close();
    await _placementCtrl.close();
    await _activityCtrl.close();
    await _riskCtrl.close();
    await _scanFinishedCtrl.close();
    await _calibrationCtrl.close();
    _snapshotNotifier.dispose();
  }

  // ===== state =====

  @override
  ValueListenable<EngineSnapshot> get snapshot => _snapshotNotifier;
  @override
  Stream<VitalsReading> get vitals => _vitalsCtrl.stream;
  @override
  Stream<WaveformSample> get waveform => _waveformCtrl.stream;
  @override
  Stream<PlacementHint> get placement => _placementCtrl.stream;
  @override
  Stream<ActivityState> get activity => _activityCtrl.stream;
  @override
  Stream<RiskAssessment> get risk => _riskCtrl.stream;
  @override
  Stream<AlertEvent> get alerts => _alertController.events;
  @override
  CameraController? get cameraController => _activeSource?.cameraController;

  // ===== baseline =====

  @override
  bool get hasBaseline => _baseline != null;
  @override
  Baseline? get baseline => _baseline;

  @visibleForTesting
  Future<void> setBaselineForTesting(Baseline baseline) async {
    _baseline = baseline;
    if (_store != null) {
      await _store!.saveBaseline(baseline);
    }
    _updateSnapshot();
  }

  @override
  Stream<CalibrationProgress> get calibration => _calibrationCtrl.stream;

  @override
  Future<void> startCalibration() async {
    if (_phase != EnginePhase.idle && _phase != EnginePhase.finished) return;
    _resetScanState();
    _isCalibration = true;
    _isReplay = false;
    _calHr.clear();
    _calHrv.clear();
    _calRr.clear();
    _activityGate.startScan(timeSinceExerciseS: null);
    _phase = EnginePhase.preparingCamera;
    _updateSnapshot();
    _activeSource = _cameraSource;
    try {
      await _activeSource!.start();
    } catch (e) {
      _phase = EnginePhase.error;
      _errorMessage = 'Camera unavailable: $e';
      _updateSnapshot();
      return;
    }
    _phase = EnginePhase.calibrating;
    _subscribeTicks();
  }

  @override
  Future<void> cancelCalibration() async {
    if (!_isCalibration) return;
    await _tickSub?.cancel();
    await _activeSource?.stop();
    _isCalibration = false;
    _phase = EnginePhase.idle;
    _updateSnapshot();
  }

  @override
  Future<void> loadDemoBaseline() async {
    final raw = await _bundle.loadString('assets/demo/baseline.json');
    _baseline = Baseline.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    _updateSnapshot();
  }

  @override
  Future<void> clearBaseline() async {
    _baseline = null;
    await _store?.clearBaseline();
    await _store?.clearCalibrationHistory();
    _updateSnapshot();
  }

  // ===== scanning =====

  @override
  Future<void> startScan({Duration? timeSinceExercise}) async {
    if (_phase != EnginePhase.idle && _phase != EnginePhase.finished) return;
    _resetScanState();
    _isReplay = false;
    _isCalibration = false;
    _timeSinceExerciseS = timeSinceExercise?.inSeconds.toDouble();
    _activityGate.startScan(timeSinceExerciseS: _timeSinceExerciseS);
    _phase = EnginePhase.preparingCamera;
    _updateSnapshot();
    _activeSource = _cameraSource;
    try {
      await _activeSource!.start();
    } catch (e) {
      _phase = EnginePhase.error;
      _errorMessage = 'Camera unavailable: $e';
      _updateSnapshot();
      return;
    }
    _phase = EnginePhase.scanning;
    _subscribeTicks();
  }

  @override
  Future<ScanSummary> endScan() async {
    _alertController.resolveUnansweredOnScanEnd(clock.nowMs());
    return _finishScan(ScanEndReason.user);
  }

  @override
  Stream<ScanSummary> get scanFinished => _scanFinishedCtrl.stream;

  // ===== replay =====

  @override
  Future<void> startReplay(
    String assetPath, {
    double speed = 1.0,
    bool useDemoBaseline = true,
  }) async {
    _resetScanState();
    _isReplay = true;
    _isCalibration = false;
    _replayBaselineOverride = null;
    if (useDemoBaseline) {
      try {
        final raw = await _bundle.loadString('assets/demo/baseline.json');
        _replayBaselineOverride = Baseline.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (_) {}
    }
    final source = ReplayVitalsSource(clock: clock, bundle: _bundle);
    source.configure(assetPath: assetPath, speed: speed);
    _activeSource = source;
    await source.start();
    _timeSinceExerciseS = source.timeSinceExerciseS;
    _activityGate.startScan(timeSinceExerciseS: _timeSinceExerciseS);
    _phase = EnginePhase.replaying;
    _updateSnapshot();
    _subscribeTicks();
  }

  @override
  Future<void> stopReplay() async {
    await _tickSub?.cancel();
    await _activeSource?.stop();
    _phase = EnginePhase.idle;
    _updateSnapshot();
  }

  // ===== alerts =====

  @override
  void respondCheckIn({required bool ok}) =>
      _alertController.respondCheckIn(ok: ok, nowMs: clock.nowMs());

  @override
  void cancelEscalation() => _alertController.cancelEscalation(clock.nowMs());

  @override
  EmergencyContact? get contact => _contact;

  @override
  Future<void> setContact(EmergencyContact contact) async {
    _contact = contact;
    await _store?.saveContact(contact);
  }

  // ===== record mode =====

  @override
  Future<void> startRecording({
    required String label,
    required String personId,
    String deviceLabel = '',
    bool includeRawSamples = false,
  }) async {
    if (_isReplay) {
      throw StateError('Record mode is disabled during replay.');
    }
    _recordWriter ??= RecordModeWriter(
      documentsDirProvider: () => getApplicationDocumentsDirectory(),
      featureNames: featureSpec.featureNames,
    );
    await _recordWriter!.start(
      label: label,
      personId: personId,
      deviceLabel: deviceLabel,
      includeRawSamples: includeRawSamples,
      nowMs: clock.nowMs(),
      meta: {
        'thresholds_version': thresholds.version,
        'feature_spec_version': featureSpec.version,
        'baseline_is_demo': _baseline?.isDemo,
        'has_baseline': _baseline != null,
      },
    );
    _recording = true;
    _updateSnapshot();
  }

  @override
  Future<RecordingResult> stopRecording() async {
    final writer = _recordWriter;
    if (writer == null || !writer.isRecording) {
      throw StateError('No recording in progress.');
    }
    final result = await writer.stop();
    _recording = false;
    _updateSnapshot();
    return result;
  }

  // ===== tick pipeline =====

  void _resetScanState() {
    _scanStartS = null;
    _noSignalSinceS = null;
    _maxLevel = RiskLevel.normal;
    _hrTrusted.clear();
    _hrvTrusted.clear();
    _rrTrusted.clear();
    _totalTicks = 0;
    _restingTicks = 0;
    _trends.reset();
    _fusionEngine.reset();
    _riskEngine.reset();
    _featureBuilder.reset();
    _lastSummary = null;
  }

  void _subscribeTicks() {
    _tickSub = _activeSource!.ticks.listen(
      _onTick,
      onDone: _onSourceDone,
      onError: (_) {},
    );
  }

  void _onSourceDone() {
    if (_isReplay) {
      unawaited(_finishScan(ScanEndReason.replayFinished));
    }
  }

  void _onTick(TickInput input) {
    final nowMs = input.vitals.timestamp;
    final nowS = nowMs / 1000.0;
    _scanStartS ??= nowS;
    final t = nowS - _scanStartS!;

    MotionClassResult? classifierResult;
    if (input.motionClassName != null) {
      classifierResult = MotionClassResult(
        className: input.motionClassName!,
        confidence: input.motionConfidence,
      );
    }
    final activityState = _activityGate.classify(
      motionStdShort: input.motionStdShort ?? 0,
      nowMs: nowMs,
      classifierResult: classifierResult,
    );

    if (_isCalibration) {
      _handleCalibrationTick(input.vitals, nowMs, t);
      return;
    }

    final baseline = _isReplay
        ? (_replayBaselineOverride ?? _baseline)
        : _baseline;

    final hrTrusted = input.vitals.quality >= thresholds.quality.trusted;
    final rrTrusted =
        math.min(input.vitals.quality, input.vitals.rrQuality) >=
        thresholds.quality.trusted;
    _trends.record('hr', t, input.vitals.hr, hrTrusted);
    _trends.record('hrv', t, input.vitals.hrv, hrTrusted);
    _trends.record('rr', t, input.vitals.rr, rrTrusted);

    final flags = _deviationEngine.evaluate(
      reading: input.vitals,
      baseline: baseline,
      activity: activityState.state,
      trends: _trends,
      nowMs: nowMs,
    );

    final fusion = _fusionEngine.evaluate(
      flags: flags,
      fingerPresent: input.vitals.fingerPresent,
      scanEndedByUser: false,
      inCooldown: _alertController.state == AlertControllerState.cooldown,
      nowS: t,
      nowMs: nowMs,
    );

    final featureRow = _featureBuilder.build(
      nowS: t,
      nowMs: nowMs,
      reading: input.vitals,
      baseline: baseline,
      activity: activityState.state,
      trends: _trends,
      timeSinceExerciseS: _timeSinceExerciseS,
      elapsedScanS: t,
    );

    double? anomalyScore;
    double? riskProb;
    if (featureRow.valid) {
      if (_iforest != null) anomalyScore = _iforest!.score(featureRow.values);
      if (_riskRf != null)
        riskProb = _riskRf!.riskProbability(featureRow.values);
    }

    final riskAssessment = _riskEngine.evaluate(
      nowS: t,
      nowMs: nowMs,
      flags: flags,
      fusion: fusion,
      anomalyScoreRaw: anomalyScore,
      riskProbabilityRaw: riskProb,
      alertEscalated: _alertController.state == AlertControllerState.escalated,
      anomalyThreshold: _iforestModel?.scoreThreshold,
    );

    _maxLevel = _maxLevel.index >= riskAssessment.level.index
        ? _maxLevel
        : riskAssessment.level;

    _alertController.tick(
      level: riskAssessment.level,
      nowMs: nowMs,
      buildPayload: () => _buildEscalationPayload(
        flags: flags,
        fusion: fusion,
        reading: input.vitals,
        nowMs: nowMs,
      ),
    );

    _totalTicks++;
    if (activityState.state == ActivityStateKind.resting) _restingTicks++;
    if (hrTrusted && input.vitals.hr != null) _hrTrusted.add(input.vitals.hr!);
    if (hrTrusted && input.vitals.hrv != null)
      _hrvTrusted.add(input.vitals.hrv!);
    if (rrTrusted && input.vitals.rr != null) _rrTrusted.add(input.vitals.rr!);

    if (_recording &&
        !_isReplay &&
        _recordWriter != null &&
        _recordWriter!.isRecording) {
      _recordWriter!.writeTick(
        vitals: input.vitals,
        activity: activityState,
        featureRow: featureRow,
        risk: riskAssessment,
      );
    }

    _vitalsCtrl.add(input.vitals);
    if (input.waveform != null) _waveformCtrl.add(input.waveform!);
    _activityCtrl.add(activityState);
    _riskCtrl.add(riskAssessment);

    _snapshotNotifier.value = _snapshotNotifier.value.copyWith(
      phase: _phase,
      elapsed: Duration(milliseconds: (t * 1000).round()),
      latestVitals: input.vitals,
      placementHint: input.vitals.fingerPresent
          ? PlacementHint.ok
          : PlacementHint.noFinger,
      activity: activityState,
      risk: riskAssessment,
      alertState: _mapAlertState(_alertController.state),
      checkInRemaining: _alertController.checkInRemainingSeconds(nowMs),
      checkInRemainingIsSet: true,
      activePayload: _alertController.activePayload,
      activePayloadIsSet: true,
      oxTrendPct: input.vitals.oxTrend,
      oxTrendPctIsSet: true,
      message: riskAssessment.statusText,
      hasBaseline: baseline != null,
      baseline: baseline,
      baselineIsSet: true,
      recording: _recording,
    );

    final checkInOpen =
        _alertController.state == AlertControllerState.checkIn ||
        _alertController.state == AlertControllerState.escalated;

    if (!_isReplay && !checkInOpen) {
      if (t >= thresholds.scan.maxS) {
        unawaited(_finishScan(ScanEndReason.timeout));
        return;
      }
      if (!input.vitals.fingerPresent) {
        _noSignalSinceS ??= t;
      } else {
        _noSignalSinceS = null;
      }
      if (_noSignalSinceS != null &&
          (t - _noSignalSinceS!) >= thresholds.scan.noSignalEndS) {
        unawaited(_finishScan(ScanEndReason.noSignal));
      }
    }
  }

  void _handleCalibrationTick(VitalsReading reading, int nowMs, double t) {
    final trusted = reading.quality >= thresholds.quality.trusted;
    final rrTrusted =
        math.min(reading.quality, reading.rrQuality) >=
        thresholds.quality.trusted;
    if (trusted && reading.hr != null) _calHr.add(reading.hr!);
    if (trusted && reading.hrv != null) _calHrv.add(reading.hrv!);
    if (rrTrusted && reading.rr != null) _calRr.add(reading.rr!);

    final totalS = thresholds.scan.calibrationS;
    final progress = CalibrationProgress(
      elapsed: Duration(milliseconds: (t * 1000).round()),
      total: Duration(milliseconds: (totalS * 1000).round()),
      trustedTicksHr: _calHr.length,
      trustedTicksHrv: _calHrv.length,
      trustedTicksRr: _calRr.length,
    );
    _calibrationCtrl.add(progress);
    _snapshotNotifier.value = _snapshotNotifier.value.copyWith(
      phase: _phase,
      elapsed: progress.elapsed,
      remaining: progress.total - progress.elapsed,
      remainingIsSet: true,
      latestVitals: reading,
      placementHint: reading.fingerPresent
          ? PlacementHint.ok
          : PlacementHint.noFinger,
    );

    if (t >= totalS) {
      unawaited(_finishCalibration(nowMs));
    }
  }

  Future<void> _finishCalibration(int nowMs) async {
    await _tickSub?.cancel();
    await _activeSource?.stop();

    final session = _baselineService.evaluateSession(
      hrTicks: _calHr,
      hrvTicks: _calHrv,
      rrTicks: _calRr,
      nowMs: nowMs,
    );

    final totalS = thresholds.scan.calibrationS;
    CalibrationProgress progress;
    if (session.success) {
      if (_store != null) await _store!.appendCalibrationSession(session);
      final history = _store?.loadCalibrationHistory() ?? [session];
      final computed = _baselineService.computeBaseline(history, nowMs: nowMs);
      _baseline = computed;
      if (_store != null) await _store!.saveBaseline(computed);
      progress = CalibrationProgress(
        elapsed: Duration(milliseconds: (totalS * 1000).round()),
        total: Duration(milliseconds: (totalS * 1000).round()),
        trustedTicksHr: _calHr.length,
        trustedTicksHrv: _calHrv.length,
        trustedTicksRr: _calRr.length,
        done: true,
        success: true,
        baseline: computed,
      );
    } else {
      progress = CalibrationProgress(
        elapsed: Duration(milliseconds: (totalS * 1000).round()),
        total: Duration(milliseconds: (totalS * 1000).round()),
        trustedTicksHr: _calHr.length,
        trustedTicksHrv: _calHrv.length,
        trustedTicksRr: _calRr.length,
        done: true,
        success: false,
        failureReason: session.failureReason,
      );
    }
    _calibrationCtrl.add(progress);
    _isCalibration = false;
    _phase = EnginePhase.finished;
    _updateSnapshot();
  }

  Future<ScanSummary> _finishScan(ScanEndReason reason) async {
    await _tickSub?.cancel();
    await _activeSource?.stop();

    final duration = _snapshotNotifier.value.elapsed;

    final summary = ScanSummary(
      endReason: reason,
      duration: duration,
      medianHr: _hrTrusted.isEmpty ? null : median(_hrTrusted),
      medianHrv: _hrvTrusted.isEmpty ? null : median(_hrvTrusted),
      medianRr: _rrTrusted.isEmpty ? null : median(_rrTrusted),
      maxLevel: _maxLevel,
      alertOutcome: _computeAlertOutcome(),
      trustedFraction: _totalTicks == 0 ? 0 : _hrTrusted.length / _totalTicks,
      escalationPayload: _alertController.activePayload,
    );

    if (!_isReplay &&
        (reason == ScanEndReason.user || reason == ScanEndReason.timeout)) {
      final b = _baseline;
      if (b != null) {
        final restingFraction = _totalTicks == 0
            ? 0.0
            : _restingTicks / _totalTicks;
        final updated = _baselineService.adaptiveUpdate(
          current: b,
          hrMedian: summary.medianHr ?? b.hr.mean,
          hrvMedian: summary.medianHrv ?? b.hrv.mean,
          rrMedian: summary.medianRr ?? b.rr.mean,
          endReason: reason == ScanEndReason.user ? 'user' : 'timeout',
          restingFraction: restingFraction,
          maxLevelRank: _maxLevel.index,
          alertOutcome: switch (summary.alertOutcome) {
            AlertOutcome.none => 'none',
            AlertOutcome.userOk => 'userOk',
            AlertOutcome.escalated => 'escalated',
            AlertOutcome.cancelled => 'cancelled',
          },
          trustedTicksHr: _hrTrusted.length,
          trustedTicksHrv: _hrvTrusted.length,
          trustedTicksRr: _rrTrusted.length,
          isReplay: false,
          nowMs: clock.nowMs(),
        );
        if (updated != null) {
          _baseline = updated;
          if (_store != null) await _store!.saveBaseline(updated);
        }
      }
    }

    _lastSummary = summary;
    _phase = EnginePhase.finished;
    _scanFinishedCtrl.add(summary);
    _alertController.resetForNewScan();
    _updateSnapshot();
    return summary;
  }

  EscalationPayload _buildEscalationPayload({
    required List<DeviationFlag> flags,
    required FusionResult fusion,
    required VitalsReading reading,
    required int nowMs,
  }) {
    final triggerType = fusion.watchdogAlert
        ? EscalationTriggerType.signalLoss
        : (fusion.ruleAlert
              ? EscalationTriggerType.multiSystem
              : EscalationTriggerType.mlSupported);
    return EscalationPayload(
      triggeredAt: nowMs,
      triggerType: triggerType,
      systems: fusion.persistentSystems,
      reasons: [
        for (final f in flags)
          if (f.trusted && f.deviating && f.reason.isNotEmpty) f.reason,
      ],
      vitalsSnapshot: reading,
      timeoutSeconds: thresholds.alerts.checkinTimeoutS.round(),
      contact:
          _contact ??
          const EmergencyContact(name: EngineStrings.contactNotSet, phone: ''),
      status: EscalationStatus.pending,
    );
  }

  AlertOutcome _computeAlertOutcome() {
    final payload = _alertController.activePayload;
    if (payload == null) return AlertOutcome.none;
    return switch (payload.status) {
      EscalationStatus.pending => AlertOutcome.none,
      EscalationStatus.userOk => AlertOutcome.userOk,
      EscalationStatus.escalated => AlertOutcome.escalated,
      EscalationStatus.cancelled => AlertOutcome.cancelled,
    };
  }

  AlertSnapshotState _mapAlertState(AlertControllerState s) => switch (s) {
    AlertControllerState.none => AlertSnapshotState.none,
    AlertControllerState.checkIn => AlertSnapshotState.checkIn,
    AlertControllerState.escalated => AlertSnapshotState.escalated,
    AlertControllerState.cooldown => AlertSnapshotState.cooldown,
  };

  void _updateSnapshot() {
    _snapshotNotifier.value = _snapshotNotifier.value.copyWith(
      phase: _phase,
      error: _errorMessage,
      errorIsSet: true,
      hasBaseline: _baseline != null,
      baseline: _baseline,
      baselineIsSet: true,
    );
  }
}

class _RootBundleAdapter implements AssetBundleLike {
  @override
  Future<String> loadString(String key) => rootBundle.loadString(key);
}
