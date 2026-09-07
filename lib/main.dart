import 'package:axiomos_workforce/routes/routes.dart';
import 'package:axiomos_workforce/routes/routes_string.dart';
import 'package:axiomos_workforce/services/connection_service.dart';
import 'package:axiomos_workforce/services/load_dropdown_data.dart';
import 'package:axiomos_workforce/views/home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await loadDropdownData();

  runApp(const MyApp());

  FlutterNativeSplash.remove();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    Get.put(ConnectivityService());
    return GetMaterialApp(
      title: 'Axiomos Workforce',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF9F9FD),
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B35D5)),
      ),
      initialRoute: Routes.homePage,
      getPages: AppRoutes.routes,
    );
  }
}
