/// Staff identity returned by `GET /api/staff/me`.
class StaffUser {
  const StaffUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.requiresPasswordChange,
  });

  factory StaffUser.fromJson(Map<String, Object?> json) {
    return StaffUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName:
          json['displayName'] as String? ?? json['name'] as String? ?? '',
      requiresPasswordChange: json['requiresPasswordChange'] as bool? ?? false,
    );
  }

  final String id;
  final String email;
  final String displayName;
  final bool requiresPasswordChange;

  StaffUser copyWith({bool? requiresPasswordChange}) {
    return StaffUser(
      id: id,
      email: email,
      displayName: displayName,
      requiresPasswordChange:
          requiresPasswordChange ?? this.requiresPasswordChange,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'email': email,
      'displayName': displayName,
      'requiresPasswordChange': requiresPasswordChange,
    };
  }
}
