import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:axiomos_workforce/controllers/dynamic_form_contoller.dart';

import 'package:axiomos_workforce/model/form_data_model.dart';
import 'package:signature/signature.dart';

import 'dynamic_form/form_extras.dart';

class FormController extends GetxController {
  RxMap<String, dynamic> formValues = <String, dynamic>{}.obs;
  var showSignaturePad = <String, RxBool>{};

  void initSignatureField(String header, bool showPadInitially) {
    if (!showSignaturePad.containsKey(header)) {
      showSignaturePad[header] = RxBool(showPadInitially);
    }
  }

  void toggleSignaturePad(String header, bool show) {
    showSignaturePad[header]?.value = show;
  }

  updateMainForm(DynamicFormController mainFormController) {
    mainFormController.customFields = formValues;
  }

  void updateValue(
    String key,
    dynamic value,
    DynamicFormController mainFormController,
  ) {
    formValues[key] = value;
    updateMainForm(mainFormController);
  }

  void submitForm() {
    print("Form Data: ${formValues.toJson()}");
  }
}

// ignore: must_be_immutable
class CustomForm extends StatelessWidget {
  Map<String, dynamic> formValues = <String, dynamic>{};
  final List<PageField> pageFields;
  final DynamicFormController parentFormController;
  final FormController controller = Get.put(FormController());
  String reference;

  CustomForm({
    super.key,
    required this.pageFields,
    required this.parentFormController,
    required this.formValues,
    required this.reference,
  });

  @override
  Widget build(BuildContext context) {
    print(
      ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::inside Custom Form",
    );
    print(pageFields);
    return Column(
      spacing: 5,
      children: pageFields.map((field) => buildFieldWidget(field)).toList(),
    );
  }

  Widget buildFieldWidget(PageField field) {
    final existingValue = formValues[field.headers];
    controller.updateValue(field.headers, existingValue, parentFormController);
    switch (field.type) {
      case "CustomTextField":
        TextEditingController textController = TextEditingController(
          text: existingValue ?? '',
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: textController,
              decoration: kTextFieldDecoration("Enter ${field.title}"),
              onChanged: (value) => controller.updateValue(
                field.headers,
                value,
                parentFormController,
              ),
            ),
          ],
        );

      case "datepicker":
        final existingValue = formValues[field.headers];
        TextEditingController dateController = TextEditingController(
          text: existingValue ?? '',
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: dateController,
              decoration: kTextFieldDecoration(
                "Select Date",
                suffixIcon: const Icon(Icons.calendar_month_rounded),
              ),
              readOnly: true,
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: Get.context!,
                  initialDate: existingValue != null
                      ? DateTime.parse(existingValue)
                      : DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  String formattedDate = pickedDate.toIso8601String();
                  dateController.text = formattedDate;
                  controller.updateValue(
                    field.headers,
                    formattedDate,
                    parentFormController,
                  );
                }
              },
            ),
          ],
        );

      case "timepicker":
        final existingValue = formValues[field.headers];
        controller.updateValue(
          field.headers,
          existingValue,
          parentFormController,
        );
        TextEditingController timeController = TextEditingController(
          text: existingValue ?? '',
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: timeController,
              decoration: kTextFieldDecoration(
                "Select Time",
                suffixIcon: const Icon(Icons.access_time_filled_sharp),
              ),
              readOnly: true,
              onTap: () async {
                TimeOfDay? pickedTime = await showTimePicker(
                  context: Get.context!,
                  initialTime: existingValue != null
                      ? TimeOfDay(
                          hour: int.parse(existingValue.split(":")[0]),
                          minute: int.parse(existingValue.split(":")[1]),
                        )
                      : TimeOfDay.now(),
                );
                if (pickedTime != null) {
                  String formattedTime =
                      "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
                  timeController.text = formattedTime;
                  controller.updateValue(
                    field.headers,
                    formattedTime,
                    parentFormController,
                  );
                }
              },
            ),
          ],
        );

      case 'simplemultiselect':
        final existingValue = formValues[field.headers] as List<dynamic>?;
        controller.updateValue(
          field.headers,
          existingValue,
          parentFormController,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            MultiSelectDialogField<String>(
              dialogHeight: 300,
              items:
                  field.options?.map((option) {
                    return MultiSelectItem<String>(option, option);
                  }).toList() ??
                  [],
              initialValue:
                  existingValue?.map((e) => e.toString()).toList() ?? [],
              onConfirm: (List<String> selectedValues) {
                controller.updateValue(
                  field.headers,
                  selectedValues,
                  parentFormController,
                );
              },
              title: Text("Select ${field.title}"),
              buttonText: Text(
                "Select ${field.title}",
                style: const TextStyle(),
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        );

      case "simpledropdown":
        final existingValue = formValues[field.headers];
        controller.updateValue(
          field.headers,
          existingValue,
          parentFormController,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: Colors.grey, width: 1.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: DropdownButtonFormField<String>(
                  hint: const Text('Select an option'),
                  value: existingValue?.toString(), // Ensure it's a String
                  items: field.options!.map((option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: (value) => controller.updateValue(
                    field.headers,
                    value,
                    parentFormController,
                  ),
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
            ),
          ],
        );

      case 'signature':
        String? imageUrl = formValues[field.headers];
        controller.updateValue(
          field.headers,
          existingValue,
          parentFormController,
        );

        // Initialize toggle state if not already present
        controller.initSignatureField(field.headers, imageUrl == null);

        return Obx(() {
          final isPadVisible =
              controller.showSignaturePad[field.headers]?.value ?? true;

          return SizedBox(
            width: double.infinity,
            child: Column(
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
                if (!isPadVisible && imageUrl != null) ...[
                  Image.network(imageUrl, height: 100),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      controller.toggleSignaturePad(field.headers, true);
                    },
                    child: const Text("Edit Signature"),
                  ),
                ] else ...[
                  Signature(
                    controller: parentFormController.getSignatureController(
                      field.headers,
                    ),
                    height: 200,
                    backgroundColor: Colors.grey[200]!,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          parentFormController
                              .signatureControllers[field.headers]
                              ?.clear();
                        },
                        child: const Text("Clear"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final savedUrl = await parentFormController
                              .saveSignature(field.headers, "$reference/image");
                          controller.updateValue(
                            field.headers,
                            savedUrl,
                            parentFormController,
                          );
                          controller.toggleSignaturePad(
                            field.headers,
                            false,
                          ); // Hide after saving
                        },
                        child: const Text("Save"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          controller.toggleSignaturePad(
                            field.headers,
                            false,
                          ); // Close without saving
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[400],
                        ),
                        child: const Text("Close"),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        });

      default:
        return const SizedBox.shrink();
    }
  }
}
