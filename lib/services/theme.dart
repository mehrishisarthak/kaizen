import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- KAIZEN V2 COLOR PALETTE ---

  /// A deep, modern teal for primary buttons and chrome.
  static const Color primaryColor = Color(0xFF00796B); // Teal 700

  /// A vibrant green for charts, highlights, and "online" status.
  static const Color accentColor = Color(0xFF00C853); // Your kaizenGreen

  /// A neutral, very dark grey for card backgrounds in dark mode.
  static const Color darkSurface = Color(0xFF1E1E1E);

  /// A neutral, pure black for the main background in dark mode.
  static const Color darkBackground = Color(0xFF121212);

  /// A very light grey for the main background in light mode.
  static const Color lightBackground = Color(0xFFF7F9FA);

  /// Pure white for card backgrounds in light mode.
  static const Color lightSurface = Colors.white;

  /// A standard red for errors.
  static const Color errorRed = Color(0xFFD32F2F); // Red 700

  // --- ADDED THIS LINE ---
  /// A specific grey for chart grid lines in dark mode.
  static const Color kaizenChartGrid = Color(0xFF37434D);

  // --- TEXT THEME ---
  /// We'll use Manrope: it's modern, clean, and great for data.
  static final TextTheme _baseTextTheme = GoogleFonts.manropeTextTheme(
    const TextTheme(
      displaySmall: TextStyle(fontWeight: FontWeight.bold, fontSize: 36),
      headlineMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
      titleLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 22),
      titleMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
      titleSmall: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
    ),
  );

  // --- COMPONENT STYLES ---
  static final _cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );

  static final _buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );

  // --- KAIZEN LIGHT THEME ---
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: lightBackground,

      // ColorScheme
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: lightSurface,
        background: lightBackground, // Added from your file
        error: errorRed,
        onPrimary: Colors.white, // Text on primary-colored buttons
        onSecondary: Colors.black, // Text on accent-colored elements
        onSurface: Color(0xFF1A1A1A),
        onBackground: Color(0xFF1A1A1A), // Added from your file
        onError: Colors.white,
      ),

      // Text Theme
      textTheme: _baseTextTheme.apply(bodyColor: const Color(0xFF1A1A1A)),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 1,
        centerTitle: true,
        titleTextStyle: _baseTextTheme.titleLarge?.copyWith(
          color: const Color(0xFF1A1A1A),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 1,
        color: lightSurface,
        surfaceTintColor: Colors.transparent, // Prevents yellowish tint
        shape: _cardShape,
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: _buttonShape,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: _baseTextTheme.titleSmall,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        elevation: 2,
      ),

      // ToggleButtons Theme
      toggleButtonsTheme: ToggleButtonsThemeData(
        color: Colors.black54,
        selectedColor: Colors.white,
        fillColor: primaryColor,
        borderRadius: BorderRadius.circular(10),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  // --- KAIZEN DARK THEME ---
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBackground,

      // ColorScheme
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: darkSurface,
        background: darkBackground, // Added from your file
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        onBackground: Colors.white, // Added from your file
        onError: Colors.white,
      ),

      // Text Theme
      textTheme: _baseTextTheme.apply(bodyColor: Colors.white),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _baseTextTheme.titleLarge?.copyWith(color: Colors.white),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkSurface,
        shape: _cardShape,
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: _buttonShape,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: _baseTextTheme.titleSmall,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: accentColor,
        unselectedItemColor: Colors.grey,
        elevation: 2,
      ),

      // ToggleButtons Theme
      toggleButtonsTheme: ToggleButtonsThemeData(
        color: Colors.white70,
        selectedColor: Colors.black,
        fillColor: accentColor,
        borderRadius: BorderRadius.circular(10),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}