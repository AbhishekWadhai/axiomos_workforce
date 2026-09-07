import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showSuccessDialog({
  String title = "Success",
  String message = "Operation completed successfully",
  VoidCallback? onOkPressed,
}) {
  Get.dialog(
    AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Colors.white,
      title: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            Get.back(); // Close the dialog
            if (onOkPressed != null) {
              onOkPressed(); // Call the passed method
            }
            Get.back(result: true); // Pop page with result
          },
          child: const Text(
            "OK",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
    barrierDismissible: false,
  );
}

/// A reusable method to show confirmation dialog
Future<bool> showConfirmationDialog({
  required BuildContext context,
  String title = "Confirmation",
  String content = "Are you sure?",
  String confirmText = "Yes",
  String cancelText = "No",
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false, // User must tap a button
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      );
    },
  );
  return result ?? false; // If dismissed, return false
}
void showRiskDialog({
  required RxString riskLevel, // e.g. RxString("High")
  required String formattedDeadline, // already formatted deadline string
  required Map<String, dynamic> matchedValue, // contains 'severity' etc.
  required int timelineHours,
}) {
  Color _colorForRisk(String level) {
    final l = level.toLowerCase();
    if (l.contains('critical')) return Colors.red.shade600;
    if (l.contains('high')) return Colors.orange.shade600;
    if (l.contains('medium')) return Colors.yellow.shade600;
    if (l.contains('low')) return Colors.green.shade600;
    return Colors.blueGrey;
  }

  final theme = Get.theme;
  final headerColor = _colorForRisk(riskLevel.value);

  Get.defaultDialog(
    // remove built-in title so we can create a custom header in content
    title: '',
    backgroundColor: Colors.transparent,
    radius: 12,
    barrierDismissible: true,
    contentPadding: const EdgeInsets.all(0),

    // custom content with header + body
    content: Container(
      width: double.infinity,
      // margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header bar with risk indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Risk Level: ${riskLevel.value}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                Text(
                  "You have to complete the given action by $formattedDeadline.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
                const SizedBox(height: 12),

                // metadata chips
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Chip(
                      label: Text(
                        "Severity: ${matchedValue['severity'] ?? 'N/A'}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      backgroundColor: theme.cardColor,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.withOpacity(0.12)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        "Alert Window: $timelineHours hour(s)",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      backgroundColor: theme.cardColor,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.withOpacity(0.12)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // You can place any extra detail here (optional)
                if ((matchedValue['notes'] ?? '').toString().isNotEmpty)
                  Column(
                    children: [
                      Text(
                        matchedValue['notes'].toString(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
              ],
            ),
          ),

          // Buttons row (full-width primary + subtle cancel)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(), // your OK action
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}