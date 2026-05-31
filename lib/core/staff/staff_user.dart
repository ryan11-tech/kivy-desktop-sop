/// Staff identity returned by `GET /api/staff/me`.
class StaffUser {
  const StaffUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.requiresPasswordChange,
    this.accountRole = 'staff',
    this.staffProfileId = '',
    this.staffCode = '',
    this.status = '',
    this.preferredName,
    this.phone,
    this.lineId,
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
      staffCode: json['staffCode'] as String? ?? '',
      status: json['status'] as String? ?? '',
      preferredName: json['preferredName'] as String?,
      phone: json['phone'] as String?,
      lineId: json['lineId'] as String?,
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
      staffCode: staffProfile['staffCode'] as String? ?? '',
      status: staffProfile['status'] as String? ?? '',
      preferredName: staffProfile['preferredName'] as String?,
      phone: staffProfile['phone'] as String?,
      lineId: staffProfile['lineId'] as String?,
    );
  }

  final String id;
  final String email;
  final String displayName;
  final bool requiresPasswordChange;
  final String accountRole;
  final String staffProfileId;
  final String staffCode;
  final String status;
  final String? preferredName;
  final String? phone;
  final String? lineId;

  bool get isAdmin => accountRole == 'admin';

  StaffUser copyWith({
    String? email,
    String? displayName,
    bool? requiresPasswordChange,
    String? accountRole,
    String? staffProfileId,
    String? staffCode,
    String? status,
    String? preferredName,
    String? phone,
    String? lineId,
  }) {
    return StaffUser(
      id: id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      requiresPasswordChange:
          requiresPasswordChange ?? this.requiresPasswordChange,
      accountRole: accountRole ?? this.accountRole,
      staffProfileId: staffProfileId ?? this.staffProfileId,
      staffCode: staffCode ?? this.staffCode,
      status: status ?? this.status,
      preferredName: preferredName ?? this.preferredName,
      phone: phone ?? this.phone,
      lineId: lineId ?? this.lineId,
    );
  }

  /// Applies a saved profile edit, preserving identity and work fields while
  /// allowing the editable personal fields to be set or cleared to null.
  StaffUser withProfile({
    required String displayName,
    required String? preferredName,
    required String? phone,
    required String? lineId,
  }) {
    return StaffUser(
      id: id,
      email: email,
      displayName: displayName,
      requiresPasswordChange: requiresPasswordChange,
      accountRole: accountRole,
      staffProfileId: staffProfileId,
      staffCode: staffCode,
      status: status,
      preferredName: preferredName,
      phone: phone,
      lineId: lineId,
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
      'staffCode': staffCode,
      'status': status,
      'preferredName': preferredName,
      'phone': phone,
      'lineId': lineId,
    };
  }
}

Map<String, Object?> _readMap(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return value.cast<String, Object?>();
  return const <String, Object?>{};
}
