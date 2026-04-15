/// Modern, minimal color palette: black, white, and grays only.
import 'package:flutter/material.dart';

class AppColors {
  // Base colors
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  // Grays
  static const Color gray950 = Color(0xFF0F0F0F); // Almost black
  static const Color gray900 = Color(0xFF1A1A1A);
  static const Color gray800 = Color(0xFF2D2D2D);
  static const Color gray700 = Color(0xFF404040);
  static const Color gray600 = Color(0xFF525252);
  static const Color gray500 = Color(0xFF656565);
  static const Color gray400 = Color(0xFF808080);
  static const Color gray300 = Color(0xFFA3A3A3);
  static const Color gray200 = Color(0xFFD1D1D1);
  static const Color gray100 = Color(0xFFE5E5E5);
  static const Color gray50 = Color(0xFFFAFAFA);

  // Semantic colors (still grayscale for minimal aesthetic)
  static const Color divider = gray200;
  static const Color shadow = Color(0x20000000); // Black with 12.5% opacity
  static const Color disabled = gray400;

  // No instances
  AppColors._();
}
