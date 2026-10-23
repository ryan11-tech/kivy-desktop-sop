enum PortalContentKind { recipe, sop }

const staffRoleOptions = <String>[
  'store_manager',
  'assistant_manager',
  'cashier',
  'kitchen_staff',
  'bar_staff',
  'content_editor',
];

const recipeTypeOptions = <String>['drink', 'base', 'food', 'prep', 'other'];

const sopTypeOptions = <String>[
  'opening',
  'closing',
  'cleaning',
  'prep',
  'maintenance',
  'inventory',
  'safety',
  'training',
  'other',
];

class PortalShop {
  const PortalShop({
    required this.id,
    required this.slug,
    required this.name,
    required this.status,
  });

  factory PortalShop.fromJson(Map<String, Object?> json) {
    return PortalShop(
      id: _string(json['id']),
      slug: _string(json['slug']),
      name: _string(json['name']),
      status: _string(json['status'], fallback: 'active'),
    );
  }

  final String id;
  final String slug;
  final String name;
  final String status;
}

class PortalStaffMembership {
  const PortalStaffMembership({
    required this.shopId,
    required this.shopName,
    required this.role,
  });

  factory PortalStaffMembership.fromJson(Map<String, Object?> json) {
    return PortalStaffMembership(
      shopId: _string(json['id']),
      shopName: _string(json['name']),
      role: _string(json['role']),
    );
  }

  final String shopId;
  final String shopName;
  final String role;
}

class PortalStaffAccount {
  const PortalStaffAccount({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.accountRole,
    required this.status,
    required this.staffCode,
    required this.mustChangePassword,
    required this.shops,
  });

  factory PortalStaffAccount.fromJson(Map<String, Object?> json) {
    return PortalStaffAccount(
      id: _string(json['id']),
      userId: _string(json['userId']),
      name: _string(json['name']),
      email: _string(json['email']),
      accountRole: _string(json['accountRole'], fallback: 'staff'),
      status: _string(json['status'], fallback: 'invited'),
      staffCode: _nullableString(json['staffCode']),
      mustChangePassword: json['mustChangePassword'] as bool? ?? true,
      shops: _list(json['shops']).map(PortalStaffMembership.fromJson).toList(),
    );
  }

  final String id;
  final String userId;
  final String name;
  final String email;
  final String accountRole;
  final String status;
  final String? staffCode;
  final bool mustChangePassword;
  final List<PortalStaffMembership> shops;
}

class PortalStaffMembershipInput {
  const PortalStaffMembershipInput({required this.shopId, required this.role});

  final String shopId;
  final String role;

  Map<String, Object?> toJson() {
    return <String, Object?>{'shopId': shopId, 'role': role};
  }
}

/// Body of `POST /api/portal/staff` and `PATCH /api/portal/staff/:id`.
///
/// Since zin_mae feature 011 the server generates every password (a one-time
/// password), so this never carries `temporaryPassword` or
/// `mustChangePassword`. `status` is only sent when it changes; suspending
/// needs a [statusReason] (see [validateSuspendReason]).
class PortalStaffMutation {
  const PortalStaffMutation({
    required this.accountRole,
    required this.email,
    required this.name,
    required this.shopMemberships,
    this.status,
    this.statusReason,
  });

  final String accountRole;
  final String email;
  final String name;
  final List<PortalStaffMembershipInput> shopMemberships;

  /// `'suspended'` or `'active'`; null leaves the status unchanged.
  final String? status;

  /// Required by the server when [status] is `'suspended'`.
  final String? statusReason;

  Map<String, Object?> toCreateJson() {
    return <String, Object?>{
      'accountRole': accountRole,
      'email': email,
      'name': name,
      'shopMemberships': shopMemberships.map((item) => item.toJson()).toList(),
    };
  }

  Map<String, Object?> toUpdateJson() {
    final reason = statusReason?.trim();
    return <String, Object?>{
      'accountRole': accountRole,
      'email': email,
      'name': name,
      if (status != null) 'status': status,
      if (status != null && reason != null && reason.isNotEmpty)
        'statusReason': reason,
      'shopMemberships': shopMemberships.map((item) => item.toJson()).toList(),
    };
  }
}

/// Length bounds the server enforces on `statusReason` (trimmed).
const suspendReasonMinLength = 5;
const suspendReasonMaxLength = 500;

/// Returns a user-facing error for a suspend reason, or null when it is valid.
String? validateSuspendReason(String reason) {
  final length = reason.trim().length;
  if (length < suspendReasonMinLength) {
    return 'Give a reason of at least $suspendReasonMinLength characters.';
  }
  if (length > suspendReasonMaxLength) {
    return 'Keep the reason under $suspendReasonMaxLength characters.';
  }
  return null;
}

/// A server-generated one-time password (`XXXX-XXXX`) and when it expires.
///
/// Shown once to the admin and never stored or logged by the app.
class PortalOneTimePassword {
  const PortalOneTimePassword({
    required this.password,
    required this.expiresAt,
    required this.expiresAtText,
  });

  factory PortalOneTimePassword.fromJson(Map<String, Object?> json) {
    final expiresText = _string(json['expiresAt']);
    return PortalOneTimePassword(
      password: _string(json['oneTimePassword']),
      expiresAt: DateTime.tryParse(expiresText)?.toUtc(),
      expiresAtText: expiresText,
    );
  }

  final String password;

  /// Parsed expiry in UTC; null when the server sent an unparseable value.
  final DateTime? expiresAt;

  /// The expiry exactly as the server sent it.
  final String expiresAtText;

  @override
  String toString() => 'PortalOneTimePassword(expiresAt: $expiresAtText)';
}

/// Result of `POST /api/portal/staff`: the new account plus its first
/// one-time password.
class PortalStaffCreateResult {
  const PortalStaffCreateResult({
    required this.staff,
    required this.oneTimePassword,
  });

  factory PortalStaffCreateResult.fromJson(Map<String, Object?> json) {
    return PortalStaffCreateResult(
      staff: PortalStaffAccount.fromJson(_map(json['staff'])),
      oneTimePassword: PortalOneTimePassword.fromJson(json),
    );
  }

  final PortalStaffAccount staff;
  final PortalOneTimePassword oneTimePassword;
}

class PortalCategory {
  const PortalCategory({
    required this.id,
    required this.slug,
    required this.name,
    required this.sortOrder,
    this.description,
    this.icon,
  });

  factory PortalCategory.fromSopJson(Map<String, Object?> json) {
    return PortalCategory(
      id: _string(json['id']),
      slug: _string(json['slug']),
      name: _string(json['name']),
      description: _nullableString(json['description']),
      sortOrder: _int(json['sortOrder']),
    );
  }

  factory PortalCategory.fromRecipeJson(Map<String, Object?> json) {
    return PortalCategory(
      id: _string(json['id']),
      slug: _string(json['slug']),
      name: _string(json['name']),
      icon: _nullableString(json['icon']),
      sortOrder: _int(json['sortOrder']),
    );
  }

  final String id;
  final String slug;
  final String name;
  final String? description;
  final String? icon;
  final int sortOrder;
}

class PortalAssignedShop {
  const PortalAssignedShop({required this.id, required this.name});

  factory PortalAssignedShop.fromJson(Map<String, Object?> json) {
    return PortalAssignedShop(
      id: _string(json['id']),
      name: _string(json['name']),
    );
  }

  final String id;
  final String name;
}

class PortalContentParameter {
  const PortalContentParameter({
    required this.name,
    required this.amount,
    required this.unit,
    this.sortOrder = 0,
  });

  factory PortalContentParameter.fromJson(Map<String, Object?> json) {
    return PortalContentParameter(
      name: _string(json['name']),
      amount: _nullableDouble(json['amount']),
      unit: _nullableString(json['unit']),
      sortOrder: _int(json['sortOrder']),
    );
  }

  final String name;
  final double? amount;
  final String? unit;
  final int sortOrder;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'name': name,
      'amount': amount,
      'unit': unit,
      'sortOrder': sortOrder,
    };
  }

  String get display {
    final amountText = amount == null ? '' : _formatNumber(amount!);
    return [
      name,
      amountText,
      unit ?? '',
    ].where((part) => part.trim().isNotEmpty).join(' ');
  }
}

class PortalRecipeVariantInput {
  const PortalRecipeVariantInput({
    required this.variantKey,
    required this.name,
    required this.parameters,
    required this.steps,
    this.sortOrder = 0,
  });

  factory PortalRecipeVariantInput.fromJson(Map<String, Object?> json) {
    return PortalRecipeVariantInput(
      variantKey: _string(json['variantKey']),
      name: _string(json['name']),
      parameters:
          _list(
            json['parameters'],
          ).map(PortalContentParameter.fromJson).toList(),
      steps: _list(json['steps']).map((step) => _string(step['body'])).toList(),
      sortOrder: _int(json['sortOrder']),
    );
  }

  final String variantKey;
  final String name;
  final List<PortalContentParameter> parameters;
  final List<String> steps;
  final int sortOrder;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'variantKey': variantKey,
      'name': name,
      'sortOrder': sortOrder,
      'parameters': parameters.map((item) => item.toJson()).toList(),
      'steps': steps,
    };
  }
}

class PortalContentItem {
  const PortalContentItem({
    required this.kind,
    required this.id,
    required this.publicId,
    required this.name,
    required this.status,
    required this.typeKey,
    required this.categoryId,
    required this.categoryName,
    required this.notes,
    required this.sortOrder,
    required this.assignedShops,
    this.parameters = const <PortalContentParameter>[],
    this.steps = const <String>[],
    this.variants = const <PortalRecipeVariantInput>[],
  });

  factory PortalContentItem.fromSopJson(Map<String, Object?> json) {
    final category = _map(json['category']);
    return PortalContentItem(
      kind: PortalContentKind.sop,
      id: _string(json['id']),
      publicId: _string(json['publicId']),
      name: _string(json['name']),
      status: _string(json['status'], fallback: 'draft'),
      typeKey: _string(json['sopType'], fallback: 'other'),
      categoryId: _nullableString(json['categoryId']),
      categoryName: _string(category['name']),
      notes: _nullableString(json['notes']),
      sortOrder: _int(json['sortOrder']),
      assignedShops:
          _list(
            json['assignedShops'],
          ).map(PortalAssignedShop.fromJson).toList(),
      parameters:
          _list(
            json['parameters'],
          ).map(PortalContentParameter.fromJson).toList(),
      steps: _list(json['steps']).map((step) => _string(step['body'])).toList(),
    );
  }

  factory PortalContentItem.fromRecipeJson(Map<String, Object?> json) {
    final category = _map(json['category']);
    return PortalContentItem(
      kind: PortalContentKind.recipe,
      id: _string(json['id']),
      publicId: _string(json['publicId']),
      name: _string(json['name']),
      status: _string(json['status'], fallback: 'draft'),
      typeKey: _string(json['recipeType'], fallback: 'other'),
      categoryId: _nullableString(json['categoryId']),
      categoryName: _string(category['name']),
      notes: _nullableString(json['notes']),
      sortOrder: _int(json['sortOrder']),
      assignedShops:
          _list(
            json['assignedShops'],
          ).map(PortalAssignedShop.fromJson).toList(),
      parameters:
          _list(
            json['parameters'],
          ).map(PortalContentParameter.fromJson).toList(),
      steps: _list(json['steps']).map((step) => _string(step['body'])).toList(),
      variants:
          _list(
            json['variants'],
          ).map(PortalRecipeVariantInput.fromJson).toList(),
    );
  }

  final PortalContentKind kind;
  final String id;
  final String publicId;
  final String name;
  final String status;
  final String typeKey;
  final String? categoryId;
  final String categoryName;
  final String? notes;
  final int sortOrder;
  final List<PortalAssignedShop> assignedShops;
  final List<PortalContentParameter> parameters;
  final List<String> steps;
  final List<PortalRecipeVariantInput> variants;

  String get kindLabel => kind == PortalContentKind.sop ? 'SOP' : 'Recipe';
}

class PortalContentMutation {
  const PortalContentMutation({
    required this.kind,
    required this.name,
    required this.typeKey,
    required this.status,
    required this.parameters,
    required this.steps,
    required this.shopIds,
    required this.sortOrder,
    this.publicId,
    this.categoryId,
    this.notes,
    this.variants = const <PortalRecipeVariantInput>[],
  });

  final PortalContentKind kind;
  final String? publicId;
  final String name;
  final String? categoryId;
  final String? notes;
  final String typeKey;
  final String status;
  final List<PortalContentParameter> parameters;
  final List<String> steps;
  final List<String> shopIds;
  final List<PortalRecipeVariantInput> variants;
  final int sortOrder;

  Map<String, Object?> toJson() {
    final body = <String, Object?>{
      if (publicId != null && publicId!.isNotEmpty) 'publicId': publicId,
      'categoryId': categoryId,
      'name': name,
      'notes': notes,
      'status': status,
      'sortOrder': sortOrder,
      'parameters': parameters.map((item) => item.toJson()).toList(),
      'steps': steps,
      'shopIds': shopIds,
    };
    if (kind == PortalContentKind.recipe) {
      body['recipeType'] = typeKey;
      body['variants'] = variants.map((item) => item.toJson()).toList();
    } else {
      body['sopType'] = typeKey;
    }
    return body;
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

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(_string(value)) ?? 0;
}

double? _nullableDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(_string(value));
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
