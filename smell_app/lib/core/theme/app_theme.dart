/// Light and dark themes with premium, minimalist design.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Exact palette per spec
  static const Color black = Color(0xFF0A0A0A);
  static const Color offWhite = Color(0xFFFAFAFA);
  static const Color lightGray = Color(0xFFF4F4F5);
  static const Color mediumGray = Color(0xFFA1A1AA);
  static const Color darkGray = Color(0xFF27272A);
  static const Color successGreen = Color(0xFF10B981);
  static const Color destructiveRed = Color(0xFFEF4444);

  /// Creates a light theme with premium, monochrome palette.
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(
      ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: offWhite,
      colorScheme: ColorScheme.light(
        primary: black,
        surface: offWhite,
        onSurface: black,
        outline: mediumGray,
        outlineVariant: lightGray,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: black,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 17,
          letterSpacing: -0.01,
          color: black,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      // Disable Material ripple — use custom tap feedback
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          color: black,
          letterSpacing: -0.02,
          height: 1.2,
        ),
        displayMedium: baseTextTheme.displayMedium?.copyWith(
          color: black,
          letterSpacing: -0.02,
        ),
        displaySmall: baseTextTheme.displaySmall?.copyWith(
          color: black,
          letterSpacing: -0.02,
        ),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          color: black,
          fontWeight: FontWeight.w600,
          fontSize: 28,
          letterSpacing: -0.02,
          height: 1.3,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: black,
          fontWeight: FontWeight.w600,
          fontSize: 24,
          letterSpacing: -0.02,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          color: black,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          letterSpacing: -0.01,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: black,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: black,
          fontWeight: FontWeight.w600,
          fontSize: 17,
          letterSpacing: -0.01,
        ),
        titleSmall: baseTextTheme.titleSmall?.copyWith(
          color: black,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: black,
          fontWeight: FontWeight.w400,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: darkGray,
          fontWeight: FontWeight.w400,
          fontSize: 15,
          height: 1.5,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: mediumGray,
          fontWeight: FontWeight.w400,
          fontSize: 13,
          height: 1.5,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          color: black,
          fontWeight: FontWeight.w500,
          fontSize: 14,
          letterSpacing: 0.1,
        ),
        labelMedium: baseTextTheme.labelMedium?.copyWith(
          color: mediumGray,
          fontWeight: FontWeight.w500,
          fontSize: 11,
          letterSpacing: 0.1,
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          color: mediumGray,
          fontWeight: FontWeight.w500,
          fontSize: 10,
          letterSpacing: 0.1,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: black,
      colorScheme: ColorScheme.dark(
        primary: offWhite,
        surface: black,
        onSurface: offWhite,
        outline: mediumGray,
        outlineVariant: darkGray,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: offWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 17,
          letterSpacing: -0.01,
          color: offWhite,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkGray,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          color: offWhite,
          letterSpacing: -0.02,
          height: 1.2,
        ),
        displayMedium: baseTextTheme.displayMedium?.copyWith(
          color: offWhite,
          letterSpacing: -0.02,
        ),
        displaySmall: baseTextTheme.displaySmall?.copyWith(
          color: offWhite,
          letterSpacing: -0.02,
        ),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          color: offWhite,
          fontWeight: FontWeight.w600,
          fontSize: 28,
          letterSpacing: -0.02,
          height: 1.3,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: offWhite,
          fontWeight: FontWeight.w600,
          fontSize: 24,
          letterSpacing: -0.02,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          color: offWhite,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          letterSpacing: -0.01,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: offWhite,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: offWhite,
          fontWeight: FontWeight.w600,
          fontSize: 17,
          letterSpacing: -0.01,
        ),
        titleSmall: baseTextTheme.titleSmall?.copyWith(
          color: offWhite,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: offWhite,
          fontWeight: FontWeight.w400,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: lightGray,
          fontWeight: FontWeight.w400,
          fontSize: 15,
          height: 1.5,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: mediumGray,
          fontWeight: FontWeight.w400,
          fontSize: 13,
          height: 1.5,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          color: offWhite,
          fontWeight: FontWeight.w500,
          fontSize: 14,
          letterSpacing: 0.1,
        ),
        labelMedium: baseTextTheme.labelMedium?.copyWith(
          color: mediumGray,
          fontWeight: FontWeight.w500,
          fontSize: 11,
          letterSpacing: 0.1,
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          color: mediumGray,
          fontWeight: FontWeight.w500,
          fontSize: 10,
          letterSpacing: 0.1,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // No instances
  AppTheme._();
}
