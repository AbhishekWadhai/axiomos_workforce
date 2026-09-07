import 'package:axiomos_workforce/constants/colors.dart';
import 'package:axiomos_workforce/views/components/buttons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Widget buildHeader(String title) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
    child: Row(
      children: [
        roundButton(icon: Icons.arrow_back_rounded, onTap: () => Get.back()),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        roundButton(icon: Icons.more_vert_rounded, onTap: () {}),
      ],
    ),
  );
}
