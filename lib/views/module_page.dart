import 'package:axiomos_workforce/widgets/custom_appbar.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:axiomos_workforce/constants/asset_path.dart';
import 'package:axiomos_workforce/constants/colors.dart';
import 'package:axiomos_workforce/controllers/module_controller.dart';
import 'package:axiomos_workforce/routes/routes_string.dart';
import 'package:axiomos_workforce/services/api_services.dart';
import 'package:axiomos_workforce/services/download_excel.dart';
import 'package:axiomos_workforce/services/text_formatters.dart';
import 'package:axiomos_workforce/services/translation.dart';
import 'package:axiomos_workforce/widgets/dynamic_tile.dart';
import 'package:axiomos_workforce/widgets/gradient_button.dart';
import 'package:axiomos_workforce/widgets/loader.dart';
import 'package:axiomos_workforce/widgets/module_filter_form.dart/module_filter_controller.dart';
import 'package:axiomos_workforce/widgets/module_filter_form.dart/module_filter_form.dart';

class DynamicModulePage extends StatefulWidget {
  const DynamicModulePage({super.key});

  @override
  State<DynamicModulePage> createState() => _DynamicModulePageState();
}

class _DynamicModulePageState extends State<DynamicModulePage> {
  late final String moduleName;
  late final DynamicModuleController controller;
  final ModuleFilterController moduleFilterController = Get.put(
    ModuleFilterController(),
  );
  // Scroll controller used for infinite scroll when server-side pagination is enabled
  final ScrollController _scrollController = ScrollController(); // <-- CHANGED

  // Jump-to page text controller (for classic pagination jump)
  final TextEditingController _jumpController =
      TextEditingController(); // <-- CHANGED

  @override
  void initState() {
    super.initState();
    moduleName = Get.arguments?[0] ?? "";
    controller = Get.put(
      DynamicModuleController(moduleName),
      tag: moduleName, // Tag ensures unique instance per module
    );

    // Setup infinite-scroll listener for server-side pagination.
    // We check the controller.paginationMode to decide whether to trigger loadMore.
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      // threshold in pixels to trigger loadMore before reaching bottom
      const threshold = 200.0;

      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - threshold) {
        // Only trigger loadMore when pagination mode is server-side
        if (controller.paginationMode == 'server' &&
            !controller.isLoading.value) {
          controller.loadMore();
        }
      }
    }); // <-- CHANGED
  }

  @override
  void dispose() {
    // Optional: remove the controller when page is disposed
    if (Get.isRegistered<DynamicModuleController>(tag: moduleName)) {
      Get.delete<DynamicModuleController>(tag: moduleName);
    }
    _scrollController.dispose(); // <-- CHANGED
    _jumpController.dispose(); // <-- CHANGED
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.config.isEmpty) {
        return Scaffold(
          body: const Center(child: Text("Module config not found")),
        );
      }

      final isTabBased = controller.config['type'] == 'tabBased';
      final tabs = isTabBased
          ? List<String>.from(controller.config['tabs'])
          : [];

      return DefaultTabController(
        length: isTabBased ? tabs.length : 1,
        child: Scaffold(
          appBar: MyAppBar(
            actions: [
              IconButton(
                icon: const Icon(Icons.file_download_rounded),
                onPressed: () {
                  showDownloadBottomSheet(moduleName);
                },
              ),
              TextButton(
                onPressed: () {
                  showFilterOptions();
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.filter_list_rounded, color: Colors.white),
                  ],
                ),
              ),
            ],
            title: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (v) {
                // If you want search to always reset to page 1, uncomment the next line:
                // controller.currentPage.value = 1; // <-- OPTIONAL
                controller.updateSearchQuery(v);
              },
              decoration: InputDecoration(
                hintText: "Search ${translate(moduleName)}",
                hintStyle: const TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
            ),
            bottom: isTabBased
                ? TabBar(
                    indicatorColor: Colors.white,
                    onTap: (idx) {
                      // If you want tab change to go to page 1:
                      // controller.currentPage.value = 1; // <-- OPTIONAL
                      controller.changeTab(idx);
                    },
                    tabs: tabs.map((t) => Tab(text: t)).toList(),
                  )
                : null,
          ),
          body: Obx(() {
            // Use column so we can place pagination controls below the list
            return Column(
              children: [
                Expanded(
                  child:
                      controller.isLoading.value &&
                          controller.currentPageItems.isEmpty
                      ? const Center(child: LottieLoader(size: 80))
                      : CustomMaterialIndicator(
                          indicatorBuilder: (context, controller) {
                            return const Padding(
                              padding: EdgeInsets.all(6.0),
                              child: LottieLoader(size: 80),
                            );
                          },
                          // Use resetPagination:true to ensure pages reset on pull-to-refresh
                          onRefresh: () async {
                            await controller.fetchData(
                              resetPagination: true,
                            ); // <-- CHANGED
                          },
                          child: Builder(
                            builder: (context) {
                              // Decide which collection to render: currentPageItems (pagination-aware)
                              final items = controller.currentPageItems;

                              // If no page items, show your empty state (preserve pull-to-refresh)
                              if (items.isEmpty) {
                                return SingleChildScrollView(
                                  controller:
                                      _scrollController, // attach scroll controller even for empty state
                                  physics:
                                      const AlwaysScrollableScrollPhysics(), // << important
                                  child: ConstrainedBox(
                                    // ensure it fills viewport so pull is possible
                                    constraints: BoxConstraints(
                                      minHeight:
                                          MediaQuery.of(context).size.height -
                                          200,
                                    ),
                                    child: Center(
                                      child: Image.asset(Assets.noData),
                                    ),
                                  ),
                                );
                              }

                              // When server-side pagination (infinite scroll style), show loader row
                              final showLoaderAtEnd =
                                  (controller.paginationMode == 'server');

                              return ListView.builder(
                                controller:
                                    _scrollController, // <-- CHANGED: attach controller for infinite scroll
                                itemCount:
                                    items.length +
                                    (showLoaderAtEnd
                                        ? 1
                                        : 0), // loader item for server mode
                                itemBuilder: (context, index) {
                                  if (showLoaderAtEnd &&
                                      index >= items.length) {
                                    // loader row for server-side pagination
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12.0,
                                      ),
                                      child: Center(
                                        child: controller.isLoading.value
                                            ? const CircularProgressIndicator()
                                            : const Text('No more items'),
                                      ),
                                    );
                                  }

                                  final item = items[index];
                                  return Column(
                                    children: [
                                      DynamicTile(
                                        controller: controller,
                                        endpoint: moduleName,
                                        item: item,
                                        fieldKeys: keysForMap,
                                        tileMapping: {
                                          "title":
                                              controller.config['tileTitle1'] ??
                                              '',
                                          "subtitle":
                                              controller.config['tileTitle2'] ??
                                              '',
                                          "trailing":
                                              controller.config['tileTitle3'] ??
                                              '',
                                        },
                                        onResult: (updatedItem) {
                                          controller.fetchData();
                                        },
                                        onLongPressed: () {
                                          controller.deleteSelection(
                                            context,
                                            item["_id"],
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                ),
                Row(
                  children: [
                    _buildPaginationBar(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: controller.creationAllowed
                            ? GradientButton(
                                borderRadius: 30,
                                onTap: () async {
                                  var result = await Get.toNamed(
                                    Routes.formPage,
                                    arguments: [
                                      moduleName,
                                      <String, dynamic>{},
                                      false,
                                    ],
                                  );
                                  if (result == true) {
                                    controller.fetchData();
                                  }
                                },
                                text: "Create",
                                height: 36,
                                icon: Icon(
                                  Icons.post_add_rounded,
                                  color: Colors.white,
                                ),
                                gradientColors: [
                                  AppColors.appMainMid,
                                  AppColors.appMainDark,
                                ],
                              )
                            : SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
      );
    });
  }

  void showFilterOptions() async {
    //final height = MediaQuery.of(context).size.height * 0.65; // 60% screen

    final result = await Get.bottomSheet(
      Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Container(
              color: Colors.white,
              //height: height, // <-- finite height prevents "infinite" error
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ModuleFilterForm(filterOptions: controller.filters),
              ),
            ),
          ),
          Positioned(
            top: -15, // 👈 Half outside
            left: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(16),
                ),
                // boxShadow: [
                //   BoxShadow(
                //     color: Colors.black26,
                //     blurRadius: 6,
                //   )
                // ],
              ),
              child: const Text(
                "Filters",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
    if (result != null) {
      // Use your result here

      printLargeJson(controller.selectedFilters);
      // Example: update your controller
      controller.selectedFilters.value = result;
      var query = ApiService().buildQueryParams(result);
      print("User submitted query: $query");
      controller.query = query;
      controller.applyFilters();
    }
  }

  Widget _buildPaginationBar() {
    return Obx(() {
      final show =
          controller.totalPages.value > 1 ||
          controller.paginationMode == 'server';
      if (!show) return const SizedBox.shrink();

      // debug info - comment out after verifying
      // print('pagination: mode=${controller.paginationMode}, total=${controller.totalPages.value}, page=${controller.currentPage.value}');

      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(30),
            color: Theme.of(context).cardColor,
            child: Container(
              height: 36, // compact height
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page size popup (reactive)
                  Obx(
                    () => PopupMenuButton<int>(
                      tooltip: 'Items per page',
                      padding: EdgeInsets.zero,
                      itemBuilder: (_) => [5, 10, 20, 50]
                          .map(
                            (v) => PopupMenuItem(value: v, child: Text('$v')),
                          )
                          .toList(),
                      onSelected: (v) =>
                          controller.setPageSize(v, resetToFirstPage: true),
                      // The child defines the tappable area — give it generous padding & min size
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 36,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${controller.pageSize.value}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.unfold_more, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Prev (small tappable area) - use explicit min size
                  SizedBox(
                    height: 32,
                    width: 36,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      icon: const Icon(Icons.chevron_left),
                      onPressed: controller.currentPage.value > 1
                          ? () => controller.prevPage()
                          : null,
                      tooltip: 'Previous page',
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Page indicator (reactive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Obx(
                      () => Text(
                        '${controller.currentPage.value} / ${controller.totalPages.value}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Next (small tappable area)
                  SizedBox(
                    height: 32,
                    width: 36,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      icon: const Icon(Icons.chevron_right),
                      onPressed:
                          controller.currentPage.value <
                              controller.totalPages.value
                          ? () => controller.nextPage()
                          : null,
                      tooltip: 'Next page',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}



///////////////////////////////////////////////////////
/// Container(
        //   child: Obx(() => Padding(
        //       padding: const EdgeInsets.symmetric(horizontal: 20.0),
        //       child: DropdownButton<String>(
        //         isExpanded: true,
        //         value: controller.selectedProject.value,
        //         hint: const Text(
        //           "Select Project",
        //           style: TextStyle(fontSize: 14),
        //         ),
        //         items: [
        //           const DropdownMenuItem<String>(
        //             value: "all",
        //             child: Text(
        //               "All Projects",
        //               style:
        //                   TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        //             ),
        //           ),
        //           ...(Strings.endpointToList["projects"] as List<dynamic>)
        //               .map<DropdownMenuItem<String>>((type) {
        //             return DropdownMenuItem<String>(
        //               value: type['_id'] as String,
        //               child: Text(
        //                 type['projectName'] as String,
        //                 style: const TextStyle(fontSize: 14),
        //               ),
        //             );
        //           }).toList(),
        //         ],
        //         onChanged: (value) {
        //           controller.selectedProject.value = value;
        //           controller.applyFilters();
        //           if (value == "all") {
        //             // handle all projects logic
        //             controller.selectedProject.value = "all";
        //             print("All Projects selected");
        //           } else {
        //             print("Project selected: $value");
        //           }
        //           Get.back();
        //         },
        //         underline:
        //             const SizedBox(), // Remove extra space under dropdown
        //       ))),
        // ),