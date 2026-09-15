import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../engine/api/engine_snapshot.dart';
import '../../services/pulse_engine_scope.dart';
import '../app_shell/app_shell_screen.dart';
import 'screens/baseline_complete_screen.dart';
import 'screens/camera_tutorial_screen.dart';
import 'screens/emergency_contact_screen.dart';
import 'screens/establish_baseline_screen.dart';
import 'screens/initial_baseline_screen.dart';
import 'screens/monitoring_concept_screen.dart';
import 'screens/permissions_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/welcome_screen.dart';
import 'widgets/onboarding_header.dart';

/// Master coordinator managing the 9-screen onboarding flow with Cal AI aesthetics.
///
/// Flow:
/// 1. Welcome Screen
/// 2. Monitoring Concept Screen
/// 3. Profile Setup Screen
/// 4. Emergency Contact Screen
/// 5. Permissions Screen
/// 6. Camera Tutorial Screen ("Measure" button)
/// 7. Establish Baseline Screen ("Let's establish your baseline." first-time tutorial)
/// 8. Initial Baseline Screen (Real camera physiological measurement)
/// 9. Baseline Complete Screen (Confirmation & finish)
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
  static const int _totalSteps = 9;
  ScanSummary? _initialScanSummary;

  void _goToNextPage() {
    if (_currentPage < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  bool _checkHasBaseline() {
    try {
      final engine = PulseEngineScope.engineOf(context);
      if (engine.snapshot.value.hasBaseline) return true;
    } catch (_) {}
    try {
      final prefs = PulseEngineScope.historyOf(context).prefs;
      if (prefs.getString('pulseguard.baseline') != null) return true;
    } catch (_) {}
    return false;
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      final hasBaseline = _checkHasBaseline();

      // If returning from measurement and baseline already exists, skip establish baseline tutorial
      if (_currentPage == 7 && hasBaseline) {
        _pageController.animateToPage(
          5,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOutCubic,
        );
        return;
      }

      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _handleCameraTutorialMeasure() {
    final hasBaseline = _checkHasBaseline();

    if (hasBaseline) {
      // Subsequent measurement: skip tutorial and jump directly to measurement (step 8, index 7)
      _pageController.animateToPage(
        7,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      // First-time baseline: navigate to "Let's establish your baseline." (step 7, index 6)
      _goToNextPage();
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
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Cal AI Top Navigation & Progress Header
              OnboardingHeader(
                currentStep: _currentPage,
                totalSteps: _totalSteps,
                onBack: _currentPage > 0 ? _goToPreviousPage : null,
              ),

              // Page View for the 9 onboarding steps
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
                      onMeasure: _handleCameraTutorialMeasure,
                      onTryIt: _handleCameraTutorialMeasure,
                    ),

                    // 7. Establish Baseline Tutorial (Transition)
                    EstablishBaselineScreen(
                      onStartMeasurement: _goToNextPage,
                    ),

                    // 8. Initial Baseline Measurement (Measure)
                    InitialBaselineScreen(
                      onMeasurementComplete: (summary) {
                        setState(() {
                          _initialScanSummary = summary;
                        });
                        _goToNextPage();
                      },
                    ),

                    // 9. Baseline Complete (Confirm)
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
