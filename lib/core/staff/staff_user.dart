/// Staff identity returned by `GET /api/staff/me`.
class StaffUser {
  const StaffUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.requiresPasswordChange,
    this.accountRole = 'staff',
    this.staffProfileId = '',
  });

  factory StaffUser.fromJson(Map<String, Object?> json) {
    return StaffUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName:
          json['displayName'] as String? ?? json['name'] as String? ?? '',
      requiresPasswordChange: json['requiresPasswordChange'] as bool? ?? false,
      accountRole: json['accountRole'] as String? ?? 'staff',
      staffProfileId: json['staffProfileId'] as String? ?? '',
    );
  }

  factory StaffUser.fromStaffSessionJson(Map<String, Object?> json) {
    final user = _readMap(json['user']);
    final staffProfile = _readMap(json['staffProfile']);
    return StaffUser(
      id: user['id'] as String? ?? staffProfile['userId'] as String? ?? '',
      email: user['email'] as String? ?? '',
      displayName: user['name'] as String? ?? '',
      requiresPasswordChange: json['requiresPasswordChange'] as bool? ?? false,
      accountRole:
          json['accountRole'] as String? ??
          staffProfile['accountRole'] as String? ??
          'staff',
      staffProfileId: staffProfile['id'] as String? ?? '',
    );
  }

  final String id;
  final String email;
  final String displayName;
  final bool requiresPasswordChange;
  final String accountRole;
  final String staffProfileId;

  bool get isAdmin => accountRole == 'admin';

  StaffUser copyWith({
    String? email,
    String? displayName,
    bool? requiresPasswordChange,
    String? accountRole,
    String? staffProfileId,
  }) {
    return StaffUser(
      id: id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      requiresPasswordChange:
          requiresPasswordChange ?? this.requiresPasswordChange,
      accountRole: accountRole ?? this.accountRole,
      staffProfileId: staffProfileId ?? this.staffProfileId,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'email': email,
      'displayName': displayName,
      'requiresPasswordChange': requiresPasswordChange,
      'accountRole': accountRole,
      'staffProfileId': staffProfileId,
    };
  }
}

Map<String, Object?> _readMap(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return value.cast<String, Object?>();
  return const <String, Object?>{};
}
