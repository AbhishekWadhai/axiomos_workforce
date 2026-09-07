import 'dart:async';
import 'dart:io';

import 'package:axiomos_workforce/constants/app_strings.dart';
import 'package:axiomos_workforce/helpers/dialogos.dart';
import 'package:axiomos_workforce/model/form_data_model.dart';

import 'package:axiomos_workforce/views/saved_form_data/saved_form_data_controller.dart';
import 'package:axiomos_workforce/widgets/custom_alert_dialog.dart';
import 'package:axiomos_workforce/widgets/dynamic_form/form_helpers.dart';
import 'package:axiomos_workforce/widgets/progress_indicators.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import 'package:axiomos_workforce/services/api_services.dart';
import 'package:axiomos_workforce/services/connection_service.dart';
import 'package:axiomos_workforce/services/image_service.dart';
import 'package:axiomos_workforce/services/load_dropdown_data.dart';
import 'package:axiomos_workforce/services/location_service.dart';

import 'package:axiomos_workforce/services/text_formatters.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class DynamicFormController extends GetxController {
  RxBool isOnline = false.obs;
  String? formId;
  RxInt severity = 1.obs;
  RxInt likelihood = 1.obs;
  RxString riskLevel = 'Low'.obs;
  //checklist variables
  RxList<Map<String, dynamic>> checkList = <Map<String, dynamic>>[].obs;
  RxMap<String, String> checklistResponses = <String, String>{}.obs;
  final imageUploading = <String, bool>{}.obs;
  RxList<PageField> additionalFields = <PageField>[].obs;
  RxBool isSaved = false.obs;
  final CameraService cameraService = CameraService();
  RxMap<String, dynamic> customFields = <String, dynamic>{}.obs;
  // Observable variables
  var formResponse = <ResponseForm>[].obs;
  var isLoading = true.obs;
  RxList<PageField> pageFields = <PageField>[].obs;
  Map<String, Rx<dynamic>> formData = {};

  Map<String, Timer?> debounceMap = {};
  RxMap<String, String> dropdownSelections = <String, String>{}.obs;
  RxMap<String, String> radioSelections = <String, String>{}.obs;
  String pagename = "";
  bool fieldsLoaded = false;
  final Map<String, TextEditingController> textControllers = {};
  RxMap<String, SignatureController> signatureControllers =
      <String, SignatureController>{}.obs;
  // Selected chips observable
  var selectedChips = <String>[].obs;
  // Observable list for storing attendees' names as maps
  final RxMap<String, RxList<Map<String, dynamic>>> subformData =
      <String, RxList<Map<String, dynamic>>>{}.obs;
  final imageErrors = <String, String?>{}.obs;
  final matrixError = <String, String?>{}.obs;
  final SavedFormDataController saveFormController = Get.find();
  var selectedFilesMap = <String, List<Map<String, dynamic>>>{}.obs;
  // Lifecycle hook
  @override
  void onInit() {
    super.onInit();
  }

  RxList<Map<String, dynamic>> getSubformData(String key) {
    if (!subformData.containsKey(key)) {
      subformData[key] = <Map<String, dynamic>>[].obs;
    }

    return subformData[key]!;
  }

  bool get allUploaded {
    final files = formData.values
        .whereType<List>() // only lists
        .expand((e) => e)
        .whereType<Map<String, dynamic>>() // only maps
        .toList();

    return files.isNotEmpty && files.every((f) => f['uploadStatus'] == 'done');
  }

  void initChecklist(List<Map<String, dynamic>> items) {
    for (var item in items) {
      final title = item['CheckPoints'] ?? item['question'];
      final defaultResponse =
          item['response'] ?? item['defaultResponse'] ?? 'No';

      if (!checklistResponses.containsKey(title)) {
        checklistResponses[title] = defaultResponse;
      }
    }
  }

  void updateChecklist(String title, String value) {
    checklistResponses[title] = value;
  }

  void saveChecklistToForm(String endpoint) {
    printLargeJson(checklistResponses);
    printLargeJson(checkList);

    // Possible field name variations
    const possibleQuestionKeys = ["CheckPoints", "question", "label"];
    const possibleResponseKeys = [
      "response",
      "defaultResponse",
      "answer",
      "value",
    ];

    for (var item in checkList) {
      // ---- 1️⃣ Find actual question key ----
      String? questionKey = possibleQuestionKeys.firstWhere(
        (key) => item.containsKey(key),
        orElse: () => "",
      );

      if (questionKey.isEmpty) continue; // Skip if no matching field

      final checkpointText = item[questionKey];

      // ---- 2️⃣ If question exists in responses map, update response field ----
      if (checklistResponses.containsKey(checkpointText)) {
        // Find the matching field to update
        String? responseKey = possibleResponseKeys.firstWhere(
          (key) => item.containsKey(key),
          orElse: () => "",
        );

        if (responseKey.isNotEmpty) {
          item[responseKey] = checklistResponses[checkpointText];
        } else {
          // If no response field exists → create one
          item["response"] = checklistResponses[checkpointText];
        }
      }
    }

    // ---- 3️⃣ Store updated list ----
    final key = endpoint == "workpermit" ? "safetyMeasuresTaken" : "details";

    // 🔥 Ensure key exists
    if (!formData.containsKey(key)) {
      formData[key] = Rx<dynamic>([]);
    }

    // 🔥 Now assign
    formData[key]!.value = List.from(checkList);

    //printLargeJson(formData);
  }

  Future<String> uploadFile(
    PageField field,
    Map<String, dynamic> file,
    String endpoint,
  ) async {
    print("!!!!!!!!!!!!!!!!!!!!!$endpoint");
    file['uploadStatus'] = 'uploading';
    //formData.refresh();

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://rohanbackend.axiomos.in/$endpoint/file'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // API parameter name
          file['path'],
        ),
      );

      final response = await request.send();
      print("8************************${response.statusCode}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        final resBody = await response.stream.bytesToString();
        final data = jsonDecode(resBody);

        // Replace path with URL from server
        // file['path'] = data['url']; // assumes API returns {"url": "..."}
        file['uploadStatus'] = 'done';
        return data["url"];
      } else {
        file['uploadStatus'] = 'error';
        return "";
      }
    } catch (e) {
      file['uploadStatus'] = 'error';
      return "";
    }

    //formData.refresh();
  }

  //////////////////////////////////////////////////////////////////Initilization Part////////////////////////////////////////////////////////
  /// Ensures page fields for [pageName] are loaded only once.
  /// Use this in `initState` of your widget, not in build!
  Future<void> ensurePageFieldsLoaded(
    String pageName, [
    Map<String, dynamic>? initialData,
  ]) async {
    if (pagename != pageName || pageFields.isEmpty) {
      isLoading.value = true;
      //--------------Vulneratbel to runtime errors-----------------------------------
      isOnline = ConnectivityService.to.isConnected;
      await loadFormData();
      await getPageFields(pageName);
      initializeFormData(initialData); // can be null
      isLoading.value = false;
    }
  }

  Future<List<String>> getSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('locations') ?? [];
  }

  Future<void> getPageFields(String pageName) async {
    pageFields.value = await formResponse
        .where((e) => e.page == pageName)
        .expand((e) => e.pageFields)
        .toList();
    //update();
  }

  // Form Data Loader
  Future<void> loadFormData() async {
    isLoading(true);
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        await loadJsonFromAssets();
      } else {
        await loadJsonFromAssets(); // Replace with loadJsonFromApi() for online mode
      }
      print("Form data loaded: $formData");
    } catch (e) {
      print("Error loading form data: $e");
    } finally {
      isLoading(false);
    }
  }

  getCustomFields(String permitKey) {
    final newFields = Strings.workpermitPageField;
    if (newFields != null) {
      // Find the matching permit by comparing permitsType with checklistKey   2025-07-15 00:00:00.000-------12:28 PM
      final matchingFields = newFields.firstWhere((permit) {
        print(
          "Comparing--------${permit["permitType"]["permitsType"]}--with--$permitKey ",
        );
        return permit["permitType"]["permitsType"] == permitKey;
      }, orElse: () => null);
      print(
        ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::$matchingFields",
      );
      printLargeJson(matchingFields);
      if (matchingFields != null) {
        // Assign its SafetyChecks to checkList.value
        additionalFields.value =
            (matchingFields["PageFields"] as List<dynamic>?)
                ?.map((e) => PageField.fromJson(e as Map<String, dynamic>))
                .toList()
                .cast<PageField>() ??
            [];
      } else {
        // If no match is found, clear the checklist
        print(
          ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::if null",
        );
        print(matchingFields);
      }
    }
  }

  // Function to check if the user has permission to view a field
  bool hasViewPermission(List<String> requiredPermissions) {
    return requiredPermissions.isEmpty ||
        requiredPermissions.any((perm) => Strings.permisssions.contains(perm));
  }

  // Function to check if the user has permission to edit a field
  bool hasEditPermission(List<String> requiredPermissions) {
    return requiredPermissions.isEmpty ||
        requiredPermissions.any((perm) => Strings.permisssions.contains(perm));
  }
  //////////////////////////////////////////////////////////////////Initilization Part////////////////////////////////////////////////////////

  ////////////////////////////////////////////////////Saving Form///////////////////////////////////////////////////////
  Future<String> saveSignatureLocally(String key, Uint8List bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$key-signature.png');
    await file.writeAsBytes(bytes);
    return file.path; // You can also prefix with "local://" if needed
  }

  void queueOfflineSignatureUpload(String key, String localPath) {
    // Add logic to save this to a sync queue
    // e.g., shared_preferences or local Hive box
    // So that once online, it can be uploaded and replaced with the URL
  }

  saveForm(String module) async {
    isSaved.value = !isSaved.value;
    updateFormDataFromControllers();
    formData["customFields"]?.value = customFields;

    // Get current date and time
    DateTime now = DateTime.now();
    String currentDate = now.toString(); // Example: "2025-07-15 00:00:00.000"
    String currentTime = DateFormat.jm().format(now); // Example: "12:28 PM"

    // Set defaults if null
    String date = formData['date']?.value ?? currentDate;
    String time = module == 'workpermit'
        ? formData['StartTime']?.value ?? currentTime
        : formData['time'] ?? currentTime;

    print("----$module--------$date-------$time");

    formId = await saveFormController.saveFormData(
      date,
      time,
      module,
      formData,
    );
  }

  unsaveForm() {
    isSaved.value = false;
    saveFormController.removeFormData(formId ?? "");
  }

  void initializeFormData(Map<String, dynamic>? initialData) {
    printLargeJson(initialData);

    if (initialData != null) {
      initialData.forEach((key, value) {
        // Find corresponding page field
        PageField? pageField = pageFields.firstWhere(
          (field) => field.headers == key,
          orElse: () => PageField(headers: '', type: '', title: "", id: ""),
        );

        String fieldType = pageField.type;

        // Ensure reactive wrapper exists
        if (!formData.containsKey(key)) {
          formData[key] = Rx<dynamic>(null);
        }

        // Assign value based on type
        if (value is List) {
          formData[key]!.value = value.map((e) {
            if (e is Map) {
              if (e.containsKey("_id")) {
                // Multiselect: store only _id
                return fieldType == "multiselect"
                    ? e["_id"].toString()
                    : Map<String, dynamic>.from(e);
              } else {
                // Checklist: store full map
                return Map<String, dynamic>.from(e);
              }
            } else {
              return e;
            }
          }).toList();
          print("✅ Stored list under [$key]: ${formData[key]!.value}");
        } else if (value is Map) {
          formData[key]!.value = Map<String, dynamic>.from(value);
        } else {
          formData[key]!.value = value;
        }
      });
    }

    // Parse checklist data
    final dynamic rawList =
        formData["safetyMeasuresTaken"]?.value ??
        formData["checkpoints"]?.value;
    if (rawList is List) {
      checkList.value = rawList
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .where(
            (map) =>
                (map.containsKey('CheckPoints') &&
                    map.containsKey('response')) ||
                (map.containsKey('question') && map.containsKey('response')),
          )
          .toList();
    } else {
      checkList.value = [];
    }

    // Parse custom fields
    customFields.value =
        (formData["customFields"]?.value as Map<String, dynamic>?) ?? {};

    // Handle permit type for custom fields
    getCustomFields(
      (formData["permitTypes"]?.value is String)
          ? formData["permitTypes"]!.value
          : formData["permitTypes"]?.value?["_id"] ?? "",
    );

    print("✅ Initialized form data");
    print("📝 Comments: ${jsonEncode(formData["comment"]?.value)}");
  }

  void updateSwitchSelection(String header, bool newValue) {
    formData[header]?.value = newValue;
    update(); // Update the UI if using GetX
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
      imageUploading[key] = true;
      if (imageFile == null) {
        print('No image selected.');
        return;
      }

      if (isOnline.value) {
        String? imageUrl = await cameraService.uploadImage(
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
      } else {
        updateFormData(key, imageFile.path);
        print('Offline: Saved image path locally');
      }
    } catch (e) {
      print('Error during image upload: $e');
    } finally {
      // Close only the loading dialog
      imageUploading[key] = false;
      // if (Navigator.of(Get.context!).canPop()) {
      //   Navigator.of(Get.context!).pop(); // closes only the dialog
      // }
    }
  }

  Future<String?> saveSignature(String key, String endpoint) async {
    File? imageFile;
    final controller = signatureControllers[key];
    if (controller != null && controller.isNotEmpty) {
      // Show the loading dialog
      Get.dialog(
        const Center(child: ImageProgressIndicator()),
        barrierDismissible: false, // Prevent dismissing the dialog
      );

      try {
        // Convert the signature to bytes
        final bytes = await controller.toPngBytes();
        final directory = await getApplicationDocumentsDirectory();
        imageFile = File(
          '${directory.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        print(
          "----------${directory.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png----------------",
        );

        // Save the bytes to the file
        await imageFile.writeAsBytes(bytes!);

        if (imageFile != null) {
          // Upload the image and get the URL
          String? imageUrl = await cameraService.uploadImage(
            imageFile,

            true,
            category: endpoint,
          );

          if (imageUrl != null) {
            // Save the image URL in the formData
            print('Image uploaded successfully: $imageUrl');
            return imageUrl;
          } else {
            print('Image upload failed.');
            return "";
          }
        }
      } catch (e) {
        print("Error: $e");
        return "";
      } finally {
        // Close the loading dialog
        Get.back();
      }
    } else {
      throw Exception("Signature is empty");
    }
  }

  // Toggle chip selection for multi-select fields
  void toggleChipSelection(String chipValue) {
    if (selectedChips.contains(chipValue)) {
      selectedChips.remove(chipValue);
    } else {
      selectedChips.add(chipValue);
    }
  }

  // Form Fields Loader

  // Method to add a new attendee
  //TODO:add a mothod to get a single map instead of a list of maps and add it to the subformData list
  void addAttendee(Map<String, String> attendee) {
    print("function called");
    //subformData.add(attendee);
    print("Updated attendees list: $subformData");
  }

  // Load JSON from Assets
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
    } catch (e) {
      print("Error loading JSON from assets: $e");
    }
  }

  // Load JSON from API
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

  // Update form data for input fields
  void updateFormData(String key, dynamic value) {
    print("Updating form data: $value");

    // Ensure key exists and is reactive
    if (!formData.containsKey(key)) {
      formData[key] = Rx<dynamic>(value);
    } else {
      formData[key]!.value = value;
    }

    print("Updated form data: ${formData[key]?.value}");
  }

  // Update dropdown selection
  void updateDropdownSelection(String key, String value) {
    dropdownSelections[key] = value;
    updateFormData(key, value);
  }

  // Update radio button selection
  void updateRadioSelection(String key, String value) {
    radioSelections[key] = value;
    updateFormData(key, value);
  }

  // Get dropdown data dynamically from API
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
  }

  Future<void> submitForm(String endpoint) async {
    saveChecklistToForm(endpoint);

    updateFormDataFromControllers();
    formData["customFields"]?.value = customFields;
    bool isValid = true;
    final cleaned = cleanFormData(formData);
    printLargeJson(cleaned);
    for (var field in pageFields) {
      switch (field.type) {
        case 'imagepicker':
          if (!validateImagePickerField(
            field.headers,
            field.title,
            isEditable: hasEditPermission(field.permissions?.edit ?? []),
          )) {
            isValid = false;
          }
          break;
        case 'signature':
          if (!validateSignatureField(
            field.headers,
            field.title,
            isEditable: hasEditPermission(field.permissions?.edit ?? []),
          )) {
            isValid = false;
          }
          break;
        case 'riskMatrix':
          if (!validateRiskMatrixField(
            field.headers,
            field.title,
            isEditable: hasEditPermission(field.permissions?.edit ?? []),
          )) {
            isValid = false;
          }
          break;
      }
    }

    if (!isValid) {
      Get.snackbar(
        "Validation Failed",
        "Please complete all required fields",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final bool isConfirmed = await Get.dialog(
      CustomAlertDialog(
        title: "Confirmation",
        description: "Are you sure you want to submit the Data?",
        buttons: [
          CustomDialogButton(
            onPressed: () {
              Get.back(result: false);
            },
            label: "Cancel",
          ),
          CustomDialogButton(
            onPressed: () {
              Get.back(result: true);
            },
            label: "Submit",
          ),
        ],
      ),
    );

    if (isConfirmed != true) return;

    // 🚦 Connectivity Check
    //final connectivityResult = await Connectivity().checkConnectivity();
    // final bool isOnline = isOn

    // Assign a UUID if not already assigned
    formData["formId"]?.value ??= const Uuid().v4();
    formData["endpoint"]?.value = endpoint; // Store for later syncing

    if (!isOnline.value) {
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      List<String> offlineForms = prefs.getStringList("offlineForms") ?? [];

      offlineForms.add(jsonEncode(formData));
      await prefs.setStringList("offlineForms", offlineForms);

      Get.snackbar(
        icon: Icon(Icons.wifi_off_rounded),
        "You are OFFLINE",
        "Form saved locally, will sync when online",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    isLoading(true);
    try {
      await Future.delayed(const Duration(milliseconds: 2500));

      final response = await ApiService().postRequest(endpoint, cleaned);

      if (response != null || response == 200 || response == 201) {
        showSuccessDialog(
          title: "Successful",
          message: "Data submitted successfully, press OK to continue",
        );
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        "Error",
        "Error Submitting data: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  // Data Update

  Future<void> updateData(String endpoint) async {
    // saveChecklistToForm(endpoint);
    // updateFormDataFromControllers();
    // formData["customFields"]?.value = customFields;
    saveChecklistToForm(endpoint);

    updateFormDataFromControllers();
    formData["customFields"]?.value = customFields;

    final cleaned = cleanFormData(formData);
    printLargeJson(cleaned);

    final isConfirmed = await Get.dialog(
      AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Are you sure you want to update the data?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text("Update"),
          ),
        ],
      ),
    );

    if (isConfirmed != true) return;

    // Set isLoading to true to show the loading indicator
    isLoading.value = true;

    try {
      // Simulate delay for API call
      await Future.delayed(const Duration(seconds: 2));

      // Make API call
      final response = await ApiService().updateData(
        endpoint,
        formData["_id"]?.value,
        cleaned,
      );

      // Stop loading indicator
      isLoading.value = false;

      if (response == 200 || response == 201) {
        // Show success dialog
        showSuccessDialog(
          title: "Update Successful",
          message: "Data updated successfully, press OK to continue",
        );
      } else {
        throw Exception("Unexpected response code: $response");
      }
    } catch (e) {
      // Stop loading on error
      isLoading.value = false;

      // Show error snackbar
      Get.snackbar(
        "Error",
        "Error updating data: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      print(e);
    }
  }

  // Fetch Geolocation
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
      String? locationName = await LocationService().determineLocationName();

      // Update the form data with the geolocation
      String result = "$locationName ($latLong)";
      updateFormData(fieldKey, result);
      print("Geolocation fetched: $result");

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
      if (Get.isDialogOpen ?? false) {
        Get.back(); // closes dialog only
      }
    }
  }

  // Validations for form fields------------------------------------------//

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

  String? validateMultiSelect(List<String>? values) {
    if (values == null || values.isEmpty) {
      return 'Please select at least one option';
    }
    return null;
  }

  bool validateImagePickerField(
    String fieldKey,
    String fieldTitle, {
    bool isEditable = true,
  }) {
    if (!isEditable) return true; // Skip validation if field is not editable

    final imageUrl = formData[fieldKey];
    if (imageUrl == null || imageUrl.toString().isEmpty) {
      imageErrors[fieldKey] = "$fieldTitle is required";
      return false;
    } else {
      imageErrors[fieldKey] = null;
      return true;
    }
  }

  bool validateRiskMatrixField(
    String fieldKey,
    String fieldTitle, {
    bool isEditable = true,
  }) {
    if (!isEditable) return true; // Skip validation if field is not editable

    final riskValue = formData[fieldKey];
    if (riskValue == null || riskValue.toString().isEmpty) {
      matrixError[fieldKey] =
          "$fieldTitle should be Updated please select again";
      return false;
    } else {
      matrixError[fieldKey] = null;
      return true;
    }
  }

  bool validateSignatureField(
    String fieldKey,
    String fieldTitle, {
    bool isEditable = true,
  }) {
    if (!isEditable) return true; // Skip validation if field is not editable

    final signatureUrl = formData[fieldKey];
    if (signatureUrl == null || signatureUrl.toString().isEmpty) {
      imageErrors[fieldKey] = "$fieldTitle is required"; // reuse same error map
      return false;
    } else {
      imageErrors[fieldKey] = null;
      return true;
    }
  }

  void updateFormDataFromControllers() {
    textControllers.forEach((key, textController) {
      if (formData.containsKey(key)) {
        formData[key]!.value = textController.text;
      } else {
        // create new Rx if missing
        formData[key] = textController.text.obs;
      }
    });
  }

  // Validations for form fields------------------------------------------//
  //   sendNotification(String source, bool isUpdate) {
  //     switch (source) {
  //       case "uauc":
  //         isUpdate
  //             ? NotificationHandler().sendNotification(notifications: [
  //                 {
  //                   "userId": formData["createdby"],
  //                   "title": "Update UAUC",
  //                   "message": "An Update made in UAUC, Check It out",
  //                   "source": "uauc"
  //                 }
  //               ])
  //             : NotificationHandler().sendNotification(notifications: [
  //                 {
  //                   "userId": formData["assignedTo"],
  //                   "title": "UAUC REPORTED",
  //                   "message":
  //                       "UAUC Incident Assigned, Take Necessary actions ASAP ",
  //                   "source": "uauc"
  //                 }
  //               ]);
  //         break;
  //       case "workpermit":
  //         if (isUpdate) {
  //           if (true) {
  //             print(
  //                 "----------------sending update notification ${formData["createdby"]}");
  //             NotificationHandler().sendNotification(notifications: [
  //               {
  //                 "userId": formData["createdby"]["_id"],
  //                 "title": "Work Permit Verified",
  //                 "message": "An Update made in Work Permit, Check It out",
  //                 "source": "workpermit",
  //               }
  //             ]);
  //           } else {
  //             print(
  //                 "----------------sending failed in edit notification ${formData["verifiedDone"]}");
  //           }
  //         } else {
  //           // Map assignedTo list into the notification format
  //           List<Map<String, String>> notifications =
  //               (formData["verifiedBy"] as List<String>).map((String userId) {
  //             return {
  //               "userId": userId,
  //               "title": "Work Permit Verification",
  //               "message": "New Work Permit created, Please verify it",
  //               "source": "workpermit",
  //             };
  //           }).toList();

  // // Pass the entire list to sendNotification
  //           NotificationHandler().sendNotification(notifications: notifications);
  //         }
  //         break;
  //     }
  //   }

  void calculateRiskLevel() {
    final score = severity.value * likelihood.value;
    if (score <= 3) {
      riskLevel.value = 'Low';
    } else if (score < 8) {
      riskLevel.value = 'Medium';
    } else if (score < 12) {
      riskLevel.value = 'High';
    } else {
      riskLevel.value = 'Critical';
    }
    final matchedValue = Strings.endpointToList["RiskRating"].firstWhere((e) {
      return e['severity'] == riskLevel.value;
    }, orElse: () => null);

    if (matchedValue != null) {
      if (formData.containsKey('riskValue')) {
        formData['riskValue']!.value = matchedValue;
      } else {
        formData['riskValue'] = Rx<dynamic>(matchedValue);
      }

      print(formData['riskValue']);
      // Parse the alert timeline (in hours)
      final int timelineHours =
          int.tryParse(matchedValue['alertTimeline'] ?? '0') ?? 0;

      // Calculate deadline
      final DateTime deadline = DateTime.now().add(
        Duration(hours: timelineHours),
      );

      // Format deadline nicely
      final String formattedDeadline =
          "${deadline.day.toString().padLeft(2, '0')}/"
          "${deadline.month.toString().padLeft(2, '0')}/"
          "${deadline.year} at ${deadline.hour.toString().padLeft(2, '0')}:"
          "${deadline.minute.toString().padLeft(2, '0')}";

      // Show the dialog
      showRiskDialog(
        riskLevel: riskLevel,
        formattedDeadline: formattedDeadline,
        matchedValue: matchedValue,
        timelineHours: timelineHours,
      );
    }

    print(formData);
  }

  Future<void> refreshDropdownData() async {
    print("refreshing data-----------------------");
    isLoading.value = true;
    await loadDropdownData(); // Loads the latest dropdowns globally or for this form
    refresh(); // Reinitializes fields
    isLoading.value = false;
  }
  //Risk Calculation-------------------------------------------------------------

  SignatureController getSignatureController(String fieldKey) {
    if (!signatureControllers.containsKey(fieldKey)) {
      signatureControllers[fieldKey] = SignatureController();
    }
    return signatureControllers[fieldKey]!;
  }

  TextEditingController getTextController(String fieldHeader) {
    print(formData[fieldHeader]);
    if (!textControllers.containsKey(fieldHeader)) {
      print(formData[fieldHeader]);
      // Create a new controller if it doesn't exist
      textControllers[fieldHeader] = TextEditingController(
        text: formData[fieldHeader]?.toString() ?? '',
      );
    }
    return textControllers[fieldHeader]!;
  }

  getSafetyChecklist(String checklistKey) {
    final permitsList = Strings.endpointToList["permitstype"];

    if (permitsList != null) {
      // Find the matching permit by comparing permitsType with checklistKey
      final matchingPermit = permitsList.firstWhere(
        (permit) => permit["permitsType"] == checklistKey,
        orElse: () => null,
      );

      if (matchingPermit != null) {
        // Assign its SafetyChecks to checkList.value
        checkList.value =
            (matchingPermit["SafetyChecks"] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [];
      } else {
        // If no match is found, clear the checklist
        checkList.clear();
      }
    } else {
      // If permitsList is null, clear the checklist
      checkList.clear();
    }
  }

  getChecklist(String checklistKey) {
    final tempCheckList = Strings.endpointToList["prefilledchecklist"];

    if (tempCheckList != null) {
      // Find the matching permit by comparing permitsType with checklistKey
      final matchingPoint = tempCheckList.firstWhere(
        (checkpoint) => checkpoint["checklistName"] == checklistKey,
        orElse: () => null,
      );

      if (matchingPoint != null) {
        // Assign its SafetyChecks to checkList.value
        checkList.value =
            (matchingPoint["items"] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [];
      } else {
        // If no match is found, clear the checklist
        checkList.clear();
      }
    } else {
      // If permitsList is null, clear the checklist
      checkList.clear();
    }
  }
}
