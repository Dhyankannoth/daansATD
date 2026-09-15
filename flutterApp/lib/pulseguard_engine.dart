/// Public barrel for the PulseGuard logic engine. This is the only import
/// the UI needs — everything else under `lib/engine/` is an implementation
/// detail. See `docs/ENGINE_API.md` for the integration guide.
library;

export 'engine/api/engine_snapshot.dart';
export 'engine/api/engine_strings.dart';
export 'engine/api/events.dart';
export 'engine/api/pulseguard_api.dart';
export 'engine/core/models/activity_state.dart';
export 'engine/core/models/baseline.dart';
export 'engine/core/models/deviation_flag.dart';
export 'engine/core/models/emergency_contact.dart';
export 'engine/core/models/escalation_payload.dart';
export 'engine/core/models/feature_row.dart';
export 'engine/core/models/vitals_reading.dart';
export 'engine/pulseguard_engine.dart';
