import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:axiomos_workforce/services/connection_service.dart';
import 'package:uuid/uuid.dart';

class OfflineFormQueue {
  static const _key = 'offlineForms';

  static Future<List<Map<String, dynamic>>> getQueuedForms() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(json));
  }

  static Future<void> addFormToQueue(Map<String, dynamic> form) async {
    final forms = await getQueuedForms();
    forms.add(form);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(forms));
  }

  static Future<void> removeForm(Map<String, dynamic> form) async {
    final forms = await getQueuedForms();
    forms.removeWhere((f) => f['formId'] == form['formId']);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(forms));
  }
}

class FormSubmitter {
  static Future<void> submitFormWithImages({
    required Map<String, dynamic> formData,
    required List<String> imagePaths,
  }) async {
    final isOnline = await ConnectivityService.to.checkConnection();
    final formId = const Uuid().v4();

    if (!isOnline) {
      await OfflineFormQueue.addFormToQueue({
        "formId": formId,
        "timestamp": DateTime.now().toIso8601String(),
        "fields": formData,
        "imagePaths": imagePaths,
        "synced": false,
      });
      Get.snackbar("Saved Offline", "Will auto-submit when online");
      return;
    }

    await uploadAndSubmit(formData, imagePaths);
  }

  static Future<void> uploadAndSubmit(
    Map<String, dynamic> fields,
    List<String> imagePaths,
  ) async {
    List<String> uploadedUrls = [];

    for (final path in imagePaths) {
      final file = File(path);
      if (file.existsSync()) {
        //final url = await ApiService.uploadImage(file); // define this
        // uploadedUrls.add(url);
      }
    }

    final payload = {...fields, "images": uploadedUrls};

    //await ApiService.submitForm(payload); // define this too
  }
}

// Future<void> syncOfflineForms() async {
//   final prefs = await SharedPreferences.getInstance();
//   List<String> offlineForms = prefs.getStringList("offlineForms") ?? [];

//   for (String formJson in offlineForms) {
//     try {
//       final Map<String, dynamic> formData = jsonDecode(formJson);
//       await uploadFilesInForm(formData); // ← reuse from earlier
//       await ApiService().postRequest(formData["endpoint"], formData);
//     } catch (e) {
//       Get.log("Failed to sync form: $e");
//     }
//   }

//   // Clear offline storage if successful
//   await prefs.remove("offlineForms");

//   Get.snackbar(
//     "Synced",
//     "Offline forms have been submitted",
//     backgroundColor: Colors.green,
//     colorText: Colors.white,
//   );
// }
