import 'package:flutter/material.dart';

/// Music library themed colors and styling.
/// Dark, warm aesthetic inspired by vinyl and listening rooms.
class AppTheme {
  AppTheme._();

  // Breakpoints for responsive layout
  static const double breakpointTablet = 600;
  static const double breakpointDesktop = 900;

  static bool isTabletOrLarger(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= breakpointTablet;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= breakpointDesktop;
  }

  /// Horizontal padding that scales with screen width
  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= breakpointDesktop) return 32;
    if (width >= breakpointTablet) return 24;
    return 16;
  }

  /// Max content width for readability on large screens
  static const double maxContentWidth = 720;

  static ThemeData get darkTheme {
    const Color surfaceDark = Color(0xFF0F0F12);
    const Color surfaceElevated = Color(0xFF1A1A1F);
    const Color surfaceCard = Color(0xFF222228);
    const Color accent = Color(0xFFE8B86D); // Warm amber / vinyl gold
    const Color accentVariant = Color(0xFFC99B4A);
    const Color onSurface = Color(0xFFE8E6E3);
    const Color onSurfaceVariant = Color(0xFF9E9B97);
    const Color outline = Color(0xFF3D3B38);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: accent,
        onPrimary: const Color(0xFF1A1A1F),
        primaryContainer: accentVariant.withValues(alpha: 0.25),
        onPrimaryContainer: accent,
        secondary: const Color(0xFF7B7F8C),
        onSecondary: surfaceDark,
        surface: surfaceDark,
        onSurface: onSurface,
        surfaceContainerHighest: surfaceElevated,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        error: const Color(0xFFE57373),
        onError: surfaceDark,
      ),
      scaffoldBackgroundColor: surfaceDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: onSurfaceVariant),
        prefixIconColor: onSurfaceVariant,
        suffixIconColor: onSurfaceVariant,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: const DividerThemeData(color: outline, thickness: 1),
      textTheme: _textTheme(onSurface, onSurfaceVariant),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accent,
        circularTrackColor: outline,
      ),
    );
  }

  static TextTheme _textTheme(Color onSurface, Color onSurfaceVariant) {
    return TextTheme(
      headlineLarge: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: onSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: onSurface,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: onSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: onSurface,
      ),
    );
  }
}
