import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:axiomos_workforce/constants/app_strings.dart';
import 'package:axiomos_workforce/controllers/dynamic_form_contoller.dart';
import 'package:axiomos_workforce/model/form_data_model.dart';

Obx buildSwitch(
  PageField field,
  DynamicFormController controller,
  bool isEditable,
) {
  // Ensure observable exists
  controller.formData.putIfAbsent(field.headers, () => Rx<bool>(false));

  return Obx(() {
    // Access the current value reactively
    final bool isSwitched = controller.formData[field.headers]!.value as bool;

    // Determine if the switch should be editable
    final bool switchEditable =
        isEditable &&
        (
        // CASE 1: List → check if current user exists in list
        (controller.formData[field.endpoint] is List &&
                (controller.formData[field.endpoint] as List).any((item) {
                  if (item is String) return item == Strings.userName;
                  if (item is Map<String, dynamic>)
                    return item.containsValue(Strings.userName);
                  return false;
                })) ||
            // CASE 2: Bool → Treat true as allowed, false as not
            (controller.formData[field.endpoint] is bool &&
                controller.formData[field.endpoint] == true));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SwitchListTile(
          title: Text(field.title),
          value: isSwitched,
          onChanged: switchEditable
              ? (bool newValue) {
                  controller.formData[field.headers]!.value = newValue;
                  // Optionally, you can call a controller helper:
                  // controller.updateSwitchSelection(field.headers, newValue);
                }
              : null, // Disable if not editable
          activeColor: isEditable ? null : Colors.grey,
          inactiveThumbColor: isEditable ? null : Colors.grey,
          inactiveTrackColor: isEditable ? null : Colors.grey[300],
        ),
        const SizedBox(height: 10),
      ],
    );
  });
}

Widget buildEditableChipField(
  PageField field,
  DynamicFormController controller,
  bool isEditable,
  bool isEdit,
) {
  // Extract existing chips from form data or initialize as an empty list
  List<String> existingChips =
      (controller.formData[field.headers] as List<dynamic>?)?.cast<String>() ??
      [];
  TextEditingController chipController = TextEditingController();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        field.title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8.0,
        children: existingChips.map((chip) {
          return Chip(
            label: Text(chip),
            onDeleted: isEditable
                ? () {
                    existingChips.remove(chip);
                    controller.updateFormData(field.headers, existingChips);
                  }
                : null, // Disable deletion if not editable
          );
        }).toList(),
      ),
      const SizedBox(height: 10),
      // Only show the input field and button if isEditable is true
      if (isEditable) ...[
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: chipController,
                decoration: kTextFieldDecoration("Add"),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    existingChips.add(value);
                    chipController.clear();
                    controller.updateFormData(field.headers, existingChips);
                  }
                },
              ),
            ),
            const SizedBox(width: 8.0),
            ElevatedButton(
              onPressed: () {
                final value = chipController.text.trim();
                if (value.isNotEmpty) {
                  existingChips.add(value);
                  chipController.clear();
                  controller.updateFormData(field.headers, existingChips);
                }
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ],
    ],
  );
}

//   Widget buildInputChips(
//       List<String> options, String fieldName, bool isEditable) {
//     return Wrap(
//       spacing: 8.0,
//       children: options.map((option) {
//         return isEditable
//             ? InputChip(
//                 label: Text(option),
//                 selected: controller.selectedChips.contains(option),
//                 onSelected: (isSelected) {
//                   isSelected
//                       ? controller.selectedChips.add(option)
//                       : controller.selectedChips.remove(option);
//                   // Call setState or update your controller here
//                 },
//               )
//             : FilterChip(
//                 label: Text(option),
//                 selected: controller.selectedChips.contains(option),
//                 onSelected: null, // Disable selection
//               );
//       }).toList(),
//     );
//   }
// }

InputDecoration kTextFieldDecoration(String hintText, {Widget? suffixIcon}) {
  return InputDecoration(
    hintText: hintText,
    filled: true,
    fillColor: Colors.white,

    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: Colors.red),
    ),
  );
}

BoxDecoration kBoxFieldDecoration({
  Color? color,
  double radius = 20,
  bool isFocused = false,
}) {
  return BoxDecoration(
    color: color ?? Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: isFocused ? const Color(0xFF2563EB) : Colors.grey,
      width: isFocused ? 2 : 1,
    ),
  );
}
