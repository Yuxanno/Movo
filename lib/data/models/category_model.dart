class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String type; // "income" | "expense" | "both"

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? 'other',
      color: json['color'] ?? '#9ca3af',
      type: json['type'] ?? 'both',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'icon': icon,
    'color': color,
    'type': type,
  };
}
