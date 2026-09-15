import 'package:flutter/material.dart';
import 'pulse_colors.dart';

/// Central typography tokens for PulseGuard adhering to the font hierarchy budget.
///
/// Primary: "Inter", with fallbacks to system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif.
/// Monospace: "JetBrains Mono", with fallback to monospace.
///
/// Features tabular figures for real-time streaming vitals values to eliminate
/// layout jitter during 1 Hz stream ticks.
class PulseTypography {
  PulseTypography._();

  /// Primary / Sans-Serif font family
  static const String fontFamily = 'Inter';

  /// Sans-serif fallbacks
  static const List<String> fontFamilyFallback = [
    'system-ui',
    '-apple-system',
    'BlinkMacSystemFont',
    'Segoe UI',
    'Roboto',
    'sans-serif',
  ];

  /// Monospace font family
  static const String fontMonoFamily = 'JetBrains Mono';

  /// Monospace fallbacks
  static const List<String> fontMonoFamilyFallback = [
    'monospace',
  ];

  /// Primary large vitals value (e.g. "72", "48") with Tabular Figures.
  static const TextStyle displayMetric = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 44,
    fontWeight: FontWeight.w600,
    height: 48 / 44,
    letterSpacing: -1.0,
    color: PulseColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Unit label positioned next to or under the metric (e.g. "BPM", "ms", "%").
  static const TextStyle displayUnit = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 20 / 16,
    letterSpacing: 0.0,
    color: PulseColors.textSecondary,
  );

  /// Large screen titles, emergency headlines, modal headers.
  static const TextStyle headingLarge = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 30 / 24,
    letterSpacing: -0.5,
    color: PulseColors.textPrimary,
  );

  /// Card section headers, dialog titles, prominent section banners.
  static const TextStyle headingMedium = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 24 / 18,
    letterSpacing: -0.2,
    color: PulseColors.textPrimary,
  );

  /// Standard descriptive text, instructions, baseline explanations.
  static const TextStyle bodyRegular = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 22 / 15,
    letterSpacing: 0.0,
    color: PulseColors.textSecondary,
  );

  /// Emphasized body text, list highlights, bolded summary phrases.
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 22 / 15,
    letterSpacing: 0.0,
    color: PulseColors.textPrimary,
  );

  /// Timestamps, signal quality badges, disclaimer copy, secondary captions.
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    letterSpacing: 0.2,
    color: PulseColors.textTertiary,
  );

  /// Labels on primary, secondary, and emergency buttons.
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 20 / 16,
    letterSpacing: 0.1,
    color: Colors.white,
  );

  /// Monospace body for technical logs, telemetry dumps, and code preview.
  static const TextStyle mono = TextStyle(
    fontFamily: fontMonoFamily,
    fontFamilyFallback: fontMonoFamilyFallback,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: PulseColors.textPrimary,
  );

  /// Compact monospace style for logs and technical alerts.
  static const TextStyle monoSmall = TextStyle(
    fontFamily: fontMonoFamily,
    fontFamilyFallback: fontMonoFamilyFallback,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: PulseColors.textPrimary,
  );
}
