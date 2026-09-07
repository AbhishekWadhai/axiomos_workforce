import 'package:axiomos_workforce/constants/colors.dart';
import 'package:flutter/material.dart';

Widget roundButton({required IconData icon, required VoidCallback onTap}) {
  return Material(
    color: Colors.white,
    elevation: 0,
    shadowColor: Colors.black.withOpacity(.05),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 52,
        height: 52,
        child: Icon(icon, size: 26, color: AppColors.textPrimary),
      ),
    ),
  );
}
