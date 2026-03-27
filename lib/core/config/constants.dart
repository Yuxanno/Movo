// Soft UI & Design Constants for FinanceFlow

class AppColors {
  // Background
  static const Color backgroundPrimary = Color(0xFFF8F9FA);
  static const Color backgroundSecondary = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5F7FC);

  // Accents
  static const Color primaryAccent = Color(0xFF6366F1); // Indigo
  static const Color secondaryAccent = Color(0xFF10B981); // Green (Income)
  static const Color negativeAccent = Color(0xFFEF4444); // Red (Expense)

  // Text
  static const Color textPrimary = Color(0xFF1F2937); // Dark Grey
  static const Color textSecondary = Color(0xFF6B7280); // Medium Grey
  static const Color textTertiary = Color(0xFF9CA3AF); // Light Grey

  // Divider & Border
  static const Color divider = Color(0xFFE5E7EB);
  static const Color border = Color(0xFFE5E7EB);

  // Shadows (will use in Box Shadows)
  static const Color shadowSoft = Color.fromARGB(20, 0, 0, 0); // rgba(0,0,0,0.08)
  static const Color shadowMedium = Color.fromARGB(31, 0, 0, 0); // rgba(0,0,0,0.12)
  static const Color shadowStrong = Color.fromARGB(41, 0, 0, 0); // rgba(0,0,0,0.16)

  // Category Colors
  static const Color categoryFood = Color(0xFFFB923C);
  static const Color categoryTransport = Color(0xFF3B82F6);
  static const Color categoryEntertainment = Color(0xFFA855F7);
  static const Color categoryUtilities = Color(0xFF06B6D4);
  static const Color categoryHealth = Color(0xFFFD08C0);
  static const Color categoryEducation = Color(0xFF8B5CF6);
  static const Color categoryOther = Color(0xFF6B7280);
}

class AppSizes {
  // Border Radius
  static const double borderRadiusXL = 24.0; // Main (Soft UI)
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusXSmall = 4.0;

  // Padding & Margins (Unit: 16px)
  static const double paddingXSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 12.0;
  static const double paddingLarge = 16.0;
  static const double paddingXLarge = 24.0;
  static const double paddingXXLarge = 32.0;

  // Icon Sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;

  // Font Sizes
  static const double fontXSmall = 12.0;
  static const double fontSmall = 14.0;
  static const double fontMedium = 16.0;
  static const double fontLarge = 20.0;
  static const double fontXLarge = 24.0;
  static const double fontDisplaySmall = 28.0;
  static const double fontDisplayMedium = 32.0;
  static const double fontDisplayLarge = 40.0;

  // Line Heights
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.4;
  static const double lineHeightRelaxed = 1.6;

  // Shadows
  static const shadowSoft = BoxShadow(
    offset: Offset(0, 4),
    blurRadius: 12,
    spreadRadius: 0,
    color: Color.fromARGB(20, 0, 0, 0),
  );

  static const shadowMedium = BoxShadow(
    offset: Offset(0, 8),
    blurRadius: 24,
    spreadRadius: 0,
    color: Color.fromARGB(31, 0, 0, 0),
  );

  static const shadowStrong = BoxShadow(
    offset: Offset(0, 12),
    blurRadius: 32,
    spreadRadius: 0,
    color: Color.fromARGB(41, 0, 0, 0),
  );
}

// Import guards
import 'package:flutter/material.dart';
