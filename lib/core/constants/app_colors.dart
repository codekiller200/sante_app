import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Bleus principaux
  static const Color blue900 = Color(0xFF0A2540);
  static const Color blue700 = Color(0xFF1A56DB);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue300 = Color(0xFF93C5FD);
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue50  = Color(0xFFEFF6FF);

  // Accent
  static const Color teal    = Color(0xFF0EA5E9);

  // Statuts
  static const Color green   = Color(0xFF10B981);
  static const Color orange  = Color(0xFFF59E0B);
  static const Color red     = Color(0xFFEF4444);

  // Neutres
  static const Color gray900 = Color(0xFF111827);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color white   = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF0F4F8);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blue700, teal],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blue900, Color(0xFF0D3460)],
  );
}
