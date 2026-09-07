import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:axiomos_workforce/constants/app_strings.dart';
import 'package:axiomos_workforce/helpers/dialogos.dart';
import 'package:axiomos_workforce/model/filter_model.dart';
import 'package:axiomos_workforce/services/api_services.dart';

class DynamicModuleController extends GetxController {
  final String moduleName;
  DynamicModuleController(this.moduleName);

  var config = <String, dynamic>{}.obs; // Holds module's config
  var dataList = <Map<String, dynamic>>[]
      .obs; // API data (typed, full list if client-side)
  var filteredList = <Map<String, dynamic>>[]
      .obs; // Data after search/tab filter (full filtered list)
  var currentPageItems = <Map<String, dynamic>>[]
      .obs; // Items for current page (what UI should show)
  String query = "";
  var isLoading = false.obs;
  var searchQuery = ''.obs;
  var selectedTabIndex = 0.obs;
  var selectedProject = RxnString();
  List<String> editAllowed = [];
  bool creationAllowed = false;
  RxBool isStatusActive = false.obs;
  RxList<Filter> filters = <Filter>[].obs;
  RxMap<String, dynamic> selectedFilters = <String, dynamic>{}.obs;
  // --- Pagination state ---
  RxInt pageSize = 50.obs; // default page size (flexible)
  RxInt currentPage = 1.obs; // 1-based
  RxInt totalPages = 1.obs;
  RxInt totalItems = 0.obs;
  List statusList = [];
  bool get canCreate => config['paginationMode'] == "local" ? false : true;

  // Pagination mode: "client" or "server". Default to client-side paging.
  // You can set this in modules.json as config['paginationMode'] = 'server'
  String get paginationMode =>
      (config['paginationMode'] as String?)?.toLowerCase() ?? 'server';

  // For server-side: store last fetched page to avoid duplicate fetches in infinite scroll
  int _lastServerPageFetched = 0;
  bool _hasMoreServerPages = true;
  bool _hasPreviousPages = false;

  @override
  void onInit() {
    super.onInit();
    loadConfig();
  }

  Future<void> loadConfig() async {
    final jsonString = await rootBundle.loadString(
      'lib/assets/json/modules.json',
    );
    final configList = List<Map<String, dynamic>>.from(jsonDecode(jsonString));

    config.value = configList.firstWhere(
      (c) => c['moduleName'] == moduleName,
      orElse: () => {},
    );
    statusList = config["statusList"] ?? [];
    // Safe read from RxMap
    final dynamic rawEditAllowed = config['editAllowed'];
    final dynamic filtersConfig = config['filters'];
    final dynamic permissions = config['permissions'];
    //creationAllowed = permissions.any((p) => Strings.permisssions.contains(p));
    editAllowed =
        (rawEditAllowed as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        [];
    // filters.value = (filtersConfig as List<dynamic>)
    //     .map<Filter>((e) => Filter.fromJson(e as Map<String, dynamic>))
    //     .toList();
    // default pageSize override from config (optional)
    final cfgPageSize = config['pageSize'];
    if (cfgPageSize is int && cfgPageSize > 0) {
      pageSize.value = cfgPageSize;
    }

    if (config.isNotEmpty) {
      await fetchData(resetPagination: true);
    }
  }

  Future<void> fetchData({bool resetPagination = false}) async {
    if (resetPagination) {
      resetPaginationState();
    }
    isLoading.value = true;
    try {
      if (paginationMode == 'server') {
        // SERVER-SIDE: Fetch page 1 (or currentPage)
        _lastServerPageFetched = 0;
        _hasMoreServerPages = true;
        currentPage.value = 1;
        await _fetchServerPage(currentPage.value);
      } else {
        print("fetching from here");
        // CLIENT-SIDE: fetch full dataset and paginate locally
        final raw = await ApiService().getRequest(moduleName);
        final List<Map<String, dynamic>> items =
            List<Map<String, dynamic>>.from(raw);
        final currentUserId = Strings.userId;
        // compute editAllowed flag for each item (same logic as before)
        for (var i = 0; i < items.length; i++) {
          final item = Map<String, dynamic>.from(items[i]);
          final canEdit = isEditAllowed(item, editAllowed, currentUserId);
          item['editAllowed'] = canEdit;
          items[i] = item;
        }

        // Apply project-level filter if not admin
        List<Map<String, dynamic>> filtered = items;
        if (Strings.roleName != "Admin") {
          filtered = items
              .where(
                (e) =>
                    e['project'] != null &&
                    e['project']['_id'] ==
                        Strings.endpointToList['project']['_id'],
              )
              .toList();
        }

        dataList.value = filtered;
        currentPageItems.value = filtered;
        print(dataList.length);
        // After setting dataList, apply filters and pagination
        // applyFilters();
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Helper: fetch a single server page.
  ///
  Future<void> _fetchServerPage(int page) async {
    if (!_hasMoreServerPages && page > _lastServerPageFetched) return;

    isLoading.value = true;
    String queryParams = "";
    try {
      if (Strings.roleName == "Admin") {
        String project = Strings.endpointToList["project"]["_id"];
        queryParams =
            "$moduleName?list=${pageSize.value}&page=${currentPage.value}&project=$project";
      } else {
        queryParams =
            "$moduleName?list=${pageSize.value}&page=${currentPage.value}";
      }

      // Add Tab Parameter if tabBased
      if (config['type'] == 'tabBased') {
        final tabs = List<String>.from(config['tabs'] ?? []);
        final selectedTab = tabs[selectedTabIndex.value];

        final tabFilters = (config['tabFilters'] ?? {})[selectedTab];
        if (tabFilters != null) {
          tabFilters.forEach((key, value) {
            queryParams += "&$key=$value";
          });
        }
      }

      // Add dynamic filters (optional for later)
      selectedFilters.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          queryParams += "&$key=$value";
        }
      });

      print("🔍 Request URL: $queryParams&");

      final raw = await ApiService().getRequest("$queryParams&");

      final List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(
        raw["data"],
      );

      final Map<String, dynamic> metaData = raw['meta'];
      currentPage.value = metaData['page'];
      pageSize.value = metaData["perPage"] ?? metaData["limit"];
      totalPages.value = metaData["totalPages"] ?? metaData["pages"];
      _hasMoreServerPages = metaData["hasNextPage"];
      _hasPreviousPages = metaData["hasPrevPage"];

      final currentUserId = Strings.userId;
      for (var i = 0; i < items.length; i++) {
        final item = Map<String, dynamic>.from(items[i]);
        final canEdit = isEditAllowed(item, editAllowed, currentUserId);
        item['editAllowed'] = canEdit;
        items[i] = item;
      }

      if (page == 1) {
        _lastServerPageFetched = 1;
        dataList.value = items;
      } else {
        _lastServerPageFetched = metaData["prevPage"] ?? 1;
        dataList.addAll(items);
      }

      filteredList.value = List<Map<String, dynamic>>.from(dataList);
      _updatePaginationMetaAndSlice();
    } catch (e, stackTrace) {
      print("❌ ERROR: $e");
      print("📌 STACK TRACE:\n$stackTrace");

      Get.snackbar(
        "Error cause here",
        e.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        duration: Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  ///delete module---------------
  Future<void> deleteSelection(BuildContext context, String key) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: "Delete Record",
      content: "Are you sure you want to delete this item?",
      confirmText: "Delete",
      cancelText: "Cancel",
    );

    if (!confirmed) return; // user cancelled

    isLoading.value = true;
    await ApiService().deleteRequest(moduleName, key);
    await fetchData(resetPagination: true);
    isLoading.value = false;
  }

  void applyFilters() {
    var tempList = List<Map<String, dynamic>>.from(dataList);

    if (selectedFilters.isNotEmpty) {
      tempList = applyDynamicFilters(
        dataList: dataList,
        filters: selectedFilters,
      );
    }

    // Tab filter (if tabBased)
    // if (config['type'] == 'tabBased') {
    //   final tabs = List<String>.from(config['tabs'] ?? []);
    //   final selectedTab = tabs[selectedTabIndex.value];

    //   final tabFilters = (config['tabFilters'] ?? {})[selectedTab];

    //   if (tabFilters != null) {
    //     tabFilters.forEach((key, value) {
    //       tempList = tempList.where((item) {
    //         final fieldValue = item[key];
    //         return fieldValue == value;
    //       }).toList();
    //     });
    //   }
    // }

    // Search filter
    if (searchQuery.value.isNotEmpty) {
      tempList = tempList
          .where(
            (item) => item.toString().toLowerCase().contains(
              searchQuery.value.toLowerCase(),
            ),
          )
          .toList();
    }

    // Set filteredList (full list after filters)
    filteredList.value = tempList;

    // Recompute pagination meta and pick page slice
    _updatePaginationMetaAndSlice();
  }

  //--------------------filters---------------------
  List<Map<String, dynamic>> applyDynamicFilters({
    required List<Map<String, dynamic>> dataList,
    required Map<String, dynamic> filters,
  }) {
    List<Map<String, dynamic>> tempList = List.from(dataList);

    DateTime parseFromDate(String? from) {
      if (from == null || from.isEmpty) {
        // Very old date so all items pass
        return DateTime(1970, 1, 1);
      }
      return DateFormat('yyyy-M-d').parse(from);
    }

    DateTime parseToDate(String? to) {
      if (to == null || to.isEmpty) {
        // Default to today
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day);
      }
      return DateFormat('yyyy-M-d').parse(to);
    }

    final fromDate = parseFromDate(filters["from"]);
    final toDate = parseToDate(filters["to"]);
    print("----Is this null ${filters["from"]}-----$toDate");
    tempList = tempList.where((item) {
      bool matches = true;

      filters.forEach((key, value) {
        if (value == null) return;

        // Skip 'from' and 'to', handled separately
        if (key == "from" || key == "to") return;

        dynamic itemValue = item[key];

        // If the field is a list of maps (e.g., typeOfTopic)
        if (itemValue is Map && value is List) {
          // Check if the item's map _id is in the filter list
          if (!value.contains(itemValue["_id"])) {
            matches = false;
          }
        } else if (itemValue is List && value is List) {
          bool anyMatch = itemValue.any((v) => value.contains(v["_id"]));
          if (!anyMatch) matches = false;
        }
        // If the field is a list of simple values
        else if (itemValue is List && value is List) {
          bool anyMatch = itemValue.any((v) => value.contains(v));
          if (!anyMatch) matches = false;
        } else if (itemValue is Map) {
          bool anyMatch = itemValue["_id"] == value;
          if (!anyMatch) matches = false;
        }
        // If the field is a single value
        else {
          if (itemValue == null ||
              !value.toString().toLowerCase().contains(
                itemValue.toString().toLowerCase(),
              )) {
            matches = false;
          }
        }
      });

      // Date filtering
      if (matches && (fromDate != null || toDate != null)) {
        final itemDate = DateTime.tryParse(item["date"] ?? item["createdAt"]);
        print("$fromDate-----$itemDate-----$toDate");
        if (itemDate == null) return false;
        if (fromDate != null && itemDate.isBefore(fromDate)) matches = false;
        if (toDate != null && itemDate.isAfter(toDate)) matches = false;
      } else {}

      return matches;
    }).toList();

    return tempList;
  }

  // ---------------- Pagination helpers ----------------

  void _updatePaginationMetaAndSlice() {
    selectedTabIndex.value = 0;
    final int total = totalItems.value;
    totalItems.value = total;

    totalPages.value = totalPages.value;

    // Clamp currentPage
    if (currentPage.value < 1) currentPage.value = 1;
    if (currentPage.value > totalPages.value)
      currentPage.value = totalPages.value;

    // Slice for current page (1-based)
    final start = (currentPage.value - 1) * pageSize.value;
    final end = start + pageSize.value;
    final slice = filteredList.sublist(
      start,
      end > filteredList.length ? filteredList.length : end,
    );

    currentPageItems.value = List<Map<String, dynamic>>.from(slice);
  }

  /// Set page size and reset to first page (and recompute slice)
  void setPageSize(int size, {bool resetToFirstPage = true}) {
    if (size <= 0) return;
    pageSize.value = size;
    currentPage.value = 1;
    _fetchServerPage(1);
    if (resetToFirstPage) currentPage.value = 1;

    _updatePaginationMetaAndSlice();
  }

  void goToPage(int page) {
    if (page < 1) page = 1;
    if (page > totalPages.value) page = totalPages.value;
    currentPage.value = page;
    _updatePaginationMetaAndSlice();

    // If server-side and requesting a page that hasn't been fetched, fetch it
    if (paginationMode == 'server' &&
        page > _lastServerPageFetched &&
        _hasMoreServerPages) {
      print("fetching data..................");
      _fetchServerPage(page);
    }
  }

  void nextPage() {
    if (currentPage.value >= totalPages.value) return;

    currentPage.value++;
    _updatePaginationMetaAndSlice();

    if (paginationMode == 'server' &&
        currentPage.value > _lastServerPageFetched &&
        _hasMoreServerPages) {
      _fetchServerPage(currentPage.value);
    }
  }

  void prevPage() {
    if (currentPage.value <= 1) return;
    currentPage.value--;
    _updatePaginationMetaAndSlice();
  }

  /// For infinite scroll: loads the next server page and appends items to filteredList/dataList.
  /// Works only when paginationMode == 'server'.
  Future<void> loadMore() async {
    if (paginationMode != 'server') {
      // For client-side infinite scroll, simply increase page and slice locally
      if (currentPage.value < totalPages.value) {
        currentPage.value++;
        _updatePaginationMetaAndSlice();
      }
      return;
    }

    if (!_hasMoreServerPages) return;

    final next = _lastServerPageFetched + 1;
    await _fetchServerPage(next);

    // after appending, update pages and slice
    // For server-mode, we treat filteredList == dataList (server should return already filtered dataset)
    _updatePaginationMetaAndSlice();
  }

  /// Reset pagination internal state
  void resetPaginationState() {
    currentPage.value = 1;
    totalPages.value = 1;
    totalItems.value = 0;
    _lastServerPageFetched = 0;
    _hasMoreServerPages = true;
    currentPageItems.clear();
  }

  void updateSearchQuery(String value) {
    searchQuery.value = value;
    applyFilters();
  }

  void changeTab(int index) async {
    selectedTabIndex.value = index;
    await fetchData(resetPagination: true);
  }

  updateStatus(String id, Map<String, dynamic> changedData) async {
    await ApiService().updateData(moduleName, id, changedData);
    print("Status Changed;;;;;;;;;;;;;;;;;;;;;;;");

    // After update, refresh current data. For server pagination you might only want to refresh current page.
    fetchData();
  }

  bool isEditAllowed(
    Map<String, dynamic> item,
    List<String> editableFields,
    String currentUserId,
  ) {
    bool fieldMatchesCurrentUser(dynamic fieldObj) {
      if (fieldObj == null) return false;

      if (fieldObj is String) {
        return fieldObj == currentUserId;
      }

      if (fieldObj is Map<String, dynamic>) {
        final fObjId = fieldObj['_id']?.toString();
        final fUserId = fieldObj['userId']?.toString();

        if (currentUserId.isNotEmpty &&
            (fUserId == currentUserId || fObjId == currentUserId)) {
          return true;
        }
        return false;
      }

      if (fieldObj is List) {
        for (final e in fieldObj) {
          if (fieldMatchesCurrentUser(e)) return true;
        }
      }

      return false;
    }

    for (final fieldName in editableFields) {
      if (!item.containsKey(fieldName)) continue;

      final fieldValue = item[fieldName];
      if (fieldMatchesCurrentUser(fieldValue)) return true;
    }

    return false;
  }
}
