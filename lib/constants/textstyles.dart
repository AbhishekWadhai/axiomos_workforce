import 'package:flutter/material.dart';


class TextStyles {
  static const TextDecoration underline = TextDecoration.underline;
  static const TextDecoration lineThrough = TextDecoration.lineThrough;

  static TextStyle get drawerTextStyle => const TextStyle(
      fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold);

  static TextStyle get appBarTextStyle => TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold , color: Colors.white);
  static TextStyle get appBarSubTextStyle => const TextStyle(
      fontSize: 16, fontWeight: FontWeight.normal, color: Colors.white);

  static TextStyle get chartTitle => TextStyle(
      fontSize: 12, fontWeight: FontWeight.w900);
}
