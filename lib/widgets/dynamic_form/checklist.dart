import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:axiomos_workforce/controllers/dynamic_form_contoller.dart';
import 'package:axiomos_workforce/model/form_data_model.dart';
import 'package:axiomos_workforce/widgets/dynamic_form/form_extras.dart';

Widget buildChecklist(
  PageField field,
  DynamicFormController controller,
  bool isEditable,
  BuildContext context,
) {
  // Initialize only once
  WidgetsBinding.instance.addPostFrameCallback((_) {
    controller.initChecklist(controller.checkList);
  });

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        field.title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),
      Container(
        decoration: kBoxFieldDecoration(),
        child: ExpansionTile(
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Text("Open ${field.title}"),
          children: [
            Obx(() {
              return Column(
                children: controller.checkList.map((checkPoint) {
                  final title =
                      checkPoint['CheckPoints'] ?? checkPoint['question'];
                  final response = controller.checklistResponses[title] ?? 'No';

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),

                        // Smooth update: only row rebuilds, not whole widget
                        Row(
                          children: ['Yes', 'No', 'N/A'].map((option) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Radio<String>(
                                  value: option,
                                  groupValue: response,
                                  onChanged: isEditable
                                      ? (value) => controller.updateChecklist(
                                          title,
                                          value!,
                                        )
                                      : null,
                                ),
                                Text(option),
                                const SizedBox(width: 10),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    ],
  );
}

// Widget buildChecklist(
//     PageField field, DynamicFormController controller, bool isEditable) {
//   return Obx(() {
//     List<Map<String, dynamic>> checkListItems = controller.checkList;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           field.title,
//           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 10),
//         Container(
//           decoration: kBoxFieldDecoration(),
//           child: ExpansionTile(
//             expandedCrossAxisAlignment: CrossAxisAlignment.start,
//             title: Text("Open ${field.title}"),
//             children: checkListItems.map((checkPoint) {
//               final String checkPointTitle =
//                   checkPoint['CheckPoints'] ?? checkPoint['question'] ?? '';
//               final String initialResponse = checkPoint['response'] ??
//                   checkPoint['defaultResponse'] ??
//                   'No';

//               //Save default value if not already present
//               // controller.formData.update(
//               //   field.headers,
//               //   (existing) {
//               //     final updatedList = List<Map<String, dynamic>>.from(existing);
//               //     final exists = updatedList
//               //         .any((e) => e['CheckPoints'] == checkPointTitle);
//               //     if (!exists) {
//               //       updatedList.add({
//               //         'CheckPoints': checkPointTitle,
//               //         'response': initialResponse,
//               //       });
//               //     }
//               //     return updatedList;
//               //   },
//               //   ifAbsent: () => [
//               //     {
//               //       'CheckPoints': checkPointTitle,
//               //       'response': initialResponse,
//               //     }
//               //   ],
//               // );

//               return Padding(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       checkPointTitle,
//                       style: const TextStyle(fontSize: 16),
//                       textAlign: TextAlign.start,
//                     ),
//                     const SizedBox(height: 8.0),
//                     Obx(() {
//                       final String currentResponse =
//                           controller.formData[field.headers]?.firstWhere(
//                                 (e) => e['CheckPoints'] == checkPointTitle,
//                                 orElse: () => {
//                                   'CheckPoints': checkPointTitle,
//                                   'response': initialResponse,
//                                 },
//                               )['response'] ??
//                               initialResponse;

//                       return Row(
//                         children: ['Yes', 'No', 'N/A'].map((option) {
//                           return Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Radio<String>(
//                                 value: option,
//                                 groupValue: currentResponse,
//                                 onChanged: isEditable
//                                     ? (value) {
//                                         final updatedCheckPoint = {
//                                           'CheckPoints': checkPointTitle,
//                                           'response': value,
//                                         };

//                                         controller.formData.update(
//                                           field.headers,
//                                           (existing) {
//                                             final updatedList =
//                                                 List<Map<String, dynamic>>.from(
//                                                     existing);
//                                             final index =
//                                                 updatedList.indexWhere((e) =>
//                                                     e['CheckPoints'] ==
//                                                     checkPointTitle);
//                                             if (index >= 0) {
//                                               updatedList[index] =
//                                                   updatedCheckPoint;
//                                             } else {
//                                               updatedList
//                                                   .add(updatedCheckPoint);
//                                             }
//                                             return updatedList;
//                                           },
//                                           ifAbsent: () => [updatedCheckPoint],
//                                         );
//                                       }
//                                     : null,
//                               ),
//                               Text(option),
//                               const SizedBox(width: 10),
//                             ],
//                           );
//                         }).toList(),
//                       );
//                     }),
//                   ],
//                 ),
//               );
//             }).toList(),
//           ),
//         ),
//       ],
//     );
//   });
// }
