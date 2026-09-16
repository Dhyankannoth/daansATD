import 'package:flutter/material.dart';
import '../../engine/api/events.dart';

/// Central color tokens for PulseGuard adhering to the sleek Cal AI / modern iOS health style.
class PulseColors {
  PulseColors._();

  // Neutral Base & Surfaces
  static const Color background = Color(0xFFF8FAFC); // Clean off-white background
  static const Color surface = Color(0xFFFFFFFF); // Pure White card surface
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFF1F5F9); // Slate 100 soft fill
  static const Color surfaceDark = Color(0xFF0F172A); // Slate 900 dark element

  // Typography & Structure
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textTertiary = Color(0xFF94A3B8); // Slate 400
  static const Color divider = Color(0xFFF1F5F9); // Ultra subtle card border
  static const Color borderSubtle = Color(0xFFE2E8F0); // Slate 200 border

  // Brand & Action
  static const Color primary = Color(0xFF0F172A); // Sleek Dark Accent (Cal AI style)
  static const Color primaryBlue = Color(0xFF0284C7); // Clinical Sky Blue
  static const Color primaryDark = Color(0xFF000000);
  static const Color primaryLight = Color(0xFFE0F2FE); // Sky 100

  // Cal AI-style soft tinted circular icon backgrounds
  static const Color tintRedBg = Color(0xFFFEE2E2); // Rose 100
  static const Color tintRedIcon = Color(0xFFEF4444); // Red 500
  static const Color tintAmberBg = Color(0xFFFEF3C7); // Amber 100
  static const Color tintAmberIcon = Color(0xFFF59E0B); // Amber 500
  static const Color tintBlueBg = Color(0xFFE0E7FF); // Indigo 100
  static const Color tintBlueIcon = Color(0xFF6366F1); // Indigo 500
  static const Color tintEmeraldBg = Color(0xFFECFDF5); // Emerald 100
  static const Color tintEmeraldIcon = Color(0xFF10B981); // Emerald 500

  // Semantic Risk Tokens (Aligned with RiskLevel enum)
  static const Color riskNormal = Color(0xFF10B981); // Emerald 500
  static const Color riskNormalBg = Color(0xFFECFDF5); // Emerald 50

  static const Color riskMonitoring = Color(0xFF0EA5E9); // Sky 500
  static const Color riskMonitoringBg = Color(0xFFF0F9FF); // Sky 50

  static const Color riskElevated = Color(0xFFF59E0B); // Amber 500
  static const Color riskElevatedBg = Color(0xFFFFFBEB); // Amber 50

  static const Color riskHigh = Color(0xFFF97316); // Orange 500
  static const Color riskHighBg = Color(0xFFFFF7ED); // Orange 50

  static const Color riskCritical = Color(0xFFEF4444); // Red 500
  static const Color riskCriticalBg = Color(0xFFFEF2F2); // Red 50

  // Emergency CTA
  static const Color emergencyRed = Color(0xFFDC2626); // Red 600
  static const Color emergencyRedPressed = Color(0xFFB91C1C); // Red 700
  static const Color emergencyRedBg = Color(0xFFFEF2F2);

  // Sleek Soft Shadows (Cal AI style)
  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x06000000),
    blurRadius: 20,
    offset: Offset(0, 4),
    spreadRadius: 0,
  );

  static const BoxShadow elevatedModalShadow = BoxShadow(
    color: Color(0x120F172A),
    blurRadius: 30,
    offset: Offset(0, 10),
  );

  static const BoxShadow fabShadow = BoxShadow(
    color: Color(0x330F172A),
    blurRadius: 18,
    offset: Offset(0, 6),
  );

  static const BoxShadow emergencyPulseShadow = BoxShadow(
    color: Color(0x33DC2626),
    blurRadius: 20,
    spreadRadius: 2,
  );

  /// Helper to get semantic color for a [RiskLevel].
  static Color forRisk(RiskLevel level) => switch (level) {
    RiskLevel.normal => riskNormal,
    RiskLevel.monitoring => riskMonitoring,
    RiskLevel.elevated => riskElevated,
    RiskLevel.high => riskHigh,
    RiskLevel.critical => riskCritical,
  };

  /// Helper to get background tint for a [RiskLevel].
  static Color backgroundForRisk(RiskLevel level) => switch (level) {
    RiskLevel.normal => riskNormalBg,
    RiskLevel.monitoring => riskMonitoringBg,
    RiskLevel.elevated => riskElevatedBg,
    RiskLevel.high => riskHighBg,
    RiskLevel.critical => riskCriticalBg,
  };
}
