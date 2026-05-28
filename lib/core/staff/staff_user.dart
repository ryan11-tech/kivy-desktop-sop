/// Staff identity returned by `GET /api/staff/me`.
class StaffUser {
  const StaffUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.requiresPasswordChange,
    required this.requiresOtp,
  });

  factory StaffUser.fromJson(Map<String, Object?> json) {
    return StaffUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? json['name'] as String? ?? '',
      requiresPasswordChange: json['requiresPasswordChange'] as bool? ?? false,
      requiresOtp: json['requiresOtp'] as bool? ?? false,
    );
  }

  final String id;
  final String email;
  final String displayName;
  final bool requiresPasswordChange;
  final bool requiresOtp;

  StaffUser copyWith({
    bool? requiresPasswordChange,
    bool? requiresOtp,
  }) {
    return StaffUser(
      id: id,
      email: email,
      displayName: displayName,
      requiresPasswordChange: requiresPasswordChange ?? this.requiresPasswordChange,
      requiresOtp: requiresOtp ?? this.requiresOtp,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'email': email,
      'displayName': displayName,
      'requiresPasswordChange': requiresPasswordChange,
      'requiresOtp': requiresOtp,
    };
  }
}
