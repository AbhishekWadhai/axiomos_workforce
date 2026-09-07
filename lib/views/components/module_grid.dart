import 'package:axiomos_workforce/routes/routes_string.dart';
import 'package:axiomos_workforce/widgets/grids.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

class ModuleGrid extends StatelessWidget {
  const ModuleGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true, // Allows GridView to size dynamically
      // physics:
      //     const NeverScrollableScrollPhysics(), // Prevents scrolling inside the grid
      padding: EdgeInsets.zero, // Removes any default padding
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // Two items per row
        mainAxisSpacing: 24, // No extra vertical spacing
        crossAxisSpacing: 24.0, // Spacing between items horizontally
        childAspectRatio: 0.78, // Adjusts the child width/height ratio
      ),
      children: [
        MyGrid(
          avatarColor: Colors.red[100]!,
          icon: Icons.badge_outlined,
          activity: "Labor\nRegistration",
          onTap: () {
            Get.toNamed(Routes.modulePage, arguments: ["labor_registration"]);
          },
        ),

        MyGrid(
          avatarColor: Colors.red[100]!,
          icon: Icons.fact_check_outlined,
          activity: "Labor\nAttendance",
          onTap: () {
            // Get.toNamed(Routes.modulePage, arguments: ["labor_attendance"]);
          },
        ),

        MyGrid(
          avatarColor: Colors.red[100]!,
          icon: Icons.directions_walk,
          activity: "Labor\nMobilization",
          onTap: () {
            Get.toNamed(Routes.mobilisationPlanView);
          },
        ),

        MyGrid(
          avatarColor: Colors.red[100]!,
          icon: Icons.assignment_outlined,
          activity: "Labor\nPlanning",
          onTap: () {
            // Get.toNamed(Routes.modulePage, arguments: ["labor_planning"]);
          },
        ),

        MyGrid(
          avatarColor: Colors.red[100]!,
          icon: Icons.calendar_month_outlined,
          activity: "Shift\nCalendar",
          onTap: () {
            // Get.toNamed(Routes.modulePage, arguments: ["shift_calendar"]);
          },
        ),

        MyGrid(
          avatarColor: Colors.red[100]!,
          icon: Icons.groups_2_outlined,
          activity: "Resource\nPool",
          onTap: () {
            // Get.toNamed(Routes.modulePage, arguments: ["resource_pool"]);
          },
        ),

        MyGrid(
          avatarColor: Colors.red[100]!,
          icon: Icons.analytics_outlined,
          activity: "Attendance\nSummary",
          onTap: () {
            //Get.toNamed(Routes.modulePage, arguments: ["attendance_summary"]);
          },
        ),

        MyGrid(
          avatarColor: Colors.red[100]!,
          icon: Icons.business_outlined,
          activity: "Contractor\nRegistration",
          onTap: () {
            // Get.toNamed(
            //   Routes.modulePage,
            //   arguments: ["contractor_registration"],
            // );
          },
        ),
      ],
    );
  }
}
