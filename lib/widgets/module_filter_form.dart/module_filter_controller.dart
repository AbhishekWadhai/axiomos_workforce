import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:axiomos_workforce/constants/app_strings.dart';
import 'package:axiomos_workforce/model/filter_model.dart';

class ModuleFilterController extends GetxController {
  final RxMap<String, dynamic> selectedFilters = <String, dynamic>{}.obs;

  final RxList<Filter> filterFields = <Filter>[].obs;

  final Map<String, TextEditingController> textControllers = {};

  void ensurePageFieldsLoaded(List<Filter> filterList) {
    filterFields.assignAll(filterList);
  }

  void updateFormData(String key, dynamic value) {
    selectedFilters[key] = value;
  }

  void clearSelection() {
    selectedFilters.clear();

    for (final controller in textControllers.values) {
      controller.clear();
    }
  }

  TextEditingController getTextController(String fieldHeader) {
    return textControllers.putIfAbsent(
      fieldHeader,
      () => TextEditingController(
        text: selectedFilters[fieldHeader]?.toString() ?? '',
      ),
    );
  }

  List<Map<String, String>> getDropdownData(String endpoint, String key) {
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

  @override
  void onClose() {
    for (final controller in textControllers.values) {
      controller.dispose();
    }

    textControllers.clear();

    super.onClose();
  }
}
