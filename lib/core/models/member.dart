enum MemberRole {
  admin,
  staff,
  none;

  static MemberRole parse(String? value) {
    return switch (value) {
      'admin' => MemberRole.admin,
      'staff' => MemberRole.staff,
      'none' || null => MemberRole.none,
      _ => throw FormatException('Unknown member role: $value'),
    };
  }
}

enum AccessStatus {
  pending,
  active,
  disabled;

  static AccessStatus parse(String? value) {
    return switch (value) {
      'active' => AccessStatus.active,
      'disabled' => AccessStatus.disabled,
      'pending' || null => AccessStatus.pending,
      _ => throw FormatException('Unknown access status: $value'),
    };
  }
}

class Member {
  const Member({
    required this.uid,
    required this.email,
    required this.role,
    required this.accessStatus,
  });

  factory Member.fromJson(Map<String, Object?> json) {
    return Member(
      uid: json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: MemberRole.parse(json['role'] as String?),
      accessStatus: AccessStatus.parse(json['accessStatus'] as String?),
    );
  }

  final String uid;
  final String email;
  final MemberRole role;
  final AccessStatus accessStatus;

  bool get isActive =>
      accessStatus == AccessStatus.active && role != MemberRole.none;
  bool get isAdmin => isActive && role == MemberRole.admin;
  bool get isStaff => isActive && role == MemberRole.staff;

  String get normalizedEmail => normalizeEmail(email);

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'uid': uid,
      'email': email,
      'normalizedEmail': normalizedEmail,
      'role': role.name,
      'accessStatus': accessStatus.name,
    };
  }

  static String normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  static String emailKey(String email) {
    return normalizeEmail(email).replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }
}

class DemoAccounts {
  const DemoAccounts._();

  static const Member admin = Member(
    uid: 'demo-admin',
    email: 'admin@zinme.local',
    role: MemberRole.admin,
    accessStatus: AccessStatus.active,
  );

  static const Member staff = Member(
    uid: 'demo-staff',
    email: 'staff@zinme.local',
    role: MemberRole.staff,
    accessStatus: AccessStatus.active,
  );
}
