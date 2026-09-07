import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationService {
  /// Determine the current position of the device.
  Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  /// Determine the name of the current location based on coordinates.
  Future<String?> determineLocationName({Position? position}) async {
    try {
      position ??= await determinePosition();

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String locationName = [
          place.subLocality,
          place.locality,
        ].where((e) => e != null && e.isNotEmpty).join(", ");

        return locationName.isNotEmpty ? locationName : "Unknown locality";
      }
    } catch (e, stacktrace) {
      print("___--------------------------_______________------------------------------------");
      debugPrint("⚠️ Geocoding error: $e\n$stacktrace");
    }

    return null;
  }
}

void showGeolocationDialog({
  required double latitude,
  required double longitude,
  Function(LatLng)? onLocationSelected, // Make it optional
}) {
  Get.defaultDialog(
    title: "Geolocation",
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 300.0,
          width: double.infinity,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(latitude, longitude),
              zoom: 15.0,
            ),
            markers: {
              Marker(
                markerId: const MarkerId("currentLocation"),
                position: LatLng(latitude, longitude),
                draggable: true,
                onDragEnd: (LatLng newPosition) {
                  if (onLocationSelected != null) {
                    onLocationSelected(
                        newPosition); // Call only if it's provided
                  }
                  Get.back(); // Close the dialog
                },
              ),
            },
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () async {
            String googleMapsUrl =
                "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude";
            if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
              await launchUrl(Uri.parse(googleMapsUrl),
                  mode: LaunchMode.externalApplication);
            } else {
              Get.snackbar("Error", "Could not open Google Maps");
            }
          },
          child: const Text("Open in Maps"),
        ),
      ],
    ),
  );
}
