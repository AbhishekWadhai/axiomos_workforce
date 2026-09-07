import 'dart:convert';

import 'package:axiomos_workforce/constants/colors.dart';
import 'package:axiomos_workforce/model/attendance/qr_model.dart';
import 'package:axiomos_workforce/model/filter_model.dart';
import 'package:axiomos_workforce/services/api_services.dart';
import 'package:axiomos_workforce/services/formatters.dart';
import 'package:axiomos_workforce/services/qr_scanner.dart';
import 'package:axiomos_workforce/views/components/headers.dart';
import 'package:axiomos_workforce/widgets/dynamic_data_view.dart';
import 'package:axiomos_workforce/widgets/module_filter_form.dart/module_filter_controller.dart';
import 'package:axiomos_workforce/widgets/module_filter_form.dart/module_filter_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MarkAttendanceView extends StatefulWidget {
  const MarkAttendanceView({super.key});

  @override
  State<MarkAttendanceView> createState() => _MarkAttendanceViewState();
}

class _MarkAttendanceViewState extends State<MarkAttendanceView> {
  final ModuleFilterController moduleController = Get.put(
    ModuleFilterController(),
  );
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> queuedAttandance = [];
  List<Filter> attendanceInfo = <Filter>[];
  Map<String, dynamic>? _attendanceFormData;
  String _searchQuery = '';
  AttendanceFilter _selectedFilter = AttendanceFilter.all;
  int _selectedLabourTab = 0;
  final List<WorkerQrData> _labours = [];
  @override
  initState() {
    super.initState();
    getfields();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void getfields() async {
    final jsonString = await rootBundle.loadString(
      'lib/assets/json/simple_form.json',
    );
    final configList = Map<String, dynamic>.from(jsonDecode(jsonString));
    final dynamic attendanceConfig = configList['attendanceInfo'];
    print('filtersConfig: $attendanceConfig');
    attendanceInfo = (attendanceConfig as List<dynamic>)
        .map<Filter>((e) => Filter.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<WorkerQrData?> _openScanner() async {
    final result = await showModalBottomSheet<WorkerQrData?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const QRScannerPlaceholder();
      },
    );
    // _showWorkerDialog(result!, context);
    final action = await _showWorkerDialog(result!, context);

    if (action == 'queue') {
      print('Queueing attendance for ${result.firstName} ${result.id}');
      setState(() {
        _labours.add(result);
      });
    } else if (action == 'attendance') {
      // Mark attendance
    }

    return result;
  }

  void _openFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9DCE8),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Filter Attendance',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF11152D),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _filterOption(title: 'All Labours', value: AttendanceFilter.all),
              _filterOption(title: 'Present', value: AttendanceFilter.present),
              _filterOption(title: 'Absent', value: AttendanceFilter.absent),
              _filterOption(
                title: 'Not Marked',
                value: AttendanceFilter.notMarked,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filterOption({
    required String title,
    required AttendanceFilter value,
  }) {
    final selected = _selectedFilter == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primary : const Color(0xFF9AA0B5),
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: const Color(0xFF20243D),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labours = _labours;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: buildHeader("Attendance")),

                  SliverToBoxAdapter(child: _buildQRCard()),

                  SliverToBoxAdapter(child: _buildWorkAllocationCard()),

                  SliverToBoxAdapter(child: _buildMarkAttendance()),

                  SliverToBoxAdapter(child: _buildLabourHeader()),

                  SliverToBoxAdapter(child: _buildLabourTabs()),
                  // SliverToBoxAdapter(child: _buildLabourList()),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    sliver: _buildLabourList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabourList() {
    final currentList = _selectedLabourTab == 0 ? _labours : _labours;

    if (currentList.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyState());
    }

    return SliverList.separated(
      itemCount: currentList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return LabourTile(
          labour: currentList[index],
          onTap: () {
            // _openLabourDetails(currentList[index]);
          },
        );
      },
    );
  }

  Widget _buildLabourTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 46,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(child: _buildTabButton(title: 'Queued', index: 0)),
            Expanded(child: _buildTabButton(title: 'Marked', index: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({required String title, required int index}) {
    final isSelected = _selectedLabourTab == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLabourTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildMarkAttendance() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () async {
            // =========================
            // CHECK WORK ALLOCATION
            // =========================

            if (_attendanceFormData == null || _attendanceFormData!.isEmpty) {
              Get.dialog(
                AlertDialog(
                  title: const Text('Work Allocation Required'),
                  content: const Text(
                    'Please fill in the work allocation details before marking attendance.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );

              return;
            }

            // =========================
            // CHECK LABOURS
            // =========================

            if (_labours.isEmpty) {
              Get.dialog(
                AlertDialog(
                  title: const Text('No Labour Selected'),
                  content: const Text(
                    'Please select at least one labour before marking attendance.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );

              return;
            }

            // =========================
            // EXTRACT LABOUR IDS
            // =========================

            final List<String> labourIds = _labours
                .map((labour) => labour.id.toString())
                .toList();

            // =========================
            // BUILD PAYLOAD
            // =========================

            final attendanceData = {
              "project": _attendanceFormData?["project"]?["_id"],
              "zoneArea": _attendanceFormData?["zoneArea"]?["_id"],
              "responsibleEngineer":
                  _attendanceFormData?["responsibleEngineer"]?["_id"],

              "shift": _attendanceFormData?["shift"],
              "section": _attendanceFormData?["section"],
              "workActivity": _attendanceFormData?["workActivity"],
              "workDescription": _attendanceFormData?["workDescription"],

              "labourIds": labourIds,

              "inTime": parseTimeToIsoString(
                _attendanceFormData!["inTime"].toString(),
              ),

              "outTime": parseTimeToIsoString(
                _attendanceFormData!["outTime"].toString(),
              ),
            };

            print('Attendance Data: ${jsonEncode(attendanceData)}');

            // =========================
            // API CALL
            // =========================

            try {
              final response = await ApiService().postRequest(
                "labour-attendance",
                attendanceData,
              );

              print('Attendance Response: $response');

              if (response == 201) {
                Get.snackbar(
                  'Success',
                  'Attendance marked successfully.',
                  snackPosition: SnackPosition.TOP,
                );

                setState(() {
                  _labours.clear();
                });
              } else {
                Get.snackbar(
                  'Failed',
                  'Unable to mark attendance.',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            } catch (e) {
              print('Mark attendance error: $e');

              Get.snackbar(
                'Error',
                'Something went wrong while marking attendance.',
                snackPosition: SnackPosition.BOTTOM,
              );
            }
          },
          icon: const Icon(Icons.check_circle_outline_rounded, size: 21),
          label: const Text(
            'Mark Attendance',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget roundButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.black.withOpacity(.05),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon, size: 26, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildQRCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8F4FF), Color(0xFFF1EEFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCD4FF), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFE9E4FF),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.qr_code_2_rounded,
              size: 43,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 16),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan QR Code',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Scan the labour\'s QR code\nto mark attendance',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
              onTap: _openScanner,
              borderRadius: BorderRadius.circular(15),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Scan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkAllocationCard() {
    final hasData =
        _attendanceFormData != null && _attendanceFormData!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 22),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =========================
          // HEADER
          // =========================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Work Allocation',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),

              TextButton.icon(
                onPressed: () async {
                  final result = await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (context) {
                      return ModuleFilterForm(filterOptions: attendanceInfo);
                    },
                  );

                  print('Module Filter Result: $result');

                  if (result != null && result is Map) {
                    setState(() {
                      _attendanceFormData = Map<String, dynamic>.from(result);
                    });
                  }
                },
                icon: Icon(
                  hasData ? Icons.edit_outlined : Icons.add_rounded,
                  size: 18,
                ),
                label: Text(hasData ? 'Edit' : 'Add'),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // =========================
          // FORM DATA
          // =========================
          if (hasData)
            DynamicDataPage(
              data: _attendanceFormData!,
              fieldKeys: {"zoneArea": "areaName", "project": "projectName"},
              variant: DynamicDataVariant.summary,
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No data entered',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget verticalDivider() {
    return Container(height: 42, width: 1, color: const Color(0xFFE7E8EF));
  }

  Widget _buildLabourHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          const Text(
            'Labour List',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            'Total: ${_labours.length}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: Color(0xFFA4A9BB)),
          SizedBox(height: 12),
          Text(
            'No labour found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Try another name, ID or filter.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// LABOUR TILE
// ============================================================

class LabourTile extends StatelessWidget {
  final WorkerQrData labour;
  final VoidCallback onTap;

  const LabourTile({super.key, required this.labour, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            children: [
              //_buildAvatar(),
              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            labour.firstName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        _buildIdChip(),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      labour.contractorName,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: Color(0xFF9BA1B7),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          labour.mobile,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Column(
              //   crossAxisAlignment: CrossAxisAlignment.end,
              //   children: [
              //     AttendanceStatusChip(status: labour.labourCode),

              //     if (labour.time != null) ...[
              //       const SizedBox(height: 7),
              //       Text(
              //         labour.time!,
              //         style: const TextStyle(
              //           fontSize: 11.5,
              //           fontWeight: FontWeight.w600,
              //           color: AppColors.textSecondary,
              //         ),
              //       ),
              //     ],
              //   ],
              // ),
              const SizedBox(width: 3),

              const Icon(
                Icons.chevron_right_rounded,
                size: 23,
                color: Color(0xFF9BA1B7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildAvatar() {
  //   final color = switch (labour.status) {
  //     AttendanceStatus.present => AppColors.green,
  //     AttendanceStatus.absent => AppColors.orange,
  //     AttendanceStatus.notMarked => AppColors.primary,
  //   };

  //   return Container(
  //     width: 54,
  //     height: 54,
  //     decoration: BoxDecoration(
  //       color: color.withOpacity(.09),
  //       shape: BoxShape.circle,
  //     ),
  //     child: Icon(Icons.person_outline_rounded, size: 29, color: color),
  //   );
  // }

  Widget _buildIdChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEFF),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        labour.id,
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ============================================================
// STATUS CHIP
// ============================================================

class AttendanceStatusChip extends StatelessWidget {
  final AttendanceStatus status;

  const AttendanceStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    late Color background;
    late Color foreground;
    late String text;

    switch (status) {
      case AttendanceStatus.present:
        background = const Color(0xFFE6F8F3);
        foreground = AppColors.green;
        text = 'Present';
        break;

      case AttendanceStatus.absent:
        background = const Color(0xFFF1F2F7);
        foreground = const Color(0xFF68708B);
        text = 'Absent';
        break;

      case AttendanceStatus.notMarked:
        background = const Color(0xFFFFF1E6);
        foreground = AppColors.orange;
        text = 'Not Marked';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

// ============================================================
// LABOUR DETAILS
// ============================================================

class LabourDetailsSheet extends StatelessWidget {
  final Labour labour;
  final VoidCallback onMarkPresent;

  const LabourDetailsSheet({
    super.key,
    required this.labour,
    required this.onMarkPresent,
  });

  @override
  Widget build(BuildContext context) {
    final isPresent = labour.status == AttendanceStatus.present;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 15, 22, 25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD9DCE8),
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 25),

            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFF0EEFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              labour.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              '${labour.role} • ${labour.id}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 24),

            _detailRow(Icons.phone_outlined, 'Phone', labour.phone),

            _detailRow(Icons.badge_outlined, 'Labour ID', labour.id),

            _detailRow(
              Icons.access_time_rounded,
              'Attendance',
              labour.time ?? 'Not marked',
            ),

            const SizedBox(height: 20),

            if (!isPresent)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: onMarkPresent,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text(
                    'Mark Present',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<String?> _showWorkerDialog(
  WorkerQrData worker,
  BuildContext context,
) async {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LABOUR',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: Color(0xFF718482),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${worker.firstName} ${worker.lastName}',
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF163D3A),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'PROJECT',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: Color(0xFF718482),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                worker.projectName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF163D3A),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Contractor',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: Color(0xFF718482),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                worker.contractorName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF163D3A),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext, 'queue');
                      },
                      child: const Text('ADD TO QUEUE'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext, 'attendance');
                      },
                      child: const Text(
                        'MARK ATTENDANCE',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

enum AttendanceStatus { present, absent, notMarked }

enum AttendanceFilter { all, present, absent, notMarked }

class Labour {
  final String id;
  final String name;
  final String role;
  final String phone;

  AttendanceStatus status;
  String? time;

  Labour({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.status,
    this.time,
  });
}

// ============================================================
// COLORS
// ============================================================
