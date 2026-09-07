import 'package:intl/intl.dart';

class Formatters {
  String toTitleCase(String input) {
    RegExp exp = RegExp(r'(?<=[a-z])[A-Z]');
    return input
        .replaceAllMapped(exp, (Match m) => ' ${m.group(0)}')
        .split(' ')
        .map((word) {
          return word[0].toUpperCase() + word.substring(1);
        })
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

class IndianDateFormatters {
  static String formatDate1(DateTime date) => DateFormat('dd-MM').format(date);
  static String formatDate2(DateTime date) =>
      DateFormat('dd/MM/yyyy').format(date);
  static String formatDate3(DateTime date) =>
      DateFormat('dd MMM yyyy').format(date);
  static String formatDate4(DateTime date) =>
      DateFormat('EEEE, dd MMMM yyyy').format(date);
  static String formatISO(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);
  static String formatWithTime(DateTime date) =>
      DateFormat('dd-MM-yyyy hh:mm a').format(date);

  // Custom Formatter
  static String formatCustom(DateTime date, String pattern) =>
      DateFormat(pattern).format(date);

  static String formatDateFromString(dynamic rawDate) {
    if (rawDate == null) return '-';

    try {
      final DateTime parsedDate = DateTime.parse(rawDate.toString());
      return DateFormat('dd-MM-yyyy').format(parsedDate);
    } catch (e) {
      return '-';
    }
  }
}

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year &&
      a.month == b.month &&
      a.day == b.day &&
      a.day == DateTime.now().day;
}

String parseTimeToIsoString(String time) {
  final parsedTime = DateFormat('h:mm a').parse(time);

  final now = DateTime.now();

  final dateTime = DateTime(
    now.year,
    now.month,
    now.day,
    parsedTime.hour,
    parsedTime.minute,
  );

  return dateTime.toUtc().toIso8601String();
}
