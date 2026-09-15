import 'dart:async';
import 'package:flutter/material.dart';
import '../../engine/api/engine_snapshot.dart';
import '../../engine/api/events.dart';
import '../../services/pulse_engine_scope.dart';
import '../../shared/widgets/dialogs/check_in_sheet.dart';
import '../../shared/widgets/navigation/pulse_bottom_nav.dart';
import '../baseline/baseline_screen.dart';
import '../emergency/escalation_screen.dart';
import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../measurement/camera_measurement_screen.dart';
import '../settings/settings_screen.dart';

/// App Root Scaffold hosting Bottom Navigation and global Alert Watchdogs.
class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key});

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  int _currentTab = 0;
  StreamSubscription<AlertEvent>? _alertSub;
  bool _checkInSheetShowing = false;

  final List<Widget> _screens = const [
    HomeScreen(),
    BaselineScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeToAlerts();
    });
  }

  void _subscribeToAlerts() {
    final engine = PulseEngineScope.engineOf(context);
    _alertSub = engine.alerts.listen((event) {
      if (!mounted) return;
      if (event.kind == AlertEventKind.checkInOpened) {
        _presentCheckInModal(event.remainingSeconds ?? 30);
      } else if (event.kind == AlertEventKind.escalated) {
        if (_checkInSheetShowing) {
          Navigator.of(context, rootNavigator: true).pop();
          _checkInSheetShowing = false;
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EscalationScreen(payload: event.payload),
          ),
        );
      }
    });
  }

  void _presentCheckInModal(int initialRemaining) {
    if (_checkInSheetShowing) return;
    _checkInSheetShowing = true;

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
                _checkInSheetShowing = false;
              },
              onUserNotOk: () {
                engine.respondCheckIn(ok: false);
                Navigator.of(sheetContext).pop();
                _checkInSheetShowing = false;
              },
            );
          },
        );
      },
    ).then((_) => _checkInSheetShowing = false);
  }

  @override
  void dispose() {
    _alertSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentTab, children: _screens),
      bottomNavigationBar: PulseBottomNav(
        currentIndex: _currentTab,
        onTabSelected: (index) {
          setState(() => _currentTab = index);
        },
        onScanPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CameraMeasurementScreen(),
            ),
          );
        },
      ),
    );
  }
}
