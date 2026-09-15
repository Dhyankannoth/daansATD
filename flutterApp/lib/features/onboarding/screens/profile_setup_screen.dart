import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/theme/pulse_typography.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../widgets/onboarding_info_icon.dart';

/// Screen 3 — Basic Profile: Collect only necessary personalization info.
/// Animation: Slide (smooth staggered slide transition focusing on usability).
class ProfileSetupScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const ProfileSetupScreen({
    super.key,
    required this.onContinue,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;

  late final AnimationController _animCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Alex Morgan');
    _ageController = TextEditingController(text: '28');

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
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('user_name');
    final savedAge = prefs.getInt('user_age');
    if (mounted) {
      if (savedName != null && savedName.isNotEmpty) {
        _nameController.text = savedName;
      }
      if (savedAge != null) {
        _ageController.text = savedAge.toString();
      }
    }
  }

  Future<void> _saveAndContinue() async {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text.trim();
      final age = int.tryParse(_ageController.text.trim()) ?? 28;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name);
      await prefs.setInt('user_age', age);

      widget.onContinue();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
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

                          // Mascot: Bluey Thinking
                          Center(
                            child: Image.asset(
                              'assets/mascot/bluey_thinking.png',
                              height: 180,
                              fit: BoxFit.contain,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Headline
                          Text(
                            "Let's get to know you.",
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
                          Text(
                            "A few basic details help me personalize your monitoring experience.",
                            style: PulseTypography.bodyRegular.copyWith(
                              fontSize: 14,
                              height: 1.5,
                              color: PulseColors.textSecondary,
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Name Input Card
                          Text(
                            'YOUR NAME',
                            style: PulseTypography.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: PulseColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            style: PulseTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: PulseColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'e.g. Alex Morgan',
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
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Age / Date of Birth Card
                          Row(
                            children: [
                              Text(
                                'AGE',
                                style: PulseTypography.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: PulseColors.textTertiary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const OnboardingInfoIcon(
                                message:
                                    'Age benchmarks help calibrate population baseline fallbacks before your personal profile completes training.',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            style: PulseTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: PulseColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'e.g. 28',
                              suffixText: 'years old',
                              suffixStyle: PulseTypography.caption.copyWith(
                                color: PulseColors.textTertiary,
                              ),
                              prefixIcon: const Icon(
                                Icons.cake_outlined,
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
                              final num = int.tryParse(val ?? '');
                              if (num == null || num < 5 || num > 120) {
                                return 'Please enter a valid age (5 - 120)';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
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
