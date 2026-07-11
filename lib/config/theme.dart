import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RippleTheme {
  // Theme Color Palette - Yellow/Black/White Modern Scheme
  static const Color primaryTeal = Color(0xFFFACC15); // Primary Yellow
  static const Color primaryTealDark = Color(0xFFEAB308); // Darker Accent Yellow
  static const Color accentCoral = Color(0xFF3B82F6); // Soft Blue accent
  static const Color secondaryEmerald = Color(0xFF10B981); // Emerald Green Accent
  
  // Light Theme Colors
  static const Color lightBgStart = Color(0xFFF8FAFC);
  static const Color lightBgEnd = Color(0xFFF1F5F9);
  static const Color lightCardBg = Colors.white;
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);

  // Dark Theme Colors
  static const Color darkBgStart = Color(0xFF0F172A); // Slate 900
  static const Color darkBgEnd = Color(0xFF020617); // Slate 950
  static const Color darkCardBg = Color(0xFF1E293B); // Slate 800
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  static ThemeData themeData(BuildContext context, bool isDarkMode) {
    // Choose base font family
    final String fontFamily = 'Outfit';
    final TextTheme baseTextTheme = isDarkMode 
        ? ThemeData.dark().textTheme 
        : ThemeData.light().textTheme;

    final customTextTheme = GoogleFonts.getTextTheme(
      fontFamily, 
      baseTextTheme.copyWith(
        displayLarge: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDarkMode ? darkTextPrimary : lightTextPrimary,
          fontSize: 32.0,
          height: 1.2,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDarkMode ? darkTextPrimary : lightTextPrimary,
          fontSize: 20.0,
          height: 1.2,
        ),
        bodyLarge: TextStyle(
          fontWeight: FontWeight.normal,
          color: isDarkMode ? darkTextPrimary : lightTextPrimary,
          fontSize: 16.0,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          fontWeight: FontWeight.normal,
          color: isDarkMode ? darkTextSecondary : lightTextSecondary,
          fontSize: 14.0,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDarkMode ? darkTextPrimary : lightTextPrimary,
          fontSize: 14.0,
          height: 1.2,
        ),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      primaryColor: primaryTeal,
      scaffoldBackgroundColor: isDarkMode ? darkBgStart : lightBgStart,
      cardTheme: CardThemeData(
        color: isDarkMode ? darkCardBg.withOpacity(0.85) : lightCardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDarkMode 
                ? Colors.white.withOpacity(0.08) 
                : Colors.black.withOpacity(0.04),
            width: 1,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDarkMode ? darkBgEnd : Colors.white,
        selectedItemColor: primaryTeal,
        unselectedItemColor: isDarkMode ? darkTextSecondary : lightTextSecondary,
        selectedLabelStyle: TextStyle(
          fontFamily: fontFamily, 
          fontSize: 12.0,
          height: 1.0,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: fontFamily, 
          fontSize: 12.0,
          height: 1.0,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.getFont(
          fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? darkTextPrimary : lightTextPrimary,
          height: 1.2,
        ),
        iconTheme: IconThemeData(
          color: isDarkMode ? darkTextPrimary : lightTextPrimary,
        ),
      ),
      colorScheme: isDarkMode
          ? const ColorScheme.dark(
              primary: primaryTeal,
              secondary: secondaryEmerald,
              tertiary: accentCoral,
              surface: darkCardBg,
              onSurface: darkTextPrimary,
            )
          : const ColorScheme.light(
              primary: primaryTeal,
              secondary: secondaryEmerald,
              tertiary: accentCoral,
              surface: lightCardBg,
              onSurface: lightTextPrimary,
            ),
      textTheme: customTextTheme,
    );
  }

  // Premium Background Gradients
  static BoxDecoration backgroundDecoration(bool isDarkMode) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDarkMode
            ? [darkBgStart, darkBgEnd]
            : [lightBgStart, lightBgEnd],
      ),
    );
  }

  static BoxDecoration glassmorphicDecoration(bool isDarkMode, {double blur = 15.0}) {
    return BoxDecoration(
      color: isDarkMode 
          ? Colors.white.withOpacity(0.03) 
          : Colors.white.withOpacity(0.7),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isDarkMode 
            ? Colors.white.withOpacity(0.08) 
            : Colors.black.withOpacity(0.05),
        width: 1,
      ),
    );
  }
}
