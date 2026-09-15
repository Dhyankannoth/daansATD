import 'package:flutter/material.dart';
import '../data/repositories/history_repository.dart';
import '../pulseguard_engine.dart';

/// App-wide dependency scope providing [PulseGuardApi] and [HistoryRepository].
class PulseEngineScope extends InheritedWidget {
  final PulseGuardApi engine;
  final HistoryRepository historyRepository;

  const PulseEngineScope({
    super.key,
    required this.engine,
    required this.historyRepository,
    required super.child,
  });

  static PulseEngineScope of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<PulseEngineScope>();
    assert(scope != null, 'No PulseEngineScope found in context');
    return scope!;
  }

  static PulseGuardApi engineOf(BuildContext context) => of(context).engine;
  static HistoryRepository historyOf(BuildContext context) =>
      of(context).historyRepository;

  @override
  bool updateShouldNotify(PulseEngineScope oldWidget) {
    return engine != oldWidget.engine ||
        historyRepository != oldWidget.historyRepository;
  }
}
