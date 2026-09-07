class Filter {
  final String key;
  final String label;
  final String type;
  final String? source;
  final String? path;
  final dynamic defaultValue;
  final List<String> options;

  Filter({
    required this.key,
    required this.label,
    required this.type,
    this.source,
    this.path,
    this.defaultValue,
    this.options = const [],
  });

  factory Filter.fromJson(Map<String, dynamic> j) => Filter(
    key: j['key'] as String,
    label: j['label'] as String,
    type: j['type'] as String,
    source: j['source'] as String?,
    path: j['path'] as String?,
    defaultValue: j['default'],
    options: j['options'] != null ? List<String>.from(j['options']) : const [],
  );

  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
    'type': type,
    'source': source,
    'path': path,
    'default': defaultValue,
    'options': options,
  };
}
