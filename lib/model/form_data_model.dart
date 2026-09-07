import 'dart:convert';

class ResponseForm {
  String? id;
  String page;
  String? pageType;
  List<String>? tabs;
  List<PageField> pageFields;
  int v;

  ResponseForm({
    required this.id,
    required this.page,
    required this.pageFields,
    this.pageType,
    this.tabs,
    required this.v,
  });

  factory ResponseForm.fromRawJson(String str) =>
      ResponseForm.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ResponseForm.fromJson(Map<String, dynamic> json) => ResponseForm(
        id: json["_id"],
        page: json["Page"],
        pageType: json["PageType"],
        pageFields: List<PageField>.from(
            json["PageFields"].map((x) => PageField.fromJson(x))),
        tabs: json["tabs"] == null
            ? []
            : List<String>.from(json["tabs"].whereType<String>()),
        v: json["__v"],
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "Page": page,
        "PageType": pageType,
        "PageFields": List<dynamic>.from(pageFields.map((x) => x.toJson())),
        "tabs": tabs == null ? [] : List<dynamic>.from(tabs!.map((x) => x)),
        "__v": v,
      };
}

class PageField {
  String title;
  String headers;
  String type;
  String id;
  String? endpoint;
  String? key;
  List<String>? options;
  String? tab;
  Permissions? permissions;
  bool required = true;

  PageField(
      {required this.title,
      required this.headers,
      required this.type,
      required this.id,
      this.endpoint,
      this.key,
      this.options,
      this.tab,
      this.permissions,
      this.required = true});

  factory PageField.fromRawJson(String str) =>
      PageField.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory PageField.fromJson(Map<String, dynamic> json) => PageField(
      title: json["Title"]?.toString() ?? "",
      headers: json["Headers"]?.toString() ?? "",
      type: json["Type"]?.toString() ?? "",
      id: json["_id"]?.toString() ?? "",
      endpoint: json["endpoint"]?.toString(),
      key: json["key"]?.toString(),
      options: json["Options"] == null
          ? []
          : List<String>.from(json["Options"].whereType<String>()),
      tab: json["tab"]?.toString() ?? "",
      permissions: json["permissions"] == null
          ? null
          : Permissions.fromJson(json["permissions"]),
      required: json["required"] == "false" ? false : true);

  Map<String, dynamic> toJson() => {
        "Title": title,
        "Headers": headers,
        "Type": type,
        "_id": id,
        "endpoint": endpoint,
        "key": key,
        "Options":
            options == null ? [] : List<dynamic>.from(options!.map((x) => x)),
        "tabs": tab,
        "permissions": permissions?.toJson(),
        "required": required
      };
}

class Permissions {
  List<String> view;
  List<String> edit;

  Permissions({
    required this.view,
    required this.edit,
  });

  factory Permissions.fromRawJson(String str) =>
      Permissions.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Permissions.fromJson(Map<String, dynamic> json) => Permissions(
        view: List<String>.from(json["view"].map((x) => x)),
        edit: List<String>.from(json["edit"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "view": List<dynamic>.from(view.map((x) => x)),
        "edit": List<dynamic>.from(edit.map((x) => x)),
      };
}
