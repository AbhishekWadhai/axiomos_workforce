import 'package:flutter/material.dart';

class AppColors {
  static Color backgroundColor = Colors.grey.shade100;
  static const Color appMainDark = Color(0xFF121C2D);
  static const Color appMainMid = Color(0xFF1A2F4B);
  static const Color appMainLight = Color(0xFF0F3D54);

  static Color? scaffoldColor = Color.fromARGB(255, 238, 246, 255);
  static const LinearGradient appMainGradient = LinearGradient(
    colors: [appMainDark, appMainMid],
    begin: Alignment.topCenter,
    end: Alignment.bottomLeft,
  );
  static const Color primary = Color(0xFF5146E5);

  static const Color background = Color(0xFFF8F9FD);

  static const Color textPrimary = Color(0xFF11152D);

  static const Color textSecondary = Color(0xFF707791);

  static const Color green = Color(0xFF00A88A);

  static const Color red = Color(0xFFE45757);

  static const Color orange = Color(0xFFE58A2B);
}
