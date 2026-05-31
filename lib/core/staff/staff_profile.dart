/// Self-service staff profile returned by `GET /api/staff/profile`.
///
/// Mirrors only the fields a staff member may see and edit about themselves
/// plus read-only work context (assigned shops). Manager-controlled data
/// (membership status, permissions, portal metadata) is intentionally absent so
/// it can never leak into the UI.
class StaffProfile {
  const StaffProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.preferredName,
    this.phone,
    this.lineId,
    required this.accountRole,
    required this.status,
    this.staffCode,
    this.shops = const <StaffProfileShop>[],
  });

  factory StaffProfile.fromJson(Map<String, Object?> json) {
    final profile = _map(json['profile']);
    return StaffProfile(
      id: _string(profile['id']),
      email: _string(profile['email']),
      displayName: _string(profile['displayName']),
      preferredName: _nullableString(profile['preferredName']),
      phone: _nullableString(profile['phone']),
      lineId: _nullableString(profile['lineId']),
      accountRole: _string(profile['accountRole'], fallback: 'staff'),
      status: _string(profile['status']),
      staffCode: _nullableString(profile['staffCode']),
      shops: _list(
        json['shops'],
      ).map(StaffProfileShop.fromJson).toList(growable: false),
    );
  }

  final String id;
  final String email;
  final String displayName;
  final String? preferredName;
  final String? phone;
  final String? lineId;
  final String accountRole;
  final String status;
  final String? staffCode;
  final List<StaffProfileShop> shops;
}

/// A shop the staff member is assigned to, as shown on their profile.
class StaffProfileShop {
  const StaffProfileShop({required this.id, required this.name, this.role});

  factory StaffProfileShop.fromJson(Map<String, Object?> json) {
    return StaffProfileShop(
      id: _string(json['id']),
      name: _string(json['name']),
      role: _nullableString(json['role']),
    );
  }

  final String id;
  final String name;

  /// Per-shop role label, or null for admin/global rows.
  final String? role;
}

/// Editable fields for `PATCH /api/staff/profile`.
///
/// Only the four self-service fields are serialized; blank optionals collapse to
/// null so the backend stores them as null.
class StaffProfileUpdate {
  const StaffProfileUpdate({
    required this.displayName,
    this.preferredName,
    this.phone,
    this.lineId,
  });

  final String displayName;
  final String? preferredName;
  final String? phone;
  final String? lineId;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'displayName': displayName.trim(),
      'preferredName': _nullableString(preferredName),
      'phone': _nullableString(phone),
      'lineId': _nullableString(lineId),
    };
  }
}

Map<String, Object?> _map(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return value.cast<String, Object?>();
  return const <String, Object?>{};
}

List<Map<String, Object?>> _list(Object? value) {
  if (value is! List) return const <Map<String, Object?>>[];
  return value.map(_map).toList(growable: false);
}

String _string(Object? value, {String fallback = ''}) {
  return (value as String? ?? fallback).trim();
}

String? _nullableString(Object? value) {
  final text = _string(value);
  return text.isEmpty ? null : text;
}
