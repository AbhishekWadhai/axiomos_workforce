import 'package:flutter/material.dart';

class FlexibleText extends StatelessWidget {
  final String text;
  final double baseFontSize; // Base size for the font
  final TextStyle? style; // Optional TextStyle

  const FlexibleText({
    Key? key,
    required this.text,
    this.baseFontSize = 14.0,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate dynamic font size
    double screenWidth = MediaQuery.of(context).size.width;
    double fontSize = screenWidth *
        (baseFontSize /
            375); // Scale based on base font size (375 is a reference width)

    return Text(
      text,
      style:
          style?.copyWith(fontSize: fontSize) ?? TextStyle(fontSize: fontSize),
    );
  }
}

String capitalizeFirstLetter(String? text) {
  if (text == null || text.isEmpty) return '';
  return text[0].toUpperCase() + text.substring(1);
}
