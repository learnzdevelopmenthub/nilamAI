import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NilamTheme {
  NilamTheme._();

  // -- Primary Brand Colors --
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color greenLight = Color(0xFFF1F8E9);
  static const Color greenContainer = Color(0xFFE8F5E9);

  // -- Secondary Accent Colors --
  static const Color warmAmber = Color(0xFFF59E0B);
  static const Color amberDark = Color(0xFFB45309);
  static const Color amberLight = Color(0xFFFCD34D);
  static const Color amberContainer = Color(0xFFFEF3C7);

  // -- Status/Alert Colors --
  static const Color redPrimary = Color(0xFFD32F2F);
  static const Color redOn = Color(0xFFB71C1C);
  static const Color redContainer = Color(0xFFFFEBEE);

  // -- Neutral Surface Colors --
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surface1 = Color(0xFFF8FAF8);
  static const Color surface2 = Color(0xFFF1F5F1);
  static const Color surfaceVariant = Color(0xFFECEFEC);
  static const Color onSurface = Color(0xFF1C1C1E);
  static const Color onSurfaceVariant = Color(0xFF5C6B5C);

  // -- Utility Colors --
  static const Color outline = Color(0xFFD4D8D4);
  static const Color outlineStrong = Color(0xFFA8B0A8);

  static ColorScheme get colorScheme => const ColorScheme(
        brightness: Brightness.light,
        primary: primaryGreen,
        onPrimary: Colors.white,
        primaryContainer: greenContainer,
        onPrimaryContainer: darkGreen,
        secondary: warmAmber,
        onSecondary: onSurface,
        secondaryContainer: amberContainer,
        onSecondaryContainer: amberDark,
        error: redPrimary,
        onError: Colors.white,
        errorContainer: redContainer,
        onErrorContainer: redOn,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineStrong,
        surfaceContainerHighest: surface2,
        surfaceContainerHigh: surface1,
        surfaceContainer: surface,
        surfaceContainerLow: surface,
        surfaceContainerLowest: Colors.white,
      );

  static TextTheme get _textTheme {
    final baseTextTheme = GoogleFonts.robotoTextTheme();
    final tamilTextTheme = GoogleFonts.notoSansTamilTextTheme();

    return baseTextTheme.merge(tamilTextTheme).copyWith(
          displayLarge: GoogleFonts.roboto(
            fontSize: 32,
            fontWeight: FontWeight.w400,
          ),
          headlineLarge: GoogleFonts.notoSansTamil(
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
          headlineMedium: GoogleFonts.notoSansTamil(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
          headlineSmall: GoogleFonts.notoSansTamil(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          bodySmall: GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          labelLarge: GoogleFonts.notoSansTamil(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          labelMedium: GoogleFonts.notoSansTamil(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          labelSmall: GoogleFonts.notoSansTamil(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        );
  }

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        textTheme: _textTheme,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: warmAmber,
          foregroundColor: onSurface,
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: outline),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(72, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primaryGreen, width: 2),
          ),
        ),
        scaffoldBackgroundColor: surface,
      );
}
