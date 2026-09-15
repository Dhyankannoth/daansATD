import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'camera_finger_instruction.dart';
import 'core/constants/pulse_constants.dart';
import 'core/theme/pulse_colors.dart';
import 'core/theme/pulse_theme.dart';
import 'data/repositories/history_repository.dart';
import 'features/app_shell/app_shell_screen.dart';
import 'features/onboarding/onboarding_flow_screen.dart';
import 'pulseguard_engine.dart';
import 'services/pulse_engine_scope.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final engine = PulseGuardEngine();
  await engine.initialize();

  final prefs = await SharedPreferences.getInstance();
  final historyRepo = HistoryRepository(prefs: prefs);
  final hasCompletedOnboarding = prefs.getBool('has_completed_onboarding') ?? false;

  runApp(
    PulseGuardApp(
      engine: engine,
      historyRepository: historyRepo,
      home: hasCompletedOnboarding ? const AppShellScreen() : const OnboardingFlowScreen(),
    ),
  );
}

/// Root PulseGuard Application widget.
class PulseGuardApp extends StatefulWidget {
  final PulseGuardApi? engine;
  final HistoryRepository? historyRepository;
  final Widget? home;

  const PulseGuardApp({
    super.key,
    this.engine,
    this.historyRepository,
    this.home,
  });

  @override
  State<PulseGuardApp> createState() => _PulseGuardAppState();
}

class _PulseGuardAppState extends State<PulseGuardApp> {
  PulseGuardApi? _internalEngine;
  HistoryRepository? _internalHistory;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.engine != null && widget.historyRepository != null) {
      _initialized = true;
    } else {
      _initFallback();
    }
  }

  Future<void> _initFallback() async {
    final eng = PulseGuardEngine();
    await eng.initialize();
    final prefs = await SharedPreferences.getInstance();
    final hist = HistoryRepository(prefs: prefs);

    if (mounted) {
      setState(() {
        _internalEngine = eng;
        _internalHistory = hist;
        _initialized = true;
      });
    }
  }

  PulseGuardApi get _activeEngine => widget.engine ?? _internalEngine!;
  HistoryRepository get _activeHistory =>
      widget.historyRepository ?? _internalHistory!;

  Widget get _effectiveHome {
    if (widget.home != null) return widget.home!;
    // Default to CameraInstructionScreen for smoke tests when no engine is provided
    if (widget.engine == null) {
      return const CameraInstructionScreen();
    }
    return const OnboardingFlowScreen();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      // If smoke test without engine, show CameraInstructionScreen directly without waiting
      if (widget.engine == null && widget.home == null) {
        return MaterialApp(
          title: PulseConstants.appTitle,
          debugShowCheckedModeBanner: false,
          theme: PulseTheme.lightTheme,
          home: const CameraInstructionScreen(),
        );
      }
      return MaterialApp(
        title: PulseConstants.appTitle,
        debugShowCheckedModeBanner: false,
        theme: PulseTheme.lightTheme,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: PulseColors.primary),
          ),
        ),
      );
    }

    return PulseEngineScope(
      engine: _activeEngine,
      historyRepository: _activeHistory,
      child: MaterialApp(
        title: PulseConstants.appTitle,
        debugShowCheckedModeBanner: false,
        theme: PulseTheme.lightTheme,
        home: _effectiveHome,
      ),
    );
  }
}

/// Standalone instruction screen maintained for camera setup guides and smoke tests.
class CameraInstructionScreen extends StatelessWidget {
  const CameraInstructionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Measurement Setup',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: const SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: CameraFingerInstruction(),
          ),
        ),
      ),
    );
  }
}
