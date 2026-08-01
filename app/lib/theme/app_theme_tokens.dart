import 'package:flutter/material.dart';

class AppThemeTokens {
  // Brand Colors
  static const Color marianBlue = Color(0xFF1565C0);
  static const Color liturgicalGold = Color(0xFFC68A00);
  static const Color liturgicalPurple = Color(0xFF6A1B9A);
  static const Color liturgicalRed = Color(0xFFC62828);
  static const Color liturgicalGreen = Color(0xFF2E7D32);
  static const Color liturgicalRose = Color(0xFFD81B60);

  // Border Radii
  static final BorderRadius cardRadius = BorderRadius.circular(16.0);
  static final BorderRadius sheetRadius = const BorderRadius.vertical(
    top: Radius.circular(20.0),
  );
  static final BorderRadius buttonRadius = BorderRadius.circular(12.0);
  static final BorderRadius chipRadius = BorderRadius.circular(8.0);

  // Layout Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 12.0;
  static const double paddingLarge = 16.0;
  static const double paddingXLarge = 20.0;
}
