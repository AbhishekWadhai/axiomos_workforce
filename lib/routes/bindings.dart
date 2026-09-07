import 'package:axiomos_workforce/views/saved_form_data/saved_form_data_controller.dart';
import 'package:get/get.dart';

class SavedFormDataBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SavedFormDataController());
  }
}