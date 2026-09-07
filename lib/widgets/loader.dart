import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieLoader extends StatelessWidget {
  final double size;

  const LottieLoader({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: size,
        width: size,
        child: Lottie.asset("lib/assets/animations_josn/Loading.json",
            repeat: true,
            reverse: false,
            animate: true,
            frameRate: FrameRate(60)),
      ),
    );
  }
}
