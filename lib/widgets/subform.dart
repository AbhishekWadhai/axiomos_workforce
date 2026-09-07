import 'dart:async';

import 'package:axiomos_workforce/controllers/dynamic_form_contoller.dart';
import 'package:axiomos_workforce/controllers/sub_form_controller.dart';
import 'package:axiomos_workforce/model/form_data_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

import 'package:signature/signature.dart';

class SubForm extends StatelessWidget {
  final String pageName;
  final Map<String, dynamic>? initialData;
  final bool isEdit;

  SubForm({
    super.key,
    required this.pageName,
    this.initialData,
    this.isEdit = false,
  });

  final GlobalKey<FormState> _subformKey = GlobalKey<FormState>();
  final SubFormController controller = Get.put(
    SubFormController(),
    permanent: false,
  );

  final DynamicFormController mainController =
      Get.find<DynamicFormController>();

  @override
  Widget build(BuildContext context) {
    controller.initializeFormData(initialData);

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Form(
              key: _subformKey,
              child: Obx(() {
                controller.getPageFields(pageName);
                return GetBuilder<SubFormController>(
                  builder: (controller) {
                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            double screenWidth = MediaQuery.of(
                              context,
                            ).size.width;

                            // Define breakpoints for responsiveness
                            if (screenWidth > 1200) {
                              // Large screen (desktop view)
                              return Column(
                                children: [
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount:
                                              3, // 3 columns for large screens
                                          crossAxisSpacing: 20,
                                          mainAxisSpacing: 20,
                                          childAspectRatio: 2,
                                        ),
                                    itemCount: controller.pageFields.length,
                                    itemBuilder: (context, index) {
                                      var field = controller.pageFields[index];
                                      return Column(
                                        children: [buildFormField(field)],
                                      );
                                    },
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (_subformKey.currentState
                                              ?.validate() ??
                                          false) {
                                        if (isEdit) {
                                          controller.updateData(pageName);
                                        } else {
                                          controller.submitForm(pageName);
                                        }
                                      } else {
                                        // Show an error if form is invalid
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please correct the errors in the form',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width,
                                      child: Text(
                                        isEdit ? 'Update' : 'Submit',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            } else if (screenWidth > 600) {
                              // Medium screen (tablet view)
                              return Column(
                                children: [
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount:
                                              2, // 2 columns for medium screens
                                          crossAxisSpacing: 20,
                                          mainAxisSpacing: 20,
                                          childAspectRatio: 2.5,
                                        ),
                                    itemCount: controller.pageFields.length,
                                    itemBuilder: (context, index) {
                                      var field = controller.pageFields[index];
                                      return Column(
                                        children: [buildFormField(field)],
                                      );
                                    },
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (_subformKey.currentState
                                              ?.validate() ??
                                          false) {
                                        if (isEdit) {
                                          controller.updateData(pageName);
                                        } else {
                                          controller.submitForm(pageName);
                                        }
                                      } else {
                                        // Show an error if form is invalid
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please correct the errors in the form',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width,
                                      child: Text(
                                        isEdit ? 'Update' : 'Submit',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              // Small screen (mobile view)
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Build form fields dynamically for mobile view
                                  ...controller.pageFields
                                      .map(
                                        (field) => Column(
                                          children: [
                                            buildFormField(field),
                                            const SizedBox(height: 10),
                                          ],
                                        ),
                                      )
                                      .toList(),

                                  const SizedBox(height: 10),

                                  // Submit button
                                  ElevatedButton(
                                    onPressed: () {
                                      if (_subformKey.currentState
                                              ?.validate() ??
                                          false) {
                                        if (isEdit) {
                                          controller.submitForm(pageName);
                                        } else {
                                          controller.submitForm(pageName);
                                        }
                                      } else {
                                        // Show an error if form is invalid
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please correct the errors in the form',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width,
                                      child: Text(
                                        isEdit ? 'Update' : 'Submit',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFormField(PageField field) {
    switch (field.type) {
      case 'imagepicker':
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await controller.pickAndUploadImage(
                      field.headers,
                      field.endpoint ?? "",
                      "gallery",
                    );
                  },
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),

                ElevatedButton.icon(
                  onPressed: () async {
                    await controller.pickAndUploadImage(
                      field.headers,
                      field.endpoint ?? "",
                      "camera",
                    );
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
              ],
            ),

            Obx(() {
              final isUploading =
                  controller.imageUploading[field.headers] ?? false;

              final imageUrl = controller.formData[field.headers];

              return Column(
                children: [
                  // your image/buttons...
                  if (isUploading)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Uploading image...'),
                        ],
                      ),
                    ),

                  if (!isUploading && imageUrl is String && imageUrl.isNotEmpty)
                    Image.network(imageUrl, height: 150),
                ],
              );
            }),
          ],
        );
      // Add this to your controller

      // Updated widget code
      case 'CustomTextField':
        // Get or create the TextEditingController for this field
        final TextEditingController textController = controller
            .getTextController(field.headers);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextFormField(
              keyboardType: field.key == "numeric"
                  ? TextInputType.number
                  : null,
              onTapOutside: (event) {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              validator: (value) => controller.validateTextField(value),
              controller: textController,
              decoration: kTextFieldDecoration("Enter ${field.title}"),
              onChanged: (value) {
                // Cancel the existing timer for this field, if any
                controller.debounceMap[field.headers]?.cancel();

                // Start a new timer for debounce specific to this field
                controller.debounceMap[field.headers] = Timer(
                  const Duration(milliseconds: 2000),
                  () {
                    // Update the form data after debounce
                    controller.updateFormData(field.headers, value);
                  },
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        );
      case 'signature':
        String? signatureUrl = controller.formData[field.headers];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.title),
            isEdit
                ? (signatureUrl != null && signatureUrl.isNotEmpty
                      ? Image.network(
                          signatureUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : const Text("No signature available."))
                : Obx(
                    () => Signature(
                      controller: controller.signatureController.value,
                      height: 200,
                      backgroundColor: Colors.grey[200]!,
                    ),
                  ),
            if (!isEdit) // Show buttons only if not in edit mode
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      controller.signatureController.value.clear();
                    },
                    child: const Text("Clear"),
                  ),
                  ElevatedButton(
                    // onPressed: () {
                    //   controller.saveSignature(
                    //     field.headers,
                    //     field.endpoint ?? "",
                    //     controller.signatureController.value,
                    //   );
                    // },
                    onPressed: () async {
                      final sigController =
                          controller.signatureController.value;
                      if (sigController == null) return;

                      if (!mainController.isOnline.value) {
                        // 🌐 Store locally
                        final bytes = await sigController.toPngBytes();
                        if (bytes != null) {
                          final localPath = await mainController
                              .saveSignatureLocally(field.headers, bytes);
                          print(
                            "-----------------${mainController.isOnline.value}",
                          );
                          print(localPath);
                          controller.updateFormData(field.headers, localPath);
                          mainController.imageErrors[field.headers] = null;

                          // Optional: mark as offline signature for future sync
                          mainController.queueOfflineSignatureUpload(
                            field.headers,
                            localPath,
                          );
                        } else {
                          mainController.imageErrors[field.headers] =
                              "Could not capture signature.";
                        }
                      } else {
                        print("Going into online-----------------------------");
                        // 🌍 Upload online
                        String? imageUrl = controller.saveSignature(
                          field.headers,
                          field.endpoint ?? "",
                          controller.signatureController.value,
                        );
                        if (imageUrl != null) {
                          controller.updateFormData(field.headers, imageUrl);
                          mainController.imageErrors[field.headers] = null;
                        }
                      }
                    },
                    child: const Text("Save"),
                  ),
                ],
              ),
          ],
        );
      case 'editablechip':
        return buildEditableChipField(field);
      case 'multiselect':
        return FutureBuilder<List<Map<String, String>>>(
          future: controller.getDropdownData(
            field.endpoint ?? "",
            field.key ?? "",
          ),
          builder:
              (
                BuildContext context,
                AsyncSnapshot<List<Map<String, String>>> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
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
                      const CircularProgressIndicator(),
                      const SizedBox(height: 10),
                    ],
                  );
                } else if (snapshot.hasError) {
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
                      const Text("Error loading data"),
                      const SizedBox(height: 10),
                    ],
                  );
                } else if (snapshot.hasData) {
                  final List<Map<String, String>> options = snapshot.data ?? [];
                  final List<String> selectedIds =
                      (controller.formData[field.headers] as List<String>?) ??
                      [];

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
                      FormField<List<String>>(
                        initialValue: selectedIds,
                        validator: (selectedItems) {
                          if (selectedItems == null || selectedItems.isEmpty) {
                            return 'Please select at least one option';
                          }
                          return null;
                        },
                        builder: (FormFieldState<List<String>> state) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MultiSelectDialogField<String>(
                                dialogHeight: 300,
                                items: options.map((
                                  Map<String, String> option,
                                ) {
                                  return MultiSelectItem<String>(
                                    option['_id'] ??
                                        "", // Use `_id` as the value
                                    option[field.key] ??
                                        '', // Display the dynamic key (e.g., `projectName`)
                                  );
                                }).toList(),
                                initialValue: selectedIds,
                                onConfirm: (List<String> selectedValues) {
                                  state.didChange(
                                    selectedValues,
                                  ); // Update the form field state
                                  controller.updateFormData(
                                    field.headers,
                                    selectedValues,
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
                              if (state.hasError)
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    state.errorText ?? '',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                } else {
                  return Container();
                }
              },
        );

      case 'dropdown':
        return Obx(() {
          final selectedValue = controller.formData[field.headers];

          return FutureBuilder<List<Map<String, String>>>(
            future: controller.getDropdownData(
              field.endpoint ?? "",
              field.key ?? "",
            ),
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<List<Map<String, String>>> snapshot,
                ) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
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
                        const CircularProgressIndicator(),
                        const SizedBox(height: 10),
                      ],
                    );
                  } else if (snapshot.hasError) {
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
                        const Text("Error loading data"),
                        const SizedBox(height: 10),
                      ],
                    );
                  } else if (snapshot.hasData) {
                    final List<Map<String, String>> options =
                        snapshot.data ?? [];

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
                        DropdownButtonHideUnderline(
                          child: Container(
                            width: double.infinity, // Occupy full width
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                10.0,
                              ), // Border radius
                              border: Border.all(
                                color: Colors.grey,
                                width: 1.0,
                              ), // Optional border
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                ),
                                validator: (value) =>
                                    controller.validateDropdown(value),
                                elevation: 0, // Remove default elevation
                                value:
                                    selectedValue, // Keep this as null initially
                                hint: const Text(
                                  'Select an option',
                                ), // Hint text
                                items: options.map((
                                  Map<String, String> option,
                                ) {
                                  return DropdownMenuItem<String>(
                                    value: option['_id'], // Use `_id` as value
                                    child: Text(
                                      option[field.key] ?? '',
                                    ), // Display the dynamic key (e.g., `projectName`)
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    controller.updateDropdownSelection(
                                      field.headers,
                                      newValue,
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    );
                  } else {
                    return Container();
                  }
                },
          );
        });
      case 'simplemultiselect':
        return MultiSelectDialogField<String>(
          dialogHeight: 300,
          items: (field.options != null)
              ? field.options!.map((option) {
                  return MultiSelectItem<String>(option, option);
                }).toList()
              : [],

          // Ensure initialValue is a non-null, valid list
          initialValue: controller.formData[field.headers] != null
              ? List<String>.from(controller.formData[field.headers])
              : [],

          onConfirm: (List<String> selectedValues) {
            controller.updateFormData(field.headers, selectedValues);
          },

          title: Text("Select ${field.title}"),
          buttonText: Text("Select ${field.title}", style: const TextStyle()),

          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
        );

      case 'simpledropdown':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0), // Border radius
                border: Border.all(
                  color: Colors.grey,
                  width: 1.0,
                ), // Optional border
              ),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(border: InputBorder.none),
                  validator: (value) => controller.validateDropdown(value),
                  elevation: 0, // Remove default elevation
                  value: controller.formData[field.headers]
                      ?.toString(), // Keep this as null initially
                  hint: const Text('Select an option'), // Hint text
                  items: (field.options != null)
                      ? field.options!.map((option) {
                          return DropdownMenuItem<String>(
                            value: option,
                            child: Text(option ?? ''),
                          );
                        }).toList()
                      : [], // Return an empty list if `field.options` is null

                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      controller.updateDropdownSelection(
                        field.headers,
                        newValue,
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        );

      case 'datepicker':
        return myDatePicker(field);

      case 'timepicker':
        return myTimePicker(field);

      case 'radio':
        return Obx(() {
          final selectedValue = controller.formData[field.headers].toString();
          final List<String> options = field.options!;

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
              Row(
                children: options.map((option) {
                  return Expanded(
                    child: RadioListTile<String>(
                      title: Text(option),
                      value: option,
                      groupValue: selectedValue,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          controller.updateRadioSelection(
                            field.headers,
                            newValue,
                          );
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
            ],
          );
        });
      case 'geolocation':
        return Obx(() {
          String? currentLocation = controller.formData[field.headers];
          double? latitude, longitude;

          if (currentLocation != null && currentLocation.isNotEmpty) {
            var coordinates = currentLocation.split(',');
            latitude = double.tryParse(coordinates[0]);
            longitude = double.tryParse(coordinates[1]);
          }

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
              TextFormField(
                controller: TextEditingController(
                  text: currentLocation ?? 'Fetching location...',
                ),
                readOnly: true, // Make the TextField read-only
                decoration: kTextFieldDecoration("Location"),
                onTap: () async {
                  await controller.fetchGeolocation(field.headers);
                },
              ),
              const SizedBox(height: 10),
              if (latitude != null && longitude != null)
                SizedBox(
                  height: 200.0,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(latitude, longitude),
                      zoom: 15.0,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId("currentLocation"),
                        position: LatLng(latitude, longitude),
                      ),
                    },
                  ),
                ),
              const SizedBox(height: 10),
            ],
          );
        });

      case 'slider':
        return Obx(() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Number of Attendees - ${controller.formData[field.headers] ?? "0"}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Slider(
                value: controller.formData[field.headers] ?? 0,
                min: 0.0,
                max: 100.0,
                divisions: 100,
                label: controller.formData[field.headers].toString(),
                onChanged: (value) {
                  controller.formData[field.headers] = value;
                },
              ),
            ],
          );
        });

      default:
        return const Text('Unsupported field type');
    }
  }

  Widget myDatePicker(PageField field) {
    // Create a TextEditingController to store and display the picked date
    final TextEditingController dateController = TextEditingController(
      text: controller.formData[field.headers]?.toString() ?? '',
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
          readOnly:
              true, // Make the TextField read-only so the user can't manually edit it
          decoration: kTextFieldDecoration("Select Date"),
          onTap: () async {
            DateTime? pickedDate = await showDatePicker(
              context: Get.context!,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (pickedDate != null) {
              String formattedDate =
                  "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}"; // Format the date
              dateController.text =
                  formattedDate; // Update the TextField with the selected date
              controller.updateFormData(
                field.headers,
                formattedDate,
              ); // Update the form data
            }
          },
        ),
      ],
    );
  }

  Widget myTimePicker(PageField field) {
    // Create a TextEditingController to store and display the selected time
    final TextEditingController timeController = TextEditingController(
      text: controller.formData[field.headers]?.toString() ?? '',
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
          readOnly:
              true, // Make the TextField read-only so the user can't manually edit it
          decoration: kTextFieldDecoration("Select Time"),
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
                field.headers,
                formattedTime,
              ); // Update the form data
            }
          },
        ),
      ],
    );
  }

  Widget buildEditableChipField(PageField field) {
    // Extract existing chips from form data or initialize as empty list
    List<String> existingChips =
        (controller.formData[field.headers] as List<String>?) ?? [];
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
              onDeleted: () {
                existingChips.remove(chip);
                controller.updateFormData(field.headers, existingChips);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: chipController,
                decoration: kTextFieldDecoration("Add a chip"),
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
    );
  }

  Widget buildInputChips(List<String> options, String fieldName) {
    return Wrap(
      spacing: 8.0,
      children: options.map((option) {
        return InputChip(
          label: Text(option),
          selected: controller.selectedChips.contains(option),
          onSelected: (isSelected) {
            isSelected
                ? controller.selectedChips.add(option)
                : controller.selectedChips.remove(option);
            // Call setState or update your controller here
          },
        );
      }).toList(),
    );
  }
}

InputDecoration kTextFieldDecoration(String hintText) {
  return InputDecoration(
    hintText: hintText,
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
  );
}
