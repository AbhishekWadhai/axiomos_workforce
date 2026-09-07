import 'package:axiomos_workforce/controllers/dynamic_form_contoller.dart';
import 'package:axiomos_workforce/model/form_data_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Widget buildRadio(
  PageField field,
  bool isEditable,
  DynamicFormController controller,
) {
  // Ensure observable exists
  controller.formData.putIfAbsent(field.headers, () => Rx<dynamic>(""));

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        field.title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),
      Obx(() {
        // Always access .value for reactive updates
        final selectedValue =
            controller.formData[field.headers]!.value as String?;
        final List<String> options = field.options ?? [];

        return Row(
          children: options.map((option) {
            return Expanded(
              child: RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: selectedValue,
                onChanged: isEditable
                    ? (String? newValue) {
                        if (newValue != null) {
                          controller.formData[field.headers]!.value = newValue;
                          // Optionally call a helper in your controller:
                          // controller.updateRadioSelection(field.headers, newValue);
                        }
                      }
                    : null, // Disable if not editable
                activeColor: isEditable ? null : Colors.grey,
                controlAffinity: ListTileControlAffinity.trailing,
              ),
            );
          }).toList(),
        );
      }),
      const SizedBox(height: 10),
    ],
  );
}
