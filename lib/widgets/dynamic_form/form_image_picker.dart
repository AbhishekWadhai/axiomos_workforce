import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:axiomos_workforce/controllers/dynamic_form_contoller.dart';
import 'package:axiomos_workforce/model/form_data_model.dart';
import 'package:axiomos_workforce/views/additional_views/image_view_page.dart';

Widget buildImagePickerField(
  PageField field,
  DynamicFormController controller,
  bool isEditable,
) {
  controller.formData.putIfAbsent(field.headers, () => "".obs);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        field.title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),

      const SizedBox(height: 10),

      Obx(() {
        final imageUrl = controller.formData[field.headers]?.value;

        final isUploading = controller.imageUploading[field.headers] ?? false;

        final imageError = controller.imageErrors[field.headers];

        final hasImage = imageUrl is String && imageUrl.isNotEmpty;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: imageError != null
                  ? Colors.red.shade300
                  : Colors.grey.shade300,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _imageActionButton(
                      icon: Icons.camera_alt_rounded,
                      label: 'Take Photo',
                      enabled: isEditable && !isUploading,
                      onPressed: () async {
                        await controller.pickAndUploadImage(
                          field.headers,
                          field.endpoint ?? "",
                          "camera",
                        );

                        if ((controller.formData[field.headers] ?? "")
                            .toString()
                            .isNotEmpty) {
                          controller.imageErrors[field.headers] = null;
                        }
                      },
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _imageActionButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      enabled: isEditable && !isUploading,
                      onPressed: () async {
                        await controller.pickAndUploadImage(
                          field.headers,
                          field.endpoint ?? "",
                          "gallery",
                        );

                        if ((controller.formData[field.headers] ?? "")
                            .toString()
                            .isNotEmpty) {
                          controller.imageErrors[field.headers] = null;
                        }
                      },
                    ),
                  ),
                ],
              ),

              // Upload loader
              if (isUploading) ...[
                const SizedBox(height: 12),

                Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Uploading image...',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],

              // Image preview
              if (!isUploading && hasImage) ...[
                const SizedBox(height: 14),

                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 180,
                        child: imageUrl.startsWith('http')
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Text('Failed to load image'),
                                  );
                                },
                              )
                            : Image.file(
                                File(imageUrl),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Text('Failed to load image'),
                                  );
                                },
                              ),
                      ),

                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Material(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              Get.to(() => ImageViewPage(imageUrl: imageUrl));
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.fullscreen_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'View',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green.shade600,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Image uploaded successfully',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],

              // Error
              if (imageError != null) ...[
                const SizedBox(height: 10),

                Text(
                  imageError,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                ),
              ],
            ],
          ),
        );
      }),
    ],
  );
}

Widget _imageActionButton({
  required IconData icon,
  required String label,
  required bool enabled,
  required VoidCallback onPressed,
}) {
  return SizedBox(
    height: 48,
    child: OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(
          color: enabled ? Colors.grey.shade400 : Colors.grey.shade300,
        ),
      ),
    ),
  );
}
