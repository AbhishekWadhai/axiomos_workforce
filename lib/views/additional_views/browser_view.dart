import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BrowserBottomSheetLauncher extends StatefulWidget {
  final String url;
  const BrowserBottomSheetLauncher({super.key, required this.url});

  @override
  State<BrowserBottomSheetLauncher> createState() =>
      _BrowserBottomSheetLauncherState();
}

class _BrowserBottomSheetLauncherState
    extends State<BrowserBottomSheetLauncher> {
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    // open after first frame
    Future.microtask(() => _openSheet());
  }

  Future<void> _openSheet() async {
    if (_opened) return;
    _opened = true;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BrowserSheetContent(url: widget.url),
    );
    // close launcher page after sheet is dismissed
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // no UI
  }
}

/// The browser content shown inside the bottom sheet.
/// Full WebView + mini AppBar with back/reload/download/close.
class BrowserSheetContent extends StatefulWidget {
  final String url;
  const BrowserSheetContent({super.key, required this.url});

  @override
  State<BrowserSheetContent> createState() => _BrowserSheetContentState();
}

class _BrowserSheetContentState extends State<BrowserSheetContent> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  http.Client? _downloadClient;

  @override
  void initState() {
    super.initState();

    // create controller and load viewer url
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _isLoading = true),
        onPageFinished: (_) => setState(() => _isLoading = false),
        onWebResourceError: (err) {
          setState(() => _isLoading = false);
          // show simple snackbar inside the sheet
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Load error: ${err.description}')),
          );
        },
      ))
      ..loadRequest(Uri.parse(_makeViewerUrl(widget.url)));
  }

  String _makeViewerUrl(String originalUrl) {
    final encoded = Uri.encodeFull(originalUrl);
    final ext = _getExtension(originalUrl).toLowerCase();
    const officeExts = {'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx'};
    const imageExts = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg'};

    if (imageExts.contains(ext)) {
      // return original so WebView/Image can load the raw image
      return originalUrl;
    }
    if (officeExts.contains(ext)) {
      return 'https://view.officeapps.live.com/op/view.aspx?src=$encoded';
    }
    return 'https://docs.google.com/gview?embedded=true&url=$encoded';
  }

  String _getExtension(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      if (!path.contains('.')) return '';
      return path.split('.').last;
    } catch (_) {
      return '';
    }
  }

  Future<void> _startDownload() async {
    if (_isDownloading) return;
    _isDownloading = true;
    _downloadProgress = 0.0;
    setState(() {});

    // show small download sheet (non-blocking for the browser sheet)
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => StatefulBuilder(builder: (context, setSheetState) {
        // start download in microtask
        Future.microtask(() async {
          try {
            _downloadClient = http.Client();
            final uri = Uri.parse(widget.url);
            final filename = uri.pathSegments.isNotEmpty
                ? uri.pathSegments.last
                : 'downloaded_file.${_getExtension(widget.url)}';

            if (!kIsWeb && Platform.isAndroid) {
              await Permission.storage.request();
            }

            final request = http.Request('GET', uri);
            final response = await _downloadClient!.send(request);
            if (response.statusCode != 200) {
              throw Exception('Server responded ${response.statusCode}');
            }

            final total = response.contentLength ?? 0;
            // choose target path
            String targetPath;
            if (!kIsWeb && Platform.isAndroid) {
              final storageStatus = await Permission.storage.status;
              if (storageStatus.isGranted) {
                final downloadsDir = Directory('/storage/emulated/0/Download');
                if (await downloadsDir.exists()) {
                  targetPath = '${downloadsDir.path}/$filename';
                } else {
                  final appDocDir = await getExternalStorageDirectory();
                  targetPath =
                      '${appDocDir?.path ?? (await getApplicationDocumentsDirectory()).path}/$filename';
                }
              } else {
                final appDocDir = await getApplicationDocumentsDirectory();
                targetPath = '${appDocDir.path}/$filename';
              }
            } else {
              final appDocDir = await getApplicationDocumentsDirectory();
              targetPath = '${appDocDir.path}/$filename';
            }

            final file = File(targetPath);
            final sink = file.openWrite();
            int received = 0;

            await for (final chunk in response.stream) {
              // cancelled?
              if (_downloadClient == null) {
                await sink.close();
                if (await file.exists()) await file.delete();
                throw Exception('Cancelled');
              }
              sink.add(chunk);
              received += chunk.length;
              if (total != 0) {
                final p = received / total;
                _downloadProgress = p;
                setSheetState(() {});
                setState(() {}); // update top-level indicator if desired
              } else {
                // unknown length
                _downloadProgress = 0.0;
                setSheetState(() {});
                setState(() {});
              }
            }

            await sink.flush();
            await sink.close();

            _downloadClient?.close();
            _downloadClient = null;
            _isDownloading = false;
            _downloadProgress = 0.0;

            // notify user and allow opening file
            if (mounted) {
              Navigator.of(context).pop(); // close download sheet
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(content: Text('Saved to: $targetPath')),
              );
              await OpenFilex.open(targetPath);
              setState(() {});
            }
          } catch (e) {
            _downloadClient?.close();
            _downloadClient = null;
            _isDownloading = false;
            _downloadProgress = 0.0;
            if (mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(content: Text('Download failed')),
              );
              setState(() {});
            }
          }
        });

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Downloading...',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            LinearProgressIndicator(
                value: _downloadProgress == 0.0 ? null : _downloadProgress),
            const SizedBox(height: 12),
            Text(_downloadProgress == 0.0
                ? 'Starting...'
                : '${(_downloadProgress * 100).toStringAsFixed(0)}%'),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton.icon(
                onPressed: () {
                  // cancel
                  _downloadClient?.close();
                  _downloadClient = null;
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel'),
              ),
            ]),
          ]),
        );
      }),
    );
  }

  @override
  void dispose() {
    _downloadClient?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewerUrl = _makeViewerUrl(widget.url);

    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.99,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            // sheet handle + mini app bar
            const SizedBox(height: 8),
            Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(4))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () async {
                    if (await _controller.canGoBack()) {
                      _controller.goBack();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                ),
                IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => _controller.reload()),
                IconButton(
                    icon: const Icon(Icons.download_rounded),
                    onPressed: _startDownload),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () {
                      // optional: open externally using url_launcher
                    }),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop()),
              ]),
            ),

            // webview area
            Expanded(
              child: Stack(children: [
                WebViewWidget(
                  controller: _controller,
                  key: ValueKey(viewerUrl),
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    // allow vertical drags to be dispatched to the WebView
                    Factory<VerticalDragGestureRecognizer>(
                        () => VerticalDragGestureRecognizer()),
                    // allow horizontal drags too, if the PDF viewer uses them
                    Factory<HorizontalDragGestureRecognizer>(
                        () => HorizontalDragGestureRecognizer()),
                    // you can add TapGestureRecognizer if needed
                  },
                ),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
              ]),
            ),
          ]),
        );
      },
    );
  }
}
