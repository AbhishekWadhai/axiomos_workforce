import 'package:axiomos_workforce/widgets/dynamic_form/form_extras.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:axiomos_workforce/controllers/dynamic_form_contoller.dart';
import 'package:axiomos_workforce/model/form_data_model.dart';

Widget buildMultiselectField(
  PageField field,
  DynamicFormController controller,
  bool isEditable,
  BuildContext context,
) {
  // Ensure reactive field initialization
  controller.formData.putIfAbsent(
    field.headers,
    () => Rx<dynamic>(<dynamic>[]),
  );

  return FutureBuilder<List<Map<String, String>>>(
    future: controller.getDropdownData(field.endpoint ?? "", field.key ?? ""),
    builder:
        (
          BuildContext context,
          AsyncSnapshot<List<Map<String, String>>> snapshot,
        ) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingField(field.title);
          } else if (snapshot.hasError) {
            Get.snackbar(
              duration: const Duration(seconds: 30),
              snapshot.stackTrace.toString(),
              snapshot.error.toString(),
            );
            return _buildErrorField(field.title);
          } else if (snapshot.hasData) {
            final List<Map<String, String>> options = snapshot.data ?? [];

            // Access the Rx value safely
            final List<dynamic> rawSelected =
                (controller.formData[field.headers]?.value as List<dynamic>);

            final List<String> selectedIds = rawSelected
                .map((item) {
                  if (item is String) return item;
                  if (item is Map<String, dynamic> && item.containsKey('_id')) {
                    return item['_id']?.toString() ?? '';
                  }
                  return '';
                })
                .where((id) => id.isNotEmpty)
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: isEditable
                      ? null
                      : () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('This field is not editable for you'),
                            backgroundColor: Colors.grey,
                          ),
                        ),
                  child: AbsorbPointer(
                    absorbing: !isEditable,
                    child: Obx(() {
                      final rx = controller.formData[field.headers]!;

                      // Safely extract list from Rx<dynamic>
                      final List<dynamic> currentList = (rx.value is List)
                          ? List<dynamic>.from(rx.value)
                          : [];

                      // Convert to selectedIds
                      final List<String> selectedIds = currentList
                          .map((item) {
                            if (item is String) return item;
                            if (item is Map<String, dynamic> &&
                                item.containsKey('_id')) {
                              return item['_id']?.toString() ?? '';
                            }
                            return '';
                          })
                          .where((id) => id.isNotEmpty)
                          .toList();

                      return Container(
                        alignment: Alignment.center,
                        constraints: const BoxConstraints(minHeight: 60),
                        decoration: kBoxFieldDecoration(),
                        child: MultiSelectBottomSheetField<String?>(
                          chipDisplay: MultiSelectChipDisplay(
                            icon: const Icon(Icons.close, size: 18),
                            onTap: (item) {
                              if (!isEditable) return;

                              final updated = List<dynamic>.from(currentList)
                                ..remove(item);

                              rx.value =
                                  updated; // 🔥 Reassign triggers rebuild
                            },
                          ),
                          decoration: BoxDecoration(),
                          buttonIcon: const Icon(Icons.list),
                          maxChildSize: 0.7,
                          initialChildSize: 0.7,
                          searchable: true,
                          validator: (value) {
                            if (!isEditable) return null;
                            if (!field.required) return null;
                            return controller.validateMultiSelect(
                              value?.whereType<String>().toList(),
                            );
                          },
                          items: options.map((option) {
                            return MultiSelectItem<String?>(
                              option['_id'] ?? '',
                              option[field.key] ?? '',
                            );
                          }).toList(),
                          initialValue: selectedIds,
                          onConfirm: (selectedValues) {
                            if (!isEditable) return;

                            rx.value = List<dynamic>.from(selectedValues);
                          },
                          title: Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: Text("Select ${field.title}"),
                          ),
                          buttonText: Text(
                            "Select ${field.title}",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isEditable ? Colors.black : Colors.grey,
                              fontSize: 16,
                              height: 1.8,
                            ),
                            strutStyle: const StrutStyle(
                              height: 2.0,
                              forceStrutHeight: true,
                            ),
                            textHeightBehavior: const TextHeightBehavior(
                              applyHeightToFirstAscent: false,
                              applyHeightToLastDescent: false,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            );
          } else {
            return const SizedBox();
          }
        },
  );
}

Widget _buildLoadingField(String title) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),
      const CircularProgressIndicator(),
      const SizedBox(height: 10),
    ],
  );
}

Widget _buildErrorField(String title) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),
      const Text("Error loading data"),
      const SizedBox(height: 10),
    ],
  );
}
