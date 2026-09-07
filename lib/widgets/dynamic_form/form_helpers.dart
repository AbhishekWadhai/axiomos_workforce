import 'package:get/get.dart';

dynamic normalizeValue(dynamic value) {
  if (value is Rx) return normalizeValue(value.value);

  if (value is List) {
    return value.map(normalizeValue).toList();
  }

  if (value is Map) {
    return value.map((k, v) => MapEntry(k, normalizeValue(v)));
  }

  return value; // Normal value (String, int, bool…)
}

Map<String, dynamic> cleanFormData(Map<String, Rx<dynamic>> formData) {
  return formData.map((key, value) {
    return MapEntry(key, normalizeValue(value));
  });
}
