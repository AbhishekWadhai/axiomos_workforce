import 'package:axiomos_workforce/routes/bindings.dart';
import 'package:axiomos_workforce/routes/routes_string.dart';
import 'package:axiomos_workforce/views/attendance_view.dart';
import 'package:axiomos_workforce/views/form_page.dart';
import 'package:axiomos_workforce/views/home_view.dart';
import 'package:axiomos_workforce/views/mobilisation/mobilisation_view.dart';
import 'package:axiomos_workforce/views/module_page.dart';
import 'package:get/get.dart';

class AppRoutes {
  static final routes = [
    GetPage(name: Routes.homePage, page: () => HomeView()),
    GetPage(name: Routes.markAttendancePage, page: () => MarkAttendanceView()),
    GetPage(
      name: Routes.formPage,
      page: () => FormPage(),
      binding: SavedFormDataBindings(),
    ),
    GetPage(name: Routes.modulePage, page: () => DynamicModulePage()),
    GetPage(
      name: Routes.mobilisationPlanView,
      page: () => MobilisationPlanView(),
    ),
  ];
}
