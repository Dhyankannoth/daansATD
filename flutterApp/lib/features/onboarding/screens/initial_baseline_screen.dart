import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/pulse_constants.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/theme/pulse_typography.dart';
import '../../../../engine/api/engine_snapshot.dart';
import '../../../../engine/api/events.dart';
import '../../../../services/pulse_engine_scope.dart';
import '../../../../shared/widgets/feedback/live_waveform_painter.dart';
import '../../../../shared/widgets/indicators/signal_quality_bar.dart';

/// Screen 7 — Initial Baseline Measurement: Perform initial physiological scan.
/// Animation: Measure (Live waveform, radial progress countdown, real-time quality & hints).
class InitialBaselineScreen extends StatefulWidget {
  final ValueChanged<ScanSummary?> onMeasurementComplete;

  const InitialBaselineScreen({
    super.key,
    required this.onMeasurementComplete,
  });

  @override
  State<InitialBaselineScreen> createState() => _InitialBaselineScreenState();
}

class _InitialBaselineScreenState extends State<InitialBaselineScreen> {
  StreamSubscription<CalibrationProgress>? _calibrationSub;
  int _countdown = PulseConstants.spotScanDurationSeconds;
  Timer? _countdownTimer;
  bool _scanStarted = false;
  bool _measurementComplete = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startInitialBaselineScan();
    });
  }

  Future<void> _startInitialBaselineScan() async {
    if (_scanStarted) return;
    _scanStarted = true;

    final engine = PulseEngineScope.engineOf(context);

    _calibrationSub = engine.calibration.listen((progress) {
      if (!progress.done) return;
      _countdownTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _measurementComplete = true;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          widget.onMeasurementComplete(null);
        }
      });
    });

    try {
      await engine.startCalibration();
      // Countdown display is driven live by snapshot.elapsed/remaining in
      // build() once calibration starts reporting progress — no local timer
      // needed here. Using a separate hardcoded-duration timer previously
      // caused the display to hit 0 and freeze while the real (120s)
      // calibration kept running in the background.
    } catch (_) {
      // If hardware camera fails or in mock test environment, fallback to simulated countdown
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          if (_countdown > 1) {
            _countdown--;
          } else {
            _countdown = 0;
            timer.cancel();
            widget.onMeasurementComplete(null);
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _calibrationSub?.cancel();
    super.dispose();
  }

  bool _hasFinger(EngineSnapshot snapshot) {
    final hint = snapshot.placementHint;
    return hint != null && hint != PlacementHint.noFinger;
  }

  String _deriveStatusText(EngineSnapshot snapshot) {
    if (_measurementComplete) return 'Measurement complete!';
    if (snapshot.phase == EnginePhase.preparingCamera) {
      return 'Preparing camera sensor...';
    }
    final hint = snapshot.placementHint;
    if (hint == null || hint == PlacementHint.noFinger) {
      return 'Place your finger over the rear camera';
    }
    return switch (hint) {
      PlacementHint.ok => 'Good signal • Measuring vital signals',
      PlacementHint.keepStill => 'Keep your finger steady and relaxed',
      PlacementHint.pressLighter => 'Press lighter — do not squeeze',
      PlacementHint.coverLens => 'Cover camera lens completely',
      PlacementHint.coverFlash => 'Cover flash light completely',
      PlacementHint.noFinger => 'Place your finger over the rear camera',
    };
  }

  @override
  Widget build(BuildContext context) {
    final engine = PulseEngineScope.engineOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return ValueListenableBuilder<EngineSnapshot>(
          valueListenable: engine.snapshot,
          builder: (context, snapshot, _) {
            final vitals = snapshot.latestVitals;
            final statusText = _deriveStatusText(snapshot);
            final remaining = snapshot.remaining;
            final totalSeconds = remaining != null
                ? (snapshot.elapsed + remaining).inSeconds
                : PulseConstants.spotScanDurationSeconds;
            final displaySeconds = remaining != null
                ? remaining.inSeconds.clamp(0, totalSeconds)
                : _countdown;
            final progress = totalSeconds > 0
                ? (1.0 - (displaySeconds / totalSeconds)).clamp(0.0, 1.0)
                : 0.0;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight > 50 ? constraints.maxHeight - 24 : 500,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // Headline
                        Text(
                          'Measuring your baseline.',
                          style: PulseTypography.headingLarge.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            height: 1.25,
                            color: PulseColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Supporting Text
                        Text(
                          'Stay still and keep your finger over the camera for about ${(totalSeconds / 60).ceil()} minutes.',
                          style: PulseTypography.bodyRegular.copyWith(
                            fontSize: 14,
                            height: 1.5,
                            color: PulseColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Central Radial Measurement Gauge
                        Center(
                          child: Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: PulseColors.surface,
                              border: Border.all(
                                color: PulseColors.divider,
                                width: 1.2,
                              ),
                              boxShadow: const [PulseColors.cardShadow],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Background Ring
                                SizedBox(
                                  width: 144,
                                  height: 144,
                                  child: CircularProgressIndicator(
                                    value: 1.0,
                                    strokeWidth: 8,
                                    color: PulseColors.surfaceDim,
                                  ),
                                ),
                                // Animated Progress
                                SizedBox(
                                  width: 144,
                                  height: 144,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 8,
                                    strokeCap: StrokeCap.round,
                                    color: _hasFinger(snapshot)
                                        ? PulseColors.tintEmeraldIcon
                                        : PulseColors.borderSubtle,
                                  ),
                                ),
                                // Inner Countdown & Heart Icon
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _hasFinger(snapshot)
                                        ? const Icon(
                                            Icons.favorite_rounded,
                                            size: 26,
                                            color: PulseColors.tintRedIcon,
                                          )
                                        : Image.asset(
                                            'assets/mascot/bluey_scanning.png',
                                            height: 48,
                                            fit: BoxFit.contain,
                                          ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$displaySeconds',
                                      style: PulseTypography.displayMetric.copyWith(
                                        fontSize: 40,
                                        fontWeight: FontWeight.w800,
                                        height: 1.0,
                                      ),
                                    ),
                                    Text(
                                      'seconds',
                                      style: PulseTypography.caption.copyWith(
                                        color: PulseColors.textTertiary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Live Status Banner with Placement Hint
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 14.0,
                          ),
                          decoration: BoxDecoration(
                            color: _hasFinger(snapshot)
                                ? PulseColors.tintEmeraldBg
                                : PulseColors.surfaceDim,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _hasFinger(snapshot)
                                  ? PulseColors.tintEmeraldIcon.withValues(alpha: 0.3)
                                  : PulseColors.divider,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _hasFinger(snapshot)
                                    ? Icons.check_circle_rounded
                                    : Icons.info_outline_rounded,
                                size: 20,
                                color: _hasFinger(snapshot)
                                    ? PulseColors.tintEmeraldIcon
                                    : PulseColors.textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  statusText,
                                  style: PulseTypography.bodyMedium.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _hasFinger(snapshot)
                                        ? PulseColors.textPrimary
                                        : PulseColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Real-time PPG Waveform Display
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: const [PulseColors.cardShadow],
                          ),
                          child: LiveWaveformWidget(
                            height: 110,
                            waveformStream: engine.waveform,
                            waveColor: _hasFinger(snapshot)
                                ? PulseColors.tintEmeraldIcon
                                : PulseColors.borderSubtle,
                            isMeasuring: _hasFinger(snapshot),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Live Signal Quality Meter
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Signal Fidelity',
                              style: PulseTypography.caption.copyWith(
                                color: PulseColors.textTertiary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SignalQualityBar(
                              quality: vitals?.quality ?? 0.0,
                              hasFinger: _hasFinger(snapshot),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Cancel / Skip helper
                    Center(
                      child: TextButton(
                        onPressed: () {
                          _countdownTimer?.cancel();
                          _calibrationSub?.cancel();
                          unawaited(engine.cancelCalibration());
                          widget.onMeasurementComplete(null);
                        },
                        child: Text(
                          'Skip Baseline for Now',
                          style: PulseTypography.caption.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: PulseColors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
