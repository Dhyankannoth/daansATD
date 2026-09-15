import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../camera_finger_instruction.dart';
import '../../core/constants/pulse_constants.dart';
import '../../core/theme/pulse_colors.dart';
import '../../core/theme/pulse_typography.dart';
import '../../data/models/measurement_record.dart';
import '../../engine/api/engine_snapshot.dart';
import '../../engine/api/events.dart';
import '../../engine/core/models/activity_state.dart';
import '../../services/pulse_engine_scope.dart';
import '../../shared/widgets/buttons/primary_button.dart';
import '../../shared/widgets/buttons/secondary_button.dart';
import '../../shared/widgets/dialogs/check_in_sheet.dart';
import '../../shared/widgets/feedback/live_waveform_painter.dart';
import '../../shared/widgets/indicators/signal_quality_bar.dart';
import '../emergency/escalation_screen.dart';
import 'measurement_results_screen.dart';

/// Explicit UI state machine for the measurement flow.
enum MeasurementUiState {
  preparing,
  awaitingFinger,
  fingerDetected,
  measuring,
  poorSignal,
  completed,
  failed,
}

/// Screen C & D: Camera Measurement Screen & Native Animation.
///
/// Drives the 15-20 second spot measurement, reactive to camera sensor state,
/// real-time PPG waveform, and placement hints.
class CameraMeasurementScreen extends StatefulWidget {
  final Duration? timeSinceExercise;
  final String? replayAssetPath;

  const CameraMeasurementScreen({
    super.key,
    this.timeSinceExercise,
    this.replayAssetPath,
  });

  @override
  State<CameraMeasurementScreen> createState() =>
      _CameraMeasurementScreenState();
}

class _CameraMeasurementScreenState extends State<CameraMeasurementScreen> {
  StreamSubscription<ScanSummary>? _scanFinishedSub;
  StreamSubscription<AlertEvent>? _alertSub;

  int _countdownSeconds = PulseConstants.spotScanDurationSeconds;
  Timer? _countdownTimer;
  bool _checkInSheetOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startMeasurement();
    });
  }

  Future<void> _startMeasurement() async {
    final engine = PulseEngineScope.engineOf(context);

    // Listen for scan completion
    _scanFinishedSub = engine.scanFinished.listen((summary) async {
      _countdownTimer?.cancel();
      if (!mounted) return;

      // Persist record
      final repo = PulseEngineScope.historyOf(context);
      final record = MeasurementRecord.fromScanSummary(
        summary: summary,
        activityState: widget.timeSinceExercise != null
            ? ActivityStateKind.recovering
            : ActivityStateKind.resting,
      );
      await repo.saveRecord(record);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              MeasurementResultsScreen(summary: summary, record: record),
        ),
      );
    });

    // Listen for alert transitions (check-in / escalation)
    _alertSub = engine.alerts.listen((alert) {
      if (!mounted) return;
      if (alert.kind == AlertEventKind.checkInOpened) {
        _showCheckInModal(alert.remainingSeconds ?? 30);
      } else if (alert.kind == AlertEventKind.escalated) {
        if (_checkInSheetOpen) {
          Navigator.of(context, rootNavigator: true).pop();
          _checkInSheetOpen = false;
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => EscalationScreen(payload: alert.payload),
          ),
        );
      }
    });

    try {
      if (widget.replayAssetPath != null) {
        await engine.startReplay(widget.replayAssetPath!, speed: 1.0);
      } else {
        await engine.startScan(timeSinceExercise: widget.timeSinceExercise);
      }

      // 20s countdown timer
      _countdownSeconds = PulseConstants.spotScanDurationSeconds;
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          if (_countdownSeconds > 0) {
            _countdownSeconds--;
          } else {
            timer.cancel();
          }
        });
      });
    } catch (_) {
      // Handled via engine error snapshot
    }
  }

  void _showCheckInModal(int initialRemaining) {
    if (_checkInSheetOpen) return;
    _checkInSheetOpen = true;

    final engine = PulseEngineScope.engineOf(context);

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ValueListenableBuilder<EngineSnapshot>(
          valueListenable: engine.snapshot,
          builder: (context, snapshot, _) {
            final remaining = snapshot.checkInRemaining ?? initialRemaining;
            return CheckInSheet(
              secondsRemaining: remaining,
              onUserOk: () {
                engine.respondCheckIn(ok: true);
                Navigator.of(sheetContext).pop();
                _checkInSheetOpen = false;
              },
              onUserNotOk: () {
                engine.respondCheckIn(ok: false);
                Navigator.of(sheetContext).pop();
                _checkInSheetOpen = false;
              },
            );
          },
        );
      },
    ).then((_) => _checkInSheetOpen = false);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _scanFinishedSub?.cancel();
    _alertSub?.cancel();
    super.dispose();
  }

  MeasurementUiState _deriveUiState(EngineSnapshot snapshot) {
    if (snapshot.phase == EnginePhase.error) return MeasurementUiState.failed;
    if (snapshot.phase == EnginePhase.preparingCamera)
      return MeasurementUiState.preparing;
    if (snapshot.phase == EnginePhase.finished)
      return MeasurementUiState.completed;

    final hint = snapshot.placementHint;
    if (hint == PlacementHint.noFinger) {
      return MeasurementUiState.awaitingFinger;
    }
    if (hint == PlacementHint.pressLighter || hint == PlacementHint.keepStill) {
      return MeasurementUiState.poorSignal;
    }
    if (snapshot.phase == EnginePhase.scanning ||
        snapshot.phase == EnginePhase.replaying) {
      return MeasurementUiState.measuring;
    }
    return MeasurementUiState.fingerDetected;
  }

  @override
  Widget build(BuildContext context) {
    final engine = PulseEngineScope.engineOf(context);

    return Scaffold(
      backgroundColor: PulseColors.background,
      appBar: AppBar(
        backgroundColor: PulseColors.surface,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Spot Measurement',
          style: PulseTypography.headingMedium,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () async {
            _countdownTimer?.cancel();
            final navigator = Navigator.of(context);
            if (widget.replayAssetPath != null) {
              await engine.stopReplay();
            } else {
              await engine.endScan();
            }
            if (mounted) navigator.pop();
          },
        ),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<EngineSnapshot>(
          valueListenable: engine.snapshot,
          builder: (context, snapshot, _) {
            final uiState = _deriveUiState(snapshot);

            if (uiState == MeasurementUiState.failed) {
              return _buildErrorView(snapshot.error ?? 'Sensor error occurred');
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // State Badge
                  _buildStateHeader(uiState, snapshot),

                  const SizedBox(height: 16),

                  // If awaiting finger: Display instructional animation on top
                  if (uiState == MeasurementUiState.awaitingFinger ||
                      uiState == MeasurementUiState.preparing) ...[
                    Container(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: const CameraFingerInstruction(height: 260),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    // Camera feed preview or Waveform Container
                    _buildActiveSensorDisplay(engine, snapshot),
                    const SizedBox(height: 16),
                  ],

                  // Placement Hint Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _getHintBackgroundColor(snapshot.placementHint),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getHintBorderColor(snapshot.placementHint),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getHintIcon(snapshot.placementHint),
                          size: 18,
                          color: _getHintTextColor(snapshot.placementHint),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            snapshot.placementHint?.message ??
                                'Hold still — measuring',
                            textAlign: TextAlign.center,
                            style: PulseTypography.bodyMedium.copyWith(
                              fontSize: 14,
                              color: _getHintTextColor(snapshot.placementHint),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Progress Bar & Countdown
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Measuring vital signals...',
                            style: PulseTypography.caption.copyWith(
                              color: PulseColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '$_countdownSeconds s remaining',
                            style: PulseTypography.caption.copyWith(
                              color: PulseColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value:
                              (PulseConstants.spotScanDurationSeconds -
                                  _countdownSeconds) /
                              PulseConstants.spotScanDurationSeconds,
                          minHeight: 8,
                          backgroundColor: PulseColors.divider,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            PulseColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Signal Quality & Live Metric Row
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: PulseColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: PulseColors.divider),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SIGNAL QUALITY',
                              style: PulseTypography.caption.copyWith(
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SignalQualityBar(
                              quality: snapshot.latestVitals?.quality ?? 0.0,
                              hasFinger:
                                  snapshot.placementHint !=
                                  PlacementHint.noFinger,
                            ),
                          ],
                        ),
                        if (snapshot.latestVitals?.hr != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'CURRENT PULSE',
                                style: PulseTypography.caption.copyWith(
                                  letterSpacing: 0.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    snapshot.latestVitals!.hr!.toStringAsFixed(
                                      0,
                                    ),
                                    style: PulseTypography.headingMedium
                                        .copyWith(
                                          color: PulseColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'BPM',
                                    style: PulseTypography.caption,
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Cancel / Finish Action
                  SecondaryButton(
                    label: 'End Measurement',
                    icon: Icons.stop_circle_outlined,
                    onPressed: () async {
                      _countdownTimer?.cancel();
                      if (widget.replayAssetPath != null) {
                        await engine.stopReplay();
                      } else {
                        await engine.endScan();
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActiveSensorDisplay(dynamic engine, EngineSnapshot snapshot) {
    final cameraController = engine.cameraController as CameraController?;

    return Column(
      children: [
        if (cameraController != null && cameraController.value.isInitialized)
          Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: PulseColors.primary, width: 3),
            ),
            clipBehavior: Clip.antiAlias,
            child: CameraPreview(cameraController),
          ),
        const SizedBox(height: 12),
        // Live Waveform Plot
        LiveWaveformWidget(
          waveformStream: engine.waveform,
          height: 90,
          isMeasuring:
              snapshot.phase == EnginePhase.scanning ||
              snapshot.phase == EnginePhase.replaying,
        ),
      ],
    );
  }

  Widget _buildStateHeader(MeasurementUiState state, EngineSnapshot snapshot) {
    final (String title, Color color, IconData icon) = switch (state) {
      MeasurementUiState.preparing => (
        'Starting sensor...',
        PulseColors.textSecondary,
        Icons.hourglass_top_rounded,
      ),
      MeasurementUiState.awaitingFinger => (
        'Place your finger',
        PulseColors.riskElevated,
        Icons.touch_app_rounded,
      ),
      MeasurementUiState.fingerDetected => (
        'Finger detected',
        PulseColors.riskMonitoring,
        Icons.check_circle_outline_rounded,
      ),
      MeasurementUiState.measuring => (
        'Recording pulse wave',
        PulseColors.riskNormal,
        Icons.monitor_heart_rounded,
      ),
      MeasurementUiState.poorSignal => (
        'Adjusting signal',
        PulseColors.riskElevated,
        Icons.warning_amber_rounded,
      ),
      MeasurementUiState.completed => (
        'Scan complete',
        PulseColors.riskNormal,
        Icons.check_circle_rounded,
      ),
      MeasurementUiState.failed => (
        'Measurement failed',
        PulseColors.riskCritical,
        Icons.error_outline_rounded,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: PulseTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        PulseColors.riskCriticalBg,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Image.asset(
                  'assets/mascot/bluey_error.png',
                  height: 140,
                  fit: BoxFit.contain,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Camera Access Required',
              textAlign: TextAlign.center,
              style: PulseTypography.headingMedium,
            ),
            const SizedBox(height: 10),
            Text(
              'PulseGuard requires camera and flash access to detect subtle capillary blood volume pulses through your fingertip.\n\n$error',
              textAlign: TextAlign.center,
              style: PulseTypography.bodyRegular.copyWith(
                color: PulseColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Retry Camera Access',
              icon: Icons.refresh_rounded,
              onPressed: () {
                _startMeasurement();
              },
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Run Demo Replay Instead',
              icon: Icons.science_outlined,
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const CameraMeasurementScreen(
                      replayAssetPath: 'assets/traces/reaction.json',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getHintBackgroundColor(PlacementHint? hint) {
    if (hint == null || hint == PlacementHint.ok)
      return PulseColors.riskNormalBg;
    if (hint == PlacementHint.noFinger) return PulseColors.surfaceDim;
    return PulseColors.riskElevatedBg;
  }

  Color _getHintBorderColor(PlacementHint? hint) {
    if (hint == null || hint == PlacementHint.ok)
      return PulseColors.riskNormal.withValues(alpha: 0.3);
    if (hint == PlacementHint.noFinger) return PulseColors.divider;
    return PulseColors.riskElevated.withValues(alpha: 0.3);
  }

  Color _getHintTextColor(PlacementHint? hint) {
    if (hint == null || hint == PlacementHint.ok) return PulseColors.riskNormal;
    if (hint == PlacementHint.noFinger) return PulseColors.textSecondary;
    return PulseColors.riskElevated;
  }

  IconData _getHintIcon(PlacementHint? hint) {
    if (hint == null || hint == PlacementHint.ok)
      return Icons.check_circle_rounded;
    if (hint == PlacementHint.noFinger) return Icons.touch_app_rounded;
    return Icons.info_outline_rounded;
  }
}
