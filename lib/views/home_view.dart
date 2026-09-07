import 'package:axiomos_workforce/constants/app_strings.dart';
import 'package:axiomos_workforce/routes/routes_string.dart';
import 'package:axiomos_workforce/views/components/module_grid.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int selectedBottomIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FD),
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 130),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const HeaderSection(),

                      const SizedBox(height: 10),

                      const ProjectSelector(),

                      const SizedBox(height: 10),

                      const SectionTitle(title: 'Quick Actions'),

                      const SizedBox(height: 10),

                      const QuickActions(),

                      const SizedBox(height: 10),
                      const SectionTitle(title: 'Statistics'),
                      const SizedBox(height: 12),
                      const AttendanceSummaryCard(),
                      const SizedBox(height: 22),
                      ModuleGrid(),

                      // const SizedBox(height: 42),

                      // const StatisticsGrid(),

                      // const SizedBox(height: 30),
                    ]),
                  ),
                ),
              ],
            ),

            // Bottom Navigation
            Positioned(
              left: 18,
              right: 18,
              bottom: 0,
              child: BottomNavigationBarWidget(
                selectedIndex: selectedBottomIndex,
                onChanged: (index) {
                  setState(() {
                    selectedBottomIndex = index;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HEADER
// ============================================================

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Profile
        Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFF0EEFF),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: const Icon(
              size: 30,
              Icons.person_outline_rounded,

              color: Color(0xFF7355E8),
            ),
          ),
        ),
        const SizedBox(width: 18),

        // Name + date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //Change with variable //todo
              Text(
                'Axiomos User',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10101A),
                  height: 1.1,
                ),
              ),

              Text(
                DateFormat('MMMM d, yyyy').format(DateTime.now()),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF747A9A),
                ),
              ),
            ],
          ),
        ),

        // Menu
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.045),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.menu_rounded,
            size: 24,
            color: Color(0xFF111226),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// PROJECT SELECTOR
// ============================================================

class ProjectSelector extends StatefulWidget {
  const ProjectSelector({super.key});

  @override
  State<ProjectSelector> createState() => _ProjectSelectorState();
}

class _ProjectSelectorState extends State<ProjectSelector> {

  //can use previously saved/selected project
  String selectedProject = Strings.endpointToList["projects"][0]["projectName"];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          builder: (_) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),

                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'Select Project',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 15),
                ...Strings.endpointToList["projects"].map(
                  (project) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 28),
                    title: Text(
                      project["projectName"],
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: project == selectedProject
                        ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFF6236DC),
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(context, project["projectName"]);
                    },
                  ),
                ),

                const SizedBox(height: 25),
              ],
            );
          },
        );

        if (result != null) {
          setState(() {
            selectedProject = result;
          });
        }
      },
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.55),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFCFC6FF), width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                selectedProject,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF151525),
                ),
              ),
            ),

            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 26,
              color: Color(0xFF111225),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SECTION TITLE
// ============================================================

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF10101B),
      ),
    );
  }
}

// ============================================================
// QUICK ACTIONS
// ============================================================

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        QuickActionCard(
          title: 'Mark\nAttendance',
          icon: Icons.fact_check_outlined,
          iconColor: const Color(0xFF6840E4),
          iconBackground: const Color(0xFFF0EDFF),
          onTap: () {
            Get.toNamed(Routes.markAttendancePage);
          },
        ),

        const SizedBox(width: 18),

        QuickActionCard(
          title: 'Register\nLabour',
          icon: Icons.person_add_alt_1_outlined,
          iconColor: const Color(0xFF0BA994),
          iconBackground: const Color(0xFFEAFBF7),
          onTap: () {
            Get.toNamed(
              Routes.formPage,
              arguments: ["labour-registration", <String, dynamic>{}, false],
            );
          },
        ),
      ],
    );
  }
}

class QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          width: 150,
          height: 150,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.035),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, size: 40, color: iconColor),
              ),

              const Spacer(),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF17172B),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ATTENDANCE SUMMARY
// ============================================================

class AttendanceSummaryCard extends StatelessWidget {
  const AttendanceSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFF0EEFF), Color(0xFFEFF8FC)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: SummaryItem(
              icon: Icons.calendar_month_outlined,
              iconColor: const Color(0xFF5E36D8),
              iconBackground: Colors.white.withOpacity(.75),
              title: "Today's Attendance",
              value: '21',
              valueColor: const Color(0xFF4F28D3),
            ),
          ),

          //Container(width: 1, height: 90, color: Colors.white.withOpacity(.5)),
          Expanded(
            child: SummaryItem(
              icon: Icons.person_add_alt_1_outlined,
              iconColor: const Color(0xFF0AA78E),
              iconBackground: const Color(0xFFE8FAF6),
              title: 'New Registration',
              value: '1',
              valueColor: const Color(0xFF00A98F),
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String value;
  final Color valueColor;

  const SummaryItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: iconBackground,
          ),
          child: Icon(icon, size: 26, color: iconColor),
        ),

        const SizedBox(width: 20),

        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// STATISTICS GRID
// ============================================================

// ============================================================
// BOTTOM NAVIGATION
// ============================================================

class BottomNavigationBarWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const BottomNavigationBarWidget({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 65,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.97),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.07),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: BottomNavItem(
              index: 0,
              selectedIndex: selectedIndex,
              icon: Icons.grid_view_rounded,
              label: 'Dashboard',
              onTap: onChanged,
            ),
          ),

          Expanded(
            child: BottomNavItem(
              index: 1,
              selectedIndex: selectedIndex,
              icon: Icons.home_outlined,
              label: 'Home',
              onTap: onChanged,
            ),
          ),

          Expanded(
            child: BottomNavItem(
              index: 2,
              selectedIndex: selectedIndex,
              icon: Icons.notifications_none_rounded,
              label: 'Notifications',
              onTap: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class BottomNavItem extends StatelessWidget {
  final int index;
  final int selectedIndex;
  final IconData icon;
  final String label;
  final ValueChanged<int> onTap;

  const BottomNavItem({
    super.key,
    required this.index,
    required this.selectedIndex,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool selected = index == selectedIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Top selected indicator
            Align(
              alignment: Alignment.topCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                width: selected ? 55 : 0,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF5427D5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Icon + label
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 23,
                  color: selected
                      ? const Color(0xFF5427D5)
                      : const Color(0xFF707792),
                ),

                const SizedBox(height: 3),

                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.1,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? const Color(0xFF5427D5)
                        : const Color(0xFF707792),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
