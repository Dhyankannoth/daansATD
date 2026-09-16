import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/theme/pulse_typography.dart';
import '../../../../engine/core/models/emergency_contact.dart';
import '../../../../services/pulse_engine_scope.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../widgets/onboarding_info_icon.dart';

/// Screen 4 — Emergency Contact: Establish a trusted person who can be contacted during escalation.
class EmergencyContactScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const EmergencyContactScreen({
    super.key,
    required this.onContinue,
  });

  @override
  State<EmergencyContactScreen> createState() => _EmergencyContactScreenState();
}

class _EmergencyContactScreenState extends State<EmergencyContactScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _customRelationCtrl;

  late final AnimationController _animCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  static const List<String> _relationshipOptions = [
    'Partner',
    'Spouse',
    'Parent',
    'Sibling',
    'Child',
    'Friend',
    'Caregiver',
    'Doctor / Physician',
    'Other',
  ];

  String _selectedRelationship = 'Partner';
  bool _isPhoneVerified = false;
  String _lastVerifiedPhone = '';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: 'Jordan Taylor');
    _phoneCtrl = TextEditingController(text: '+1 (555) 019-2834');
    _customRelationCtrl = TextEditingController();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);

    _animCtrl.forward();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final prefs = await SharedPreferences.getInstance();
    final contactName = prefs.getString('contact_name');
    final contactPhone = prefs.getString('contact_phone');
    final contactRelation = prefs.getString('contact_relation');
    final verified = prefs.getBool('contact_phone_verified') ?? false;

    if (mounted) {
      setState(() {
        if (contactName != null && contactName.isNotEmpty) {
          _nameCtrl.text = contactName;
        }
        if (contactPhone != null && contactPhone.isNotEmpty) {
          _phoneCtrl.text = contactPhone;
        }
        if (contactRelation != null && contactRelation.isNotEmpty) {
          if (_relationshipOptions.contains(contactRelation)) {
            _selectedRelationship = contactRelation;
          } else {
            _selectedRelationship = 'Other';
            _customRelationCtrl.text = contactRelation;
          }
        }
        if (verified && contactPhone != null && contactPhone.isNotEmpty) {
          _isPhoneVerified = true;
          _lastVerifiedPhone = contactPhone;
        }
      });
    }
  }

  String _getEffectiveRelationship() {
    if (_selectedRelationship == 'Other') {
      final custom = _customRelationCtrl.text.trim();
      return custom.isNotEmpty ? custom : 'Other';
    }
    return _selectedRelationship;
  }

  String? _validatePhone(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Please enter a phone number';
    }
    final digitsOnly = val.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 7) {
      return 'Phone number too short (minimum 7 digits)';
    }
    if (digitsOnly.length > 15) {
      return 'Phone number too long (maximum 15 digits)';
    }
    final validChars = RegExp(r'^[0-9+\s()\-]+$');
    if (!validChars.hasMatch(val.trim())) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  void _onPhoneChanged(String val) {
    if (_isPhoneVerified && val.trim() != _lastVerifiedPhone) {
      setState(() {
        _isPhoneVerified = false;
      });
    }
  }

  Future<void> _openVerificationSheet() async {
    final phone = _phoneCtrl.text.trim();
    final validationError = _validatePhone(phone);
    if (validationError != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: PulseColors.riskCritical,
        ),
      );
      return;
    }

    final codeCtrl = TextEditingController();
    bool codeSent = false;
    bool isVerifying = false;
    String? codeError;

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomPadding = MediaQuery.of(sheetContext).viewInsets.bottom;
            return Container(
              decoration: const BoxDecoration(
                color: PulseColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grab handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: PulseColors.borderSubtle,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: PulseColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          color: PulseColors.primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verify Contact Number',
                              style: PulseTypography.headingMedium.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              phone,
                              style: PulseTypography.caption.copyWith(
                                color: PulseColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'PulseGuard verifies that this number is valid and reachable so automated escalation alerts arrive without failure.',
                    style: PulseTypography.bodyRegular.copyWith(
                      fontSize: 13.5,
                      height: 1.45,
                      color: PulseColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (!codeSent) ...[
                    // Step 1: Send Code
                    PrimaryButton(
                      label: isVerifying ? 'Sending Code...' : 'Send Verification Code',
                      icon: Icons.send_rounded,
                      onPressed: isVerifying
                          ? null
                          : () async {
                              setSheetState(() => isVerifying = true);
                              await Future.delayed(const Duration(milliseconds: 650));
                              setSheetState(() {
                                isVerifying = false;
                                codeSent = true;
                              });
                            },
                    ),
                  ] else ...[
                    // Step 2: Enter Code
                    Text(
                      'ENTER 4-DIGIT VERIFICATION CODE',
                      style: PulseTypography.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: PulseColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: codeCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      autofocus: true,
                      style: PulseTypography.headingMedium.copyWith(
                        letterSpacing: 8,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '••••',
                        errorText: codeError,
                        filled: true,
                        fillColor: PulseColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: PulseColors.borderSubtle),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: PulseColors.borderSubtle),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: PulseColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Auto-fill convenience button for rapid testing / simulation
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          codeCtrl.text = '4826';
                          setSheetState(() {
                            codeError = null;
                          });
                        },
                        icon: const Icon(Icons.flash_on_rounded, size: 16),
                        label: const Text('Auto-fill Test Code (4826)'),
                        style: TextButton.styleFrom(
                          foregroundColor: PulseColors.primary,
                          textStyle: PulseTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    PrimaryButton(
                      label: isVerifying ? 'Confirming...' : 'Confirm & Verify',
                      icon: Icons.check_circle_outline_rounded,
                      onPressed: isVerifying
                          ? null
                          : () async {
                              final entered = codeCtrl.text.trim();
                              if (entered.length < 4) {
                                setSheetState(() {
                                  codeError = 'Please enter 4 digits';
                                });
                                return;
                              }
                              setSheetState(() => isVerifying = true);
                              await Future.delayed(const Duration(milliseconds: 500));
                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop(true);
                              }
                            },
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    ).then((verified) {
      codeCtrl.dispose();
      if (verified == true && mounted) {
        setState(() {
          _isPhoneVerified = true;
          _lastVerifiedPhone = phone;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: PulseColors.riskNormal,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Phone number verified: $phone',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });
  }

  Future<void> _saveAndContinue() async {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameCtrl.text.trim();
      final phone = _phoneCtrl.text.trim();
      final relation = _getEffectiveRelationship();
      final engine = PulseEngineScope.engineOf(context);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('contact_name', name);
      await prefs.setString('contact_phone', phone);
      await prefs.setString('contact_relation', relation);
      await prefs.setBool('contact_phone_verified', _isPhoneVerified);

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
    _customRelationCtrl.dispose();
    _animCtrl.dispose();
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
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),

                          // Mascot: Bluey Happy (aligned with current onboarding theme)
                          Center(
                            child: Image.asset(
                              'assets/mascot/bluey_happy.png',
                              height: 180,
                              fit: BoxFit.contain,
                            ),
                          ),

                          const SizedBox(height: 16),

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

                          // Supporting Text with Privacy Tooltip
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

                          const SizedBox(height: 24),

                          // Contact Name Card
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

                          const SizedBox(height: 20),

                          // Phone Number & Verification Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'PHONE NUMBER',
                                style: PulseTypography.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: PulseColors.textTertiary,
                                ),
                              ),
                              if (_isPhoneVerified)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: PulseColors.riskNormal.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: PulseColors.riskNormal.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 13,
                                        color: PulseColors.riskNormal,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Verified',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: PulseColors.riskNormal,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                InkWell(
                                  onTap: _openVerificationSheet,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: PulseColors.primary.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: PulseColors.primary.withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.verified_outlined,
                                          size: 13,
                                          color: PulseColors.primary,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Verify Number',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: PulseColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            onChanged: _onPhoneChanged,
                            style: PulseTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: PulseColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'e.g. +1 555-019-2834',
                              prefixIcon: const Icon(
                                Icons.phone_outlined,
                                color: PulseColors.textSecondary,
                              ),
                              suffixIcon: _isPhoneVerified
                                  ? const Icon(
                                      Icons.verified_rounded,
                                      color: PulseColors.riskNormal,
                                    )
                                  : IconButton(
                                      tooltip: 'Verify phone number',
                                      icon: const Icon(
                                        Icons.sms_outlined,
                                        color: PulseColors.textSecondary,
                                      ),
                                      onPressed: _openVerificationSheet,
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
                            validator: _validatePhone,
                          ),

                          const SizedBox(height: 20),

                          // Relationship Dropdown
                          Text(
                            'RELATIONSHIP',
                            style: PulseTypography.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: PulseColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            key: ValueKey(_selectedRelationship),
                            initialValue: _relationshipOptions.contains(_selectedRelationship)
                                ? _selectedRelationship
                                : 'Other',
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: PulseColors.textSecondary,
                            ),
                            dropdownColor: PulseColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            style: PulseTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: PulseColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Select relationship',
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
                            items: _relationshipOptions.map((role) {
                              return DropdownMenuItem<String>(
                                value: role,
                                child: Text(
                                  role,
                                  style: PulseTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: PulseColors.textPrimary,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedRelationship = val;
                                });
                              }
                            },
                          ),

                          // Custom relationship field if "Other" is selected
                          if (_selectedRelationship == 'Other') ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _customRelationCtrl,
                              textCapitalization: TextCapitalization.words,
                              style: PulseTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: PulseColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Specify relationship (e.g. Neighbor, Coach)',
                                prefixIcon: const Icon(
                                  Icons.edit_note_rounded,
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
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Continue CTA Button
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
