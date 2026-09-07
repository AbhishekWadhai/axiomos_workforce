import 'package:flutter/material.dart';
import 'package:axiomos_workforce/constants/colors.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback onTap;
  final String text;
  final double elevation;
  final double borderRadius;
  final double width;
  final double height;
  final List<Color> gradientColors;
  final Widget? icon;
  final TextStyle textStyle;
  final Color shadowColor;

  const GradientButton({
    Key? key,
    required this.onTap,
    required this.text,
    this.elevation = 6.0,
    this.borderRadius = 12.0,
    this.width = 150,
    this.height = 50,
    this.gradientColors = const [AppColors.appMainMid, AppColors.appMainLight],
    this.icon,
    this.textStyle = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    this.shadowColor = Colors.black54,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          // boxShadow: [
          //   BoxShadow(
          //     color: shadowColor.withOpacity(0.6),
          //     offset: Offset(elevation, elevation), // Shadow for 3D effect
          //     blurRadius: elevation * 2,
          //   ),
          //   BoxShadow(
          //     color: Colors.white.withOpacity(0.3),
          //     offset:
          //         Offset(-elevation / 2, -elevation / 2), // Light reflection
          //     blurRadius: elevation,
          //   ),
          // ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 8)],
            Text(text, style: textStyle),
          ],
        ),
      ),
    );
  }
}
