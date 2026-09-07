import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:axiomos_workforce/controllers/dynamic_form_contoller.dart';
import 'package:axiomos_workforce/model/form_data_model.dart';
import 'package:signature/signature.dart';

Widget buildSignature(
  PageField field,
  DynamicFormController controller,
  bool isEdit,
) {
  return _SignatureField(field: field, controller: controller, isEdit: isEdit);
}

class _SignatureField extends StatefulWidget {
  final PageField field;
  final DynamicFormController controller;
  final bool isEdit;

  const _SignatureField({
    required this.field,
    required this.controller,
    required this.isEdit,
  });

  @override
  State<_SignatureField> createState() => _SignatureFieldState();
}

class _SignatureFieldState extends State<_SignatureField> {
  bool showPad = false; // local toggle

  @override
  Widget build(BuildContext context) {
    bool isOnline = widget.controller.isOnline.value;
    String? signatureUrl =
        widget.controller.formData[widget.field.headers]?.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.field.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),

        // Either image or pad
        if (widget.isEdit && !showPad)
          (signatureUrl != null && signatureUrl.isNotEmpty
              ? Image.network(
                  signatureUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              : const Text("No signature available."))
        else
          Signature(
            controller: widget.controller.getSignatureController(
              widget.field.headers,
            ),
            height: 200,
            backgroundColor: Colors.grey[200]!,
          ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                if (widget.isEdit && !showPad) {
                  // Switch from image → pad
                  setState(() {
                    showPad = true;
                  });
                } else {
                  // Clear pad
                  widget.controller.signatureControllers[widget.field.headers]
                      ?.clear();
                }
              },
              child: Text(widget.isEdit && !showPad ? "Re-sign" : "Clear"),
            ),
            ElevatedButton(
              onPressed: () async {
                final sigController = widget
                    .controller
                    .signatureControllers[widget.field.headers];
                if (sigController == null) return;

                if (!isOnline) {
                  final bytes = await sigController.toPngBytes();
                  if (bytes != null) {
                    final localPath = await widget.controller
                        .saveSignatureLocally(widget.field.headers, bytes);
                    widget.controller.updateFormData(
                      widget.field.headers,
                      localPath,
                    );
                    widget.controller.imageErrors[widget.field.headers] = null;

                    widget.controller.queueOfflineSignatureUpload(
                      widget.field.headers,
                      localPath,
                    );
                  } else {
                    widget.controller.imageErrors[widget.field.headers] =
                        "Could not capture signature.";
                  }
                } else {
                  String? imageUrl = await widget.controller.saveSignature(
                    widget.field.headers,
                    widget.field.endpoint ?? "",
                  );
                  if (imageUrl != null) {
                    widget.controller.updateFormData(
                      widget.field.headers,
                      imageUrl,
                    );
                    widget.controller.imageErrors[widget.field.headers] = null;
                  }
                }

                if (widget.isEdit) {
                  // After saving in edit, return to image view
                  setState(() {
                    showPad = false;
                  });
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),

        // Error message display
        Obx(() {
          final error = widget.controller.imageErrors[widget.field.headers];
          return error != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(error, style: const TextStyle(color: Colors.red)),
                )
              : const SizedBox.shrink();
        }),
      ],
    );
  }
}
