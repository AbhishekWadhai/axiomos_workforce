import 'package:flutter/material.dart';
import 'package:axiomos_workforce/constants/app_strings.dart';
import 'package:axiomos_workforce/controllers/dynamic_form_contoller.dart';
import 'package:axiomos_workforce/model/form_data_model.dart';

import 'form_extras.dart';

Widget buildDefaultField(
  PageField field,
  DynamicFormController controller,
  bool isEdit,
) {
  final dynamic savedValue = controller.formData[field.headers]?.value;

  if (isEdit && field.headers.toLowerCase() == "createdby") {
    return const SizedBox.shrink();
  }

  String displayValue = "";
  String saveValue = "";

  if (isEdit && savedValue != null) {
    if (savedValue is Map) {
      displayValue = savedValue[field.key] ?? "";
      saveValue = savedValue["_id"] ?? "";
      controller.updateFormData(field.headers, savedValue);
    } else if (savedValue is String) {
      // Check if savedValue matches the _id from constants
      String? constantId = Strings.endpointToList[field.endpoint]?["_id"];
      if (constantId != null && constantId == savedValue) {
        displayValue = Strings.endpointToList[field.endpoint]?[field.key] ?? "";
        saveValue = constantId;
      } else {
        displayValue = savedValue;
        saveValue = savedValue;
      }
      controller.updateFormData(field.headers, saveValue);
    }
  } else {
    displayValue = Strings.endpointToList[field.endpoint]?[field.key] ?? "";
    saveValue = Strings.endpointToList[field.endpoint]?["_id"] ?? "";
    controller.updateFormData(field.headers, saveValue);
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
        controller: TextEditingController(text: displayValue),
        decoration: kTextFieldDecoration(""),
        readOnly: true,
      ),
      const SizedBox(height: 10),
    ],
  );
}
