import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/pulse_colors.dart';
import '../../engine/api/engine_snapshot.dart';
import '../app_shell/app_shell_screen.dart';
import 'screens/baseline_complete_screen.dart';
import 'screens/camera_tutorial_screen.dart';
import 'screens/emergency_contact_screen.dart';
import 'screens/initial_baseline_screen.dart';
import 'screens/monitoring_concept_screen.dart';
import 'screens/permissions_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/welcome_screen.dart';
import 'widgets/onboarding_header.dart';

/// Master coordinator managing the 8-screen onboarding flow with Cal AI aesthetics.
class OnboardingFlowScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const OnboardingFlowScreen({
    super.key,
    this.onComplete,
  });

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalSteps = 8;
  ScanSummary? _initialScanSummary;

  void _goToNextPage() {
    if (_currentPage < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', true);

    if (!mounted) return;

    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const AppShellScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentPage > 0) {
          _goToPreviousPage();
        }
      },
      child: Scaffold(
        backgroundColor: PulseColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Cal AI Top Navigation & Progress Header
              OnboardingHeader(
                currentStep: _currentPage,
                totalSteps: _totalSteps,
                onBack: _currentPage > 0 ? _goToPreviousPage : null,
              ),

              // Page View for the 8 onboarding steps
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Controlled step progression
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                  },
                  children: [
                    // 1. Welcome (Reveal)
                    WelcomeScreen(
                      onGetStarted: _goToNextPage,
                    ),

                    // 2. How Monitoring Works (Pulse)
                    MonitoringConceptScreen(
                      onContinue: _goToNextPage,
                    ),

                    // 3. Basic Profile (Slide)
                    ProfileSetupScreen(
                      onContinue: _goToNextPage,
                    ),

                    // 4. Emergency Contact (Connect)
                    EmergencyContactScreen(
                      onContinue: _goToNextPage,
                    ),

                    // 5. Permissions (Enable)
                    PermissionsScreen(
                      onContinue: _goToNextPage,
                    ),

                    // 6. Camera Tutorial (Guide)
                    CameraTutorialScreen(
                      onTryIt: _goToNextPage,
                    ),

                    // 7. Initial Baseline Measurement (Measure)
                    InitialBaselineScreen(
                      onMeasurementComplete: (summary) {
                        setState(() {
                          _initialScanSummary = summary;
                        });
                        _goToNextPage();
                      },
                    ),

                    // 8. Baseline Complete (Confirm)
                    BaselineCompleteScreen(
                      summary: _initialScanSummary,
                      onStartMonitoring: _completeOnboarding,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
