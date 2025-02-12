import 'package:flutter/material.dart';

class Util {
  // Fonts
  static const List<String> availableFonts = [
    'Inter',
    'Roboto',
    'Lato',
    'Open Sans',
    'Montserrat',
    'Source Code Pro',
    'JetBrains Mono',
    'Fira Code',
    'Ubuntu',
    'Poppins',
  ];

  static String appFont = availableFonts[0];

  // Colors
  static const primaryPurple = Color(0xFF8B5CF6);
  static const primaryCyan = Color(0xFF22D3EE);
  static const accentPink = Color(0xFFEC4899);
  static const accentGreen = Color(0xFF10B981);
  static const accentYellow = Color(0xFFFBBF24);
  static const accentOrange = Color(0xFFF97316);

  // Dark theme colors
  static const darkSurface = Color(0xFF1E1B2C);
  static const darkBackground = Color(0xFF0F0B1A);
  static const darkSurfaceLight = Color(0xFF2D2E32);
  static const borderColor = Color(0xFF2D2E32);

  // Light theme colors
  static const lightSurface = Color(0xFFFAFAFA);
  static const lightBackground = Color(0xFFF4F4F5);
  static const lightSurfaceDark = Color(0xFFE4E4E7);
  static const lightBorderColor = Color(0xFFD4D4D8);

  // Opacity helpers
  static Color withOpacity40(Color color) => color.withOpacity(0.4);
  static Color withOpacity20(Color color) => color.withOpacity(0.2);
  static Color withOpacity10(Color color) => color.withOpacity(0.1);
  static Color withOpacity90(Color color) => color.withOpacity(0.9);

  // Add these color lists at the top of the Util class
  static const List<Color> primaryColors = [
    Color(0xFF8B5CF6), // Default purple
    Color(0xFF3B82F6), // Blue
    Color(0xFFEC4899), // Pink
    Color(0xFF10B981), // Green
    Color(0xFFF97316), // Orange
  ];

  static const List<Color> secondaryColors = [
    Color(0xFF22D3EE), // Default cyan
    Color(0xFF6EE7B7), // Mint
    Color(0xFFFBBF24), // Yellow
    Color(0xFF818CF8), // Indigo
    Color(0xFFF472B6), // Light pink
  ];
}
