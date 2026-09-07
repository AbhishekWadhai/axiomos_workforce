import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:axiomos_workforce/constants/app_strings.dart';
import 'package:axiomos_workforce/services/api_services.dart';
import 'package:axiomos_workforce/services/shared_preferences.dart';

Future<void> loadDropdownData() async {
  final endpoints = <String>[
    'projects',
    'users',
    'contractors',
    'labour-details',
    'mobilisation-plans',
    'labour-categories',
    'zones',
    'roles',
    'teams',
    'daily-interactions',
  ];

  final connectivityResult = await Connectivity().checkConnectivity();

  final isOnline = connectivityResult.any(
    (result) => result != ConnectivityResult.none,
  );

  final apiService = ApiService();
  final prefsService = SharedPrefService();

  final requests = endpoints.map((endpoint) async {
    List<dynamic> parsedData = [];

    try {
      if (isOnline) {
        final response = await apiService.getRequest(endpoint);

        if (response is List) {
          parsedData = response;
        } else if (response is Map) {
          parsedData = response['data'] is List ? response['data'] : [];
        }

        await prefsService.saveDropdownListToPrefs(endpoint, parsedData);

        print('🟢 [$endpoint] Fetched ${parsedData.length} items');
      } else {
        parsedData =
            await prefsService.getDropdownListFromPrefs(endpoint) ?? [];

        print('📦 [$endpoint] Loaded ${parsedData.length} cached items');
      }

      // Dynamic assignment
      Strings.endpointToList[endpoint] = parsedData;
    } catch (error, stackTrace) {
      print('⚠️ [$endpoint] Error: $error');

      // Try cache if API failed
      if (isOnline) {
        try {
          parsedData =
              await prefsService.getDropdownListFromPrefs(endpoint) ?? [];

          Strings.endpointToList[endpoint] = parsedData;

          print('📦 [$endpoint] Fallback cache: ${parsedData.length} items');
        } catch (cacheError) {
          print('❌ [$endpoint] Cache fallback failed: $cacheError');
        }
      }

      print(stackTrace);
    }
  }).toList();

  await Future.wait(requests);

  print(
    '✅ Dropdown data loaded from '
    '${isOnline ? 'API' : 'Cache'}',
  );
}
