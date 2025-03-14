import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primaryColor = Color(0xFF6C63FF);
  static const secondaryColor = Color(0xFF00D9B5);
  static const accentColor = Color(0xFFFFB800);
  static const backgroundColor = Color(0xFFF0F3FF);
  static const errorColor = Color(0xFFFF6B6B);

  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    fontFamily: GoogleFonts.poppins().fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      secondary: secondaryColor,
      background: backgroundColor,
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: primaryColor.withOpacity(0.2),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
} 