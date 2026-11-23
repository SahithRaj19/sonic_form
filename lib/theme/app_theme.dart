import 'package:flutter/material.dart';

class AppTheme {
  // Brand color palette - Deep Dark with Electric Lime accents
  static const Color darkBackground = Color(0xFF0C0E12);
  static const Color darkSurface = Color(0xFF141820);
  static const Color darkSurfaceVariant = Color(0xFF1C222C);
  static const Color darkSurfaceElevated = Color(0xFF252D3A);
  static const Color darkBorder = Color(0xFF2E3846);
  static const Color darkDivider = Color(0xFF232A34);

  // Vibrant Lime Accents
  static const Color limeAccent = Color(0xFFCCFF00); // Electric Lime
  static const Color limeMuted = Color(0xFFA3E635); // Soft Neon Lime
  static const Color limeDeep = Color(0xFF709900); // Deep Forest Lime
  static const Color limeGlow = Color(0x33CCFF00); // 20% Alpha for halos
  static const Color limeSubtle = Color(0x1ACCFF00); // 10% Alpha for surfaces

  // Neutral typography
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textTertiary = Color(0xFF71717A);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: limeAccent,
        onPrimary: Color(0xFF111827),
        primaryContainer: darkSurfaceElevated,
        onPrimaryContainer: limeAccent,
        secondary: limeMuted,
        onSecondary: Color(0xFF111827),
        surface: darkSurface,
        onSurface: textPrimary,
        surfaceContainerHighest: darkSurfaceVariant,
        outline: darkBorder,
        outlineVariant: darkDivider,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: limeAccent),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: limeAccent,
        inactiveTrackColor: darkSurfaceElevated,
        thumbColor: limeAccent,
        overlayColor: limeGlow,
        trackHeight: 4.0,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 7,
          elevation: 2,
        ),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF111827);
          }
          return textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return limeAccent;
          }
          return darkSurfaceElevated;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return darkBorder;
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceVariant,
        selectedColor: limeAccent,
        disabledColor: darkSurface,
        labelStyle: const TextStyle(
          color: textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Color(0xFF111827),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        side: const BorderSide(color: darkBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkSurfaceElevated,
        contentTextStyle: const TextStyle(color: textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: darkBorder),
        ),
      ),
    );
  }
}
