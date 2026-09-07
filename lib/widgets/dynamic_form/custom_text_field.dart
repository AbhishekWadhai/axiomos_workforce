import 'package:flutter/material.dart';
import 'package:axiomos_workforce/controllers/dynamic_form_contoller.dart';
import 'package:axiomos_workforce/model/form_data_model.dart';

import 'form_extras.dart';

Widget buildCustomTextField(
  PageField field,
  DynamicFormController controller,
  bool isEditable,
  BuildContext context,
) {
  final TextEditingController textController = controller.getTextController(
    field.headers,
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        field.title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),
      TextFormField(
        onTapOutside: (event) {
          // FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        validator: (value) {
          if (!isEditable) return null; // Skip validation for read-only
          return controller.validateTextField(value);
        },
        controller: textController,
        decoration: kTextFieldDecoration("Enter ${field.title}"),
        readOnly: !isEditable,
        keyboardType: field.key == "numeric" ? TextInputType.number : null,
      ),
    ],
  );
}
