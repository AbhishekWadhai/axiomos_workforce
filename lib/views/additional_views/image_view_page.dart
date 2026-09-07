import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ImageViewPage extends StatelessWidget {
  final String imageUrl;

  const ImageViewPage({super.key, required this.imageUrl});

  Future<void> _saveImage(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode != 200) {
        throw Exception("Failed to download image");
      }

      final result = await ImageGallerySaverPlus.saveImage(
        Uint8List.fromList(response.bodyBytes),
        quality: 100,
        name: "image_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (result['isSuccess'] == true) {
        print("success block");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Image saved successfully"),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        print("fail block");
        throw Exception("Save failed");
      }

      debugPrint("Save result: $result");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to save image"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      debugPrint("Save error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          /// IMAGE VIEW
          Container(
            decoration: const BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: PhotoViewGallery.builder(
                itemCount: 1,
                builder: (context, index) {
                  return PhotoViewGalleryPageOptions(
                    imageProvider: NetworkImage(imageUrl),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered,
                  );
                },
                scrollPhysics: const BouncingScrollPhysics(),
                backgroundDecoration:
                    const BoxDecoration(color: Colors.black87),
                pageController: PageController(),
              ),
            ),
          ),

          /// CLOSE BUTTON
          Positioned(
            bottom: 20,
            right: 16,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.close),
              label: const Text("Close"),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          /// SAVE BUTTON
          // Positioned(
          //   bottom: 20,
          //   left: 16,
          //   child: ElevatedButton.icon(
          //     icon: const Icon(Icons.save),
          //     label: const Text("Save"),
          //     onPressed: () => _saveImage(context),
          //   ),
          // ),
        ],
      ),
    );
  }
}
