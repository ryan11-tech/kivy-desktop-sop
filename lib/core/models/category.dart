class Category {
  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.order,
  });

  factory Category.fromJson(String id, Map<String, Object?> json) {
    return Category(
      id: id,
      name: (json['name'] as String? ?? '').trim(),
      icon: (json['icon'] as String? ?? '').trim(),
      order: json['order'] as int? ?? 0,
    );
  }

  final String id;
  final String name;
  final String icon;
  final int order;

  Map<String, Object?> toJson() {
    return <String, Object?>{'name': name, 'icon': icon, 'order': order};
  }
}
