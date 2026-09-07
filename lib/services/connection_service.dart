import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:axiomos_workforce/services/api_services.dart';
import 'package:axiomos_workforce/services/shared_preferences.dart';

class ConnectivityService extends GetxService {
  static ConnectivityService get to => Get.find();

  final _connectivity = Connectivity();
  final RxBool isConnected = true.obs;
  final RxBool _snackbarVisible = false.obs;
  List<Map<String, dynamic>> offlineFormsData = <Map<String, dynamic>>[];
  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    try {
      // Check initial state
      var result = await _connectivity.checkConnectivity();

      _updateConnectionStatus(result);

      // Listen for changes
      _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    } catch (e) {
      Get.log('Could not check connectivity status: $e', isError: true);
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final connected = results.any(
      (result) => result != ConnectivityResult.none,
    );
    isConnected.value = connected;

    if (!connected) {
      _showOfflineSnackbar();
    } else {
      _dismissOfflineSnackbar();
      // call the method here to sync offline data----------
      syncFormsWithServer();
    }
  }

  void _showOfflineSnackbar() {
    if (!_snackbarVisible.value) {
      _snackbarVisible.value = true;
      Get.showSnackbar(
        GetSnackBar(
          message: "No internet connection",
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.red,
          margin: const EdgeInsets.all(8),
          borderRadius: 8,
          snackPosition: SnackPosition.TOP,
          onTap: (_) {},
        ),
      );
    }
  }

  void _dismissOfflineSnackbar() {
    if (_snackbarVisible.value) {
      Get.closeAllSnackbars();
      _snackbarVisible.value = false;
      Get.showSnackbar(
        GetSnackBar(
          title: "Back online",
          message: "Syncing Data",
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.green,
          margin: const EdgeInsets.all(8),
          borderRadius: 8,
          snackPosition: SnackPosition.TOP,
          onTap: (_) {},
        ),
      );
    }
  }

  // Helper method to check connectivity before API calls
  Future<bool> checkConnection() async {
    if (isConnected.value) return true;

    // Double check current status
    var result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);

    return isConnected.value;
  }

  Future<void> syncFormsWithServer() async {
    print("Starting offline forms sync");
    final offlineData = await SharedPrefService().getStringList("offlineForms");

    if (offlineData == null || offlineData.isEmpty) {
      print("No offline forms found to sync");
      return;
    }

    // Parse all stored form data
    List<Map<String, dynamic>> offlineFormsData = offlineData
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();

    print("Loaded ${offlineFormsData.length} offline forms for sync");
    List<String> successfulForms = [];
    List<Map<String, dynamic>> syncLogs = [];

    for (final form in offlineFormsData) {
      final formData = Map<String, dynamic>.from(form);
      final String? formId = formData['formId'];
      final String? endpoint = formData['endpoint'];

      if (formId == null || endpoint == null) {
        print("Skipping form - missing formId or endpoint");
        continue;
      }

      try {
        print("Processing form $formId");

        // Upload any files in the form
        await uploadFilesInForm(formData);

        // Submit the form to the API
        try {
          final response = await ApiService().postRequest(endpoint, formData);

          if (response != null && (response == 200 || response == 201)) {
            // Record successful sync log
            syncLogs.add({
              'formId': formId,
              'endpoint': endpoint,
              'timestamp': DateTime.now().toIso8601String(),
              'status': 'success',
              'response': response,
              'data': formData, // Include the full form data if needed
            });

            successfulForms.add(formId);
            print("✅ Successfully synced form $formId");
          } else {
            syncLogs.add({
              'formId': formId,
              'endpoint': endpoint,
              'timestamp': DateTime.now().toIso8601String(),
              'status': 'failed',
              'error': 'Invalid response: $response',
              'data': formData,
            });
            print(
              "❌ Failed to sync form $formId - invalid response: $response",
            );
          }
        } catch (e) {
          syncLogs.add({
            'formId': formId,
            'endpoint': endpoint,
            'timestamp': DateTime.now().toIso8601String(),
            'status': 'failed',
            'error': e.toString(),
            'data': formData,
          });
          print("❌ API Error for form $formId: $e");

          Get.snackbar(
            "Error",
            "Error submitting form $formId",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } catch (e) {
        syncLogs.add({
          'formId': formId,
          'endpoint': endpoint,
          'timestamp': DateTime.now().toIso8601String(),
          'status': 'failed',
          'error': e.toString(),
          'data': formData,
        });
        print("❌ Processing Error for form $formId: $e");
      }
    }

    // Save sync logs (you can implement this method)
    if (syncLogs.isNotEmpty) {
      await _saveSyncLogs(syncLogs);
    }

    if (successfulForms.isNotEmpty) {
      // Filter out successfully submitted forms
      List<String> remainingForms = offlineFormsData
          .where((form) => !successfulForms.contains(form['formId']))
          .map((form) => jsonEncode(form))
          .toList();

      await SharedPrefService().saveStringList("offlineForms", remainingForms);

      Get.snackbar(
        "Sync Complete",
        "${successfulForms.length} forms submitted successfully",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      print(
        "Sync complete - ${successfulForms.length} forms successfully synced",
      );
    } else {
      print("Sync complete - no forms were successfully synced");
    }
  }

  // Example method to save sync logs
  Future<void> _saveSyncLogs(List<Map<String, dynamic>> logs) async {
    // Implement your log saving logic here
    // This could save to SharedPreferences, a local database, or send to a logging endpoint
    final existingLogs =
        await SharedPrefService().getStringList("syncLogs") ?? [];
    final newLogs = logs.map((log) => jsonEncode(log)).toList();
    await SharedPrefService().saveStringList("syncLogs", [
      ...existingLogs,
      ...newLogs,
    ]);
  }

  Future<bool> uploadFilesInForm(
    Map<String, dynamic> data, {
    String? endpoint,
  }) async {
    // Use provided endpoint or try to get from data
    final String? baseEndpoint = endpoint ?? data['endpoint'] as String?;
    if (baseEndpoint == null) {
      print("❌ Base endpoint is null");
      return false;
    }

    bool success = true;

    for (var key in data.keys) {
      var value = data[key];
      if (value == null) continue;

      // Case 1: Direct file path
      if (value is String) {
        try {
          if (value.contains('/') &&
              !value.startsWith('http') &&
              File(value).existsSync()) {
            print("📤 Uploading file for key [$key] from path $value");
            String uploadedUrl = await ApiService.uploadImage(
              File(value),
              baseEndpoint,
              false,
            );
            print("✅ Uploaded URL: $uploadedUrl");
            data[key] = uploadedUrl;
          }
        } catch (e) {
          print("❌ Error uploading file for key [$key]: $e");
          success = false;
        }
      }
      // Case 2: Nested object - pass down the baseEndpoint
      else if (value is Map<String, dynamic>) {
        bool nestedSuccess = await uploadFilesInForm(
          value,
          endpoint: baseEndpoint,
        );
        if (!nestedSuccess) success = false;
      }
      // Case 3: Array of items
      else if (value is List) {
        for (int i = 0; i < value.length; i++) {
          var item = value[i];
          if (item == null) continue;

          if (item is Map<String, dynamic>) {
            // Pass the baseEndpoint to nested objects
            bool itemSuccess = await uploadFilesInForm(
              item,
              endpoint: baseEndpoint,
            );
            if (!itemSuccess) success = false;
          } else if (item is String) {
            try {
              if (item.contains('/') &&
                  !item.startsWith('http') &&
                  File(item).existsSync()) {
                print("📤 Uploading file in list [$key][$i] from path $item");
                String uploadedUrl = await ApiService.uploadImage(
                  File(item),
                  baseEndpoint,
                  false,
                );
                value[i] = uploadedUrl;
              }
            } catch (e) {
              print("❌ Error uploading file in list [$key][$i]: $e");
              success = false;
            }
          }
        }
      }
    }

    return success;
  }
}



  // Future<void> syncFormsWithServer() async {
  //   final SharedPreferences prefs = await SharedPreferences.getInstance();
  //   final offlineData = prefs.getStringList("offlineForms");

  //   if (offlineData == null || offlineData.isEmpty) return;

  //   // Parse all stored form data
  //   List<Map<String, dynamic>> offlineFormsData =
  //       offlineData.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

  //   List<String> successfulForms = [];

  //   for (final form in offlineFormsData) {
  //     final formData = Map<String, dynamic>.from(form);
  //     final String? formId = formData['formId'];
  //     final String? endpoint = formData['endpoint'];

  //     if (formId == null || endpoint == null) continue;

  //     try {
  //       // Upload file paths inside formData, converting them to URLs
  //       await uploadFilesInForm(formData);

  //       // Submit the form to the API
  //       await ApiService().postRequest(endpoint, formData);

  //       // Track successful form IDs
  //       successfulForms.add(formId);
  //     } catch (e) {
  //       Get.log("❌ Failed to sync form $formId: $e", isError: true);
  //     }
  //   }

  //   if (successfulForms.isNotEmpty) {
  //     // Filter out successfully submitted forms
  //     List<String> remainingForms = offlineFormsData
  //         .where((form) => !successfulForms.contains(form['formId']))
  //         .map((form) => jsonEncode(form))
  //         .toList();

  //     await prefs.setStringList("offlineForms", remainingForms);

  //     Get.snackbar(
  //       "Sync Complete",
  //       "${successfulForms.length} forms submitted successfully",
  //       backgroundColor: Colors.green,
  //       colorText: Colors.white,
  //     );
  //   }
  // }