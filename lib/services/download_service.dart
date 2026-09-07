import 'package:get/get.dart';

import 'package:axiomos_workforce/services/download_excel.dart';
import 'package:http/http.dart' as http;

downloadFile(String fullEndpoint) async {
  try {
    final bytes = await downloadFromApi(
      fullEndpoint,
    ); // should return bodyBytes
    String splitName = fullEndpoint
        .split('/')
        .last; // original file name with extension
    final extension = splitName.contains('.') ? splitName.split('.').last : '';
    final nameWithoutExt = splitName.replaceAll('.$extension', '');

    // Safe timestamp: remove colon
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');

    final fileName = '$nameWithoutExt-$timestamp.$extension';
    final mimeType = getMimeType(fileName);
    Get.back(); // Close bottom sheet
    // Show "Open or Share" option
    await saveAndHandleFile(
      fileBytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
  } catch (e) {
    print('Download error: $e');
    Get.snackbar('Error', 'Failed to download: $e');
  }
}

downloadFromApi(String url) async {
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes; // ✅ This is binary-safe
    } else {
      print(response.statusCode);
      throw Exception('Failed to download file');
    }
  } catch (e) {
    print("Exception thrown----$e");
    throw Exception('Error: $e');
  }
}

String getMimeType(String fileName) {
  final ext = fileName.split('.').last.toLowerCase();

  switch (ext) {
    case 'xlsx':
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    case 'xls':
      return 'application/vnd.ms-excel';
    case 'docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    case 'doc':
      return 'application/msword';
    case 'pdf':
      return 'application/pdf';
    case 'png':
      return 'image/png';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'txt':
      return 'text/plain';
    default:
      return 'application/octet-stream'; // fallback for unknown types
  }
}
