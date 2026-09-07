import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:axiomos_workforce/constants/app_strings.dart';
import 'package:axiomos_workforce/constants/colors.dart';
import 'package:axiomos_workforce/helpers/sixed_boxes.dart';
import 'package:axiomos_workforce/model/filter_model.dart';

import 'package:axiomos_workforce/widgets/gradient_button.dart';
import 'package:axiomos_workforce/widgets/module_filter_form.dart/module_filter_controller.dart';

class ModuleFilterForm extends StatefulWidget {
  final List<Filter> filterOptions;
  const ModuleFilterForm({super.key, required this.filterOptions});

  @override
  State<ModuleFilterForm> createState() => _ModuleFilterFormState();
}

class _ModuleFilterFormState extends State<ModuleFilterForm> {
  final ModuleFilterController controller = Get.find<ModuleFilterController>();
  @override
  void initState() {
    super.initState();
    controller.ensurePageFieldsLoaded(widget.filterOptions);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      ...controller.filterFields.map((field) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: buildFilterFields(field),
                        );
                      }),
                    ],
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: GradientButton(
                          gradientColors: [
                            AppColors.appMainLight,
                            AppColors.appMainMid,
                          ],
                          borderRadius: 4,
                          height: 35,
                          onTap: () {
                            controller.clearSelection();
                          },
                          text: "Clear",
                        ),
                      ),
                      sb20,
                      Expanded(
                        flex: 2,
                        child: GradientButton(
                          gradientColors: [
                            AppColors.appMainDark,
                            AppColors.appMainDark,
                          ],
                          borderRadius: 4,
                          height: 35,
                          onTap: () {
                            // Add text field values to selectedFilters
                            controller.textControllers.forEach((
                              key,
                              textController,
                            ) {
                              print(key);

                              controller.selectedFilters[key] =
                                  textController.text;
                            });

                            final result = Map<String, dynamic>.from(
                              controller.selectedFilters,
                            );
                            print(result);
                            Get.back(result: result);
                          },
                          text: "Apply",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildFilterFields(Filter field) {
    switch (field.type) {
      case 'dropdown':
        return dropdown(field);
      case 'simpleDropdown':
        return simpleDropdown(field);
      case 'multiselect':
        return multiselect(field);

      case 'date':
        return myDatePicker(field, context);

      case 'time':
        return myTimePicker(field);

      case 'text':
        return textField(field);
      default:
        return SizedBox.shrink();
    }
  }

  Obx simpleDropdown(Filter field) {
    return Obx(() {
      final selectedValue = controller.selectedFilters[field.key];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
            ),
            value: selectedValue,
            hint: const Text('Select an option'),
            items: field.options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(
                  option,
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                controller.updateFormData(field.key, newValue);
              }
            },
          ),
        ],
      );
    });
  }

  /////////////////////////dropdown////////////////////////////////////////////////////
  Widget dropdown(Filter field) {
    final options = controller.getDropdownData(
      field.source ?? '',
      field.path ?? '',
    );

    return Obx(() {
      final selectedValue = controller.selectedFilters[field.key];

      final processedValue = selectedValue is Map ? selectedValue : null;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
            ),
            value: selectedValue?['_id']?.toString(),
            hint: Text('Select ${field.label}'),
            items: options.map((option) {
              return DropdownMenuItem<String>(
                value: option['_id']?.toString(),
                child: Text(option[field.path] ?? ''),
              );
            }).toList(),

            onChanged: (value) {
              if (value == null) return;

              final selectedOption = options.firstWhere(
                (option) => option['_id'] == value,
              );
              print('Selected Option: $selectedOption');
              controller.updateFormData(field.key, selectedOption);
            },
          ),
        ],
      );
    });
  }

  //////////////multiselect////////////////////////////////////
  Widget multiselect(Filter field) {
    // No FutureBuilder required.
    // getDropdownData() is now synchronous.
    final List<Map<String, String>> options = controller.getDropdownData(
      field.source ?? "",
      field.path ?? "",
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This field is not editable for you'),
                backgroundColor: Colors.grey,
              ),
            );
          },

          child: Obx(() {
            final rawValue = controller.selectedFilters[field.key];

            final List<String> selectedIds = rawValue is List
                ? rawValue
                      .map((item) {
                        if (item is String) {
                          return item;
                        }

                        if (item is Map<String, dynamic>) {
                          return item['_id']?.toString() ?? '';
                        }

                        return '';
                      })
                      .where((id) => id.isNotEmpty)
                      .toList()
                : <String>[];

            return MultiSelectDialogField<String>(
              searchable: true,
              dialogHeight: 300,

              items: options.map((option) {
                return MultiSelectItem<String>(
                  option['_id'] ?? '',
                  option[field.path] ?? '',
                );
              }).toList(),

              initialValue: selectedIds,

              onConfirm: (List<String> values) {
                controller.updateFormData(field.key, values);
              },

              title: Text("Select ${field.label}"),

              buttonText: Text(
                "Select ${field.label}",
                style: const TextStyle(color: Colors.black54),
              ),

              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4.0),
              ),
            );
          }),
        ),
      ],
    );
  }
  ///////////////////////date and time Picker//////////////////////////

  Widget myDatePicker(Filter field, BuildContext context) {
    return Obx(() {
      final dateController = TextEditingController(
        text: controller.selectedFilters[field.key]?.toString() ?? '',
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: dateController,
            readOnly: true,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              hintText: 'Select Date',
            ),
            onTap: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );

              if (pickedDate != null) {
                final formatted =
                    "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";

                dateController.text = formatted;
                controller.updateFormData(field.key, formatted);
              }
            },
          ),
        ],
      );
    });
  }

  Widget myTimePicker(Filter field) {
    // Create a TextEditingController to store and display the selected time

    return Obx(() {
      final TextEditingController timeController = TextEditingController(
        text: controller.selectedFilters[field.key]?.toString() ?? '',
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: timeController,
            readOnly:
                true, // Make the TextField read-only so the user can't manually edit it
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              hintText: 'Select Time',
            ),
            onTap: () async {
              TimeOfDay? selectedTime = await showTimePicker(
                context: Get.context!,
                initialTime: TimeOfDay.now(),
              );
              if (selectedTime != null) {
                String formattedTime = selectedTime.format(
                  Get.context!,
                ); // Format the time
                timeController.text =
                    formattedTime; // Update the TextField with the selected time
                controller.updateFormData(
                  field.key,
                  formattedTime,
                ); // Update the form data
              }
            },
          ),
        ],
      );
    });
  }

  //////////////////////////textField///////////////////////////////
  ///
  Widget textField(Filter field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(field.label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8.0),
        TextFormField(
          controller: controller.getTextController(field.key),
          scrollPadding: const EdgeInsets.only(bottom: 120),
          // onChanged: onChanged,
          decoration: InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            hintText: 'Enter ${field.label}',
          ),
          //validator: validator,
        ),
      ],
    );
  }
}
