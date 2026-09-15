import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'core/theme/pulse_typography.dart';

/// Clean, medical-app instructional animation widget demonstrating
/// how to place a finger over the phone's camera and hold it there.
class CameraFingerInstruction extends StatefulWidget {
  /// Overall height of the instruction widget. Defaults to responsive layout.
  final double? height;

  /// Custom duration of one complete loop cycle. Defaults to 4 seconds.
  final Duration cycleDuration;

  /// Relative X position of the camera center within the phone image (0.0 to 1.0).
  /// For this phone asset, the primary camera lens is at ~27.5% from the left.
  final double cameraRelativeX;

  /// Relative Y position of the camera center within the phone image (0.0 to 1.0).
  /// For this phone asset, the primary camera lens is at ~13.5% from the top.
  final double cameraRelativeY;

  /// Scale multiplier applied to the finger when covering the camera.
  final double fingerCoverScale;

  /// Asset path for phone graphic.
  final String phoneAsset;

  /// Asset path for finger graphic.
  final String fingerAsset;

  const CameraFingerInstruction({
    super.key,
    this.height,
    this.cycleDuration = const Duration(seconds: 4),
    this.cameraRelativeX = 0.275,
    this.cameraRelativeY = 0.135,
    this.fingerCoverScale = 1.04,
    this.phoneAsset = 'assets/animations/phone.png',
    this.fingerAsset = 'assets/animations/finger_2.png',
  });

  @override
  State<CameraFingerInstruction> createState() =>
      _CameraFingerInstructionState();
}

class _CameraFingerInstructionState extends State<CameraFingerInstruction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _approachAnimation;
  late final Animation<double> _releaseAnimation;

  // Aspect ratio of the phone asset (width / height)
  // 540 / 968 ~= 0.558 (9:16 approx)
  static const double _phoneAspectRatio = 540 / 968;

  // For finger_2.png (hand with pointing index finger):
  // The index fingertip pad is at ~45.2% from left and ~17% from top of the square image.
  static const double _fingertipAnchorXRatio = 0.452;
  static const double _fingertipAnchorYRatio = 0.170;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.cycleDuration,
    );

    // Sequence Breakdown (4.0s total):
    // 0.0s - 1.0s (0.00 -> 0.25): Approach (hand moves upward toward camera)
    // 1.0s - 3.0s (0.25 -> 0.75): Hold (stationary over camera with subtle pulse)
    // 3.0s - 4.0s (0.75 -> 1.00): Release (hand returns smoothly downward)

    _approachAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.00, 0.25, curve: Curves.easeInOutCubic),
    );

    _releaseAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.75, 1.00, curve: Curves.easeInOutCubic),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive dimensions that guarantee no overflow
        final maxHeight =
            widget.height ??
            (constraints.maxHeight.isFinite ? constraints.maxHeight : 440.0);
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 320.0;

        // Animation container height fits comfortably
        final double animContainerHeight = (maxHeight * 0.70).clamp(
          180.0,
          320.0,
        );
        final double phoneHeight = animContainerHeight * 0.88;
        final double phoneWidth = phoneHeight * _phoneAspectRatio;

        // The finger_2.png hand image is square (1:1 aspect ratio)
        // Sized appropriately relative to the phone so the index finger tip fits the camera module nicely
        final double handSize = phoneWidth * 0.95;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Animation canvas
            SizedBox(
              height: animContainerHeight,
              width: maxWidth,
              child: Center(
                child: SizedBox(
                  width: phoneWidth,
                  height: phoneHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // Fixed Phone Image
                      Positioned.fill(
                        child: Image.asset(
                          widget.phoneAsset,
                          fit: BoxFit.contain,
                        ),
                      ),

                      // Animated Finger Layer
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          final tApproach = _approachAnimation.value;
                          final tRelease = _releaseAnimation.value;

                          // 0.0 = initial position (below camera/phone), 1.0 = covering camera
                          final double progress = (tApproach - tRelease).clamp(
                            0.0,
                            1.0,
                          );

                          // Initial state position: hand below phone, index pointing upward
                          final double startX =
                              phoneWidth * widget.cameraRelativeX;
                          final double startY = phoneHeight * 0.92;

                          // Final target position: fingertip positioned directly over camera lens
                          final double targetX =
                              phoneWidth * widget.cameraRelativeX;
                          final double targetY =
                              phoneHeight * widget.cameraRelativeY;

                          // Current interpolated position for the fingertip center
                          final double currentTipX =
                              startX + (targetX - startX) * progress;
                          final double currentTipY =
                              startY + (targetY - startY) * progress;

                          // Subtle feedback during hold phase (1.0s to 3.0s)
                          double holdScale = 1.0;
                          double holdGlow = 0.0;
                          if (_controller.value >= 0.25 &&
                              _controller.value <= 0.75) {
                            final cycleVal =
                                (_controller.value - 0.25) / 0.50; // 0.0 to 1.0
                            final sineVal =
                                (1.0 - math.cos(cycleVal * 4 * math.pi)) / 2.0;
                            holdScale =
                                1.0 +
                                (widget.fingerCoverScale - 1.0) *
                                    (0.5 + 0.5 * sineVal);
                            holdGlow = 0.15 * sineVal;
                          } else if (progress > 0.0) {
                            holdScale =
                                1.0 +
                                (widget.fingerCoverScale - 1.0) * progress;
                          }

                          // Anchor coordinates: align index fingertip precisely over currentTip
                          final double handLeft =
                              currentTipX - (handSize * _fingertipAnchorXRatio);
                          final double handTop =
                              currentTipY - (handSize * _fingertipAnchorYRatio);

                          return Positioned(
                            left: handLeft,
                            top: handTop,
                            child: Transform.scale(
                              scale: holdScale,
                              alignment: Alignment(
                                (_fingertipAnchorXRatio - 0.5) * 2,
                                (_fingertipAnchorYRatio - 0.5) * 2,
                              ),
                              child: Stack(
                                alignment: Alignment.topLeft,
                                children: [
                                  // Optional subtle sensor coverage indicator
                                  if (holdGlow > 0.01)
                                    Positioned(
                                      left:
                                          handSize * _fingertipAnchorXRatio -
                                          12,
                                      top:
                                          handSize * _fingertipAnchorYRatio -
                                          12,
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.redAccent.withValues(
                                            alpha: holdGlow,
                                          ),
                                        ),
                                      ),
                                    ),
                                  // Hand Image with pointing finger
                                  SizedBox(
                                    width: handSize,
                                    height: handSize,
                                    child: Image.asset(
                                      widget.fingerAsset,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18.0),

            // Instructional Text Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Cover the camera with your finger',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: PulseTypography.fontFamily,
                      fontFamilyFallback: PulseTypography.fontFamilyFallback,
                      fontSize: 18.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A), // Slate 800
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    'Keep your finger in place for a few seconds',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: PulseTypography.fontFamily,
                      fontFamilyFallback: PulseTypography.fontFamilyFallback,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF64748B), // Slate 500
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
