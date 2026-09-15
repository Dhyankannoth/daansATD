import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pulse_colors.dart';
import 'pulse_typography.dart';

/// App theme configuring Material 3 with PulseGuard design tokens.
class PulseTheme {
  PulseTheme._();

  static ThemeData get lightTheme {
    final baseTheme = ThemeData(useMaterial3: true, brightness: Brightness.light);
    return baseTheme.copyWith(
      scaffoldBackgroundColor: PulseColors.background,
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).apply(
        fontFamilyFallback: PulseTypography.fontFamilyFallback,
        bodyColor: PulseColors.textPrimary,
        displayColor: PulseColors.textPrimary,
      ),
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: PulseColors.primary,
        onPrimary: Colors.white,
        primaryContainer: PulseColors.primaryLight,
        onPrimaryContainer: PulseColors.primaryDark,
        secondary: PulseColors.textSecondary,
        onSecondary: Colors.white,
        error: PulseColors.riskCritical,
        onError: Colors.white,
        surface: PulseColors.surface,
        onSurface: PulseColors.textPrimary,
        outline: PulseColors.divider,
        outlineVariant: PulseColors.borderSubtle,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: PulseColors.surface,
        foregroundColor: PulseColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        titleTextStyle: PulseTypography.headingMedium,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: PulseColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: PulseColors.divider, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: PulseColors.surface,
        elevation: 2,
        indicatorColor: PulseColors.primaryLight,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return PulseTypography.caption.copyWith(
              color: PulseColors.primary,
              fontWeight: FontWeight.w600,
            );
          }
          return PulseTypography.caption.copyWith(
            color: PulseColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: PulseColors.primary, size: 24);
          }
          return const IconThemeData(
            color: PulseColors.textSecondary,
            size: 24,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: PulseColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: PulseTypography.button,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: PulseColors.textPrimary,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: PulseColors.divider, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: PulseTypography.button.copyWith(
            color: PulseColors.textPrimary,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: PulseColors.divider,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: PulseColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: PulseTypography.headingMedium,
        contentTextStyle: PulseTypography.bodyRegular,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: PulseColors.surface,
        modalBackgroundColor: PulseColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PulseColors.surfaceDim,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: PulseTypography.bodyRegular.copyWith(
          color: PulseColors.textTertiary,
        ),
        labelStyle: PulseTypography.bodyRegular.copyWith(
          color: PulseColors.textSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PulseColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PulseColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PulseColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PulseColors.riskCritical),
        ),
      ),
    );
  }
}
