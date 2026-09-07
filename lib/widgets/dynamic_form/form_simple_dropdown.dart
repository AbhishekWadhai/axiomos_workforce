import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:axiomos_workforce/controllers/dynamic_form_contoller.dart';
import 'package:axiomos_workforce/model/form_data_model.dart';

Widget buildSimpleDropdown(PageField field, DynamicFormController controller) {
  // Ensure the rx exists before Obx runs
  controller.formData.putIfAbsent(field.headers, () => ''.obs);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        field.title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 6),

      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey),
        ),

        child: Obx(() {
          final selectedValue = controller.formData[field.headers]!.value;

          return DropdownButtonFormField<String>(
            decoration: const InputDecoration(border: InputBorder.none),
            value: selectedValue.isEmpty ? null : selectedValue,

            hint: const Text("Select an option"),
            validator: controller.validateDropdown,

            items:
                field.options?.map((option) {
                  return DropdownMenuItem(value: option, child: Text(option));
                }).toList() ??
                [],

            onChanged: (value) {
              if (value != null) {
                controller.formData[field.headers]!.value = value;
              }
            },
          );
        }),
      ),
    ],
  );
}
