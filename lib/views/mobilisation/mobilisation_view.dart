import 'dart:convert';

import 'package:axiomos_workforce/model/filter_model.dart';
import 'package:axiomos_workforce/routes/routes_string.dart';
import 'package:axiomos_workforce/services/api_services.dart';
import 'package:axiomos_workforce/services/text_formatters.dart';
import 'package:axiomos_workforce/views/components/headers.dart';
import 'package:axiomos_workforce/widgets/dynamic_data_view.dart';
import 'package:axiomos_workforce/widgets/module_filter_form.dart/module_filter_controller.dart';
import 'package:axiomos_workforce/widgets/module_filter_form.dart/module_filter_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MobilisationPlanView extends StatefulWidget {
  const MobilisationPlanView({super.key});

  @override
  State<MobilisationPlanView> createState() => _MobilisationPlanViewState();
}

class _MobilisationPlanViewState extends State<MobilisationPlanView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override
  initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
    getfields();
    getDraftPlans();
    getSubmittedPlans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> getSubmittedPlans() async {
    final response = await ApiService().getRequest("mobilisation");

    // Adjust this according to your actual API response.
    if (response != null) {
      setState(() {
        submittedPlans = (response['data'] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      });
    }
  }

  List<Map<String, dynamic>> mobilisationInfoResult = [];
  List<Map<String, dynamic>> draftPlans = [];
  List<Map<String, dynamic>> submittedPlans = [];

  List<Filter> mobilisationInfo = <Filter>[];
  void getfields() async {
    final jsonString = await rootBundle.loadString(
      'lib/assets/json/simple_form.json',
    );
    final configList = Map<String, dynamic>.from(jsonDecode(jsonString));
    final dynamic attendanceConfig = configList['mobilisationInfo'];
    print('filtersConfig: $attendanceConfig');
    mobilisationInfo = (attendanceConfig as List<dynamic>)
        .map<Filter>((e) => Filter.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _submitPlan(Map<String, dynamic> plan) async {
    printLargeJson(plan);
    final response = await ApiService().postRequest("mobilisation", plan);

    if (response != null) {
      setState(() {
        draftPlans.remove(plan);
      });

      await _saveDrafts();

      await getSubmittedPlans();
    } else {
      Get.snackbar(
        "Error",
        "Failed to submit the plan. Please try again.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _saveDrafts() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('mobilisationDrafts', jsonEncode(draftPlans));
  }

  // Replace this with your API data later.
  bool hasPlan = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            buildHeader("Mobilisation Plan"),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  labelColor: Colors.blue.shade700,
                  unselectedLabelColor: Colors.grey.shade600,
                  tabs: const [
                    Tab(text: 'Drafts'),
                    Tab(text: 'Submitted'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPlanList(draftPlans, isDraft: true),
                  _buildPlanList(submittedPlans, isDraft: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanList(
    List<Map<String, dynamic>> plans, {
    required bool isDraft,
  }) {
    return Column(
      children: [
        Expanded(
          child: plans.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: plans.length,
                  itemBuilder: (context, index) {
                    return _buildPlanCard(plans[index], isDraft);
                  },
                ),
        ),

        if (isDraft)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createPlan,
                icon: const Icon(Icons.add),
                label: const Text(
                  'Create Mobilisation Plan',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> getDraftPlans() async {
    final prefs = await SharedPreferences.getInstance();

    final savedData = prefs.getString('mobilisationDrafts');

    if (savedData == null) return;

    final List<dynamic> decoded = jsonDecode(savedData);

    setState(() {
      draftPlans = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.groups_outlined,
                size: 42,
                color: Colors.blue,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'No Mobilisation Plan',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 8),

            Text(
              'Create a manpower mobilisation plan '
              'to define your workforce requirements.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan, bool isDraft) {
    final project = plan['project'] as Map<String, dynamic>?;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    plan['planName'] ?? 'Untitled Plan',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Submit
                isDraft
                    ? ElevatedButton.icon(
                        onPressed: () {
                          _submitPlan(plan);
                        },
                        icon: const Icon(Icons.send, size: 17),
                        label: const Text('Submit'),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.green.shade50,
                          foregroundColor: Colors.green.shade700,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      )
                    : SizedBox.shrink(),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              project?['projectName'] ?? 'No Project',
              style: const TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 4),

            Text(
              '${plan['periodType']} • '
              '${plan['month']}/${plan['year']}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),

            const SizedBox(height: 14),

            // Section actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // View Sections
                TextButton.icon(
                  onPressed: () {
                    _viewSections(plan);
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('View Sections'),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    foregroundColor: Colors.grey.shade800,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Add Sections
                TextButton.icon(
                  onPressed: () {
                    _addSections(plan);
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Sections'),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addSections(Map<String, dynamic> plan) async {
    final result = await Get.toNamed(
      Routes.formPage,
      arguments: ["sections", <String, dynamic>{}, false, null, true],
    );

    if (result != null && result is Map) {
      setState(() {
        final sections = plan['sections'] as List? ?? [];

        sections.add(Map<String, dynamic>.from(result));

        plan['sections'] = sections;
      });
      await _saveDrafts();
    }
  }

  void _createPlan() async {
    {
      final ModuleFilterController moduleController = Get.put(
        ModuleFilterController(),
      );
      final result = await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) {
          return ModuleFilterForm(filterOptions: mobilisationInfo);
        },
      );

      print('Module Filter Result: $result');

      if (result != null && result is Map) {
        setState(() {
          final plan = Map<String, dynamic>.from(result);

          plan['sections'] = <Map<String, dynamic>>[];
          draftPlans.add(plan);
          //mobilisationInfoResult.add(plan);
        });
        await _saveDrafts();
      }
    }

    debugPrint('Create mobilisation plan');
  }
}

void _viewSections(Map<String, dynamic> plan) {
  final sections = plan['sections'] as List? ?? [];

  Get.bottomSheet(
    Container(
      height: Get.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Sections',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Sections
          Expanded(
            child: sections.isEmpty
                ? _buildNoSections()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: sections.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final section = Map<String, dynamic>.from(
                        sections[index],
                      );

                      return _buildSectionTile(section, index);
                    },
                  ),
          ),
        ],
      ),
    ),
    isScrollControlled: true,
  );
}

Widget _buildSectionTile(Map<String, dynamic> section, int index) {
  final zone = section['zone'] is Map
      ? Map<String, dynamic>.from(section['zone'])
      : <String, dynamic>{};

  final responsibleSenior = section['responsibleSenior'] is Map
      ? Map<String, dynamic>.from(section['responsibleSenior'])
      : <String, dynamic>{};

  final requirements = section['requirements'] is List
      ? section['requirements']
      : [];

  return Card(
    elevation: 0,
    color: Colors.grey.shade50,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: Colors.grey.shade200),
    ),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),

      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),

      title: Text(
        section['sectionName']?.toString() ?? 'Section ${index + 1}',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),

      subtitle: Text(
        zone['areaName']?.toString() ?? 'No zone',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),

      children: [
        _buildInfoRow(
          Icons.location_on_outlined,
          'Zone',
          zone['areaName']?.toString() ?? '-',
        ),

        _buildInfoRow(
          Icons.person_outline,
          'Responsible Senior',
          responsibleSenior['name']?.toString() ?? '-',
        ),

        const SizedBox(height: 8),

        _buildDescriptionCard(section['workDescription']?.toString() ?? '-'),

        const SizedBox(height: 16),

        // Requirements heading
        Row(
          children: [
            const Icon(Icons.groups_outlined, size: 18),
            const SizedBox(width: 8),
            Text(
              'Labour Requirements',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (requirements.isEmpty)
          _buildNoRequirements()
        else
          ...requirements.asMap().entries.map((entry) {
            final requirement = Map<String, dynamic>.from(entry.value);

            return _buildRequirementCard(requirement, entry.key);
          }),
      ],
    ),
  );
}

Widget _buildInfoRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 10),

        SizedBox(
          width: 115,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ),

        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

Widget _buildDescriptionCard(String description) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Work Description',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade900,
          fontWeight: FontWeight.w700,
        ),
      ),
      SizedBox(height: 6),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          description,
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
      ),
    ],
  );
}

Widget _buildRequirementCard(Map<String, dynamic> requirement, int index) {
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Requirement ${index + 1}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const Spacer(),

            Text(
              '${requirement['plannedWorkers'] ?? 0} workers',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        _buildRequirementRow('Shift', requirement['shift']),

        _buildRequirementRow('Work Activity', requirement['workActivity']),

        _buildRequirementRow('Remarks', requirement['remarks']),
      ],
    ),
  );
}

Widget _buildRequirementRow(String label, dynamic value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
        Expanded(
          child: Text(
            value?.toString() ?? '-',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}

Widget _buildNoSections() {
  return const Center(
    child: Text('No sections added yet', style: TextStyle(color: Colors.grey)),
  );
}

Widget _buildNoRequirements() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Text(
      'No labour requirements',
      style: TextStyle(fontSize: 12, color: Colors.grey),
    ),
  );
}
