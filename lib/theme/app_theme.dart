import 'package:flutter/material.dart';

class AppTheme {
  // Brand Color Palette
  static const Color primaryCoffee = Color(0xFF2C1810);
  static const Color coffeeDark = Color(0xFF1B0F0A);
  static const Color coffeeMedium = Color(0xFF4A2818);
  static const Color coffeeLight = Color(0xFF78472A);
  
  static const Color amberGold = Color(0xFFF59E0B);
  static const Color amberDark = Color(0xFFD97706);
  static const Color amberLight = Color(0xFFFCD34D);

  static const Color creamBg = Color(0xFFFDFBF7);
  static const Color creamCard = Color(0xFFFFFFFF);
  static const Color creamDark = Color(0xFFF3EDE2);

  static const Color darkBg = Color(0xFF12100E);
  static const Color darkCard = Color(0xFF1E1B18);
  static const Color darkBorder = Color(0xFF2E2A25);

  static const Color milkTeaBlue = Color(0xFF2563EB);
  static const Color snackAmber = Color(0xFFEA580C);
  static const Color successGreen = Color(0xFF10B981);
  static const Color dangerRed = Color(0xFFEF4444);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: amberGold,
      scaffoldBackgroundColor: creamBg,
      colorScheme: const ColorScheme.light(
        primary: amberGold,
        onPrimary: Color(0xFF2C1810),
        secondary: coffeeMedium,
        onSecondary: Colors.white,
        surface: creamCard,
        onSurface: Color(0xFF1E1B18),
        error: dangerRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryCoffee,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: creamCard,
        elevation: 1,
        shadowColor: primaryCoffee.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: creamDark.withValues(alpha: 0.7)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: amberGold,
          foregroundColor: const Color(0xFF2C1810),
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryCoffee,
          side: const BorderSide(color: Color(0xFFE5E0D8)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E0D8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E0D8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: amberGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: dangerRed),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: amberGold,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: amberGold,
        onPrimary: Color(0xFF2C1810),
        secondary: amberLight,
        onSecondary: Colors.black,
        surface: darkCard,
        onSurface: Colors.white,
        error: dangerRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkCard,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: const CardThemeData(
        color: darkCard,
        elevation: 2,
        shadowColor: Color(0x66000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: darkBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF191614),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: amberGold, width: 2),
        ),
      ),
    );
  }
}
