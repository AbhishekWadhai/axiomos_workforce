import 'dart:async';
import 'dart:io';

import 'package:axiomos_workforce/constants/app_strings.dart';
import 'package:axiomos_workforce/model/form_data_model.dart';
import 'package:axiomos_workforce/services/api_services.dart';
import 'package:axiomos_workforce/services/image_service.dart';
import 'package:axiomos_workforce/services/location_service.dart';
import 'package:axiomos_workforce/widgets/progress_indicators.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:path_provider/path_provider.dart';

import 'dart:convert';
import 'package:flutter/services.dart';

import 'package:signature/signature.dart';

class SubFormController extends GetxController {
  final CameraService imageUploadService = CameraService();
  final imageUploading = <String, bool>{}.obs;
  var formResponse = <ResponseForm>[].obs;
  var isLoading = true.obs;
  RxList<PageField> pageFields = <PageField>[].obs;
  RxMap<String, dynamic> formData = <String, dynamic>{}.obs;
  Map<String, Timer?> debounceMap = {};
  RxMap<String, String> dropdownSelections = <String, String>{}.obs;
  RxMap<String, String> radioSelections = <String, String>{}.obs;
  final Map<String, TextEditingController> _textControllers = {};
  bool fieldsLoaded = false; // Flag to check if fields are loaded
  final signatureController = SignatureController().obs;
  @override
  void onInit() {
    super.onInit();
    loadFormData();
  }

  @override
  void dispose() {
    Get.delete<SubFormController>(); // Dispose SubFormController
    super.dispose();
  }

  @override
  void onClose() {
    super.onClose();
    print("SubFormController disposed.");
  }

  var selectedChips = <String>[].obs;

  TextEditingController getTextController(String fieldHeader) {
    if (!_textControllers.containsKey(fieldHeader)) {
      // Create a new controller if it doesn't exist
      _textControllers[fieldHeader] = TextEditingController(
        text: formData[fieldHeader]?.toString() ?? '',
      );
    }
    return _textControllers[fieldHeader]!;
  }

  saveSignature(
    String key,
    String endpoint,
    SignatureController signatureController,
  ) async {
    File? imageFile;

    if (signatureController.isNotEmpty) {
      // Show the loading dialog
      Get.dialog(
        const Center(child: ImageProgressIndicator()),
        barrierDismissible: false, // Prevent dismissing the dialog
      );

      try {
        // Convert the signature to bytes
        final bytes = await signatureController.toPngBytes();
        final directory = await getApplicationDocumentsDirectory();
        imageFile = File('${directory.path}/signature.png');

        // Save the bytes to the file
        await imageFile.writeAsBytes(bytes!);

        if (imageFile != null) {
          // Upload the image and get the URL
          String? imageUrl = await imageUploadService.uploadImage(
            imageFile,

            true,
            category: endpoint,
          );

          if (imageUrl != null) {
            // Save the image URL in the formData
            updateFormData(key, imageUrl);
            print('Image uploaded successfully: $imageUrl');
          } else {
            print('Image upload failed.');
          }
        } else {
          print('No image selected.');
        }
      } catch (e) {
        print("Error: $e");
      } finally {
        // Close the loading dialog
        Get.back();
      }
    } else {
      throw Exception("Signature is empty");
    }
  }

  // Function to add or remove chips
  void toggleChipSelection(String chipValue) {
    if (selectedChips.contains(chipValue)) {
      selectedChips.remove(chipValue);
    } else {
      selectedChips.add(chipValue);
    }
  }

  // Call this method when the form is first loaded
  void initializeFormData(Map<String, dynamic>? initialData) {
    if (initialData != null) {
      initialData.forEach((key, value) {
        if (value is List) {
          // Check if the list elements contain an "id" or if they are regular strings
          formData[key] = value.map((e) {
            if (e is Map && e.containsKey("_id")) {
              return e["_id"]
                  .toString(); // Return the id if it's a Map with an "_id" key
            } else if (e is String) {
              return e; // If it's already a string, return it as is
            }
            return e.toString(); // Fallback to toString() for any other cases
          }).toList();
        } else if (value is Map && value.containsKey("_id")) {
          formData[key] = value["_id"]
              .toString(); // Handle the map containing an "_id"
        } else {
          formData[key] = value; // Handle other cases
        }
      });
    }
    print(
      "------------------------------------00000000000000 Current Page Data 0000000000000--------------------------------",
    );
    print(jsonEncode(formData));
  }

  Future<dynamic> pickAndUploadImage(
    String key,
    String category,
    String source,
  ) async {
    File? imageFile;

    // Show dialog using Flutter's native dialog method
    imageUploading[key] = true;

    try {
      if (source == "camera") {
        imageFile = await Get.to(() => CameraPreviewScreen());
      } else {
        final picked = await ImagePicker().pickImage(
          source: ImageSource.gallery,
        );
        if (picked != null) imageFile = File(picked.path);
      }

      if (imageFile == null) {
        print('No image selected.');
        return;
      }

      String? imageUrl = await imageUploadService.uploadImage(
        imageFile,
        false,

        category: category,
      );
      if (imageUrl != null) {
        updateFormData(key, imageUrl);
        print('Image uploaded successfully: $imageUrl');
      } else {
        print('Image upload failed.');
      }
    } catch (e) {
      print('Error during image upload: $e');
    } finally {
      // Close only the loading dialog
      // if (Navigator.of(Get.context!).canPop()) {
      //   Navigator.of(Get.context!).pop(); // closes only the dialog
      // }
      imageUploading[key] = false;
    }
  }

  Future<void> getPageFields(String pageName) async {
    pageFields.value = await formResponse
        .where((e) => e.page == pageName)
        .expand((e) => e.pageFields)
        .toList();

    update();
  }

  Future<void> loadFormData() async {
    isLoading(true);
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        await loadJsonFromAssets();
      } else {
        await loadJsonFromAssets(); // Should be loadJsonFromApi() if online
      }
      print("Form data loaded: $formData");
    } catch (e) {
      print("Error loading form data: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<void> loadJsonFromAssets() async {
    try {
      final String response = await rootBundle.loadString(
        'lib/assets/json/forms.json',
      );
      final data = await json.decode(response) as List<dynamic>;
      formResponse.value = data
          .map<ResponseForm>((element) => ResponseForm.fromJson(element))
          .toList();
      print("Loaded form data from assets: $formResponse");
      // print(
      //     "------------------------------------00000000000000000000000000000000000000000000--------------------------------");
      // print(jsonEncode(formResponse));
    } catch (e) {
      print("Error loading JSON from assets: $e");
    }
  }

  Future<void> loadJsonFromApi() async {
    try {
      final jsonResult = await ApiService().getRequest("fields");
      formResponse.value = jsonResult
          .map<ResponseForm>((element) => ResponseForm.fromJson(element))
          .toList();
      print("Loaded form data from API: $formResponse");
    } catch (e) {
      print("Error loading JSON from API: $e");
    }
  }

  Future<List<Map<String, String>>> getDropdownData(
    String endpoint,
    String key,
  ) async {
    final dropdownResult = Strings.endpointToList[endpoint] ?? [];
    return dropdownResult
        .map<Map<String, String>>(
          (element) => {
            '_id': element['_id'].toString(),
            key: element[key].toString(),
          },
        )
        .toList();
    // print("API calling going on");
    // final dropdownResult = await ApiService().getRequest(endpoint);
    // print("API call success");
    // return dropdownResult
    //     .map<Map<String, String>>(
    //       (element) => {
    //         '_id': element['_id'].toString(),
    //         key: element[key].toString(), // Use the dynamic key here
    //       },
    //     )
    //     .toList();
  }

  void updateFormData(String key, dynamic value) {
    formData[key] = value;
    update();
    print(
      "------------------------------------00000000000000 Updated Data 0000000000000--------------------------------",
    );
    print("Updated form data: $formData");
  }

  void updateDropdownSelection(String key, String value) {
    dropdownSelections[key] = value;
    print(jsonEncode(dropdownSelections));
    updateFormData(key, value);
  }

  void updateRadioSelection(String key, String value) {
    radioSelections[key] = value;
    updateFormData(key, value);
  }

  //validations for the dynamic form
  String? validateTextField(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field cannot be empty';
    }
    return null;
  }

  String? validateDropdown(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select an option';
    }
    return null;
  }

  Future<void> updateData(String endpoint) async {
    try {
      print(
        "UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUubmitted Data ",
      );
      print(jsonEncode(formData));

      await ApiService().updateData(endpoint, formData["_id"], formData);
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        const SnackBar(
          content: Text('Data Updated Successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Get.back(result: true);
    } catch (e) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text('Error Updating data: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print(e);
    }
  }

  Future<void> submitForm(String endpoint) async {
    // Show a circular progress indicator

    try {
      Get.dialog(
        const Center(child: CustomProgressIndicator()),
        barrierDismissible: false, // Prevent dismissing the dialog
      );
      // Add a delay to simulate form processing or data initialization
      await Future.delayed(const Duration(seconds: 2, microseconds: 500));

      // Debugging: Print form data to the console
      print("Form Submission Started...");
      print(
        "Submitted Data:------------------>>>>>>>>>>>>>> ${jsonEncode(formData)}",
      );

      Get.back();
    } catch (e) {
      print("Error during form submission: $e");

      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      // Show an error message
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (Get.isDialogOpen ?? false) {
        Get.back(result: formData);
        Get.delete<SubFormController>();
      }
    }
  }

  Future<void> fetchGeolocation(String fieldKey) async {
    try {
      // Show loading dialog
      Get.dialog(
        const LocationProgressIndicator(),

        barrierDismissible: false, // Prevent dismissing the dialog manually
      );

      // Fetch the user's geolocation
      Position position = await LocationService().determinePosition();
      String latLong = "${position.latitude}, ${position.longitude}";

      // Update the form data with the geolocation
      updateFormData(fieldKey, latLong);
      print("Geolocation fetched: $latLong");

      // Optional: Notify the user of success
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        const SnackBar(
          content: Text('Geolocation fetched successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error fetching location: $e");

      // Optional: Notify the user of the error
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text('Error fetching geolocation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Close the loading dialog
      Get.back();
    }
  }
}
