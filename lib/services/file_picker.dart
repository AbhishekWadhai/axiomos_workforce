// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
// import 'package:rohan_suraksha_sathi/models/form_data_model.dart';
// import 'package:http/http.dart' as http;
// import '../controller/dynamic_form_contoller.dart';

// Widget buildFilePickerField(
//     PageField field, DynamicFormController controller, bool isEditable) {
//   return Obx(() {
//     final file = controller.formData[field.headers];

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(field.title ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
//         const SizedBox(height: 8),
//         ElevatedButton(
//           onPressed: isEditable
//               ? () async {
//                   final pickedFile = await pickFile();
//                   if (pickedFile != null) {
//                     uploadAttachment(pickedFile, "workpermit");
//                   }
//                 }
//               : null,
//           child: Text(file != null ? "Change File" : "Attach File"),
//         ),
//         if (file != null)
//           Padding(
//             padding: const EdgeInsets.only(top: 8.0),
//             child: Text("Selected: ${file.name}"),
//           ),
//       ],
//     );
//   });
// }

// Future<PlatformFile?> pickFile() async {
//   FilePickerResult? result = await FilePicker.platform.pickFiles();

//   if (result != null && result.files.isNotEmpty) {
//     return result.files.first;
//   }
//   return null;
// }

// void uploadAttachment(PlatformFile file, String endpoint) async {
//   final request = http.MultipartRequest(
//       'POST', Uri.parse('https://rohan-sage.vercel.app/$endpoint'));
//   request.files.add(
//     http.MultipartFile.fromBytes(
//       'file',
//       file.bytes!,
//       filename: file.name,
//     ),
//   );
//   final response = await request.send();
//   if (response.statusCode == 200) {
//     print('Uploaded successfully');
//   } else {
//     print('Upload failed');
//   }
// }
