import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:axiomos_workforce/constants/app_strings.dart';

class FilterController extends GetxController {
  /// The module config for which filters are currently active (a Map from your JSON)
  RxMap<String, dynamic> moduleConfig = <String, dynamic>{}.obs;

  /// original dataset (items for this module)
  final allItems = <Map<String, dynamic>>[].obs;

  /// filtered dataset (for UI)
  final displayedItems = <Map<String, dynamic>>[].obs;

  /// selected values for filters. key -> dynamic:
  /// - dropdown: String (value or 'all')
  /// - text: String
  /// - date: DateTime (or ISO string)
  /// - daterange: Map {'start': DateTime?, 'end': DateTime?}
  final RxMap<String, dynamic> selected = <String, dynamic>{}.obs;

  /// text controllers for text filters so we can keep text between builds
  final Map<String, TextEditingController> textControllers = {};

  @override
  void onClose() {
    // dispose text controllers
    for (final c in textControllers.values) {
      c.dispose();
    }
    super.onClose();
  }

  /// Call this when you open filters for a module.
  /// moduleConf is one module Map from your JSON (the object with moduleName, filters, etc.)
  void initForModule(
    Map<String, dynamic> moduleConf,
    List<Map<String, dynamic>> items,
  ) {
    moduleConfig.assignAll(moduleConf);
    allItems.assignAll(items);
    displayedItems.assignAll(items);

    // initialize selected map & text controllers from config defaults
    selected.clear();
    textControllers.clear();

    final filters = (moduleConfig['filters'] as List<dynamic>?) ?? [];
    for (var f in filters) {
      final k = f['key'].toString();
      final def = (f['default'] ?? '').toString();

      if (f['type'] == 'text') {
        textControllers[k] = TextEditingController(text: def);
        selected[k] = def;
      } else if (f['type'] == 'daterange') {
        // store as a map with DateTime? values
        selected[k] = {'start': null, 'end': null};
      } else {
        // dropdown/date/other -> default string or 'all'
        selected[k] = def.isEmpty ? 'all' : def;
      }
    }

    // apply filters once initialized
    applyFilters();
  }

  /// helper to set a filter value
  void setFilterValue(String key, dynamic value) {
    if (moduleConfig.isEmpty) return;
    selected[key] = value;
    // for text filters, also update controller if exists
    if (textControllers.containsKey(key) && value is String) {
      textControllers[key]!.text = value;
    }
    // do not auto-apply if you want manual Apply button — call applyFilters() explicitly.
  }

  /// apply all filters described in moduleConfig['filters'] to allItems and fill displayedItems
  void applyFilters() {
    final filters = (moduleConfig['filters'] as List<dynamic>?) ?? [];
    final result = allItems.where((item) {
      for (var f in filters) {
        final key = f['key'].toString();
        final type = (f['type'] ?? 'dropdown').toString();
        final path = (f['path'] ?? key).toString();

        final sel = selected.containsKey(key) ? selected[key] : null;
        // nothing selected or 'all' means skip this filter
        if (sel == null) continue;
        if (type == 'dropdown' &&
            (sel == 'all' || (sel is String && sel.isEmpty)))
          continue;
        if (type == 'text' && (sel is String && sel.trim().isEmpty)) continue;
        if (type == 'date' && sel == '') continue;
        if (type == 'daterange') {
          // expect sel to be {'start': DateTime?, 'end': DateTime?}
          final start = (sel is Map) ? sel['start'] as DateTime? : null;
          final end = (sel is Map) ? sel['end'] as DateTime? : null;
          if (start == null && end == null) continue; // no constraint
          final itemVal = _getNestedValue(item, path);
          final itemDate = _toDate(itemVal);
          if (itemDate == null) return false; // cannot compare
          if (start != null && itemDate.isBefore(start)) return false;
          if (end != null && itemDate.isAfter(end)) return false;
          continue;
        }

        // fetch item value at path and compare based on type
        final itemVal = _getNestedValue(item, path);
        if (type == 'text') {
          final v = (itemVal ?? '').toString().toLowerCase();
          final q = (sel as String).toLowerCase();
          if (!v.contains(q)) return false;
        } else if (type == 'date') {
          final selDate = (sel is DateTime) ? sel : _toDate(sel);
          final itemDate = _toDate(itemVal);
          if (selDate == null || itemDate == null) return false;
          // compare day equality
          if (itemDate.year != selDate.year ||
              itemDate.month != selDate.month ||
              itemDate.day != selDate.day)
            return false;
        } else {
          // default equality comparator (dropdown etc.)
          final itemStr = itemVal?.toString();
          if (itemStr == null) return false;
          if (itemStr != sel.toString()) return false;
        }
      }
      return true;
    }).toList();

    displayedItems.assignAll(result);
  }

  // ---------- helpers ----------
  dynamic _getNestedValue(dynamic obj, String path) {
    if (obj == null) return null;
    var cur = obj;
    for (final p in path.split('.')) {
      if (cur is Map<String, dynamic> && cur.containsKey(p)) {
        cur = cur[p];
      } else {
        // if cur is an object with properties, try dynamic access fallback
        try {
          cur = (cur as dynamic)[p];
        } catch (e) {
          // fallback to null or toString
          try {
            return cur.toString();
          } catch (_) {
            return null;
          }
        }
      }
      if (cur == null) return null;
    }
    return cur;
  }

  DateTime? _toDate(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val;
    try {
      return DateTime.tryParse(val.toString());
    } catch (_) {
      return null;
    }
  }
}

void showFilterOptionsForModule(
  BuildContext context,
  FilterController controller,
  Map<String, dynamic> moduleConf,
) {
  controller.initForModule(
    moduleConf,
    /* pass your module's all items here */ controller.allItems,
  ); // ensure allItems set before opening

  Get.bottomSheet(
    Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Obx(() {
        final filters = (moduleConf['filters'] as List<dynamic>?) ?? [];
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Filters",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      // reset to defaults
                      for (var f in filters) {
                        final k = f['key'].toString();
                        final def = (f['default'] ?? '').toString();
                        if (f['type'] == 'daterange') {
                          controller.setFilterValue(k, {
                            'start': null,
                            'end': null,
                          });
                        } else if (f['type'] == 'text') {
                          controller.textControllers[k]?.text = def;
                          controller.setFilterValue(k, def);
                        } else {
                          controller.setFilterValue(
                            k,
                            def.isEmpty ? 'all' : def,
                          );
                        }
                      }
                      controller.applyFilters();
                      Get.back();
                    },
                    child: Text("Reset"),
                  ),
                ],
              ),

              // each filter widget
              ...filters.map<Widget>((f) {
                final key = f['key'].toString();
                final label = (f['label'] ?? key).toString();
                final type = (f['type'] ?? 'dropdown').toString();

                if (type == 'dropdown') {
                  final sourceName = f['source']?.toString();
                  // resolve source list. adapt if your sources live elsewhere.
                  final sourceList =
                      (Strings.endpointToList[sourceName] as List<dynamic>?) ??
                      [];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: TextStyle(fontSize: 13)),
                        const SizedBox(height: 6),
                        Obx(() {
                          final cur = controller.selected.containsKey(key)
                              ? controller.selected[key]
                              : (f['default'] ?? 'all');
                          return DropdownButton<String>(
                            isExpanded: true,
                            value: cur == null ? 'all' : cur.toString(),
                            underline: SizedBox(),
                            items: [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('All'),
                              ),
                              ...sourceList.map<DropdownMenuItem<String>>((
                                item,
                              ) {
                                if (item is String) {
                                  return DropdownMenuItem(
                                    value: item,
                                    child: Text(item),
                                  );
                                } else if (item is Map) {
                                  final v = (item['_id'] ?? item['value'] ?? '')
                                      .toString();
                                  final t =
                                      (item['projectName'] ??
                                              item['name'] ??
                                              item['label'] ??
                                              v)
                                          .toString();
                                  return DropdownMenuItem(
                                    value: v,
                                    child: Text(t),
                                  );
                                } else {
                                  final s = item.toString();
                                  return DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  );
                                }
                              }).toList(),
                            ],
                            onChanged: (val) {
                              controller.setFilterValue(key, val);
                            },
                          );
                        }),
                      ],
                    ),
                  );
                } else if (type == 'text') {
                  controller.textControllers.putIfAbsent(
                    key,
                    () => TextEditingController(
                      text: (f['default'] ?? '').toString(),
                    ),
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: TextStyle(fontSize: 13)),
                        const SizedBox(height: 6),
                        Obx(() {
                          final ec = controller.textControllers[key]!;
                          return TextField(
                            controller: ec,
                            decoration: InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                              hintText: 'Type to search',
                            ),
                            onChanged: (val) =>
                                controller.setFilterValue(key, val),
                          );
                        }),
                      ],
                    ),
                  );
                } else if (type == 'date') {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: TextStyle(fontSize: 13)),
                        const SizedBox(height: 6),
                        Obx(() {
                          final cur = controller.selected.containsKey(key)
                              ? controller.selected[key]
                              : null;
                          final display = cur is DateTime
                              ? "${cur.year}-${cur.month}-${cur.day}"
                              : (cur?.toString() ?? 'Select date');
                          return InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: (cur is DateTime)
                                    ? cur
                                    : DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null)
                                controller.setFilterValue(key, picked);
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(display),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                } else if (type == 'daterange') {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: TextStyle(fontSize: 13)),
                        const SizedBox(height: 6),
                        Obx(() {
                          final cur =
                              controller.selected[key]
                                  as Map<String, dynamic>? ??
                              {'start': null, 'end': null};
                          final start = cur['start'] as DateTime?;
                          final end = cur['end'] as DateTime?;
                          final display =
                              (start != null
                                  ? "${start.year}-${start.month}-${start.day}"
                                  : 'Start') +
                              ' → ' +
                              (end != null
                                  ? "${end.year}-${end.month}-${end.day}"
                                  : 'End');

                          return Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: start ?? DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      controller.setFilterValue(key, {
                                        'start': picked,
                                        'end': end,
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      start != null
                                          ? "${start.year}-${start.month}-${start.day}"
                                          : 'Start',
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: end ?? DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      controller.setFilterValue(key, {
                                        'start': start,
                                        'end': picked,
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      end != null
                                          ? "${end.year}-${end.month}-${end.day}"
                                          : 'End',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  );
                } else {
                  // unknown type -> skip
                  return SizedBox.shrink();
                }
              }).toList(),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // close without applying changes
                        Get.back();
                      },
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // ensure text controllers values are captured
                        for (final e in controller.textControllers.entries) {
                          controller.setFilterValue(e.key, e.value.text);
                        }
                        controller.applyFilters();
                        Get.back();
                      },
                      child: Text('Apply'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      }),
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}
