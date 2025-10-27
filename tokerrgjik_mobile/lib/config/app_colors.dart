import 'package:flutter/material.dart';

/// App-wide color constants
/// Masculine, professional color scheme
class AppColors {
  // Primary colors - Dark blue/slate theme (masculine)
  static const Color primary = Color(0xFF2C3E50); // Dark blue-grey
  static const Color primaryLight = Color(0xFF34495E); // Lighter slate
  static const Color primaryDark = Color(0xFF1A252F); // Darker slate
  
  // Accent colors
  static const Color accent = Color(0xFF3498DB); // Bright blue
  static const Color accentDark = Color(0xFF2980B9); // Darker blue
  static const Color gold = Color(0xFFDAA520); // Gold for highlights
  
  // Gradient colors (masculine blue gradient instead of purple)
  static const Color gradientStart = Color(0xFF2C3E50); // Dark slate
  static const Color gradientEnd = Color(0xFF3498DB); // Bright blue
  
  // Create gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );
  
  // Secondary gradient (steel/silver theme)
  static const LinearGradient steelGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5D6D7E), Color(0xFF85929E)],
  );
  
  // Success, warning, error
  static const Color success = Color(0xFF27AE60); // Green
  static const Color warning = Color(0xFFF39C12); // Orange
  static const Color error = Color(0xFFE74C3C); // Red
  
  // Background shades
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF1A252F);
  
  // Text colors
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textLight = Colors.white;
  
  // Game-specific
  static const Color boardGold = Color(0xFFDAA520);
  static const Color player1 = Color(0xFFFFF8DC); // Cream
  static const Color player2 = Color(0xFF1ABC9C); // Turquoise
  
  // Party/celebration colors (toned down, masculine)
  static const Color partyPrimary = Color(0xFF3498DB); // Blue instead of pink
  static const Color partySecondary = Color(0xFFDAA520); // Gold
  static const Color partyAccent = Color(0xFF27AE60); // Green
  
  // Chat colors
  static const Color chatPrimary = Color(0xFF2C3E50); // Dark slate instead of purple
  static const Color chatAccent = Color(0xFF3498DB); // Blue
}
