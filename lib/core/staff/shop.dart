/// A shop the signed-in staff member has access to.
class Shop {
  const Shop({required this.id, required this.name, this.role});

  factory Shop.fromJson(Map<String, Object?> json) {
    return Shop(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String?,
    );
  }

  final String id;
  final String name;

  /// Optional per-shop role label from the backend (e.g. "manager", "barista").
  final String? role;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      if (role != null) 'role': role,
    };
  }
}
