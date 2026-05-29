import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'shop.dart';
import 'staff_user.dart';

/// Persists staff session metadata behind [FlutterSecureStorage].
///
/// Keys are namespaced with `staff.*` so the existing PIN unlock state
/// (`pin.*`) is untouched. The Better Auth session cookie itself is kept by
/// [CookieStore]; this class stores the user payload, shop list cache, and
/// the chosen active shop id.
class SecureSessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  static const String _userKey = 'staff.user.cache';
  static const String _shopsKey = 'staff.shops.cache';
  static const String _activeShopKey = 'staff.shop.active_id';

  final FlutterSecureStorage _storage;

  Future<void> saveUser(StaffUser user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<StaffUser?> readUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null || raw.isEmpty) return null;
    return StaffUser.fromJson(jsonDecode(raw) as Map<String, Object?>);
  }

  Future<void> saveShops(List<Shop> shops) async {
    await _storage.write(
      key: _shopsKey,
      value: jsonEncode(shops.map((s) => s.toJson()).toList()),
    );
  }

  Future<List<Shop>> readShops() async {
    final raw = await _storage.read(key: _shopsKey);
    if (raw == null || raw.isEmpty) return const <Shop>[];
    final list = jsonDecode(raw) as List<Object?>;
    return list
        .whereType<Map<String, Object?>>()
        .map(Shop.fromJson)
        .toList(growable: false);
  }

  Future<void> saveActiveShopId(String shopId) async {
    await _storage.write(key: _activeShopKey, value: shopId);
  }

  Future<String?> readActiveShopId() async {
    return _storage.read(key: _activeShopKey);
  }

  Future<void> clear() async {
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _shopsKey);
    await _storage.delete(key: _activeShopKey);
  }
}
