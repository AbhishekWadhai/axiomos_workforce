import 'dart:convert';
import 'dart:io'; // Import for File
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
// Import for basename

class ApiService {
  static String baseUrl = "https://jkumarlabourtrackerapi.axiomos.in";

  // Common method for making GET requests to download file
  Future<Uint8List> getFileRequest(String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint');

    try {
      final response = await http.get(url);
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

  // Common method for making GET requests
  Future<dynamic> getRequest(String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print(response.statusCode);
        throw Exception('Failed to load data');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Common method for making POST requests
  Future<dynamic> postRequest(String endpoint, dynamic data) async {
    final url = Uri.parse('$baseUrl/$endpoint');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 201) {
        print("API post successfully: ${response.statusCode}");
        return response.statusCode;
      } else if (response.statusCode == 200) {
        print("API post successfully");
        //print(jsonEncode(response.body));
        return jsonDecode(response.body);
      } else if (response.statusCode == 426) {
        print("API post successfully");
        //print(jsonEncode(response.body));
        return jsonDecode(response.body);
      } else {
        print(
          "Failed to post data. Status code: ------${response.statusCode}-------------------",
        );
      }
    } catch (e) {
      print(e);
      throw Exception('Error here: $e');
    }
  }

  // Update method
  Future<int> updateData(
    String endpoint,
    String id,
    Map<String, dynamic> updatedData,
  ) async {
    final url = Uri.parse('$baseUrl/$endpoint/$id');

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('Data updated successfully: $responseData');
        return response.statusCode;
      } else {
        print('Failed to update data. Status code: ${response.statusCode}');
        return 0;
      }
    } catch (e) {
      print('Error updating data: $e');
      return 0;
    }
  }

  // Common method for making DELETE requests
  Future<dynamic> deleteRequest(String endpoint, String key) async {
    final url = Uri.parse('$baseUrl/$endpoint/$key');

    try {
      final response = await http.delete(url);
      if (response.statusCode == 200 || response.statusCode == 204) {
        print("API delete successfully");
        return response.body.isNotEmpty ? jsonDecode(response.body) : null;
      } else {
        throw Exception('Failed to delete data');
      }
    } catch (e) {
      print(e);
      throw Exception('Error: $e');
    }
  }

  // New method for multipart file uploads
  Future<void> uploadFile(
    String endpoint,
    File file,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl/$endpoint');

    try {
      var request = http.MultipartRequest('POST', url);

      // Attach the file
      request.files.add(
        await http.MultipartFile.fromPath(
          'documentaryEvidencePhoto', // Field name expected by the API
          file.path,
          filename: basename(file.path), // Get the file name
        ),
      );

      // Add other form fields
      data.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // Send the request
      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("File uploaded successfully.");
      } else {
        print('Failed to upload file. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading file: $e');
    }
  }

  static Future<String> uploadImage(
    File file,
    String endpoint,
    bool isSignature, {
    String? customFileName,
  }) async {
    try {
      final uri = Uri.parse('https://jkumar.vercel.app/$endpoint/image');
      print("🌐 Uploading to: $uri");
      print("📦 File path: ${file.path}");

      final request = http.MultipartRequest('POST', uri)
        ..files.add(
          await http.MultipartFile.fromPath(
            'image', // Make sure backend expects this key
            file.path,
            filename: customFileName ?? basename(file.path),
          ),
        );

      final response = await request.send();
      print("📨 Response status: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = await response.stream.bytesToString();
        print("✅ Response body: $responseBody");

        final result = jsonDecode(responseBody);
        if (result != null && result["fileUrl"] != null) {
          print("✅ Upload successful: ${result["fileUrl"]}");
          return result["fileUrl"];
        } else {
          print('⚠️ Invalid response format: $result');
          return "";
        }
      } else {
        final error = await response.stream.bytesToString();
        print("❌ Upload failed: ${response.statusCode} - $error");
        throw Exception("Upload failed: ${response.statusCode}");
      }
    } catch (e, stack) {
      print("❌ Exception in uploadImage: $e");
      print(stack);
      return "";
    }
  }

  Future<String?> uploadFileToApi(File file, String endpoint) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://jkumar.vercel.app/$endpoint'),
      );

      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = jsonDecode(respStr);
        return data['url']; // The uploaded file URL from your API
      } else {
        debugPrint('Upload failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  String buildQueryParams(Map<String, dynamic> filters) {
    final params = <String>[];

    filters.forEach((key, value) {
      if (value == null) return;

      // 🟢 List → comma separated
      if (value is List) {
        if (value.isEmpty) return;

        final joined = value.join(',');
        params.add(
          '${Uri.encodeQueryComponent(key)}='
          '${Uri.encodeQueryComponent(joined)}',
        );
        return;
      }

      // 🟢 DateTime
      if (value is DateTime) {
        final date = value.toIso8601String().split('T').first;
        params.add(
          '${Uri.encodeQueryComponent(key)}='
          '${Uri.encodeQueryComponent(date)}',
        );
        return;
      }

      // 🟢 String (date-safe)
      if (value is String) {
        params.add(
          '${Uri.encodeQueryComponent(key)}='
          '${Uri.encodeQueryComponent(value)}',
        );
        return;
      }

      // 🟢 Default
      params.add(
        '${Uri.encodeQueryComponent(key)}='
        '${Uri.encodeQueryComponent(value.toString())}',
      );
    });

    return params.join('&');
  }
}
