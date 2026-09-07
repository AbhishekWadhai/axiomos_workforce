import 'package:flutter/material.dart';

Color getRiskColor(String riskLevel) {
  switch (riskLevel) {
    case 'Low':
      return Colors.green;
    case 'Medium':
      return Colors.amber;
    case 'High':
      return Colors.orange;
    case 'Critical':
      return Colors.red;
    default:
      return Colors.grey; // fallback color
  }
}

String calculateActionCompletionTime(
  Map<String, dynamic>? matchedValue,
  DateTime? createdAt,
) {
  if (matchedValue == null || matchedValue.isEmpty || createdAt == null) {
    return "-";
  }

  // Parse alert timeline (in hours)
  final int hours = int.tryParse(matchedValue['alertTimeline'] ?? '0') ?? 0;

  // Calculate deadline
  final DateTime deadline = createdAt.add(Duration(hours: hours));

  // Format deadline
  return "${deadline.day.toString().padLeft(2, '0')}/"
      "${deadline.month.toString().padLeft(2, '0')}/"
      "${deadline.year} at "
      "${deadline.hour.toString().padLeft(2, '0')}:"
      "${deadline.minute.toString().padLeft(2, '0')}";
}
