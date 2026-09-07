import 'package:flutter/material.dart';

class IllustrationFb4 extends StatelessWidget {
  const IllustrationFb4({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 202,
      decoration: const BoxDecoration(
          image: DecorationImage(
              fit: BoxFit.contain,
              image: NetworkImage(
                  "https://firebasestorage.googleapis.com/v0/b/flutterbricks-public.appspot.com/o/finance_app_2%2Fillustrations%2FIllustration4.png?alt=media&token=df4e85fc-b46f-45da-bda9-e8264db20d11"))),
    );
  }
}
