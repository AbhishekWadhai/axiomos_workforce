import 'package:axiomos_workforce/services/translation.dart';

class DataFormatter {
  final Map<String, dynamic> fieldKeys = keysForMap;

  String formatCellValue(dynamic value, String key) {
    if (value == null) return '';

    if (value is String) {
      if (_isImageUrl(value)) return "IMAGE:$value";

      try {
        final parsedDate = DateTime.parse(value);
        return _formatDate(parsedDate);
      } catch (_) {
        return value;
      }
    }

    if (value is List) {
      if (value.isEmpty) return '-';

      if (value.first is Map) {
        return value
            .map((item) {
              if (item is Map) {
                if (fieldKeys.containsKey(key)) {
                  final fieldName = fieldKeys[key]!;
                  return item[fieldName]?.toString() ?? '';
                }
                return item.values.join(', ');
              }
              return '';
            })
            .join('; ');
      }

      return value.map((e) => e.toString()).join(', ');
    }

    if (fieldKeys.containsKey(key)) {
      final fieldName = fieldKeys[key]!;
      return value[fieldName]?.toString() ?? '';
    }

    return value.toString();
  }

  bool _isImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.bmp') ||
        lower.endsWith('.webp') ||
        url.contains("drive.google.com");
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.year}';
}
