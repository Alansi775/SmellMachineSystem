/// Typography system using Google Fonts: Inter (English and Turkish).
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTextStyles {
  // Display styles
  static TextStyle get displayLarge {
    return GoogleFonts.inter(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.25,
      color: AppColors.black,
    );
  }

  static TextStyle get displayMedium {
    return GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.29,
      color: AppColors.black,
    );
  }

  static TextStyle get displaySmall {
    return GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.33,
      color: AppColors.black,
    );
  }

  // Headline styles
  static TextStyle get headlineLarge {
    return GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: AppColors.black,
    );
  }

  static TextStyle get headlineMedium {
    return GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.44,
      color: AppColors.black,
    );
  }

  static TextStyle get headlineSmall {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.5,
      color: AppColors.black,
    );
  }

  // Title styles
  static TextStyle get titleLarge {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.5,
      color: AppColors.black,
    );
  }

  static TextStyle get titleMedium {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.43,
      color: AppColors.black,
    );
  }

  static TextStyle get titleSmall {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.33,
      color: AppColors.black,
    );
  }

  // Body styles
  static TextStyle get bodyLarge {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: AppColors.black,
    );
  }

  static TextStyle get bodyMedium {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.43,
      color: AppColors.black,
    );
  }

  static TextStyle get bodySmall {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.33,
      color: AppColors.black,
    );
  }

  // Label styles
  static TextStyle get labelLarge {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.43,
      letterSpacing: 0.1,
      color: AppColors.black,
    );
  }

  static TextStyle get labelMedium {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.33,
      letterSpacing: 0.15,
      color: AppColors.black,
    );
  }

  static TextStyle get labelSmall {
    return GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 1.27,
      letterSpacing: 0.2,
      color: AppColors.black,
    );
  }

  // No instances
  AppTextStyles._();
}
