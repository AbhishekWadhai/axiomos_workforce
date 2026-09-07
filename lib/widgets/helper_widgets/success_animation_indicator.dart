import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:axiomos_workforce/constants/asset_path.dart';
import 'package:axiomos_workforce/helpers/sixed_boxes.dart';

class SuccessAnimationIndicator extends StatelessWidget {
  final String messageText;
  final VoidCallback buttonAction;
  const SuccessAnimationIndicator({
    super.key,
    this.messageText = "",
    required this.buttonAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Center(
        child: Column(
          children: [
            GestureDetector(
              onTap: buttonAction,
              child: SizedBox(
                height: 250,
                width: 250,
                child: LottieBuilder.asset(Assets.successAnimation),
              ),
            ),
            Text(messageText, style: TextStyle(fontWeight: FontWeight.bold)),
            sb20,
            TextButton(onPressed: buttonAction, child: Text("Continue")),
          ],
        ),
      ),
    );
  }
}
