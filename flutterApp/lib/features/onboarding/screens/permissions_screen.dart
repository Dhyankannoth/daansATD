import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/theme/pulse_typography.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../widgets/onboarding_info_icon.dart';

/// Screen 5 — Permissions: Explain permissions before requesting them.
/// Animation: Enable (staggered subtle activation Camera -> Notifications -> Health Data).
class PermissionsScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const PermissionsScreen({
    super.key,
    required this.onContinue,
  });

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;

  bool _cameraGranted = true;
  bool _notificationsGranted = true;
  bool _healthDataGranted = false;

  late final Animation<double> _camAnim;
  late final Animation<double> _notifAnim;
  late final Animation<double> _healthAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _camAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.00, 0.40, curve: Curves.easeOut),
    );

    _notifAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.30, 0.70, curve: Curves.easeOut),
    );

    _healthAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.60, 1.00, curve: Curves.easeOut),
    );

    _animCtrl.forward();
    _checkCameraAvailable();
  }

  Future<void> _checkCameraAvailable() async {
    try {
      final cameras = await availableCameras();
      if (mounted) {
        setState(() {
          _cameraGranted = cameras.isNotEmpty;
        });
      }
    } catch (_) {
      // Graceful fallback
    }
  }

  Future<void> _saveAndContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('perm_camera', _cameraGranted);
    await prefs.setBool('perm_notifications', _notificationsGranted);
    await prefs.setBool('perm_health_data', _healthDataGranted);

    widget.onContinue();
  }

  @override
  void dispose() {
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),

                    // Mascot: Bluey Permissions
                    Center(
                      child: Image.asset(
                        'assets/mascot/bluey_permision.png',
                        height: 180,
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Headline
                    Text(
                      'A few permissions are needed.',
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
                      'PulseGuard runs contactless PPG pulse extraction through your camera and provides timely notifications.',
                      style: PulseTypography.bodyRegular.copyWith(
                        fontSize: 14,
                        height: 1.5,
                        color: PulseColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // 1. Camera Permission Card (Stagger 1)
                    FadeTransition(
                      opacity: _camAnim,
                      child: _buildPermissionCard(
                        title: 'Camera',
                        description: 'Used for contactless vital measurements.',
                        icon: Icons.camera_alt_rounded,
                        iconBg: PulseColors.tintEmeraldBg,
                        iconColor: PulseColors.tintEmeraldIcon,
                        enabled: _cameraGranted,
                        isRequired: true,
                        onToggle: (val) => setState(() => _cameraGranted = val),
                        infoTooltip:
                            'Camera video stream is processed in-memory and immediately discarded. No video frames are ever recorded or stored.',
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 2. Notifications Permission Card (Stagger 2)
                    FadeTransition(
                      opacity: _notifAnim,
                      child: _buildPermissionCard(
                        title: 'Notifications',
                        description:
                            'Used to notify you when I notice something that needs your attention.',
                        icon: Icons.notifications_active_rounded,
                        iconBg: PulseColors.tintAmberBg,
                        iconColor: PulseColors.tintAmberIcon,
                        enabled: _notificationsGranted,
                        isRequired: true,
                        onToggle: (val) => setState(() => _notificationsGranted = val),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 3. Health Data Permission Card (Stagger 3)
                    FadeTransition(
                      opacity: _healthAnim,
                      child: _buildPermissionCard(
                        title: 'Health Data',
                        description:
                            'Optional. Used to incorporate compatible wearable or health data.',
                        icon: Icons.monitor_heart_rounded,
                        iconBg: PulseColors.tintBlueBg,
                        iconColor: PulseColors.tintBlueIcon,
                        enabled: _healthDataGranted,
                        isRequired: false,
                        onToggle: (val) => setState(() => _healthDataGranted = val),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Primary CTA
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: PrimaryButton(
                    label: 'Allow & Continue',
                    onPressed: _saveAndContinue,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required bool enabled,
    required bool isRequired,
    required ValueChanged<bool> onToggle,
    String? infoTooltip,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: PulseColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: enabled ? PulseColors.borderSubtle : PulseColors.divider,
          width: 1.2,
        ),
        boxShadow: const [PulseColors.cardShadow],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: PulseTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: PulseColors.textPrimary,
                      ),
                    ),
                    if (infoTooltip != null) ...[
                      const SizedBox(width: 6),
                      OnboardingInfoIcon(message: infoTooltip),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: PulseTypography.caption.copyWith(
                    fontSize: 12,
                    height: 1.4,
                    color: PulseColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: enabled,
            activeTrackColor: PulseColors.surfaceDark,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}
