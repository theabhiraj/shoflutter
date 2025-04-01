import 'package:flutter/material.dart';

class DesignSystem {
  // Primary Colors
  static const Color primaryColor = Color(0xFF1A237E); // Deep Indigo
  static const Color secondaryColor = Color(0xFF4CAF50); // Green
  static const Color accentColor = Color(0xFFFFA000); // Amber
  static const Color errorColor = Color(0xFFD32F2F); // Red

  // Neutral Colors
  static const Color surfaceColor = Colors.white;
  static const Color backgroundColor = Color(0xFFF8F9FA); // Lighter background
  static const Color textPrimaryColor =
      Color(0xFF1F2937); // Darker text for better contrast
  static const Color textSecondaryColor =
      Color(0xFF6B7280); // More visible secondary text

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF1A237E),
      Color(0xFF3949AB),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [
      Colors.white,
      Color(0xFFF5F5F5),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text Styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
    height: 1.3, // Better line height
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
    height: 1.3,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimaryColor,
    height: 1.5, // Better readability
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondaryColor,
    height: 1.5,
  );

  // Card Decorations
  static BoxDecoration cardDecoration = BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration primaryCardDecoration = BoxDecoration(
    gradient: LinearGradient(
      colors: [
        primaryColor,
        Color(0xFF283593), // Slightly lighter indigo for gradient
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: primaryColor.withOpacity(0.2),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // Button Styles
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 2,
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  );

  static final ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: surfaceColor,
    foregroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 1,
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  );

  // Input Decorations
  static InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: textSecondaryColor),
      filled: true,
      fillColor: backgroundColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  // Status Colors
  static const Color successColor =
      Color(0xFF2E7D32); // Darker green for better visibility
  static const Color warningColor =
      Color(0xFFED6C02); // Darker amber for better visibility
  static const Color infoColor =
      Color(0xFF0277BD); // Darker blue for better visibility

  // Status Styles
  static BoxDecoration getStatusDecoration(Color color) {
    return BoxDecoration(
      color:
          color.withOpacity(0.12), // Slightly more opaque for better visibility
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: color.withOpacity(0.5), // More visible border
      ),
    );
  }

  // Avatar Styles
  static BoxDecoration avatarDecoration = BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(
      color: primaryColor.withOpacity(0.8), // More visible border
      width: 2,
    ),
  );
}
