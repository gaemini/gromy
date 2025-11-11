import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (Green Theme)
  static const Color primaryGreen = Color(0xFF2D7A4F); // 진한 초록
  static const Color lightGreen = Color(0xFFE8F5E9); // 매우 연한 초록
  static const Color mediumGreen = Color(0xFF81C784); // 중간 초록
  static const Color darkGreen = Color(0xFF1B5E3F); // 더 진한 초록
  
  // Base Colors
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  
  // Gray Scale
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFE0E0E0);
  static const Color gray300 = Color(0xFFBDBDBD);
  static const Color gray400 = Color(0xFF9E9E9E);
  static const Color gray500 = Color(0xFF757575);
  static const Color gray600 = Color(0xFF616161);
  static const Color gray700 = Color(0xFF424242);
  static const Color gray800 = Color(0xFF303030);
  static const Color gray900 = Color(0xFF212121);
  
  // Accent Colors
  static const Color primaryBlue = Color(0xFF0095F6); // 보조 파란색
  static const Color heartRed = Color(0xFFFF3040); // Like button red
  static const Color notificationBadge = Color(0xFF2D7A4F); // 초록색 배지
  
  // Semantic Colors
  static const Color error = Color(0xFFED4956);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF0095F6);
  
  // Background Colors
  static const Color backgroundPrimary = white;
  static const Color backgroundSecondary = gray50;
  static const Color backgroundTertiary = gray100;
  
  // Text Colors
  static const Color textPrimary = black;
  static const Color textSecondary = gray600;
  static const Color textTertiary = gray400;
  static const Color textOnPrimary = white;
  
  // Border Colors
  static const Color borderLight = gray200;
  static const Color borderMedium = gray300;
  static const Color borderDark = gray400;
  
  // Shadow Colors
  static const Color shadowLight = Color(0x0A000000); // 4% black
  static const Color shadowMedium = Color(0x14000000); // 8% black
  static const Color shadowDark = Color(0x29000000); // 16% black
  
  // Component Specific Colors
  static const Color bottomNavSelected = primaryGreen;
  static const Color bottomNavUnselected = gray400;
  static const Color appBarIconColor = black;
  static const Color floatingActionButton = primaryGreen;
  
  // Removed Colors (연보라색 제거)
  // static const Color purple = Color(0xFF8B5CF6); // REMOVED
  // static const Color lightPurple = Color(0xFFEDE9FE); // REMOVED
  // static const Color greenPrimary = Color(0xFF2D7A4F); // REMOVED - 기존 녹색 테마
}
