import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:axiomos_workforce/constants/app_strings.dart';
import 'package:axiomos_workforce/constants/asset_path.dart';
import 'package:axiomos_workforce/constants/colors.dart';
import 'package:axiomos_workforce/helpers/custom_card.dart';
import 'package:axiomos_workforce/routes/routes_string.dart';

class AutoCarousel extends StatefulWidget {
  final DateTimeRange selectedRange;

  const AutoCarousel({Key? key, required this.selectedRange}) : super(key: key);

  @override
  _AutoCarouselState createState() => _AutoCarouselState();
}

class _AutoCarouselState extends State<AutoCarousel> {
  late PageController _pageController;
  late Timer _timer;
  int _currentPage = 5000;

  int workPermitCount = 0;
  int inductionCount = 0;
  int uaucCount = 0;
  int specificCount = 0;
  int meetingCount = 0;

  List<Widget> get _items => [
    CardFb2(
      totalNo: workPermitCount.toString(),
      text: 'Work Permit',
      imageUrl: Assets.workPermit,
      subtitle: 'Available Work Permit',
      onPressed: () => Get.toNamed(Routes.userDetailsDataPage),
    ),
    CardFb2(
      totalNo: inductionCount.toString(),
      text: 'Inductees',
      imageUrl: Assets.workPermit,
      subtitle: 'Total number of inductees',
      onPressed: () => Get.toNamed(Routes.userDetailsDataPage),
    ),
    CardFb2(
      totalNo: uaucCount.toString(),
      text: 'Observation',
      imageUrl: Assets.workPermit,
      subtitle: 'Reported observation',
      onPressed: () => Get.toNamed(Routes.userDetailsDataPage),
    ),
    CardFb2(
      totalNo: specificCount.toString(),
      text: 'Specific Training',
      imageUrl: Assets.workPermit,
      subtitle: 'Specific Training Conducted',
      onPressed: () => Get.toNamed(Routes.userDetailsDataPage),
    ),
    CardFb2(
      totalNo: meetingCount.toString(),
      text: 'TBT Meetings',
      imageUrl: Assets.workPermit,
      subtitle: 'TBT Meetings Conducted',
      onPressed: () => Get.toNamed(Routes.userDetailsDataPage),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
    _startAutoScroll();
    _filterCounts();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (_pageController.hasClients) {
        _currentPage++;
        _pageController.animateToPage(
          _currentPage,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() {}); // Update dot
      }
    });
  }

  void _filterCounts() {
    bool isWithinRange(DateTime? date) {
      if (date == null) return false;

      final selectedStart = DateTime(
        widget.selectedRange.start.year,
        widget.selectedRange.start.month,
        widget.selectedRange.start.day,
      );

      final selectedEnd = DateTime(
        widget.selectedRange.end.year,
        widget.selectedRange.end.month,
        widget.selectedRange.end.day,
      );

      final currentDate = DateTime(date.year, date.month, date.day);

      return !currentDate.isBefore(selectedStart) &&
          !currentDate.isAfter(selectedEnd);
    }

    setState(() {
      workPermitCount = Strings.workpermit.where((item) {
        final date = DateTime.tryParse(item['date'] ?? '');
        return isWithinRange(date);
      }).length;

      inductionCount = Strings.induction.where((item) {
        final date = DateTime.tryParse(item['date'] ?? '');
        return isWithinRange(date);
      }).length;

      uaucCount = Strings.uauc.where((item) {
        final date = DateTime.tryParse(item['date'] ?? '');
        return isWithinRange(date);
      }).length;

      specificCount = Strings.specific.where((item) {
        final date = DateTime.tryParse(item['date'] ?? '');
        return isWithinRange(date);
      }).length;

      meetingCount = Strings.meetings.where((item) {
        final date = DateTime.tryParse(item['date'] ?? '');
        return isWithinRange(date);
      }).length;
    });
  }

  @override
  void didUpdateWidget(covariant AutoCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedRange != widget.selectedRange) {
      _filterCounts();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Column(
      children: [
        SizedBox(
          height: 100,
          child: PageView.builder(
            controller: _pageController,
            itemBuilder: (context, index) {
              final actualIndex = index % items.length;
              return items[actualIndex];
            },
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(items.length, (index) {
            final activeIndex = _currentPage % items.length;
            return AnimatedContainer(
              duration: Duration(milliseconds: 300),
              margin: EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: 8,
              decoration: BoxDecoration(
                color: activeIndex == index
                    ? AppColors.appMainDark
                    : Colors.grey,
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ],
    );
  }
}
