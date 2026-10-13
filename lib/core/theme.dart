import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MilkColors {
  // Brand & Mood Palette
  static const Color milkWhite = Color(0xFFFDFCF8);
  static const Color cream = Color(0xFFFFF7E6);
  static const Color creamLight = Color(0xFFFFFBF2);
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color primaryGreenDark = Color(0xFF1B5E20);
  static const Color primaryGreenLight = Color(0xFFE8F5E9);
  static const Color dairyBlue = Color(0xFF1E6FD9);
  static const Color dairyBlueLight = Color(0xFFE3F2FD);
  static const Color butterYellow = Color(0xFFF6C453);
  static const Color butterYellowLight = Color(0xFFFFF8E1);
  static const Color butterYellowDark = Color(0xFFE5A823);
  static const Color charcoal = Color(0xFF1F2933);
  static const Color charcoalLight = Color(0xFF52606D);
  static const Color charcoalMuted = Color(0xFF7B8794);
  static const Color border = Color(0xFFE4E7EB);
  static const Color surfaceElevated = Colors.white;

  // Status Colors
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFE67E22);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF1976D2);
}

ThemeData buildTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
  final textTheme = GoogleFonts.nunitoTextTheme(base.textTheme).apply(
    bodyColor: MilkColors.charcoal,
    displayColor: MilkColors.charcoal,
  );

  return base.copyWith(
    scaffoldBackgroundColor: MilkColors.milkWhite,
    colorScheme: const ColorScheme.light(
      primary: MilkColors.primaryGreen,
      onPrimary: Colors.white,
      primaryContainer: MilkColors.primaryGreenLight,
      onPrimaryContainer: MilkColors.primaryGreenDark,
      secondary: MilkColors.dairyBlue,
      onSecondary: Colors.white,
      secondaryContainer: MilkColors.dairyBlueLight,
      onSecondaryContainer: MilkColors.dairyBlue,
      tertiary: MilkColors.butterYellowDark,
      onTertiary: Colors.white,
      tertiaryContainer: MilkColors.butterYellowLight,
      surface: MilkColors.milkWhite,
      onSurface: MilkColors.charcoal,
      error: MilkColors.error,
    ),
    textTheme: textTheme.copyWith(
      headlineLarge: textTheme.headlineLarge?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: MilkColors.charcoal,
        letterSpacing: -0.5,
      ),
      headlineMedium: textTheme.headlineMedium?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: MilkColors.charcoal,
      ),
      headlineSmall: textTheme.headlineSmall?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: MilkColors.charcoal,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: MilkColors.charcoal,
      ),
      titleMedium: textTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: MilkColors.charcoal,
      ),
      bodyLarge: textTheme.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: MilkColors.charcoal,
      ),
      bodyMedium: textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: MilkColors.charcoalLight,
      ),
      labelLarge: textTheme.labelLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: MilkColors.milkWhite,
      foregroundColor: MilkColors.charcoal,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: MilkColors.charcoal,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: MilkColors.border, width: 1),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: MilkColors.primaryGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: MilkColors.primaryGreen,
        side: const BorderSide(color: MilkColors.primaryGreen, width: 1.5),
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: MilkColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: MilkColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: MilkColors.primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: MilkColors.error),
      ),
      labelStyle: const TextStyle(color: MilkColors.charcoalLight, fontSize: 15),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: MilkColors.creamLight,
      selectedColor: MilkColors.primaryGreen,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      side: const BorderSide(color: MilkColors.border),
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: MilkColors.primaryGreenLight,
      elevation: 4,
      shadowColor: Colors.black12,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: MilkColors.primaryGreenDark,
          );
        }
        return const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: MilkColors.charcoalMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: MilkColors.primaryGreenDark, size: 26);
        }
        return const IconThemeData(color: MilkColors.charcoalMuted, size: 24);
      }),
    ),
    dividerTheme: const DividerThemeData(
      color: MilkColors.border,
      thickness: 1,
      space: 24,
    ),
  );
}
