import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:axiomos_workforce/services/shared_preferences.dart';

class SavedFormDataController extends GetxController {
  String formKey = "savedFormDataKey";
  RxList<Map<String, dynamic>> savedFormData = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> offlineFormsData = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchSavedFormData();
    fetchOffline();
  }

  fetchOffline() async {
    final offlineData = await SharedPrefService().getStringList("offlineForms");
    if (offlineData != null) {
      offlineFormsData.value = offlineData
          .map((e) => jsonDecode(e) as Map<String, dynamic>)
          .toList();
    }
  }

  Future<String> saveFormData(
    String date,
    String time,
    String moduleName,
    Map<String, dynamic> formData,
  ) async {
    print(jsonEncode(formData["safetyMeasuresTaken"]));

    String id = generateFormId(moduleName, date, time);
    print("Saving Form: $id");

    Map<String, dynamic> entry = {
      "id": id,
      "date": date,
      "time": time,
      "module": moduleName,
      "formData": formData,
    };

    // Optional: Check if an entry with same ID exists, replace it
    int existingIndex = savedFormData.indexWhere((e) => e['id'] == id);
    if (existingIndex != -1) {
      savedFormData[existingIndex] = entry;
    } else {
      savedFormData.add(entry);
    }

    await SharedPrefService().saveString(formKey, jsonEncode(savedFormData));
    print("Form data saved with ID: $id");
    return id;
  }

  Future<void> fetchSavedFormData() async {
    String? fetchedFormData = await SharedPrefService().getString(formKey);

    if (fetchedFormData != null && fetchedFormData.isNotEmpty) {
      try {
        List<dynamic> decodedList = jsonDecode(fetchedFormData);
        List<Map<String, dynamic>> typedList = decodedList
            .cast<Map<String, dynamic>>();
        savedFormData.assignAll(typedList);
        print("Fetched ${savedFormData.length} items");
      } catch (e) {
        print("Error decoding saved form data: $e");
      }
    } else {
      savedFormData.clear();
    }
  }

  //////////Id Generation--------------------------------------------------

  String generateFormId(String moduleName, String dateStr, String timeStr) {
    DateTime date = DateTime.parse(dateStr); // "2025-07-09 00:00:00.000"

    // Extract parts
    String yy = date.year.toString().substring(2); // "25"
    String mm = date.month.toString().padLeft(2, '0'); // "07"
    String dd = date.day.toString().padLeft(2, '0'); // "09"

    // Convert time string like "6:02 PM" to 24-hr format
    TimeOfDay time = parseTime(timeStr); // Custom method below
    String hh = time.hour.toString().padLeft(2, '0'); // "18"
    String min = time.minute.toString().padLeft(2, '0'); // "02"

    return "$moduleName$yy$mm$dd$hh$min"; // e.g. "workpermit2507091802"
  }

  TimeOfDay parseTime(String timeStr) {
    // Expects "6:02 PM"
    final format = TimeOfDayFormat.h_colon_mm_space_a;
    final timeParts = timeStr
        .toLowerCase()
        .replaceAll(" ", "")
        .split(RegExp(r'[:apm]'));

    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);
    bool isPM = timeStr.toLowerCase().contains("pm");

    if (isPM && hour < 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;

    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> removeFormData(String id) async {
    int index = savedFormData.indexWhere((e) => e['id'] == id);

    if (index != -1) {
      savedFormData.removeAt(index); // Remove from list
      await SharedPrefService().saveString(
        formKey,
        jsonEncode(savedFormData),
      ); // Update storage
      print("Form data with ID $id removed.");
    } else {
      print("No form data found with ID $id.");
    }
  }

  Future<void> clearAllFormData() async {
    savedFormData.clear();
    await SharedPrefService().remove(formKey); // Remove from SharedPrefs
    print("All saved form data cleared.");
  }
}
