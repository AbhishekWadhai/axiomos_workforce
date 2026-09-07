// Add these fonts to your project and pubspec.yaml:
// assets/fonts/NotoSans-Regular.ttf
// assets/fonts/NotoSans-Bold.ttf

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:open_filex/open_filex.dart';
import 'package:axiomos_workforce/constants/asset_path.dart';
import 'package:axiomos_workforce/services/translation.dart';

Future<pw.Font> _loadFont(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  return pw.Font.ttf(data);
}

Future<void> saveDynamicDataPdf(
  Map<String, dynamic> data,
  Map<String, dynamic> fieldKeys,
  String moduleName,
) async {
  final pdfDoc = pw.Document();

  // load logo + fonts
  final logo = await loadAssetImage(Assets.mainLogo);

  // colors
  final PdfColor bgCard = PdfColor.fromInt(0xFFF6F7F9);
  final PdfColor labelColor = PdfColor.fromInt(0xFF7A7F86);
  final PdfColor dividerColor = PdfColor.fromInt(0xFFE6E9EC);
  final PdfColor titleColor = PdfColors.black;

  // Build table rows (same logic as before) but return list of pw.TableRow
  final tableRows = await _buildTableRowsAsync(data, fieldKeys, labelColor);

  // Try to add a single MultiPage using the unicode fonts (preferred)
  try {
    pdfDoc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        ),
        build: (context) => [
          // header
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFFFFFFF),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    padding: pw.EdgeInsets.all(6),
                    child: pw.Image(logo, width: 46, height: 46),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        moduleName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Generated: ${DateTime.now().toLocal()}',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColor.fromInt(0xFF9AA0A6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          // table (large, let MultiPage handle pagination)
          pw.Container(
            padding: pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFFFFFFF),
              borderRadius: pw.BorderRadius.circular(6),
              boxShadow: [
                pw.BoxShadow(
                  color: PdfColor.fromInt(0x11000000),
                  blurRadius: 4,
                ),
              ],
            ),
            child: pw.Table(
              border: pw.TableBorder(
                horizontalInside: pw.BorderSide(
                  width: 0.5,
                  color: dividerColor,
                ),
              ),
              columnWidths: {
                0: pw.FlexColumnWidth(0.35),
                1: pw.FlexColumnWidth(0.65),
              },
              children: tableRows,
            ),
          ),
        ],
      ),
    );
  } on Exception catch (e) {
    // Fallback for TooManyPagesException or other layout issues:
    // chunk the rows into pages with a smaller table per page.
    print('MultiPage failed: $e — falling back to chunked pages.');

    // chunk size: number of table rows per page (tune this as needed)
    const int chunkSize = 40; // tweak if you need more/less rows per page
    for (var i = 0; i < tableRows.length; i += chunkSize) {
      final chunk = tableRows.sublist(
        i,
        (i + chunkSize).clamp(0, tableRows.length),
      );
      pdfDoc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // small header on each fallback page
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFFFFFFF),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    padding: pw.EdgeInsets.all(6),
                    child: pw.Image(logo, width: 36, height: 36),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        moduleName,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Generated: ${DateTime.now().toLocal()}',
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: pw.EdgeInsets.all(8),
                child: pw.Table(
                  border: pw.TableBorder(
                    horizontalInside: pw.BorderSide(
                      width: 0.5,
                      color: dividerColor,
                    ),
                  ),
                  columnWidths: {
                    0: pw.FlexColumnWidth(0.35),
                    1: pw.FlexColumnWidth(0.65),
                  },
                  children: chunk,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // save file
  final directory = await getApplicationDocumentsDirectory();
  final path = directory.path;
  final filePath =
      '$path/${moduleName.replaceAll(' ', '_').toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.pdf';
  final file = File(filePath);
  await file.writeAsBytes(await pdfDoc.save());
  print("PDF saved to: $filePath");
  final result = await OpenFilex.open(filePath);
  print("Open result: ${result.message}");
}

// helper: build table rows, includes header row
/// Helper: basic image fetcher using HttpClient (no new package).
/// Returns null on failure.
Future<Uint8List?> _fetchImageBytes(
  String url, {
  Duration timeout = const Duration(seconds: 8),
}) async {
  try {
    final uri = Uri.parse(url);
    final httpClient = HttpClient();
    httpClient.userAgent = "dart_pdf_image_fetcher";
    final request = await httpClient.getUrl(uri).timeout(timeout);
    final response = await request.close().timeout(timeout);
    if (response.statusCode == 200) {
      final bytes = await consolidateHttpClientResponseBytes(response);
      return bytes;
    }
    return null;
  } catch (_) {
    return null;
  }
}

/// Utility: checks if a given string looks like an image URL.
bool _looksLikeImageUrl(String url) {
  final u = url.toLowerCase();
  if (u.startsWith('http://') || u.startsWith('https://')) {
    if (u.endsWith('.png') ||
        u.endsWith('.jpg') ||
        u.endsWith('.jpeg') ||
        u.endsWith('.gif') ||
        u.endsWith('.webp') ||
        u.endsWith('.bmp'))
      return true;
    // heuristics: google drive / cdn / https presence
    if (url.contains('drive.google.com') ||
        url.contains('cdn') ||
        url.contains('https://'))
      return true;
  }
  return false;
}

/// Async version of your table row builder that embeds thumbnails when possible.
///
/// Note: caller must await this.
Future<List<pw.TableRow>> _buildTableRowsAsync(
  Map<String, dynamic> data,
  Map<String, dynamic> fieldKeys,
  PdfColor labelColor,
) async {
  final excludedKeys = ['_id', 'password', '__v', 'editAllowed'];
  final filteredData = Map.fromEntries(
    data.entries.where((entry) => !excludedKeys.contains(entry.key)),
  );

  final headerStyle = pw.TextStyle(
    fontSize: 10,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.white,
  );
  final labelStyle = pw.TextStyle(
    fontSize: 9,
    fontWeight: pw.FontWeight.bold,
    color: labelColor,
  );
  final valueStyle = pw.TextStyle(fontSize: 10);

  final rows = <pw.TableRow>[];

  // header
  rows.add(
    pw.TableRow(
      decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFF2B2F33)),
      children: [
        pw.Padding(
          padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: pw.Text('PARAMETER', style: headerStyle),
        ),
        pw.Padding(
          padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: pw.Text('VALUE', style: headerStyle),
        ),
      ],
    ),
  );

  String titleForKey(String key) => translate(key).toUpperCase();

  String? extractImageUrlFromMap(Map<String, dynamic> map) {
    final candidates = [
      'image',
      'imageUrl',
      'img',
      'imgUrl',
      'photo',
      'photoUrl',
      'url',
      'avatar',
    ];
    for (final c in candidates) {
      if (map.containsKey(c) &&
          map[c] != null &&
          map[c].toString().trim().isNotEmpty) {
        final s = map[c].toString();
        if (s.startsWith('http://') || s.startsWith('https://')) return s;
      }
    }
    for (final entry in map.entries) {
      final v = entry.value;
      if (v is String &&
          (v.startsWith('http://') || v.startsWith('https://'))) {
        final lower = v.toLowerCase();
        if (lower.endsWith('.png') ||
            lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.webp') ||
            lower.endsWith('.gif')) {
          return v;
        }
      }
    }
    return null;
  }

  void addSimpleTextRow(String label, String value) {
    rows.add(
      pw.TableRow(
        children: [
          pw.Padding(
            padding: pw.EdgeInsets.all(8),
            child: pw.Text(label, style: labelStyle),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(8),
            child: pw.Text(value, style: valueStyle),
          ),
        ],
      ),
    );
  }

  void addSimpleRowWidget(String label, pw.Widget valueWidget) {
    rows.add(
      pw.TableRow(
        children: [
          pw.Padding(
            padding: pw.EdgeInsets.all(8),
            child: pw.Text(label, style: labelStyle),
          ),
          pw.Padding(padding: pw.EdgeInsets.all(8), child: valueWidget),
        ],
      ),
    );
  }

  // iterate entries in data
  for (final e in filteredData.entries) {
    final key = e.key;
    final value = e.value;
    final title = titleForKey(key);

    if (value == null || (value is String && value.trim().isEmpty)) {
      addSimpleTextRow(title, '-');
      continue;
    }

    // Map value
    if (value is Map<String, dynamic>) {
      if (fieldKeys.containsKey(key)) {
        final subFieldName = fieldKeys[key];
        final subValue = value[subFieldName]?.toString() ?? '-';
        addSimpleTextRow(title, subValue);
      } else {
        // Section header row
        rows.add(
          pw.TableRow(
            children: [
              pw.Padding(
                padding: pw.EdgeInsets.all(6),
                child: pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Container()),
            ],
          ),
        );
        // Each subfield
        for (final sub in value.entries) {
          final subKey = sub.key;
          final subVal = sub.value;
          if (subVal is String && _looksLikeImageUrl(subVal)) {
            // attempt to download and embed
            final bytes = await _fetchImageBytes(subVal);
            if (bytes != null && bytes.isNotEmpty) {
              addSimpleRowWidget(
                subKey.replaceAll('_', ' ').toUpperCase(),
                pw.Container(
                  child: pw.Image(
                    pw.MemoryImage(bytes),
                    width: 90,
                    height: 90,
                    fit: pw.BoxFit.cover,
                  ),
                ),
              );
            } else {
              // fallback link
              addSimpleRowWidget(
                subKey.replaceAll('_', ' ').toUpperCase(),
                pw.UrlLink(
                  destination: subVal,
                  child: pw.Text(
                    'View Image',
                    style: pw.TextStyle(
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                ),
              );
            }
          } else {
            addSimpleTextRow(
              subKey.replaceAll('_', ' ').toUpperCase(),
              subVal?.toString() ?? '-',
            );
          }
        }
      }
    }
    // List value
    else if (value is List) {
      // LIST OF PRIMITIVES (strings / urls)
      if (value.isNotEmpty && value.every((e) => e is! Map)) {
        // all strings and all image urls => render thumbnails inline
        if (value.isNotEmpty &&
            value.every((e) => e is String && _looksLikeImageUrl(e))) {
          final thumbWidgets = <pw.Widget>[];
          for (final v in value) {
            final url = v.toString();
            final bytes = await _fetchImageBytes(url);
            if (bytes != null && bytes.isNotEmpty) {
              thumbWidgets.add(
                pw.Container(
                  margin: pw.EdgeInsets.only(right: 6),
                  child: pw.Image(
                    pw.MemoryImage(bytes),
                    width: 90,
                    height: 90,
                    fit: pw.BoxFit.cover,
                  ),
                ),
              );
            } else {
              thumbWidgets.add(
                pw.Container(
                  margin: pw.EdgeInsets.only(right: 6),
                  child: pw.UrlLink(
                    destination: url,
                    child: pw.Text(
                      'View',
                      style: pw.TextStyle(
                        decoration: pw.TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              );
            }
          }
          addSimpleRowWidget(title, pw.Wrap(children: thumbWidgets));
        } else {
          // primitive list that isn't images
          addSimpleTextRow(title, value.map((e) => e.toString()).join(', '));
        }
      }
      // LIST OF MAPS
      else {
        // --- STRICT: if fieldKeys contains key, only show that field from each map ---
        if (value.isNotEmpty &&
            value.first is Map &&
            fieldKeys.containsKey(key)) {
          final String fieldName = fieldKeys[key]?.toString() ?? '';
          final extracted = value
              .map((e) {
                if (e is Map) return e[fieldName]?.toString();
                return null;
              })
              .where((v) => v != null && v.toString().trim().isNotEmpty)
              .cast<String>()
              .toList();

          if (extracted.isEmpty) {
            addSimpleTextRow(title, '-');
            continue;
          }

          // If extracted values are image URLs -> render thumbnail strip
          final images = extracted.where((s) => _looksLikeImageUrl(s)).toList();
          if (images.isNotEmpty) {
            final thumbWidgets = <pw.Widget>[];
            for (final url in images) {
              final bytes = await _fetchImageBytes(url);
              if (bytes != null && bytes.isNotEmpty) {
                thumbWidgets.add(
                  pw.Container(
                    margin: pw.EdgeInsets.only(right: 6),
                    child: pw.Image(
                      pw.MemoryImage(bytes),
                      width: 90,
                      height: 90,
                      fit: pw.BoxFit.cover,
                    ),
                  ),
                );
              } else {
                thumbWidgets.add(
                  pw.Container(
                    margin: pw.EdgeInsets.only(right: 6),
                    child: pw.UrlLink(
                      destination: url,
                      child: pw.Text(
                        'View',
                        style: pw.TextStyle(
                          decoration: pw.TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                );
              }
            }
            addSimpleRowWidget(title, pw.Wrap(children: thumbWidgets));
            continue; // important: don't render whole item maps
          }

          // Otherwise render extracted non-image values as text (joined)
          addSimpleTextRow(title, extracted.join('; '));
          continue; // important: don't render whole item maps
        }

        // ---- Fallback: when fieldKeys not present, render the existing itemized behavior ----
        // Section header
        rows.add(
          pw.TableRow(
            children: [
              pw.Padding(
                padding: pw.EdgeInsets.all(6),
                child: pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Container()),
            ],
          ),
        );

        for (var i = 0; i < value.length; i++) {
          final item = value[i];
          rows.add(
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'Item ${i + 1}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: pw.EdgeInsets.all(6),
                  child: pw.Container(),
                ),
              ],
            ),
          );

          if (item is Map<String, dynamic>) {
            // If fieldKeys contains key for this list, extract that field's url first and show thumbnail
            String? imageFieldFromFieldKeys;
            if (fieldKeys.containsKey(key)) {
              imageFieldFromFieldKeys = fieldKeys[key]?.toString();
            }
            String? imgUrl = imageFieldFromFieldKeys != null
                ? (item[imageFieldFromFieldKeys]?.toString())
                : null;
            imgUrl ??= extractImageUrlFromMap(item);

            if (imgUrl != null && _looksLikeImageUrl(imgUrl)) {
              final bytes = await _fetchImageBytes(imgUrl);
              if (bytes != null && bytes.isNotEmpty) {
                addSimpleRowWidget(
                  'Image',
                  pw.Image(
                    pw.MemoryImage(bytes),
                    width: 90,
                    height: 90,
                    fit: pw.BoxFit.cover,
                  ),
                );
              } else {
                addSimpleRowWidget(
                  'Image',
                  pw.UrlLink(
                    destination: imgUrl,
                    child: pw.Text(
                      'View Image',
                      style: pw.TextStyle(
                        decoration: pw.TextDecoration.underline,
                      ),
                    ),
                  ),
                );
              }
            }

            // then add the remaining fields (skipping the already shown image key)
            for (final kv in item.entries) {
              final k = kv.key;
              final v = kv.value;
              final lowerK = k.toLowerCase();
              if (imgUrl != null &&
                  (lowerK.contains('image') ||
                      lowerK.contains('img') ||
                      lowerK.contains('photo') ||
                      lowerK.contains('url') ||
                      lowerK == 'avatar')) {
                // skip to avoid duplicate
                continue;
              }
              if (v is String && _looksLikeImageUrl(v)) {
                final bytes = await _fetchImageBytes(v);
                if (bytes != null && bytes.isNotEmpty) {
                  addSimpleRowWidget(
                    k.replaceAll('_', ' ').toUpperCase(),
                    pw.Image(
                      pw.MemoryImage(bytes),
                      width: 90,
                      height: 90,
                      fit: pw.BoxFit.cover,
                    ),
                  );
                } else {
                  addSimpleRowWidget(
                    k.replaceAll('_', ' ').toUpperCase(),
                    pw.UrlLink(
                      destination: v,
                      child: pw.Text(
                        'View',
                        style: pw.TextStyle(
                          decoration: pw.TextDecoration.underline,
                        ),
                      ),
                    ),
                  );
                }
              } else {
                addSimpleTextRow(
                  k.replaceAll('_', ' ').toUpperCase(),
                  v?.toString() ?? '-',
                );
              }
            }
          } else {
            // non-map list item
            addSimpleTextRow('Item ${i + 1}', item.toString());
          }
        }
      } // end list-of-maps branch
    }
    // primitive single value
    else {
      if (value is String && _looksLikeImageUrl(value)) {
        final bytes = await _fetchImageBytes(value);
        if (bytes != null && bytes.isNotEmpty) {
          addSimpleRowWidget(
            title,
            pw.Image(
              pw.MemoryImage(bytes),
              width: 90,
              height: 90,
              fit: pw.BoxFit.cover,
            ),
          );
        } else {
          addSimpleRowWidget(
            title,
            pw.UrlLink(
              destination: value,
              child: pw.Text(
                'View',
                style: pw.TextStyle(decoration: pw.TextDecoration.underline),
              ),
            ),
          );
        }
      } else {
        addSimpleTextRow(title, value.toString());
      }
    }
  } // end for entries

  return rows;
}

// small helper reused in this file (same as above)
String? extractImageUrlFromMap(Map<String, dynamic> map) {
  final candidates = [
    'image',
    'imageUrl',
    'img',
    'imgUrl',
    'photo',
    'photoUrl',
    'url',
    'avatar',
  ];
  for (final c in candidates) {
    if (map.containsKey(c) &&
        map[c] != null &&
        map[c].toString().trim().isNotEmpty) {
      final s = map[c].toString();
      if (s.startsWith('http://') || s.startsWith('https://')) return s;
    }
  }
  for (final entry in map.entries) {
    final v = entry.value;
    if (v is String && (v.startsWith('http://') || v.startsWith('https://'))) {
      final lower = v.toLowerCase();
      if (lower.endsWith('.png') ||
          lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg') ||
          lower.endsWith('.webp') ||
          lower.endsWith('.gif')) {
        return v;
      }
    }
  }
  return null;
}

// memory image loader (unchanged)
Future<pw.MemoryImage> loadAssetImage(String path) async {
  final data = await rootBundle.load(path);
  return pw.MemoryImage(data.buffer.asUint8List());
}
