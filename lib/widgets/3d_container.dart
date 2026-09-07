import 'package:flutter/material.dart';

class ThreeDContainer extends StatelessWidget {
  final Widget child;

  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  final Color startColor;
  final Color endColor;

  final Color shadowColor;
  final Color glowColor;

  final double elevation;
  final double blur;

  final bool enableGlow;
  final bool enableBorder;

  const ThreeDContainer({
    super.key,
    required this.child,
    this.borderRadius = 30,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.startColor = Colors.white,
    this.endColor = const Color(0xFFF7F8FA),
    this.shadowColor = Colors.black,
    this.glowColor = Colors.white,
    this.elevation = 20,
    this.blur = 40,
    this.enableGlow = true,
    this.enableBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),

        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [startColor, endColor],
        ),

        border: enableBorder
            ? Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5)
            : null,

        boxShadow: [
          // Main floating shadow
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.15),
            blurRadius: blur,
            spreadRadius: 0,
            offset: Offset(0, elevation),
          ),

          // Ambient shadow
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.08),
            blurRadius: blur * 1.5,
            spreadRadius: 0,
            offset: Offset(0, elevation * 1.5),
          ),

          // Top highlight
          // BoxShadow(
          //   color: Colors.white.withValues(alpha: 0.8),
          //   blurRadius: 10,
          //   offset: const Offset(0, -2),
          // ),

          if (enableGlow)
            BoxShadow(
              color: glowColor.withValues(alpha: 0.15),
              blurRadius: 50,
              spreadRadius: 5,
            ),
        ],
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(padding: padding, child: child),
      ),
    );
  }
}
