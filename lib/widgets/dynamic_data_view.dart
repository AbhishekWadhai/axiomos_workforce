import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:axiomos_workforce/services/text_formatters.dart';
import 'package:axiomos_workforce/views/additional_views/image_view_page.dart';

enum DynamicDataVariant { defaultView, summary }

class DynamicDataPage extends StatelessWidget {
  final ScrollController? controller;
  final Map<String, dynamic> data;
  final Map<String, dynamic> fieldKeys;
  final DynamicDataVariant variant;

  final List<String> excludedKeys = [
    '_id',
    'password',
    '__v',
    'editAllowed',
    'createdby',
    '_escalationHistory',
  ];

  DynamicDataPage({
    this.controller,
    required this.data,
    required this.fieldKeys,
    this.variant = DynamicDataVariant.defaultView,
  });

  // Function to filter out excluded keys and create dynamic rows for key-value pairs
  List<Widget> _buildKeyValuePairs(Map<String, dynamic> data) {
    final filteredData = Map.fromEntries(
      data.entries.where(
        (entry) =>
            !entry.key.startsWith('_') && // 🔥 exclude all _fields
            !excludedKeys.contains(entry.key),
      ),
    );

    return filteredData.entries.map((entry) {
      bool isChecklist = false;
      bool isObjectId = false;
      final formattedValue = _formatCellValue(entry.value, entry.key);

      Widget valueWidget;
      if (formattedValue.startsWith("CHECKLIST:")) {
        valueWidget = _buildCheckListTable(data[entry.key]);
        isChecklist = true;
      } else if (formattedValue.startsWith("NESTED:")) {
        valueWidget = _buildNested({"data": data[entry.key]});
        isChecklist = true;
        //valueWidget = _buildCheckListTable(data[entry.key]);
      } else if (formattedValue.startsWith("IMAGE:")) {
        String imageUrl = formattedValue.substring(6); // Extract URL
        valueWidget = GestureDetector(
          onTap: () => Get.to(ImageViewPage(imageUrl: imageUrl)),
          child: Image.network(
            imageUrl,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Icon(Icons.broken_image),
          ),
        );
      } else if (formattedValue.startsWith("USER")) {
        valueWidget = Container(
          margin: const EdgeInsets.only(top: 12, bottom: 12.0),
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey, width: 1),
          ),
          child: DynamicDataPage(data: data[entry.key], fieldKeys: fieldKeys),
        );
        isChecklist = true;
      } else if (formattedValue.startsWith("objId")) {
        isObjectId = true;
        valueWidget = SizedBox.shrink();
      } else {
        valueWidget = Text(
          formattedValue,
          style: const TextStyle(fontSize: 16),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: isObjectId
            ? const SizedBox.shrink() // 1. If it's a MongoID, show nothing
            : isChecklist
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    TextFormatters().toTitleCase(entry.key),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  valueWidget,
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      TextFormatters().toTitleCase(entry.key),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Spacer(),
                  Expanded(flex: 2, child: valueWidget),
                ],
              ),
      );
    }).toList();
  }

  // Helper function to format cell value based on its type
  String _formatCellValue(dynamic value, String key) {
    if (value != null) {
      // ---------- 🟢 ADD THIS BLOCK HERE ----------
      if (value is List && value.isNotEmpty && value.first is Map) {
        //final firstMap = value.first as Map;

        if (_isChecklist(value)) {
          return "CHECKLIST:$key"; // Special signal for UI rendering
        } else if (hasMapAndStringInFirstElement(value)) {
          return "NESTED:$key";
        } else {
          print("");
        }
      }
      if (value is String) {
        if (RegExp(r'^\d+$').hasMatch(value)) {
          return value;
        }
        if (isValidMongoId(value)) {
          return "objId:$value";
        }
        // Check if the value is an image URL
        if (_isImageUrl(value)) {
          return "IMAGE:$value"; // Placeholder for image display logic
        }

        // Try parsing as DateTime
        try {
          DateTime parsedDate = DateTime.parse(value);
          return _formatDate(parsedDate);
        } catch (e) {
          return value; // Return original string if not a date
        }
      }

      // Check if the value is a list of maps
      if (value is List) {
        if (value.isEmpty) return '-';

        // 1. Handle List of Maps (Objects)
        if (value.first is Map) {
          return value
              .map((item) {
                if (item is Map) {
                  if (fieldKeys.containsKey(key)) {
                    String fieldName = fieldKeys[key]!;
                    return item[fieldName]?.toString() ?? '';
                  }
                  return item.values.join(', ');
                }
                return '';
              })
              .join(' | ');
        }

        // 2. Handle List of Primitives (Strings/Ints/ObjectIDs)
        final mongoIdRegex = RegExp(r'^[0-9a-fA-F]{24}$');

        // Check if the first item is a MongoID (assuming the whole list is IDs)
        bool isIdList = mongoIdRegex.hasMatch(value.first.toString());

        if (isIdList) {
          // If it's a list of IDs (like your "project" field),
          // you usually don't want to show the hex string to the user.
          return 'objId'; // Or return value.join(', ') if you actually want to see them.
        }

        // If it's a normal list (like List of Categories or Tags)
        return value.map((e) => e.toString()).join(', ');
      }
      if (value is Map) {
        if (_isUserLikeMap(value)) {
          return "USER:";
        }

        // ❌ All other maps fall through normally
      }

      // Check if the field exists in fieldKeys
      if (fieldKeys.containsKey(key)) {
        String fieldName = fieldKeys[key]!;
        return value[fieldName]?.toString() ?? '';
      } else {
        return value.toString();
      }
    } else {
      return '';
    }
  }

  bool isValidMongoId(String id) {
    final regExp = RegExp(r'^[0-9a-fA-F]{24}$');
    return regExp.hasMatch(id);
  }

  bool _isUserLikeMap(Map map) {
    const allowedKeys = {'name', 'email', 'phone'};

    return map.keys.any((k) => k is String && allowedKeys.contains(k));
  }

  // Helper function to check if a string is an image URL
  bool _isImageUrl(String url) {
    if (url.toLowerCase().endsWith('.png') ||
        url.toLowerCase().endsWith('.jpg') ||
        url.toLowerCase().endsWith('.jpeg') ||
        url.toLowerCase().endsWith('.gif') ||
        url.toLowerCase().endsWith('.bmp') ||
        url.toLowerCase().endsWith('.webp')) {
      return true;
    }

    // Check for Google Drive file URLs
    return url.contains("drive.google.com");
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }

  bool _isChecklist(List list) {
    if (list.isEmpty || list.first is! Map) return false;

    final map = list.first as Map;

    // Possible question keys
    const questionKeys = ["CheckPoints", "question", "title", "description"];

    // Possible response keys
    const responseKeys = ["response", "answer", "status", "value"];

    // Check if at least one question & one response key exists
    bool hasQuestion = map.keys.any((k) => questionKeys.contains(k));
    bool hasResponse = map.keys.any((k) => responseKeys.contains(k));

    return hasQuestion && hasResponse;
  }

  bool hasMapAndStringInFirstElement(List list) {
    if (list.isEmpty || list.first is! Map) return false;

    final Map map = list.first as Map;

    int meaningfulFieldCount = 0;

    for (final entry in map.entries) {
      final key = entry.key.toString();
      final value = entry.value;

      // ignore technical keys
      if (key == '_id') continue;

      if (value is String || value is num || value is bool || value is Map) {
        meaningfulFieldCount++;
      }

      // early exit
      if (meaningfulFieldCount >= 2) return true;
    }

    return false;
  }

  // Change the parameter name for clarity
  Widget _buildNested(Map<String, dynamic> wrapperMap) {
    final List<dynamic> nestedList = wrapperMap["data"] as List<dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // ✅ important
      children: [
        ...nestedList.map((item) {
          //compare this with the working of .map and for loop

          if (item is Map<String, dynamic>) {
            return Container(
              margin: const EdgeInsets.only(top: 12, bottom: 12.0),
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey, width: 1),
              ),
              child: DynamicDataPage(data: item, fieldKeys: fieldKeys),
            );
          }

          return const SizedBox.shrink();
        }).toList(),
      ],
    );
  }

  Widget _buildCheckListTable(List<dynamic> list) {
    // printLargeJson(list);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(top: 8),
      child: Table(
        border: TableBorder.all(color: Colors.grey),
        columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(1)},
        children: [
          // Header Row
          const TableRow(
            decoration: BoxDecoration(color: Color(0xFFEFEFEF)),
            children: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "Check Point",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "Response",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          // Dynamic rows
          ...list.map((item) {
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(item["CheckPoints"] ?? item['question']),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(item["response"] ?? "-"),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case DynamicDataVariant.summary:
        return _buildSummaryView();

      case DynamicDataVariant.defaultView:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: _buildKeyValuePairs(data),
            ),
          ),
        );
    }
  }

  Widget _buildSummaryView() {
    final visibleEntries = data.entries.where(
      (entry) =>
          !entry.key.startsWith('_') && !excludedKeys.contains(entry.key),
    );

    if (visibleEntries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'No data entered',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      children: visibleEntries.map((entry) {
        final value = _getDisplayValue(entry.key, entry.value);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  TextFormatters().toTitleCase(entry.key),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getDisplayValue(String key, dynamic value) {
    if (value == null) {
      return '-';
    }

    if (value is Map) {
      if (fieldKeys.containsKey(key)) {
        final fieldName = fieldKeys[key];
        return value[fieldName]?.toString() ?? '-';
      }

      // For your filter structure:
      if (value.containsKey('value')) {
        return value['value']?.toString() ?? '-';
      }

      if (value.containsKey('name')) {
        return value['name']?.toString() ?? '-';
      }

      if (value.containsKey('_id')) {
        return value['_id']?.toString() ?? '-';
      }
    }

    if (value is List) {
      if (value.isEmpty) {
        return '-';
      }

      return value
          .map((item) {
            if (item is Map) {
              if (fieldKeys.containsKey(key)) {
                return item[fieldKeys[key]]?.toString() ?? '';
              }

              return item['name']?.toString() ??
                  item['value']?.toString() ??
                  '';
            }

            return item.toString();
          })
          .join(', ');
    }

    return value.toString();
  }
}
