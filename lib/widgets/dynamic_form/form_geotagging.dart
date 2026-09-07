import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:axiomos_workforce/controllers/dynamic_form_contoller.dart';
import 'package:axiomos_workforce/model/form_data_model.dart';
import 'package:axiomos_workforce/services/location_service.dart';
import 'package:axiomos_workforce/services/shared_preferences.dart';

import 'form_extras.dart';

Widget buildGeolocation(
  PageField field,
  bool isEditable,
  DynamicFormController controller,
) {
  // Ensure the observable exists
  controller.formData.putIfAbsent(field.headers, () => Rx<dynamic>(""));

  // Create a persistent TextEditingController for display
  final textController = TextEditingController();

  return Obx(() {
    final value = controller.formData[field.headers]!.value as String? ?? "";
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (textController.text != value) {
        textController.text = value;
      }
    });
    // keep text field in sync

    double? latitude, longitude;
    final regex = RegExp(r'\(([^,]+),\s*([^)]+)\)');
    final match = regex.firstMatch(value);

    if (match != null) {
      latitude = double.tryParse(match.group(1)!);
      longitude = double.tryParse(match.group(2)!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: textController,
          readOnly: true,
          decoration: kTextFieldDecoration("Location"),
          validator: isEditable ? controller.validateTextField : null,
          onTap: isEditable
              ? () async {
                  if (controller.isOnline.value) {
                    // Online: fetch current location
                    await controller.fetchGeolocation(field.headers);

                    if (latitude != null && longitude != null) {
                      showGeolocationDialog(
                        latitude: latitude,
                        longitude: longitude,
                        onLocationSelected: (newPos) {
                          final newValue =
                              "(${newPos.latitude}, ${newPos.longitude})";
                          controller.formData[field.headers]!.value = newValue;
                        },
                      );
                    }
                  } else {
                    // Offline: show saved locations
                    final savedLocations = await controller.getSavedLocations();
                    if (savedLocations.isEmpty) {
                      Get.snackbar(
                        "No Locations",
                        "No saved locations available offline.",
                      );
                      return;
                    }

                    Get.bottomSheet(
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: ListView(
                          shrinkWrap: true,
                          children: savedLocations.map((loc) {
                            return ListTile(
                              title: Text(loc),
                              onTap: () {
                                controller.formData[field.headers]!.value = loc;
                                Get.back();
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  }
                }
              : null,
        ),
        if (!isEditable)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              "Location is read-only.",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        const SizedBox(height: 10),
      ],
    );
  });
}
