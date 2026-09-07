import 'package:axiomos_workforce/constants/asset_path.dart';
import 'package:axiomos_workforce/helpers/sixed_boxes.dart';
import 'package:flutter/material.dart';

class CardFb2 extends StatelessWidget {
  final String text;
  final String imageUrl;
  final String subtitle;
  final String totalNo;
  final Function() onPressed;

  const CardFb2({
    required this.text,
    required this.imageUrl,
    required this.subtitle,
    required this.onPressed,
    required this.totalNo,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: 75,
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            image: const DecorationImage(
              opacity: 0.2,
              image: AssetImage(Assets.cardBg), // Use AssetImage here
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.circular(12.5),
            boxShadow: [
              BoxShadow(
                offset: const Offset(10, 20),
                blurRadius: 10,
                spreadRadius: 0,
                color: Colors.grey.withOpacity(.05),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.data_saver_off_rounded, size: 50),
              sb40,
              Text(
                totalNo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),
              sb20,
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
