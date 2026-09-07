// import 'package:axiomos_workforce/widgets/custom_alert_dialog.dart';
// import 'package:axiomos_workforce/widgets/helper_widgets/flexibleText.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:axiomos_workforce/constants/colors.dart';

// import 'package:axiomos_workforce/services/connection_service.dart';
// import 'package:axiomos_workforce/services/formatters.dart';
// import 'package:axiomos_workforce/services/translation.dart';
// import 'package:axiomos_workforce/views/saved_form_data/saved_form_data_controller.dart';


// class SavedFormData extends StatelessWidget {
//   final SavedFormDataController controller = Get.find();

//   SavedFormData({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         actions: [
//           IconButton(
//             onPressed: () {
//               ConnectivityService.to.syncFormsWithServer();
//             },
//             icon: Icon(Icons.refresh),
//           ),
//         ],
//         leading: IconButton(
//           onPressed: () => Get.back(),
//           icon: const Icon(Icons.arrow_back_ios_rounded),
//         ),
//         title: const FlexibleText(
//           text: "Saved Forms",
//           baseFontSize: 22,
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: AppColors.appMainDark,
//       ),
//       body: Obx(
//         () => controller.savedFormData.isEmpty
//             ? const Center(child: Text("No saved forms found."))
//             : ListView.separated(
//                 padding: const EdgeInsets.all(12),
//                 itemCount: controller.savedFormData.length,
//                 separatorBuilder: (_, __) => const SizedBox(height: 10),
//                 itemBuilder: (context, index) {
//                   final item = controller.savedFormData[index];
//                   //final offline = controller.offlineFormsData[index];

//                   return Material(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(12),
//                     elevation: 2,
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 14,
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: Text(
//                                   translate(item['module']),
//                                   style: const TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 6),
//                           Row(
//                             children: [
//                               Icon(
//                                 Icons.calendar_today,
//                                 size: 16,
//                                 color: Colors.grey[600],
//                               ),
//                               const SizedBox(width: 6),
//                               Text(
//                                 IndianDateFormatters.formatDate2(
//                                   DateTime.parse(item['date']),
//                                 ),
//                                 style: TextStyle(color: Colors.grey[800]),
//                               ),
//                               const Spacer(),
//                               Icon(
//                                 Icons.access_time,
//                                 size: 16,
//                                 color: Colors.grey[600],
//                               ),
//                               const SizedBox(width: 6),
//                               Text(
//                                 item['time'],
//                                 style: TextStyle(color: Colors.grey[800]),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 12),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.end,
//                             children: [
//                               TextButton.icon(
//                                 label: const Text(
//                                   "Delete",
//                                   style: TextStyle(color: Colors.redAccent),
//                                 ),
//                                 icon: const Icon(
//                                   Icons.delete_outline,
//                                   color: Colors.redAccent,
//                                 ),
//                                 onPressed: () {
//                                   Get.dialog(
//                                     CustomAlertDialog(
//                                       title: "Delete!",
//                                       description:
//                                           "Do you want to delete this form?",
//                                       buttons: [
//                                         CustomDialogButton(
//                                           isPrimary: true,
//                                           color: Colors.red,
//                                           label: "Yes",
//                                           onPressed: () {
//                                             controller.removeFormData(
//                                               item['id'],
//                                             );
//                                             Get.back();
//                                           },
//                                         ),
//                                         CustomDialogButton(
//                                           label: "No",
//                                           onPressed: () => Get.back(),
//                                         ),
//                                       ],
//                                     ),
//                                   );
//                                 },
//                               ),
//                               TextButton.icon(
//                                 onPressed: () {
//                                   Get.toNamed(
//                                     Routes.formPage,
//                                     arguments: [
//                                       item['module'],
//                                       item['formData'],
//                                       false,
//                                       item['id'],
//                                     ],
//                                   );
//                                 },
//                                 icon: const Icon(Icons.edit, size: 18),
//                                 label: const Text("Edit"),
//                                 style: TextButton.styleFrom(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 12,
//                                     vertical: 8,
//                                   ),
//                                   foregroundColor: Colors.blue,
//                                   textStyle: const TextStyle(fontSize: 14),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//       ),
//       backgroundColor: const Color(0xFFF5F5F5),
//     );
//   }
// }
