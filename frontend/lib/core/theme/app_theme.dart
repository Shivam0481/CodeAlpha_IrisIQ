import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF4F46E5); // Indigo
  static const Color secondaryColor = Color(0xFF7C3AED); // Violet
  static const Color accentColor = Color(0xFF06B6D4); // Cyan
  
  static const Color darkBgColor = Color(0xFF0B0F19); // Sleek Startup Dark
  static const Color darkCardColor = Color(0xFF161E2E);
  
  static const Color lightBgColor = Color(0xFFF9FAFB); // Neutral Light
  static const Color lightCardColor = Color(0xFFFFFFFF);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: lightBgColor,
        error: Colors.redAccent,
      ),
      scaffoldBackgroundColor: lightBgColor,
      cardTheme: CardThemeData(
        color: lightCardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: darkCardColor,
        error: Colors.redAccent,
      ),
      scaffoldBackgroundColor: darkBgColor,
      cardTheme: CardThemeData(
        color: darkCardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade800.withOpacity(0.4), width: 1),
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}

// Extension to get glassmorphic shadows and styling easily
extension GlassDecorations on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  BoxDecoration get glassDecoration {
    return BoxDecoration(
      color: isDarkMode
          ? const Color(0xFF1E293B).withOpacity(0.4)
          : Colors.white.withOpacity(0.6),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: isDarkMode
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.05),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: isDarkMode
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.03),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
