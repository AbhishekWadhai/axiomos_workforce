import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:axiomos_workforce/constants/app_strings.dart';
import 'package:axiomos_workforce/services/api_services.dart';

const List<String> dateRangeEndpoints = [
  "workpermit",
  "meeting",
  "specific",
  "uauc",
  "induction",
  "safetyreport",
];

Future<void> loadDateRangeData({
  required String from,
  required String to,
  Map<String, dynamic>? commonParams,
}) async {
  // Check connectivity once
  final connectivityResultList = await Connectivity().checkConnectivity();
  final bool isOnline = connectivityResultList.any(
    (r) => r != ConnectivityResult.none,
  );

  if (!isOnline) {
    print("❌ Offline — date range fetch skipped");
    return;
  }

  List<Future<void>> requests = dateRangeEndpoints.map((endpoint) async {
    try {
      final queryParams = {
        "from": from,
        "to": to,
        if (commonParams != null) ...commonParams,
      };

      final queryString = queryParams.entries
          .map((e) => "${e.key}=${e.value}")
          .join("&");

      final apiUrl = "$endpoint?$queryString";

      final response = await ApiService().getRequest(apiUrl);

      List<dynamic> parsedData = [];

      if (response is List) {
        parsedData = response;
      } else if (response is Map && response["data"] != null) {
        parsedData = response["data"];
      }

      // 🔹 Assign to memory (same pattern as loadDropdownData)
      switch (endpoint) {
        case "workpermit":
          Strings.workpermit = parsedData
              .where(
                (e) =>
                    e['project']['_id'] ==
                    Strings.endpointToList['project']['_id'],
              )
              .toList();
          break;

        case "meeting":
          Strings.meetings = parsedData
              .where(
                (e) =>
                    e['project']['_id'] ==
                    Strings.endpointToList['project']['_id'],
              )
              .toList();
          break;

        case "specific":
          Strings.specific = parsedData
              .where(
                (e) =>
                    e['project']['_id'] ==
                    Strings.endpointToList['project']['_id'],
              )
              .toList();
          break;

        case "uauc":
          Strings.uauc = parsedData
              .where(
                (e) =>
                    e['project']['_id'] ==
                    Strings.endpointToList['project']['_id'],
              )
              .toList();
          break;

        case "induction":
          Strings.induction = parsedData
              .where(
                (e) =>
                    e['project']['_id'] ==
                    Strings.endpointToList['project']['_id'],
              )
              .toList();
          break;

        case "safetyreport":
          Strings.safetyreport = parsedData
              .where(
                (e) =>
                    e['project']['_id'] ==
                    Strings.endpointToList['project']['_id'],
              )
              .toList();
          break;
      }

      print("🟢 [$endpoint] Loaded ${parsedData.length} items");
    } catch (e) {
      print("⚠️ [$endpoint] Failed to load: $e");
    }
  }).toList();

  await Future.wait(requests);

  print("✅ All date-range data loaded ($from → $to)");
}
