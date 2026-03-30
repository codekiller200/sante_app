import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const navy = Color(0xFF12304A);
  static const blue = Color(0xFF2E6CF6);
  static const aqua = Color(0xFF31C6D4);
  static const surface = Color(0xFFF5F8FC);
  static const card = Colors.white;
  static const text = Color(0xFF132238);
  static const muted = Color(0xFF708198);
  static const border = Color(0xFFDCE5F0);
  static const success = Color(0xFF1FA971);
  static const warning = Color(0xFFF2A53A);
  static const danger = Color(0xFFE05555);

  static const blue900 = navy;
  static const blue700 = blue;
  static const blue500 = blue;
  static const blue300 = Color(0xFF9BC0FF);
  static const blue100 = Color(0xFFDDEBFF);
  static const blue50 = Color(0xFFF1F6FF);
  static const teal = aqua;
  static const green = success;
  static const orange = warning;
  static const red = danger;
  static const gray900 = text;
  static const gray600 = muted;
  static const gray400 = Color(0xFF94A3B8);
  static const gray200 = border;
  static const gray100 = Color(0xFFF3F6FA);
  static const white = Colors.white;
  static const background = surface;

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, Color(0xFF21528B)],
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blue, aqua],
  );

  static const darkGradient = heroGradient;
}
