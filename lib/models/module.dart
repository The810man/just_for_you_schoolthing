class Module {
  final String name;
  final String description;
  final String path;
  final Map<String, dynamic> ui;

  Module({
    required this.name,
    required this.description,
    required this.path,
    required this.ui,
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      name: json['name'] ?? 'Unknown',
      description: json['description'] ?? '',
      path: json['path'],
      ui: json['ui'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'description': description, 'path': path, 'ui': ui};
  }
}
