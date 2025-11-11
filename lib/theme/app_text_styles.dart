import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Pretendard 폰트를 기본으로, 영문은 Inter 사용
  static TextStyle _baseTextStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
  
  // Display Styles
  static TextStyle displayLarge = _baseTextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );
  
  static TextStyle displayMedium = _baseTextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );
  
  static TextStyle displaySmall = _baseTextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.3,
  );
  
  // Headline Styles
  static TextStyle headlineLarge = _baseTextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );
  
  static TextStyle headlineMedium = _baseTextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );
  
  static TextStyle headlineSmall = _baseTextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  
  // Title Styles
  static TextStyle titleLarge = _baseTextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
  );
  
  static TextStyle titleMedium = _baseTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
  
  static TextStyle titleSmall = _baseTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
  
  // Body Styles
  static TextStyle bodyLarge = _baseTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  static TextStyle bodyMedium = _baseTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  static TextStyle bodySmall = _baseTextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  // Label Styles
  static TextStyle labelLarge = _baseTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
  
  static TextStyle labelMedium = _baseTextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );
  
  static TextStyle labelSmall = _baseTextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );
  
  // Caption Styles
  static TextStyle caption = _baseTextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textTertiary,
  );
  
  static TextStyle captionBold = _baseTextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textTertiary,
  );
  
  // Button Styles
  static TextStyle button = _baseTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
  
  static TextStyle buttonLarge = _baseTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
  
  // Instagram Specific Styles
  static TextStyle instagramLogo = GoogleFonts.dancingScript(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );
  
  static TextStyle username = _baseTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  
  static TextStyle usernameSmall = _baseTextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
  
  static TextStyle postContent = _baseTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );
  
  static TextStyle hashtag = _baseTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.primaryBlue,
  );
  
  static TextStyle timestamp = _baseTextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textTertiary,
  );
  
  static TextStyle likeCount = _baseTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  
  static TextStyle commentCount = _baseTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  // Navigation Bar
  static TextStyle navBarLabel = _baseTextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
  );
  
  // AppBar
  static TextStyle appBarTitle = _baseTextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );
  
  // Error & Empty States
  static TextStyle emptyStateTitle = _baseTextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );
  
  static TextStyle emptyStateSubtitle = _baseTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textTertiary,
  );
}
