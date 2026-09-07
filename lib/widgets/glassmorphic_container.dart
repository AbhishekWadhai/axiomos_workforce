import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphicContainer extends StatelessWidget {
  final Widget child;

  // Layout
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double width;
  final double height;
  final Alignment alignment;

  // Glass effect
  final double blur;
  final double opacity;
  final Gradient? gradient;

  // Border & styling
  final double borderRadius;
  // final double borderWidth;
  // final double borderOpacity;
  // final Color borderColor;
  final BoxBorder? border;

  // Shadow (optional depth)
  final List<BoxShadow>? boxShadow;

  // Performance toggle
  final bool enableBlur;

  const GlassmorphicContainer({
    super.key,
    required this.child,

    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.width = double.infinity,
    this.height = 0,
    this.alignment = Alignment.center,
    this.border,
    this.blur = 10,
    this.opacity = 0.1,
    this.gradient,

    this.borderRadius = 16,
    // this.borderWidth = 1,
    // this.borderOpacity = 0.2,
    // this.borderColor = Colors.white,
    this.boxShadow,

    this.enableBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height == 0 ? null : height;

    Widget container = Container(
      width: width,
      height: effectiveHeight,
      margin: margin,
      alignment: alignment,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient:
            gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(opacity + 0.05),
                Colors.white.withOpacity(opacity),
              ],
            ),
        border: border,
        boxShadow:
            boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
      ),
      child: child,
    );

    // If blur disabled → return simple container
    if (!enableBlur) {
      return container;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: container,
      ),
    );
  }
}
