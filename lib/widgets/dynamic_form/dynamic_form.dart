import 'package:axiomos_workforce/services/text_formatters.dart';
import 'package:axiomos_workforce/widgets/dynamic_form/form_helpers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:axiomos_workforce/controllers/dynamic_form_contoller.dart';
import 'package:axiomos_workforce/model/form_data_model.dart';
import 'package:axiomos_workforce/services/connection_service.dart';
import 'package:axiomos_workforce/widgets/dynamic_form/build_file_picker.dart';
import 'package:axiomos_workforce/widgets/dynamic_form/build_radio.dart';
import 'package:axiomos_workforce/widgets/dynamic_form/calculated_field.dart';
import 'package:axiomos_workforce/widgets/dynamic_form/checklist.dart';
import 'package:axiomos_workforce/widgets/dynamic_form/custom_field.dart';
import 'package:axiomos_workforce/widgets/dynamic_form/custom_text_field.dart';
import 'package:axiomos_workforce/widgets/dynamic_form/date_time_fields.dart';
import 'package:axiomos_workforce/widgets/dynamic_form/default_field.dart';
import 'package:axiomos_workforce/widgets/dynamic_form/form_dropdown.dart';
import 'package:axiomos_workforce/widgets/dynamic_form/form_extras.dart';
import 'package:axiomos_workforce/widgets/dynamic_form/form_geotagging.dart';
import 'package:axiomos_workforce/widgets/dynamic_form/form_image_picker.dart';
import 'package:axiomos_workforce/widgets/dynamic_form/form_signature_pad.dart';
import 'package:axiomos_workforce/widgets/dynamic_form/form_simple_multiselect.dart';
import 'package:axiomos_workforce/widgets/dynamic_form/multiselect_field.dart';
import 'package:axiomos_workforce/widgets/dynamic_form/secondary_form.dart';
import 'package:axiomos_workforce/widgets/dynamic_form/form_simple_dropdown.dart';
import 'package:axiomos_workforce/widgets/progress_indicators.dart';

import 'risk_matrix.dart';

class DynamicForm extends StatefulWidget {
  final String pageName;
  final Map<String, dynamic>? initialData;
  final bool isEdit;
  final bool toAdd;

  DynamicForm({
    Key? key,
    required this.pageName,
    this.initialData,
    this.isEdit = false,
    this.toAdd = false,
  }) : super(key: key);

  @override
  State<DynamicForm> createState() => _DynamicFormState();
}

class _DynamicFormState extends State<DynamicForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final DynamicFormController controller = Get.find();

  // @override
  // void initState() {
  //   super.initState();
  //   // Load fields and form data for the page only once
  //   //controller.isOffline.value = ConnectivityService.to.checkConnection();
  //   controller.ensurePageFieldsLoaded(widget.pageName, widget.initialData);
  // }

  @override
  void initState() {
    super.initState();

    // Start loading
    setState(() {
      controller.isLoading.value = true;
    });

    controller.ensurePageFieldsLoaded(widget.pageName, widget.initialData).then(
      (_) {
        setState(() {
          controller.isLoading.value = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey[100],
          body: controller.isLoading.value
              ? SizedBox.shrink()
              : _buildFormContent(),
        ),
        Obx(
          () => controller.isLoading.value
              ? Container(
                  color: Colors.grey.withOpacity(0.3),
                  child: const Center(child: CustomProgressIndicator()),
                )
              : SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildFormContent() {
    bool hasTabs = controller.pageFields.any((f) => (f.tab ?? '').isNotEmpty);
    return hasTabs ? buildTabBasedForm() : buildLinearForm();
  }

  Widget buildLinearForm() {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        color: Colors.white,
      ),
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          //keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...controller.pageFields
                  .where(
                    (field) => controller.hasViewPermission(
                      List<String>.from(field.permissions?.view ?? []),
                    ),
                  )
                  .map(
                    (field) => Column(
                      children: [
                        buildFormField(
                          field,
                          controller.hasEditPermission(
                            field.permissions?.edit ?? [],
                          ),
                          context,
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
              const SizedBox(height: 10),
              widget.toAdd ? buildAddButton() : buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTabBasedForm() {
    // Group fields by tab
    final groupedFields = <String, List<PageField>>{};
    for (var field in controller.pageFields) {
      if (controller.hasViewPermission(
        List<String>.from(field.permissions?.view ?? []),
      )) {
        final tabName = (field.tab ?? '').isNotEmpty ? field.tab! : 'General';
        groupedFields.putIfAbsent(tabName, () => []).add(field);
      }
    }

    final tabNames = groupedFields.keys.toList();

    return DefaultTabController(
      length: tabNames.length,
      child: Builder(
        builder: (context) {
          final TabController tabController = DefaultTabController.of(context);

          return Column(
            children: [
              TabBar(
                labelColor: Colors.black,
                unselectedLabelColor: Colors.black54,
                indicatorColor: Colors.black,
                isScrollable: true,
                tabs: tabNames.map((name) => Tab(text: name)).toList(),
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: TabBarView(
                    children: List.generate(tabNames.length, (index) {
                      final isLastTab = index == tabNames.length - 1;
                      final fields = groupedFields[tabNames[index]]!;

                      return KeepAliveWrapper(
                        child: SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...fields.map(
                                (field) => Column(
                                  children: [
                                    buildFormField(
                                      field,
                                      controller.hasEditPermission(
                                        field.permissions?.edit ?? [],
                                      ),
                                      context,
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Align(
                                alignment: Alignment.centerRight,
                                child: isLastTab
                                    ? buildSubmitButton()
                                    : ElevatedButton(
                                        onPressed: () {
                                          if (_formKey.currentState
                                                  ?.validate() ??
                                              false) {
                                            tabController.animateTo(index + 1);
                                          }
                                        },
                                        child: const Text('Next'),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildSubmitButton() {
    return ElevatedButton(
      onPressed: () {
        //controller.submitForm(widget.pageName);
        // setState(() {
        //   controller.isLoading.value = true;
        // });
        if (_formKey.currentState?.validate() ?? false) {
          widget.isEdit
              ? controller.updateData(widget.pageName)
              : controller.submitForm(widget.pageName);
          // setState(() {
          //   controller.isLoading.value = false;
          // });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please correct the errors in the form'),
              backgroundColor: Colors.red,
            ),
          );
          // setState(() {
          //   controller.isLoading.value = false;
          // });
        }
      },
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: widget.isEdit
            ? const Text('Update', textAlign: TextAlign.center)
            : Obx(
                () => Text(
                  controller.isOnline.value ? 'Submit' : 'Save to Submit',
                  textAlign: TextAlign.center,
                ),
              ),
      ),
    );
  }

  Widget buildAddButton() {
    return ElevatedButton(
      onPressed: () {
        if (_formKey.currentState?.validate() ?? false) {
          controller.updateFormDataFromControllers();
          final cleaned = cleanFormData(controller.formData);
          printLargeJson(cleaned);
          Get.back(result: cleaned);
          //Add data logic to get back

          // widget.isEdit
          //     ? controller.updateData(widget.pageName)
          //     : controller.submitForm(widget.pageName);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please correct the errors in the form'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: const Text('Add', textAlign: TextAlign.center),
      ),
    );
  }

  Widget buildFormField(
    PageField field,
    bool isEditable,
    BuildContext context,
  ) {
    switch (field.type) {
      case 'riskMatrix':
        return buildRiskMatrix(field, controller, widget.isEdit);
      case 'customFields':
        return buildCustomFields(controller, widget.pageName);

      case 'defaultField':
        return buildDefaultField(field, controller, widget.isEdit);

      case 'checklist':
        return buildChecklist(field, controller, isEditable, context);

      case 'CustomTextField':
        return buildCustomTextField(field, controller, isEditable, context);

      case 'calculatedField':
        return buildCalculatedField(field, controller);

      case 'editablechip':
        return buildEditableChipField(
          field,
          controller,
          widget.isEdit,
          isEditable,
        );

      case 'multiselect':
        return buildMultiselectField(field, controller, isEditable, context);

      case 'imagepicker':
        return buildImagePickerField(field, controller, isEditable);

      case 'secondaryForm':
        return buildSecondaryFormField(field, controller, isEditable);

      case 'dropdown':
        return buildDropdownField(field, controller, isEditable);

      case 'simplemultiselect':
        return buildSimpleMultiSelect(field, controller, isEditable);

      case 'simpledropdown':
        return buildSimpleDropdown(field, controller);

      case 'datepicker':
        return myDatePicker(field, controller, isEditable);

      case 'timepicker':
        return myTimePicker(field, controller, isEditable);

      case 'radio':
        return buildRadio(field, isEditable, controller);

      case 'switch':
        return buildSwitch(field, controller, isEditable);
      case 'signature':
        return buildSignature(field, controller, widget.isEdit);

      case 'geolocation':
        return buildGeolocation(field, isEditable, controller);
      case 'filePicker':
        return buildFilePicker(field, isEditable, controller, widget.isEdit);
      default:
        return const Text('Unsupported field type');
    }
  }
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({Key? key, required this.child}) : super(key: key);

  @override
  _KeepAliveWrapperState createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
