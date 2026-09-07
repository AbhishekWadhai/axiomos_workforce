import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import 'package:share_plus/share_plus.dart';
import 'package:axiomos_workforce/constants/app_strings.dart';
import 'package:axiomos_workforce/constants/asset_path.dart';
import 'package:axiomos_workforce/services/api_services.dart';
import 'package:axiomos_workforce/services/translation.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:open_filex/open_filex.dart';

class DownloadController extends GetxController {
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);
  String projectId = Strings.endpointToList['project']['_id'];

  void setDateRange(PickerDateRange range) {
    startDate.value = range.startDate;
    endDate.value = range.endDate;
  }

  String get formattedRange {
    if (startDate.value == null || endDate.value == null) {
      return 'No date selected';
    }
    final from = DateFormat('dd MMM yyyy').format(startDate.value!);
    final to = DateFormat('dd MMM yyyy').format(endDate.value!);
    return '$from - $to';
  }

  Future<void> downloadData(String endpoint) async {
    if (startDate.value == null || endDate.value == null) {
      Get.snackbar('Error', 'Please select a valid date range.');
      return;
    }

    final from = DateFormat('yyyy-MM-dd').format(startDate.value!);
    final to = DateFormat('yyyy-MM-dd').format(endDate.value!);

    final fullEndpoint =
        "$endpoint/export-excel?project=$projectId&from=$from&to=$to";

    try {
      print("Downloading from: $fullEndpoint");

      final bytes = await ApiService().getFileRequest(
        fullEndpoint,
      ); // should return bodyBytes

      final fileName = '$endpoint-report_${from}_to_${to}.xlsx';
      final mimeType =
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
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

  void resetDates() {
    startDate.value = null;
    endDate.value = null;
  }
}

void showDownloadBottomSheet(String endpoint) {
  final controller = Get.put(DownloadController());

  Get.bottomSheet(
    Obx(
      () => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Text(
              "Download Report (${translate(endpoint)})",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),

            // Date range picker button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.date_range),
              label: const Text("Pick Date Range"),
              onPressed: () => _showDateRangePicker(controller),
            ),

            const SizedBox(height: 10),

            // Selected range
            Text(
              controller.formattedRange,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 30),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      controller.resetDates();
                      Get.back();
                    },
                    child: const Text(
                      "Cancel",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: SizedBox(
                      height: 24,
                      width: 24,
                      child: Image.asset(Assets.xls, fit: BoxFit.contain),
                    ),
                    label: const Text(
                      "Download",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    onPressed: () => controller.downloadData(endpoint),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
  );
}

void _showDateRangePicker(DownloadController controller) {
  Get.dialog(
    AlertDialog(
      contentPadding: const EdgeInsets.all(8),
      content: SizedBox(
        width: 350,
        height: 350,
        child: SfDateRangePicker(
          view: DateRangePickerView.month,
          selectionMode: DateRangePickerSelectionMode.range,
          onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
            if (args.value is PickerDateRange) {
              final PickerDateRange range = args.value;

              final DateTime start = range.startDate!;
              final DateTime end = range.endDate ?? start;

              controller.startDate.value = start;
              controller.endDate.value = end;
            }
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text("OK")),
      ],
    ),
  );
}

Future<void> saveAndHandleFile({
  required Uint8List fileBytes,
  required String fileName,
  required String mimeType,
}) async {
  try {
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(fileBytes);

    // Bottom sheet for user choice
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Open File'),
              onTap: () async {
                Get.back();
                await OpenFilex.open(filePath);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share File'),
              onTap: () async {
                Get.back();
                await Share.shareXFiles([
                  XFile(filePath, mimeType: mimeType),
                ], text: 'Here is your file 📎');
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Get.back(),
            ),
          ],
        ),
      ),
    );
  } catch (e) {
    print('Error saving or handling file: $e');
    Get.snackbar('Error', 'Something went wrong: $e');
  }
}
