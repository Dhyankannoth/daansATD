import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/theme/pulse_typography.dart';
import '../../../../engine/core/models/emergency_contact.dart';
import '../../../../services/pulse_engine_scope.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../widgets/onboarding_info_icon.dart';
import '../widgets/pulse_connecting_indicator.dart';

/// Screen 4 — Emergency Contact: Establish a person who can be contacted during escalation.
/// Animation: Connect (User ──⚡── Contact connecting animation).
class EmergencyContactScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const EmergencyContactScreen({
    super.key,
    required this.onContinue,
  });

  @override
  State<EmergencyContactScreen> createState() => _EmergencyContactScreenState();
}

class _EmergencyContactScreenState extends State<EmergencyContactScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _relationCtrl;
  String _userName = 'You';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: 'Jordan Taylor');
    _phoneCtrl = TextEditingController(text: '+1 (555) 019-2834');
    _relationCtrl = TextEditingController(text: 'Partner');

    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name');
    final contactName = prefs.getString('contact_name');
    final contactPhone = prefs.getString('contact_phone');
    final contactRelation = prefs.getString('contact_relation');

    if (mounted) {
      setState(() {
        if (name != null && name.isNotEmpty) _userName = name;
        if (contactName != null && contactName.isNotEmpty) _nameCtrl.text = contactName;
        if (contactPhone != null && contactPhone.isNotEmpty) _phoneCtrl.text = contactPhone;
        if (contactRelation != null && contactRelation.isNotEmpty) {
          _relationCtrl.text = contactRelation;
        }
      });
    }
  }

  Future<void> _saveAndContinue() async {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameCtrl.text.trim();
      final phone = _phoneCtrl.text.trim();
      final relation = _relationCtrl.text.trim();
      final engine = PulseEngineScope.engineOf(context);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('contact_name', name);
      await prefs.setString('contact_phone', phone);
      await prefs.setString('contact_relation', relation);

      // Save to engine
      await engine.setContact(
        EmergencyContact(name: name, phone: phone),
      );

      if (!mounted) return;
      widget.onContinue();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _relationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight > 50 ? constraints.maxHeight - 24 : 500,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // Headline
                      Text(
                        'Who should I contact if you need help?',
                        style: PulseTypography.headingLarge.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          height: 1.25,
                          color: PulseColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Supporting Text
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              'Add someone I can reach quickly if you become unresponsive or need assistance.',
                              style: PulseTypography.bodyRegular.copyWith(
                                fontSize: 14,
                                height: 1.5,
                                color: PulseColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const OnboardingInfoIcon(
                            message:
                                'Emergency contacts are strictly private. I never send unsolicited cellular texts or make unprompted network calls.',
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Animation: Connect (User -> Contact visual bridge)
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _nameCtrl,
                        builder: (context, value, _) {
                          return PulseConnectingIndicator(
                            userName: _userName,
                            contactName: value.text.trim().isNotEmpty
                                ? value.text.trim()
                                : 'Contact',
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Contact Name
                      Text(
                        'CONTACT NAME',
                        style: PulseTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: PulseColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        style: PulseTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: PulseColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. Jordan Taylor',
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            color: PulseColors.textSecondary,
                          ),
                          filled: true,
                          fillColor: PulseColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: PulseColors.borderSubtle),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: PulseColors.borderSubtle),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: PulseColors.surfaceDark,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter contact name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Phone Number
                      Text(
                        'PHONE NUMBER',
                        style: PulseTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: PulseColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        style: PulseTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: PulseColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. +1 555-0199',
                          prefixIcon: const Icon(
                            Icons.phone_outlined,
                            color: PulseColors.textSecondary,
                          ),
                          filled: true,
                          fillColor: PulseColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: PulseColors.borderSubtle),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: PulseColors.borderSubtle),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: PulseColors.surfaceDark,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter phone number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Relationship
                      Text(
                        'RELATIONSHIP',
                        style: PulseTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: PulseColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _relationCtrl,
                        textCapitalization: TextCapitalization.words,
                        style: PulseTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: PulseColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. Partner, Parent, Coach',
                          prefixIcon: const Icon(
                            Icons.favorite_outline_rounded,
                            color: PulseColors.textSecondary,
                          ),
                          filled: true,
                          fillColor: PulseColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: PulseColors.borderSubtle),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: PulseColors.borderSubtle),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: PulseColors.surfaceDark,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // CTA Button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: PrimaryButton(
                      label: 'Continue',
                      onPressed: _saveAndContinue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
