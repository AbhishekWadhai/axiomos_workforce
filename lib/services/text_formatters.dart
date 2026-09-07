import 'dart:convert';

class TextFormatters {
String toTitleCase(String input) {
  if (input.trim().isEmpty) return input;

  RegExp exp = RegExp(r'(?<=[a-z])[A-Z]');
  return input
      .replaceAllMapped(exp, (Match m) => ' ${m.group(0)}')
      .trim()
      .split(RegExp(r'\s+')) // ✅ handles multiple spaces
      .map((word) =>
          word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

  String toCamelCase(String input) {
    List<String> words = input.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return '';

    String camelCaseString = words.first.toLowerCase();
    for (int i = 1; i < words.length; i++) {
      camelCaseString +=
          words[i][0].toUpperCase() + words[i].substring(1).toLowerCase();
    }
    return camelCaseString;
  }
}

void printLargeJson(dynamic jsonData) {
  const encoder = JsonEncoder.withIndent('  ');
  final prettyJson = encoder.convert(jsonData);

  // Split into chunks of 800 characters
  final pattern = RegExp('.{1,800}');
  pattern.allMatches(prettyJson).forEach((match) {
    print(match.group(0));
  });
}
