import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

/// Function to request specific permissions: location, data connectivity, storage, and camera
/// Returns a `Map` with the permission as the key and its status as the value.
Future<Map<Permission, PermissionStatus>> requestEssentialPermissions() async {
  // List of required permissions
  final permissions = [
    Permission.location, // For location access
    Permission.locationWhenInUse, // Location when the app is in use
    Permission.storage, // For storage access
    //Permission.camera,             // For camera access
  ];

  Map<Permission, PermissionStatus> statuses = {};

  // Request necessary permissions
  for (Permission permission in permissions) {
    // Check the current status of the permission
    PermissionStatus status = await permission.status;

    if (status.isDenied || status.isPermanentlyDenied) {
      // Request the permission if it hasn't been granted
      status = await permission.request();
    }

    // Add the result to the map
    statuses[permission] = status;
  }

  // Check location services and request to enable it if needed
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    showToast("Location services are disabled. Please enable them.");
    openLocationSettings();
  } else {
    // Check for location permission
    LocationPermission locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();
      if (locationPermission == LocationPermission.denied) {
        showToast("Location permission is denied.");
      }
    }
  }

  // Check network connectivity and request user to enable it if needed
  List<ConnectivityResult> connectivityResults =
      await Connectivity().checkConnectivity();
  if (connectivityResults.isEmpty) {
    showToast("No internet connection. Please enable Wi-Fi or Mobile Data.");
    //openNetworkSettings();
  }

  return statuses;
}

/// Opens the device's location settings for the user to enable it
void openLocationSettings() {
  Geolocator.openLocationSettings();
}

/// Opens the device's network settings for the user to enable Wi-Fi or Mobile Data
// void openNetworkSettings() async {
//   if (await canLaunch('App-prefs:') || await canLaunch('android.settings.WIFI_SETTINGS')) {
//     await launch('android.settings.WIFI_SETTINGS'); // Opens Wi-Fi settings on Android
//   } else {
//     showToast("Cannot open network settings.");
//   }
// }

/// Show GetX toast (snack bar) message
void showToast(String message) {
  Get.snackbar(
    'Alert', // The title of the snack bar
    message, // The content of the snack bar
    snackPosition: SnackPosition.BOTTOM, // Position at the bottom of the screen
    backgroundColor: Colors.black.withOpacity(0.7),
    colorText: Colors.white,
    margin: EdgeInsets.all(10),
    borderRadius: 8,
    duration: Duration(seconds: 3), // How long the toast is shown
  );
}
