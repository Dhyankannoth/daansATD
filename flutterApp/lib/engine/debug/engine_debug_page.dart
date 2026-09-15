import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../pulseguard_engine.dart';
import '../api/engine_snapshot.dart';

/// Plain-text dev harness for exercising [PulseGuardEngine] before the real
/// UI lands. NOT product UI — push it temporarily (see docs/ENGINE_API.md)
/// to test the engine on a device.
class EngineDebugPage extends StatefulWidget {
  const EngineDebugPage({super.key, required this.engine});

  final PulseGuardEngine engine;

  @override
  State<EngineDebugPage> createState() => _EngineDebugPageState();
}

class _EngineDebugPageState extends State<EngineDebugPage> {
  final _log = <String>[];
  bool _initialized = false;

  PulseGuardEngine get _engine => widget.engine;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _engine.alerts.listen((e) => _appendLog('alert: ${e.kind.name}'));
    _engine.scanFinished.listen((s) => _appendLog('scanFinished: ${s.endReason.name}'));
    await _engine.initialize();
    setState(() => _initialized = true);
  }

  void _appendLog(String line) {
    setState(() {
      _log.insert(0, line);
      if (_log.length > 50) _log.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PulseGuard Engine Debug')),
      body: !_initialized
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder<EngineSnapshot>(
              valueListenable: _engine.snapshot,
              builder: (context, snapshot, _) => _buildBody(snapshot),
            ),
    );
  }

  Widget _buildBody(EngineSnapshot snapshot) {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Text(_dump(snapshot), style: const TextStyle(fontFamily: 'monospace')),
          ),
        ),
        const Divider(),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(onPressed: () => _engine.startScan(), child: const Text('Start scan')),
            ElevatedButton(onPressed: () async => _appendLog('summary: ${await _engine.endScan()}'), child: const Text('End scan')),
            ElevatedButton(onPressed: () => _engine.startCalibration(), child: const Text('Calibrate')),
            ElevatedButton(
              onPressed: () => _engine.startReplay('assets/traces/reaction.json', speed: 1.0),
              child: const Text('Replay reaction'),
            ),
            ElevatedButton(
              onPressed: () => _engine.respondCheckIn(ok: true),
              child: const Text("I'm fine"),
            ),
            ElevatedButton(
              onPressed: () => _engine.respondCheckIn(ok: false),
              child: const Text('I need help'),
            ),
          ],
        ),
        const Divider(),
        Expanded(
          flex: 2,
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: _log.map((l) => Text(l, style: const TextStyle(fontSize: 12))).toList(),
          ),
        ),
        if (_engine.cameraController != null)
          SizedBox(
            height: 120,
            child: CameraPreview(_engine.cameraController!),
          ),
      ],
    );
  }

  String _dump(EngineSnapshot s) {
    final v = s.latestVitals;
    return [
      'phase: ${s.phase.name}',
      'elapsed: ${s.elapsed}',
      'message: ${s.message}',
      'hasBaseline: ${s.hasBaseline}',
      'alertState: ${s.alertState.name}',
      'checkInRemaining: ${s.checkInRemaining}',
      'risk: ${s.risk?.level.name} — ${s.risk?.statusText}',
      'hr: ${v?.hr} hrv: ${v?.hrv} rr: ${v?.rr} quality: ${v?.quality}',
      'fingerPresent: ${v?.fingerPresent}',
      'oxTrend: ${s.oxTrendPct}',
      'error: ${s.error}',
    ].join('\n');
  }
}
