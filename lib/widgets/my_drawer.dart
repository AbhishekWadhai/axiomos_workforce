import 'package:axiomos_workforce/widgets/glassmorphic_container.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:axiomos_workforce/constants/app_strings.dart';
import 'package:axiomos_workforce/constants/asset_path.dart';
import 'package:axiomos_workforce/constants/colors.dart';
import 'package:axiomos_workforce/constants/textstyles.dart';
import 'package:axiomos_workforce/helpers/sixed_boxes.dart';
import 'package:axiomos_workforce/routes/routes_string.dart';
import 'package:axiomos_workforce/services/shared_preferences.dart';
import 'package:axiomos_workforce/services/text_formatters.dart';

import 'package:axiomos_workforce/widgets/custom_alert_dialog.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Drawer(
        surfaceTintColor: AppColors.appMainDark,
        width: MediaQuery.of(context).size.width * 0.75,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(0),
            bottomLeft: Radius.circular(20), // Top-right corner radius
          ),
        ),
        child: Column(
          children: [
            Container(
              width: double
                  .infinity, // Ensures the container spans the entire width
              decoration: BoxDecoration(
                image: DecorationImage(
                  opacity: 0.9,
                  image: const AssetImage(
                    Assets.appBarBg, // Replace with your background image path
                  ),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      0.2,
                    ), // Shadow color with opacity
                    blurRadius: 10, // How much the shadow is blurred
                    offset: const Offset(
                      0,
                      5,
                    ), // Horizontal and vertical offset of the shadow
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GlassmorphicContainer(
                  //borderWidth: 0,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.appMainMid.withOpacity(0.6),
                      AppColors.appMainLight.withOpacity(0.4),
                      AppColors.appMainLight.withOpacity(0.9),
                    ],
                  ),
                  blur: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 50,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            Assets.logoExtended,
                            fit: BoxFit
                                .contain, // Adjusts image fit within the SizedBox
                          ),
                        ),
                      ),
                      sb10,
                      GlassmorphicContainer(
                        padding: EdgeInsetsGeometry.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "SAFETY BUDDY",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            sb4,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      TextFormatters().toTitleCase(
                                        Strings.userName,
                                      ),
                                      style: TextStyles.appBarSubTextStyle,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          Strings.locationName,
                                          style: TextStyles.appBarSubTextStyle,
                                        ),
                                        sb12,
                                        Text(
                                          DateFormat(
                                            'd, MMM',
                                          ).format(DateTime.now()),
                                          style: TextStyles.appBarSubTextStyle,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  DrawerMenuTile(
                    icon: Icon(Icons.person, color: Colors.black54),
                    title: "Profile",
                    onTap: () {
                      Get.toNamed(Routes.profilePage);
                    },
                  ),

                  if (Strings.roleName == "Execution" ||
                      Strings.roleName == "Management" ||
                      Strings.roleName == "Project Manager" ||
                      Strings.roleName == "Admin" &&
                          Strings.endpointToList['project']?["workpermitAllow"] ==
                              "yes") ...[
                    DrawerMenuTile(
                      icon: Image.asset(Assets.workPermit, height: 28),
                      title: Strings.workPermit,
                      onTap: () {
                        Get.toNamed(
                          Routes.modulePage,
                          arguments: ['workpermit'],
                        );
                      },
                    ),
                  ],
                  if (Strings.roleName == "Safety" ||
                      Strings.roleName == "Management" ||
                      Strings.roleName == "Project Manager" ||
                      Strings.roleName == "Admin") ...[
                    DrawerMenuTile(
                      icon: Image.asset(Assets.tbtMeeting, height: 28),
                      title: Strings.tbtMeeting,
                      onTap: () {
                        Get.toNamed(Routes.modulePage, arguments: ['meeting']);
                      },
                    ),
                  ],
                  if (Strings.roleName == "Safety" ||
                      Strings.roleName == "Management" ||
                      Strings.roleName == "Project Manager" ||
                      Strings.roleName == "Admin") ...[
                    DrawerMenuTile(
                      icon: Image.asset(Assets.safetyInduction, height: 28),
                      title: Strings.safetyInduction,
                      onTap: () {
                        Get.toNamed(
                          Routes.modulePage,
                          arguments: ['induction'],
                        );
                      },
                    ),
                  ],
                  DrawerMenuTile(
                    icon: Image.asset(Assets.uauc, height: 28),
                    title: Strings.uaucs,
                    onTap: () {
                      Get.toNamed(Routes.modulePage, arguments: ['uauc']);
                    },
                  ),

                  if (Strings.roleName == "Safety" ||
                      Strings.roleName == "Management" ||
                      Strings.roleName == "Project Manager" ||
                      Strings.roleName == "Admin") ...[
                    DrawerMenuTile(
                      icon: Image.asset(Assets.specificTraining, height: 28),
                      title: Strings.specificTraining,
                      onTap: () {
                        Get.toNamed(Routes.modulePage, arguments: ['specific']);
                      },
                    ),
                  ],
                  DrawerMenuTile(
                    icon: Icon(Icons.feedback_outlined, color: Colors.black),
                    title: "Dev. Feedback",
                    onTap: () {
                      Get.toNamed(
                        Routes.formPage,
                        arguments: ['feedback', <String, dynamic>{}, false],
                      );
                    },
                  ),

                  DrawerMenuTile(
                    icon: Icon(
                      Icons.vertical_split_outlined,
                      color: Colors.black,
                    ),
                    title: "App Info",
                    onTap: () {
                      Get.toNamed(Routes.packageInfoPage);
                    },
                  ),

                  DrawerMenuTile(
                    icon: Icon(Icons.bookmarks_outlined, color: Colors.black),
                    title: "Saved Form",
                    onTap: () {
                      Get.toNamed(
                        Routes.savedFormData,
                        arguments: ['feedback', <String, dynamic>{}, false],
                      );
                    },
                  ),

                  // ListTile(
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.logout),
              onTap: () async {
                Get.dialog(
                  CustomAlertDialog(
                    visual: Icon(
                      Icons.logout_rounded,
                      color: AppColors.appMainDark,
                    ),
                    title: "Logout Confirmation",
                    description: "Are you sure you want to logout?",
                    buttons: [
                      CustomDialogButton(
                        isPrimary: true,
                        color: AppColors.appMainMid,
                        label: "Yes, logout",
                        onPressed: () async {
                          await SharedPrefService().remove("token");
                          await SharedPrefService().remove("decodedData");
                          Get.offAllNamed(Routes.loginPage);
                        },
                      ),
                      CustomDialogButton(
                        label: "Cancel",
                        onPressed: () {
                          Get.back();
                        },
                      ),
                    ],
                  ),
                );
              },
              title: Text('Logout', style: TextStyles.drawerTextStyle),
            ),
          ],
        ),
      ),
    );
  }
}

class DrawerMenuTile extends StatelessWidget {
  final Widget icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const DrawerMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFF7A17) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            minTileHeight: 46,
            dense: true,
            visualDensity: const VisualDensity(horizontal: 0, vertical: -3),
            minVerticalPadding: 0,
            leading: icon,

            title: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: selected ? Colors.black87 : Colors.grey.shade800,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            onTap: onTap,
          ),
          Divider(),
        ],
      ),
    );
  }
}
