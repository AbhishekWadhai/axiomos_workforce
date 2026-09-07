import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CustomAlertDialog extends StatelessWidget {
  final Widget? visual; // Icon, Image, or Lottie
  final String title;
  final String description;
  final List<CustomDialogButton> buttons;

  const CustomAlertDialog({
    super.key,
    this.visual,
    required this.title,
    required this.description,
    required this.buttons,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (visual != null) ...[
            visual!,
            const SizedBox(width: 10),
          ],
          Expanded(child: Text(title, style: const TextStyle(fontSize: 18))),
        ],
      ),
      content: Text(description, style: const TextStyle(fontSize: 15)),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      actions: buttons.map((button) {
        return button.isPrimary
            ? ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: button.color ?? Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: button.onPressed,
                child: Text(button.label),
              )
            : TextButton(
                onPressed: button.onPressed,
                child: Text(button.label),
              );
      }).toList(),
    );
  }
}

class CustomDialogButton {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final Color? color;

  CustomDialogButton({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.color,
  });
}
