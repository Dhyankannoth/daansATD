import 'package:flutter/material.dart';
import '../../../core/theme/pulse_colors.dart';
import '../../../core/theme/pulse_typography.dart';
import '../indicators/pulse_info_icon.dart';

/// Poses representing Bluey's behavioral states throughout the application.
enum BlueyPose {
  welcome,
  calm,
  checking,
  scanning,
  thinking,
  excited,
  attentive,
  empty,
}

extension BlueyPoseAsset on BlueyPose {
  String get assetPath => switch (this) {
        BlueyPose.welcome => 'assets/mascot/bluey_welcome.png',
        BlueyPose.calm => 'assets/mascot/bluey_happy.png',
        BlueyPose.checking => 'assets/mascot/bluey_checking.png',
        BlueyPose.scanning => 'assets/mascot/bluey_scanning.png',
        BlueyPose.thinking => 'assets/mascot/bluey_thinking.png',
        BlueyPose.excited => 'assets/mascot/bluey_excited.png',
        BlueyPose.attentive => 'assets/mascot/bluey_error.png',
        BlueyPose.empty => 'assets/mascot/bluey_emptyState.png',
      };
}

/// Visual layout presentation for Bluey.
enum BlueyLayoutMode {
  /// Direct standalone mascot graphic.
  standalone,

  /// Side-by-side companion speech card with speech bubble styling.
  speechCard,

  /// Prominent top greeting header with name and subtitle.
  heroGreeting,

  /// Compact inline row for headers or cards.
  compactRow,
}

/// Centralized companion component that presents Bluey as an intelligent,
/// supportive, and empathetic product companion.
class BlueyCompanion extends StatefulWidget {
  final BlueyPose pose;
  final BlueyLayoutMode layoutMode;
  final String? title;
  final String? message;
  final String? infoTooltip;
  final double? mascotHeight;
  final Widget? action;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool animate;

  const BlueyCompanion({
    super.key,
    this.pose = BlueyPose.calm,
    this.layoutMode = BlueyLayoutMode.speechCard,
    this.title,
    this.message,
    this.infoTooltip,
    this.mascotHeight,
    this.action,
    this.backgroundColor,
    this.borderColor,
    this.animate = false,
  });

  /// Factory constructor for a hero greeting card at the top of a screen.
  factory BlueyCompanion.heroGreeting({
    Key? key,
    required String userName,
    String subtitle = "I'm keeping an eye on your vital signals.",
    BlueyPose pose = BlueyPose.welcome,
    String? infoTooltip,
    Widget? trailing,
    double mascotHeight = 100,
  }) {
    return BlueyCompanion(
      key: key,
      pose: pose,
      layoutMode: BlueyLayoutMode.heroGreeting,
      title: 'Hi, $userName',
      message: subtitle,
      infoTooltip: infoTooltip,
      mascotHeight: mascotHeight,
      action: trailing,
      animate: true,
    );
  }

  /// Factory constructor for monitoring status announcement.
  factory BlueyCompanion.status({
    Key? key,
    required String statusTitle,
    required String statusMessage,
    required BlueyPose pose,
    String? infoTooltip,
    Color? backgroundColor,
    Color? borderColor,
    double mascotHeight = 76,
    Widget? action,
  }) {
    return BlueyCompanion(
      key: key,
      pose: pose,
      layoutMode: BlueyLayoutMode.speechCard,
      title: statusTitle,
      message: statusMessage,
      infoTooltip: infoTooltip,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      mascotHeight: mascotHeight,
      action: action,
    );
  }

  /// Factory constructor for standalone mascot asset.
  factory BlueyCompanion.standalone({
    Key? key,
    required BlueyPose pose,
    double height = 140,
    bool animate = false,
  }) {
    return BlueyCompanion(
      key: key,
      pose: pose,
      layoutMode: BlueyLayoutMode.standalone,
      mascotHeight: height,
      animate: animate,
    );
  }

  @override
  State<BlueyCompanion> createState() => _BlueyCompanionState();
}

class _BlueyCompanionState extends State<BlueyCompanion> {
  Widget _buildMascotImage({double? height}) {
    return Image.asset(
      widget.pose.assetPath,
      height: height ?? widget.mascotHeight ?? 80,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.layoutMode) {
      BlueyLayoutMode.standalone => _buildMascotImage(),
      BlueyLayoutMode.heroGreeting => _buildHeroGreeting(context),
      BlueyLayoutMode.speechCard => _buildSpeechCard(context),
      BlueyLayoutMode.compactRow => _buildCompactRow(context),
    };
  }

  Widget _buildHeroGreeting(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? PulseColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: widget.borderColor ?? PulseColors.borderSubtle,
          width: 1.0,
        ),
        boxShadow: const [PulseColors.cardShadow],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildMascotImage(height: widget.mascotHeight ?? 92),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.title != null) ...[
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.title!,
                          style: PulseTypography.headingMedium.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: PulseColors.textPrimary,
                          ),
                        ),
                      ),
                      if (widget.infoTooltip != null) ...[
                        const SizedBox(width: 4),
                        PulseInfoIcon(message: widget.infoTooltip!),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                ],
                if (widget.message != null) ...[
                  Text(
                    widget.message!,
                    style: PulseTypography.bodyRegular.copyWith(
                      fontSize: 13,
                      height: 1.35,
                      color: PulseColors.textSecondary,
                    ),
                  ),
                ],
                if (widget.action != null) ...[
                  const SizedBox(height: 6),
                  widget.action!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? PulseColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.borderColor ?? PulseColors.divider,
          width: 1.0,
        ),
        boxShadow: const [PulseColors.cardShadow],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildMascotImage(height: widget.mascotHeight ?? 74),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.title != null) ...[
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.title!,
                          style: PulseTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: PulseColors.textPrimary,
                          ),
                        ),
                      ),
                      if (widget.infoTooltip != null) ...[
                        const SizedBox(width: 4),
                        PulseInfoIcon(message: widget.infoTooltip!),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                ],
                if (widget.message != null) ...[
                  Text(
                    widget.message!,
                    style: PulseTypography.caption.copyWith(
                      fontSize: 12,
                      height: 1.35,
                      color: PulseColors.textSecondary,
                    ),
                  ),
                ],
                if (widget.action != null) ...[
                  const SizedBox(height: 6),
                  widget.action!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildMascotImage(height: widget.mascotHeight ?? 48),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.title != null) ...[
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.title!,
                        style: PulseTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: PulseColors.textPrimary,
                        ),
                      ),
                    ),
                    if (widget.infoTooltip != null) ...[
                      const SizedBox(width: 4),
                      PulseInfoIcon(message: widget.infoTooltip!, size: 14),
                    ],
                  ],
                ),
              ],
              if (widget.message != null) ...[
                Text(
                  widget.message!,
                  style: PulseTypography.caption.copyWith(
                    fontSize: 11,
                    color: PulseColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
