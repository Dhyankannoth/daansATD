import 'package:flutter/material.dart';
import '../../core/constants/pulse_constants.dart';
import '../../core/theme/pulse_colors.dart';
import '../../core/theme/pulse_typography.dart';
import '../../services/pulse_engine_scope.dart';
import '../../shared/widgets/buttons/secondary_button.dart';
import '../emergency/emergency_contacts_screen.dart';
import '../measurement/camera_measurement_screen.dart';

/// Screen L: Settings & Clinical Disclaimer Screen.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _userName = 'Alex Morgan';
  int _userAge = 28;

  @override
  Widget build(BuildContext context) {
    final engine = PulseEngineScope.engineOf(context);

    return Scaffold(
      backgroundColor: PulseColors.background,
      appBar: AppBar(
        backgroundColor: PulseColors.surface,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Settings & Safety',
          style: PulseTypography.headingMedium,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Section
              Text(
                'USER PROFILE',
                style: PulseTypography.caption.copyWith(
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PulseColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: PulseColors.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: PulseColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: PulseColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName,
                            style: PulseTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Age $_userAge • Solo Outdoor Athlete',
                            style: PulseTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _editProfileDialog(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Emergency Configuration
              Text(
                'EMERGENCY CONFIGURATION',
                style: PulseTypography.caption.copyWith(
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),

              ListTile(
                tileColor: PulseColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: PulseColors.divider),
                ),
                leading: const Icon(
                  Icons.contact_phone_rounded,
                  color: PulseColors.primary,
                ),
                title: const Text(
                  'Manage Emergency Contact',
                  style: PulseTypography.bodyMedium,
                ),
                subtitle: Text(
                  engine.contact != null
                      ? '${engine.contact!.name} (${engine.contact!.phone})'
                      : 'Not configured yet',
                  style: PulseTypography.caption,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const EmergencyContactsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),

              ListTile(
                tileColor: PulseColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: PulseColors.divider),
                ),
                leading: const Icon(
                  Icons.timer_outlined,
                  color: PulseColors.primary,
                ),
                title: const Text(
                  'Check-In Watchdog Countdown',
                  style: PulseTypography.bodyMedium,
                ),
                subtitle: const Text(
                  '30 seconds (Apple/Garmin incident protocol)',
                  style: PulseTypography.caption,
                ),
              ),

              const SizedBox(height: 24),

              // Sensor Diagnostics & Permissions
              Text(
                'SENSOR PERMISSIONS & DIAGNOSTICS',
                style: PulseTypography.caption.copyWith(
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PulseColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: PulseColors.divider),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.camera_alt_outlined,
                          color: PulseColors.riskNormal,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Camera & LED Flash Sensor',
                            style: PulseTypography.bodyMedium,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: PulseColors.riskNormalBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Active',
                            style: PulseTypography.caption.copyWith(
                              color: PulseColors.riskNormal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Icon(
                          Icons.sensors_rounded,
                          color: PulseColors.riskNormal,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Accelerometer / Motion Sensor',
                            style: PulseTypography.bodyMedium,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: PulseColors.riskNormalBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Active',
                            style: PulseTypography.caption.copyWith(
                              color: PulseColors.riskNormal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Demonstration Traces Section
              Text(
                'DEMO SCENARIOS & REPLAY TRACES',
                style: PulseTypography.caption.copyWith(
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),

              SecondaryButton(
                label: 'Replay: Allergic Reaction Trace',
                icon: Icons.play_circle_outline_rounded,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CameraMeasurementScreen(
                        replayAssetPath: 'assets/traces/reaction.json',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),

              SecondaryButton(
                label: 'Replay: Normal Physical Trace',
                icon: Icons.play_circle_outline_rounded,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CameraMeasurementScreen(
                        replayAssetPath: 'assets/traces/normal.json',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),

              SecondaryButton(
                label: 'Replay: Signal Loss Watchdog Trace',
                icon: Icons.play_circle_outline_rounded,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CameraMeasurementScreen(
                        replayAssetPath: 'assets/traces/signal_loss.json',
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),

              // Clinical Disclaimer & Regulatory Notice
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: PulseColors.surfaceDim,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: PulseColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.gavel_rounded,
                          size: 20,
                          color: PulseColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'CLINICAL & REGULATORY NOTICE',
                          style: TextStyle(
                            fontFamily: PulseTypography.fontFamily,
                            fontFamilyFallback: PulseTypography.fontFamilyFallback,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: PulseColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      PulseConstants.clinicalDisclaimer,
                      style: PulseTypography.caption.copyWith(
                        color: PulseColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _editProfileDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: _userName);
    final ageCtrl = TextEditingController(text: '$_userAge');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ageCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _userName = nameCtrl.text.trim();
                _userAge = int.tryParse(ageCtrl.text) ?? _userAge;
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
