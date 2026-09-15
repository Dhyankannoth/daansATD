import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/theme/pulse_typography.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../widgets/onboarding_trust_badge.dart';

/// Screen 1 — Welcome: Introduce the product and establish trust.
/// Animation: Reveal (Branding -> Headline -> Supporting Text -> Trust Badge -> CTA).
class WelcomeScreen extends StatefulWidget {
  final VoidCallback onGetStarted;

  const WelcomeScreen({
    super.key,
    required this.onGetStarted,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;

  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;

  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;

  late final Animation<double> _bodyFade;
  late final Animation<Offset> _bodySlide;

  late final Animation<double> _trustFade;
  late final Animation<double> _ctaFade;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    // Staggered reveal sequence
    _logoFade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.00, 0.35, curve: Curves.easeOut),
    );
    _logoSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.00, 0.35, curve: Curves.easeOutCubic),
    ));

    _titleFade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.20, 0.55, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.20), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.20, 0.55, curve: Curves.easeOutCubic),
    ));

    _bodyFade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.40, 0.75, curve: Curves.easeOut),
    );
    _bodySlide = Tween<Offset>(begin: const Offset(0, 0.20), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.40, 0.75, curve: Curves.easeOutCubic),
    ));

    _trustFade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.60, 0.90, curve: Curves.easeOut),
    );

    _ctaFade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.75, 1.00, curve: Curves.easeOut),
    );

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
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
                // Top & Center Content
                Column(
                  children: [
                    const SizedBox(height: 16),

                    // Hero Mascot: Bluey Welcome
                    FadeTransition(
                      opacity: _logoFade,
                      child: SlideTransition(
                        position: _logoSlide,
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      PulseColors.tintBlueBg.withValues(alpha: 0.8),
                                      PulseColors.tintBlueBg.withValues(alpha: 0.1),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.3, 0.7, 1.0],
                                  ),
                                ),
                              ),
                              Image.asset(
                                'assets/mascot/bluey_welcome.png',
                                height: 150,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Headline
                    FadeTransition(
                      opacity: _titleFade,
                      child: SlideTransition(
                        position: _titleSlide,
                        child: Text(
                          'Know when something changes.',
                          textAlign: TextAlign.center,
                          style: PulseTypography.headingLarge.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            height: 1.25,
                            color: PulseColors.textPrimary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Supporting Text
                    FadeTransition(
                      opacity: _bodyFade,
                      child: SlideTransition(
                        position: _bodySlide,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'Monitor changes in your vital signals and get an early warning when something looks unusual.',
                            textAlign: TextAlign.center,
                            style: PulseTypography.bodyRegular.copyWith(
                              fontSize: 15,
                              height: 1.5,
                              color: PulseColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Privacy & Security Trust Badge
                    FadeTransition(
                      opacity: _trustFade,
                      child: const OnboardingTrustBadge(
                        title: 'Your privacy and security matter to us.',
                        message:
                            'All physiological baseline data stays locally on your device. We never sell, share, or broadcast your health information.',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // CTA Button (Pill-shaped PrimaryButton)
                FadeTransition(
                  opacity: _ctaFade,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: PrimaryButton(
                      label: 'Get Started',
                      onPressed: widget.onGetStarted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
