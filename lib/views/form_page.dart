import 'package:axiomos_workforce/constants/colors.dart';
import 'package:axiomos_workforce/controllers/dynamic_form_contoller.dart';
import 'package:axiomos_workforce/services/translation.dart';
import 'package:axiomos_workforce/widgets/custom_alert_dialog.dart';
import 'package:axiomos_workforce/widgets/custom_appbar.dart';
import 'package:axiomos_workforce/widgets/dynamic_form/dynamic_form.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FormPage extends StatelessWidget {
  FormPage({super.key});
  final DynamicFormController controller = Get.put(DynamicFormController());
  @override
  Widget build(BuildContext context) {
    final dynamic pageTitle = Get.arguments[0];
    final dynamic initialData = Get.arguments[1];
    final bool isEditable = Get.arguments[2] ?? false;
    controller.formId = Get.arguments.length > 3 ? Get.arguments[3] ?? "" : "";
    controller.isSaved.value = Get.arguments.length > 3 ? true : false;
    final bool isAdd = Get.arguments.length > 4 ? true : false;

    return Scaffold(
      appBar: MyAppBar(
        // leading: IconButton(
        //   onPressed: () {
        //     Get.back();
        //   },
        //   icon: Icon(Icons.arrow_back_ios_rounded),
        // ),
        title: Obx(
          () => RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: translate(pageTitle),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // Assuming AppBar background is dark
                  ),
                ),
                if (!controller.isOnline.value)
                  TextSpan(
                    text: ' (Offline)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: Colors.red,
                    ),
                  ),
              ],
            ),
          ),
        ),

        //Text(translate(pageTitle), style: TextStyle(fontSize: ),),
        //iconTheme: const IconThemeData(color: Colors.black),
        //elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              Get.dialog(
                CustomAlertDialog(
                  visual: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.appMainMid,
                  ),
                  title: 'Confirm Refresh',
                  description:
                      'This will fetch the latest dropdown data.\nPress "Yes" to continue?',
                  buttons: [
                    CustomDialogButton(
                      label: 'Cancel',
                      onPressed: () => Get.back(),
                    ),
                    CustomDialogButton(
                      color: AppColors.appMainMid,
                      label: 'Yes',
                      isPrimary: true,
                      onPressed: () {
                        Get.back();
                        controller.refreshDropdownData();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          isAdd
              ? SizedBox.shrink()
              : IconButton(
                  onPressed: () {
                    if (controller.isSaved.value) {
                      // Show dialog to confirm unsave
                      Get.dialog(
                        CustomAlertDialog(
                          title: "Remove Saved?",
                          description:
                              "Are you sure you want to remove this from saved forms?",
                          buttons: [
                            CustomDialogButton(
                              color: AppColors.appMainMid,
                              label: 'Yes',
                              isPrimary: true,
                              onPressed: () {
                                Get.back(); // Close dialog
                                controller
                                    .unsaveForm(); // <-- You need to implement this
                              },
                            ),
                            CustomDialogButton(
                              label: 'No',
                              onPressed: () => Get.back(),
                            ),
                          ],
                        ),
                      );
                    } else {
                      // Show dialog to confirm save
                      Get.dialog(
                        CustomAlertDialog(
                          title: "Save Progress?",
                          description: "Progress will be saved in /Saved_Forms",
                          buttons: [
                            CustomDialogButton(
                              color: AppColors.appMainMid,
                              label: 'Yes',
                              isPrimary: true,
                              onPressed: () {
                                Get.back(); // Close dialog
                                controller.saveForm(pageTitle);
                              },
                            ),
                            CustomDialogButton(
                              label: 'No',
                              onPressed: () => Get.back(),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  icon: Obx(
                    () => Icon(
                      controller.isSaved.value
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                    ),
                  ),
                ),
        ],
      ),
      body: DynamicForm(
        pageName: pageTitle,
        initialData: initialData,
        isEdit: isEditable,
        toAdd: isAdd,
      ),
    );
  }
}
