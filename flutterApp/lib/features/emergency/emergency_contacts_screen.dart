import 'package:flutter/material.dart';
import '../../core/theme/pulse_colors.dart';
import '../../core/theme/pulse_typography.dart';
import '../../engine/core/models/emergency_contact.dart';
import '../../services/pulse_engine_scope.dart';
import '../../shared/widgets/buttons/primary_button.dart';
import '../../shared/widgets/buttons/secondary_button.dart';
import '../../shared/widgets/mascot/bluey_companion.dart';

/// Screen K: Emergency Contacts Screen.
class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _relationController;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _relationController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final engine = PulseEngineScope.engineOf(context);
      final contact = engine.contact;
      if (contact != null) {
        setState(() {
          _nameController.text = contact.name;
          _phoneController.text = contact.phone;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;

    final engine = PulseEngineScope.engineOf(context);
    final contact = EmergencyContact(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    await engine.setContact(contact);
    if (!mounted) return;

    setState(() => _saved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: PulseColors.riskNormal,
        content: Text('Emergency contact saved successfully.'),
      ),
    );
  }

  void _simulateAlertPayload() {
    final name = _nameController.text.trim().isEmpty
        ? 'Alex Morgan'
        : _nameController.text.trim();
    final phone = _phoneController.text.trim().isEmpty
        ? '+1 (555) 0199'
        : _phoneController.text.trim();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Simulated Emergency Payload'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'During an actual escalation, the application prepares this simulated emergency notification payload:',
              style: PulseTypography.bodyRegular.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PulseColors.surfaceDim,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: PulseColors.divider),
              ),
              child: Text(
                'EMERGENCY ALERT (SIMULATED)\n'
                'Target: $name ($phone)\n'
                'Method: Simulated local dispatch\n'
                'Timestamp: ${DateTime.now().toIso8601String()}\n'
                'Reason: Multi-system vital deviation\n'
                'Vitals: HR 128 BPM (+42 BPM), RR 26 BrPM, HRV 18 ms\n'
                'Status: Unresponsive to 30s check-in',
                style: PulseTypography.monoSmall,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Notice: As specified in ENGINE_API.md, PulseGuard never transmits unauthorized cellular SMS or makes unprompted network calls.',
              style: PulseTypography.caption.copyWith(
                color: PulseColors.textTertiary,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close Preview'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PulseColors.background,
      appBar: AppBar(
        backgroundColor: PulseColors.surface,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Emergency Contact',
          style: PulseTypography.headingMedium,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BlueyCompanion(
                  pose: BlueyPose.calm,
                  layoutMode: BlueyLayoutMode.speechCard,
                  title: 'Emergency Contact',
                  message:
                      'Adding a contact helps me reach someone you trust if you ever need assistance.',
                  infoTooltip:
                      'If multi-system physiological deviations persist and you indicate feeling unwell or don\'t respond to the 30-second check-in, PulseGuard prepares an immediate escalation alert with your vital stats.',
                  mascotHeight: 68,
                ),

                const SizedBox(height: 24),

                Text(
                  'CONTACT DETAILS',
                  style: PulseTypography.caption.copyWith(
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                // Name Input
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Full Name',
                    hintText: 'e.g. Sarah Jenkins',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter contact name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Phone Input
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Phone Number',
                    hintText: 'e.g. +1 555-0199',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Relationship Input
                TextFormField(
                  controller: _relationController,
                  decoration: const InputDecoration(
                    labelText: 'Relationship (Optional)',
                    hintText: 'e.g. Partner, Parent, Coach',
                    prefixIcon: Icon(Icons.favorite_outline_rounded),
                  ),
                ),

                const SizedBox(height: 28),

                PrimaryButton(
                  label: _saved ? 'Contact Saved' : 'Save Emergency Contact',
                  icon: _saved
                      ? Icons.check_circle_outline_rounded
                      : Icons.save_rounded,
                  backgroundColor: _saved ? PulseColors.riskNormal : null,
                  onPressed: _saveContact,
                ),

                const SizedBox(height: 14),

                SecondaryButton(
                  label: 'Test Emergency Alert (Simulation)',
                  icon: Icons.notifications_active_outlined,
                  onPressed: _simulateAlertPayload,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
