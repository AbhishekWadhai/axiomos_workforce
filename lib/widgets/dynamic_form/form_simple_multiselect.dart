import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:axiomos_workforce/controllers/dynamic_form_contoller.dart';
import 'package:axiomos_workforce/model/form_data_model.dart';

Widget buildSimpleMultiSelect(
  PageField field,
  DynamicFormController controller,
  bool isEditable,
) {
  // Ensure the observable exists before Obx runs
  controller.formData.putIfAbsent(
    field.headers,
    () => Rx<dynamic>(<String>[].obs),
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        field.title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),
      Obx(() {
        final selectedValues =
            (controller.formData[field.headers]?.value as List?)
                ?.map((e) => e.toString())
                .toList()
                .obs ??
            <String>[].obs;

        return MultiSelectDialogField<String>(
          validator: isEditable ? controller.validateMultiSelect : null,
          dialogHeight: 300,
          items: (field.options ?? [])
              .map((option) => MultiSelectItem<String>(option, option))
              .toList(),
          initialValue: selectedValues.toList(),
          onConfirm: (List<String> values) {
            selectedValues.assignAll(values);
            controller.updateFormData(
              field.headers,
              selectedValues,
            ); // updates reactively
          },
          title: Text("Select ${field.title}"),
          buttonText: Text("Select ${field.title}"),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    ],
  );
}
