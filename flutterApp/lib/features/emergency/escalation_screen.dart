import 'package:flutter/material.dart';
import '../../core/constants/pulse_constants.dart';
import '../../core/theme/pulse_colors.dart';
import '../../core/theme/pulse_typography.dart';
import '../../engine/core/models/escalation_payload.dart';
import '../../services/pulse_engine_scope.dart';
import '../../shared/widgets/buttons/emergency_button.dart';
import '../../shared/widgets/buttons/secondary_button.dart';
import '../../shared/widgets/cards/vital_metric_tile.dart';

/// Screen G: Escalation Screen (Emergency State).
///
/// Stripped of unnecessary navigation and complex charts to prioritize immediate
/// emergency dialing, contact dispatch, and paramedic vitals handover.
class EscalationScreen extends StatelessWidget {
  final EscalationPayload? payload;

  const EscalationScreen({super.key, this.payload});

  @override
  Widget build(BuildContext context) {
    final engine = PulseEngineScope.engineOf(context);
    final contact = payload?.contact ?? engine.contact;

    return Scaffold(
      backgroundColor: PulseColors.background,
      appBar: AppBar(
        backgroundColor: PulseColors.emergencyRed,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              'EMERGENCY ALERT',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Primary Emergency Headline
              Text(
                PulseConstants.escalationHeadline,
                style: PulseTypography.headingLarge.copyWith(
                  color: PulseColors.emergencyRed,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                PulseConstants.escalationSubtitle,
                style: PulseTypography.bodyRegular.copyWith(
                  color: PulseColors.textPrimary,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              // Advisory Card for Prescribed Emergency Medication
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PulseColors.riskCriticalBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: PulseColors.riskCritical.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.medication_liquid_rounded,
                      color: PulseColors.emergencyRed,
                      size: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emergency Medication Guidance',
                            style: PulseTypography.bodyMedium.copyWith(
                              color: PulseColors.emergencyRed,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            PulseConstants.escalationMedicationNotice,
                            style: PulseTypography.bodyRegular.copyWith(
                              color: PulseColors.textPrimary,
                              fontSize: 14,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Thumb-Zone Emergency Action 1: Call 911 / Emergency Services
              EmergencyButton(
                label: 'CALL EMERGENCY (911 / 112)',
                subtitle: 'Direct one-tap phone call trigger',
                icon: Icons.phone_in_talk_rounded,
                isCritical: true,
                onPressed: () {
                  _showCallDialog(context, '911');
                },
              ),

              const SizedBox(height: 14),

              // Emergency Action 2: Notify Emergency Contact
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [PulseColors.cardShadow],
                ),
                child: Material(
                  color: PulseColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      _showSimulatedContactAlert(
                        context,
                        contact?.name ?? 'Emergency Contact',
                        contact?.phone ?? '911',
                      );
                    },
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 64),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: PulseColors.divider,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: PulseColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.send_rounded,
                              color: PulseColors.primaryDark,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contact != null
                                      ? 'NOTIFY ${contact.name.toUpperCase()}'
                                      : 'NOTIFY EMERGENCY CONTACT',
                                  style: PulseTypography.button.copyWith(
                                    color: PulseColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  contact != null
                                      ? '${contact.phone} • Dispatches simulated payload'
                                      : 'Configure in Emergency Contacts tab',
                                  style: PulseTypography.caption.copyWith(
                                    color: PulseColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: PulseColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Emergency Summary for Paramedics
              Text(
                'VITALS SNAPSHOT FOR PARAMEDICS',
                style: PulseTypography.caption.copyWith(
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w700,
                  color: PulseColors.textPrimary,
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
                    VitalMetricTile(
                      icon: Icons.favorite_rounded,
                      title: 'Heart Rate at Escalation',
                      value: payload?.vitalsSnapshot.hr != null
                          ? payload!.vitalsSnapshot.hr!.toStringAsFixed(0)
                          : '124',
                      unit: 'BPM',
                      comparison: 'Tachycardia / Baseline shift',
                      comparisonColor: PulseColors.riskCritical,
                    ),
                    const SizedBox(height: 8),
                    VitalMetricTile(
                      icon: Icons.stacked_line_chart_rounded,
                      title: 'HRV (RMSSD)',
                      value: payload?.vitalsSnapshot.hrv != null
                          ? payload!.vitalsSnapshot.hrv!.toStringAsFixed(0)
                          : '18',
                      unit: 'ms',
                      comparison: 'Sympathetic hyperactivity',
                    ),
                    const SizedBox(height: 8),
                    VitalMetricTile(
                      icon: Icons.air_rounded,
                      title: 'Respiration Rate',
                      value: payload?.vitalsSnapshot.rr != null
                          ? payload!.vitalsSnapshot.rr!.toStringAsFixed(0)
                          : '24',
                      unit: 'BrPM',
                      comparison: 'Tachypnea / Airway effort',
                      comparisonColor: PulseColors.riskCritical,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Resolution / Cancel Action
              SecondaryButton(
                label: 'I Am Safe — Cancel Alert',
                icon: Icons.check_circle_outline_rounded,
                onPressed: () {
                  engine.cancelEscalation();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showCallDialog(BuildContext context, String number) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emergency Dialing'),
        content: Text(
          'Connecting to emergency dispatch ($number)...\n\nStay on the line, speak calmly, and provide your current location to the dispatcher.',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PulseColors.emergencyRed,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Dismiss Call Screen'),
          ),
        ],
      ),
    );
  }

  void _showSimulatedContactAlert(
    BuildContext context,
    String name,
    String phone,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Contact Dispatched (Simulated)'),
        content: Text(
          'Emergency notification payload prepared for $name ($phone).\n\nIncludes timestamp, recent vital metrics, and indication of physical distress.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
