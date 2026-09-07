import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:axiomos_workforce/controllers/dynamic_form_contoller.dart';
import 'package:axiomos_workforce/controllers/sub_form_controller.dart';
import 'package:axiomos_workforce/model/form_data_model.dart';
import 'package:axiomos_workforce/services/translation.dart';
import 'package:axiomos_workforce/widgets/dynamic_data_view.dart';
import 'package:axiomos_workforce/widgets/subform.dart';

Widget buildSecondaryFormField(
  PageField field,
  DynamicFormController controller,
  bool isEditable,
) {
  // Each secondary form gets its own list.
  final subformList = controller.getSubformData(field.headers);

  // Initialize existing data for THIS secondary form only.
  if (controller.formData[field.headers] != null) {
    final existingData = controller.formData[field.headers]?.value;

    if (existingData is List) {
      subformList.value = existingData
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } else if (existingData is Map) {
      subformList.value = [Map<String, dynamic>.from(existingData)];
    }
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // ============================================================
      // SECTION HEADER
      // ============================================================
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                Obx(
                  () => Text(
                    subformList.isEmpty
                        ? 'No records added'
                        : '${subformList.length} '
                              '${subformList.length == 1 ? 'record' : 'records'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),

          // Add button in header
          if (isEditable && (field.key == 'list' || subformList.isEmpty))
            _secondaryFormAddButton(
              onPressed: () async {
                final result = await Get.dialog(
                  Dialog(
                    insetPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: SafeArea(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 900),
                        child: WillPopScope(
                          onWillPop: () async {
                            Get.delete<SubFormController>();
                            return true;
                          },
                          child: SubForm(pageName: field.headers),
                        ),
                      ),
                    ),
                  ),
                );

                if (result != null) {
                  final data = Map<String, dynamic>.from(result);

                  // LIST MODE
                  if (field.key == 'list') {
                    subformList.add(data);

                    controller.formData.putIfAbsent(
                      field.headers,
                      () => Rx<dynamic>(<Map<String, dynamic>>[]),
                    );

                    controller.formData[field.headers]?.value =
                        List<Map<String, dynamic>>.from(subformList);
                  }
                  // MAP MODE
                  else if (field.key == 'map') {
                    subformList.value = [data];

                    controller.formData.putIfAbsent(
                      field.headers,
                      () => Rx<dynamic>(<String, dynamic>{}),
                    );

                    controller.formData[field.headers]?.value =
                        Map<String, dynamic>.from(data);
                  }
                }
              },
            ),
        ],
      ),

      const SizedBox(height: 12),

      // ============================================================
      // DISPLAY LIST
      // ============================================================
      Obx(() {
        if (subformList.isEmpty) {
          return _secondaryFormEmptyState(
            isEditable: isEditable,
            onAdd: isEditable
                ? () async {
                    final result = await Get.dialog(
                      Dialog(
                        insetPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: SafeArea(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 900),
                            child: WillPopScope(
                              onWillPop: () async {
                                Get.delete<SubFormController>();
                                return true;
                              },
                              child: SubForm(pageName: field.headers),
                            ),
                          ),
                        ),
                      ),
                    );

                    if (result != null) {
                      final data = Map<String, dynamic>.from(result);

                      if (field.key == 'list') {
                        subformList.add(data);

                        controller.formData.putIfAbsent(
                          field.headers,
                          () => Rx<dynamic>(<Map<String, dynamic>>[]),
                        );

                        controller.formData[field.headers]?.value =
                            List<Map<String, dynamic>>.from(subformList);
                      } else if (field.key == 'map') {
                        subformList.value = [data];

                        controller.formData.putIfAbsent(
                          field.headers,
                          () => Rx<dynamic>(<String, dynamic>{}),
                        );

                        controller.formData[field.headers]?.value =
                            Map<String, dynamic>.from(data);
                      }
                    }
                  }
                : null,
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: subformList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final attendee = subformList[index];

            final title = attendee[field.key]?.toString();

            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  collapsedBackgroundColor: Colors.white,
                  backgroundColor: Colors.white,
                  key: ValueKey(attendee),

                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),

                  childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),

                  iconColor: Theme.of(context).primaryColor,

                  collapsedIconColor: Colors.grey.shade600,

                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      size: 20,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),

                  title: Text(
                    title?.isNotEmpty == true ? title! : 'Record ${index + 1}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  subtitle: Text(
                    'Record ${index + 1}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),

                  children: [
                    // ==================================================
                    // DATA VIEW
                    // ==================================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DynamicDataPage(
                        data: attendee,
                        fieldKeys: keysForMap,
                        variant: DynamicDataVariant.summary,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // ACTION BUTTONS
                    // ==================================================
                    if (isEditable)
                      Row(
                        children: [
                          // EDIT
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final result = await Get.dialog(
                                  Dialog(
                                    insetPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 24,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: SafeArea(
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxHeight: 900,
                                        ),
                                        child: WillPopScope(
                                          onWillPop: () async {
                                            Get.delete<SubFormController>();
                                            return true;
                                          },
                                          child: SubForm(
                                            pageName: field.headers,
                                            initialData: attendee,
                                            isEdit: true,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );

                                if (result != null) {
                                  final updatedData = Map<String, dynamic>.from(
                                    result,
                                  );

                                  subformList[index] = updatedData;

                                  if (field.key == 'list') {
                                    controller.formData[field.headers]?.value =
                                        List<Map<String, dynamic>>.from(
                                          subformList,
                                        );
                                  } else if (field.key == 'map') {
                                    controller.formData[field.headers]?.value =
                                        Map<String, dynamic>.from(updatedData);
                                  }
                                }
                              },
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Edit'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(context).primaryColor,
                                side: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.4),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // DELETE
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                subformList.removeAt(index);

                                if (field.key == 'list') {
                                  controller.formData[field.headers]?.value =
                                      List<Map<String, dynamic>>.from(
                                        subformList,
                                      );
                                } else if (field.key == 'map') {
                                  controller.formData[field.headers]?.value =
                                      {};
                                }
                              },
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                              ),
                              label: const Text('Remove'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade600,
                                side: BorderSide(color: Colors.red.shade200),
                                backgroundColor: Colors.red.shade50,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    ],
  );
}

Widget _secondaryFormAddButton({required VoidCallback onPressed}) {
  return ElevatedButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.add_rounded, size: 19),
    label: const Text('Add', style: TextStyle(fontWeight: FontWeight.w600)),
    style: ElevatedButton.styleFrom(
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

Widget _secondaryFormEmptyState({
  required bool isEditable,
  VoidCallback? onAdd,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Row(
      children: [
        Icon(Icons.inbox_outlined, size: 20, color: Colors.grey.shade500),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            isEditable ? 'No Data added yet' : 'No Data available',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ),

        if (isEditable && onAdd != null)
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 17),
            label: const Text('Add'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
      ],
    ),
  );
}
