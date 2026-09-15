import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Clean, medical-app instructional animation widget demonstrating
/// how to place a finger over the phone's camera and hold it there.
class CameraFingerInstruction extends StatefulWidget {
  /// Overall height of the instruction widget. Defaults to responsive layout.
  final double? height;

  /// Custom duration of one complete loop cycle. Defaults to 4 seconds.
  final Duration cycleDuration;

  /// Relative X position of the camera center within the phone image (0.0 to 1.0).
  /// For this phone asset, the camera module is located at ~27% from the left.
  final double cameraRelativeX;

  /// Relative Y position of the camera center within the phone image (0.0 to 1.0).
  /// For this phone asset, the primary camera lens is at ~13% from the top.
  final double cameraRelativeY;

  /// Scale multiplier applied to the finger when covering the camera.
  final double fingerCoverScale;

  const CameraFingerInstruction({
    super.key,
    this.height,
    this.cycleDuration = const Duration(seconds: 4),
    this.cameraRelativeX = 0.275,
    this.cameraRelativeY = 0.135,
    this.fingerCoverScale = 1.04,
  });

  @override
  State<CameraFingerInstruction> createState() => _CameraFingerInstructionState();
}

class _CameraFingerInstructionState extends State<CameraFingerInstruction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _approachAnimation;
  late final Animation<double> _releaseAnimation;

  // Aspect ratio of the phone asset (width / height)
  // The phone image is 1080 x 1920 (9:16)
  static const double _phoneAspectRatio = 1080 / 1920;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.cycleDuration,
    );

    // Sequence Breakdown (4.0s total):
    // 0.0s - 1.0s (0.00 -> 0.25): Approach (finger moves upward to camera)
    // 1.0s - 3.0s (0.25 -> 0.75): Hold (finger stationary over camera + subtle pulse)
    // 3.0s - 4.0s (0.75 -> 1.00): Release (finger returns to initial position)

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
        // Compute responsive dimensions that guarantee no overflow
        final maxHeight = widget.height ??
            (constraints.maxHeight.isFinite ? constraints.maxHeight : 440.0);
        final maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 320.0;

        // Reserve space: Animation container takes ~72% of total height, text takes ~28%
        final double animContainerHeight = (maxHeight * 0.70).clamp(180.0, 320.0);
        final double phoneHeight = animContainerHeight * 0.88;
        final double phoneWidth = phoneHeight * _phoneAspectRatio;

        // Finger sizing relative to phone
        final double fingerWidth = phoneWidth * 0.38;
        final double fingerHeight = fingerWidth * 2.1; // finger aspect ratio

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
                          'assets/animations/phone.png',
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
                          // Approach brings progress from 0 -> 1
                          // Release brings progress from 1 -> 0
                          final double progress = (tApproach - tRelease).clamp(0.0, 1.0);

                          // Initial state position: finger below phone, pointing up toward camera
                          final double startX = phoneWidth * widget.cameraRelativeX;
                          final double startY = phoneHeight * 0.95;

                          // Final target position: fingertip positioned over camera
                          final double targetX = phoneWidth * widget.cameraRelativeX;
                          final double targetY = phoneHeight * widget.cameraRelativeY;

                          // Current interpolated position (anchor at fingertip center: top-center)
                          final double currentX = startX + (targetX - startX) * progress;
                          final double currentY = startY + (targetY - startY) * progress;

                          // Subtle feedback during hold phase (1.0s to 3.0s)
                          // Very gentle scale breathing pulse
                          double holdScale = 1.0;
                          double holdGlow = 0.0;
                          if (_controller.value >= 0.25 && _controller.value <= 0.75) {
                            final cycleVal = (_controller.value - 0.25) / 0.50; // 0.0 to 1.0
                            // 2 gentle sine wave cycles during the 2s hold
                            final sineVal = (1.0 - math.cos(cycleVal * 4 * math.pi)) / 2.0;
                            holdScale = 1.0 + (widget.fingerCoverScale - 1.0) * (0.5 + 0.5 * sineVal);
                            holdGlow = 0.15 * sineVal;
                          } else if (progress > 0.0) {
                            holdScale = 1.0 + (widget.fingerCoverScale - 1.0) * progress;
                          }

                          return Positioned(
                            left: currentX - (fingerWidth / 2),
                            top: currentY - (fingerHeight * 0.12), // Align camera with fingertip pad
                            child: Transform.scale(
                              scale: holdScale,
                              alignment: const Alignment(0, -0.75), // Scale around fingertip pad
                              child: Stack(
                                alignment: Alignment.topCenter,
                                children: [
                                  // Optional subtle camera coverage indicator
                                  if (holdGlow > 0.01)
                                    Positioned(
                                      top: fingerHeight * 0.08,
                                      child: Container(
                                        width: fingerWidth * 0.75,
                                        height: fingerWidth * 0.75,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.redAccent.withValues(alpha: holdGlow),
                                        ),
                                      ),
                                    ),
                                  // Finger Image
                                  SizedBox(
                                    width: fingerWidth,
                                    height: fingerHeight,
                                    child: Image.asset(
                                      'assets/animations/finger.png',
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
                      fontFamily: 'Roboto',
                      fontSize: 18.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B), // Slate 800
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    'Keep your finger in place for a few seconds',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Roboto',
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
