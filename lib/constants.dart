// Add this to a constants.dart file
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary colors
  static const Color primaryColor = Color(0xFF3C64B1);
  static const Color secondaryColor = Color(0xFF1E88E5);
  static const Color accentColor = Color(0xFF03A9F4);

  // Background colors
  static const Color scaffoldBackground = Colors.white;
  static const Color cardBackground = Color(0xFFF5F9FF);

  // Text colors
  static const Color textPrimary = Color(0xFF1D1D1D);
  static const Color textSecondary = Color(0xFF6E7191);

  // Category/chip colors
  static const Color businessColor = Color(0xFFE6F2FF);
  static const Color tradingColor = Color(0xFFE6FFF2);
  static const Color designColor = Color(0xFFFFF2E6);

  // Common styles
  static TextStyle headingStyle = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static TextStyle subheadingStyle = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle bodyStyle = GoogleFonts.poppins(
    fontSize: 16,
    color: textPrimary,
  );

  static TextStyle captionStyle = GoogleFonts.poppins(
    fontSize: 14,
    color: textSecondary,
  );

  // Button styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );

  // Card decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
