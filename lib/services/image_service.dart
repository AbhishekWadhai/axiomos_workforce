import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
//import 'package:image/image.dart' as img_pkg;
import 'package:camera/camera.dart';
import 'package:intl/intl.dart';
import 'package:http_parser/http_parser.dart';

import 'package:path/path.dart'; // For handling file paths
import 'package:path_provider/path_provider.dart';

class CameraService with ChangeNotifier {
  late CameraController _controller;
  late List<CameraDescription> _cameras;
  int _currentCameraIndex = 0;
  bool _isInitialized = false;

  // Initialize the camera
  Future<void> initializeCamera() async {
    try {
      _cameras = await availableCameras();
      _currentCameraIndex = 0;

      await _initController();
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _initController() async {
    _controller = CameraController(
      _cameras[_currentCameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller.initialize();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;

    _isInitialized = false;
    notifyListeners();

    await _controller.dispose();

    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;

    await _initController();
  }

  // Function to capture an image
  Future<File?> captureImage() async {
    if (!_isInitialized) {
      print('Camera is not initialized.');
      return null;
    }

    try {
      // Capture image
      final XFile picture = await _controller.takePicture();
      return File(picture.path);
    } catch (e) {
      print('Error capturing image: $e');
      return null;
    }
  }

  // Function to upload image to API and retrieve the URL
  Future<String?> uploadImage(
    File image,

    bool isSignature, {
    String? customFileName,

    required String category,
  }) async {
    File? imageFile = isSignature ? image : await compressImage(image);

    if (imageFile == null) {
      print("Image compression failed.");
      return null;
    }

    try {
      final url = Uri.parse('https://jkumarlabourtrackerapi.axiomos.in/image');

      final request = http.MultipartRequest('POST', url);

      // Required fields
      request.fields['referenceId'] =
          'image-${DateTime.now().millisecondsSinceEpoch}';
      request.fields['category'] = category;

      // File extension
      final fileExtension = extension(imageFile.path).toLowerCase();

      MediaType? contentType;

      switch (fileExtension) {
        case '.jpg':
        case '.jpeg':
          contentType = MediaType('image', 'jpeg');
          break;

        case '.png':
          contentType = MediaType('image', 'png');
          break;

        case '.webp':
          contentType = MediaType('image', 'webp');
          break;

        default:
          print('Unsupported image format: $fileExtension');
          return null;
      }

      final fileName = customFileName != null
          ? '$customFileName$fileExtension'
          : basename(imageFile.path);

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          filename: fileName,
          contentType: contentType,
        ),
      );

      final response = await request.send();

      final responseBody = await http.Response.fromStream(response);

      print('Upload status: ${response.statusCode}');
      print('Upload response: ${responseBody.body}');

      if (response.statusCode == 201) {
        final result = jsonDecode(responseBody.body);

        if (result != null && result['data']['url'] != null) {
          print("--------------------------------------");
          print(result['data']["url"]);
          return result['data']['url'];
        }

        print('Invalid response format');
        return null;
      }

      print(
        'Failed to upload image. '
        'Status code: ${response.statusCode}',
      );

      return null;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<File?> compressImage(File imageFile) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = imageFile.absolute.path;

      final targetPath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';

      var compressedImage = await FlutterImageCompress.compressAndGetFile(
        filePath,
        targetPath,
        quality: 70,
        minWidth: 1080,
        minHeight: 1080,
      );

      if (compressedImage == null) {
        print('Compression failed.');
        return null;
      }

      return File(compressedImage.path);
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  // Dispose the camera controller
  Future<void> dispose() async {
    await _controller.dispose();
  }

  // Check if the camera is initialized
  bool get isInitialized => _isInitialized;

  // Provide the controller to be used in UI for camera preview
  CameraController get controller => _controller;
}

class CameraPreviewScreen extends StatefulWidget {
  final bool includeLocation;

  const CameraPreviewScreen({super.key, this.includeLocation = false});

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  late CameraController _controller;
  late List<CameraDescription> _cameras;

  bool _initialized = false;

  Position? _position;
  String _address = 'Location unavailable';

  final GlobalKey _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initEverything();
  }

  Future<void> _initEverything() async {
    try {
      // --------------------------------------------
      // Initialize camera
      // --------------------------------------------

      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      _controller = CameraController(
        _cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller.initialize();

      if (!mounted) return;

      // Camera is ready.
      // We do NOT wait for location.
      setState(() {
        _initialized = true;
      });

      // --------------------------------------------
      // Location is optional
      // --------------------------------------------

      if (widget.includeLocation) {
        await _tryGetLocation();
      }
    } catch (e) {
      debugPrint('Camera initialization failed: $e');

      if (!mounted) return;

      Get.snackbar(
        'Camera Error',
        'Unable to initialize camera.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _tryGetLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      // Request permission only when location
      // has explicitly been requested.
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // Location permission unavailable.
      // Camera should continue working.
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('Location permission not available');

        return;
      }

      // --------------------------------------------
      // Get current position
      // --------------------------------------------

      _position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // --------------------------------------------
      // Get address
      // --------------------------------------------

      await _getAddressFromLatLng();

      if (!mounted) return;

      setState(() {});
    } catch (e) {
      // Location failure must NOT affect camera.
      debugPrint('Location unavailable: $e');

      _position = null;
      _address = 'Location unavailable';

      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _getAddressFromLatLng() async {
    if (_position == null) {
      _address = 'Location unavailable';
      return;
    }

    try {
      final placemarks = await placemarkFromCoordinates(
        _position!.latitude,
        _position!.longitude,
      );

      if (placemarks.isEmpty) {
        _address = 'Address unavailable';
        return;
      }

      final place = placemarks.first;

      final parts = <String>[
        if (place.street?.isNotEmpty == true) place.street!,
        if (place.subLocality?.isNotEmpty == true) place.subLocality!,
        if (place.locality?.isNotEmpty == true) place.locality!,
        if (place.administrativeArea?.isNotEmpty == true)
          place.administrativeArea!,
      ];

      _address = parts.isNotEmpty ? parts.join(', ') : 'Address unavailable';
    } catch (e) {
      debugPrint('Address lookup failed: $e');

      _address = 'Address unavailable';
    }
  }

  Future<void> _captureStampedImage() async {
    try {
      if (!_initialized || !_controller.value.isInitialized) {
        debugPrint('Camera is not initialized');
        return;
      }

      final renderObject = _repaintKey.currentContext?.findRenderObject();

      if (renderObject is! RenderRepaintBoundary) {
        debugPrint('RepaintBoundary not found');
        return;
      }

      final boundary = renderObject;

      // --------------------------------------------
      // Capture the complete widget
      // --------------------------------------------

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        debugPrint('Failed to convert image to bytes');
        return;
      }

      final Uint8List bytes = byteData.buffer.asUint8List();

      // --------------------------------------------
      // Save temporary image
      // --------------------------------------------

      final dir = await getTemporaryDirectory();

      final file = File(
        '${dir.path}/stamped_'
        '${DateTime.now().millisecondsSinceEpoch}.png',
      );

      await file.writeAsBytes(bytes);

      debugPrint('Image captured: ${file.path}');

      // --------------------------------------------
      // Return image to previous screen
      // --------------------------------------------

      Get.back(result: file);
    } catch (e) {
      debugPrint('Capture failed: $e');

      if (!mounted) return;

      Get.snackbar(
        'Capture Failed',
        'Unable to capture image.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Widget _overlayWidget() {
    final now = DateTime.now();

    final formattedDate = DateFormat('dd MMM, yyyy').format(now);

    final formattedTime = DateFormat('HH:mm').format(now);

    return Positioned(
      bottom: 16,
      right: 16,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.65),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------------------------------
                // Date and time
                // Always displayed
                // ------------------------------------
                Text(
                  '$formattedDate, $formattedTime',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                // ------------------------------------
                // Location
                // Only displayed when:
                //
                // 1. includeLocation == true
                // 2. Location was successfully obtained
                // ------------------------------------
                if (widget.includeLocation && _position != null) ...[
                  const SizedBox(height: 4),

                  Text(
                    '$_address '
                    '(${_position!.latitude.toStringAsFixed(5)}, '
                    '${_position!.longitude.toStringAsFixed(5)})',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cameraPreview() {
    final size = MediaQuery.of(Get.context!).size;

    final cameraRatio = _controller.value.aspectRatio;

    final isPortrait = size.height > size.width;

    // Android camera sensor is generally
    // landscape-oriented.
    final previewRatio = isPortrait ? (1 / cameraRatio) : cameraRatio;

    return Center(
      child: OverflowBox(
        maxWidth: size.width,
        maxHeight: size.height,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: size.width,
            height: size.width / previewRatio,
            child: Stack(
              children: [CameraPreview(_controller), _overlayWidget()],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --------------------------------------------
    // Only camera initialization is required.
    // Location is NOT required.
    // --------------------------------------------

    if (!_initialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ----------------------------------------
          // Camera + timestamp/location overlay
          // ----------------------------------------
          RepaintBoundary(key: _repaintKey, child: _cameraPreview()),

          // ----------------------------------------
          // Capture button
          // ----------------------------------------
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                backgroundColor: Colors.red,
                onPressed: _captureStampedImage,
                child: const Icon(Icons.camera_alt),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_initialized) {
      _controller.dispose();
    }

    super.dispose();
  }
}
