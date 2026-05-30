import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'pin_lock_service.dart';

abstract class PinCredentialStore {
  Future<bool> hasPin(String userId);
  Future<void> setPin(String userId, String pin);
  Future<bool> verifyPin(String userId, String pin);
  Future<void> clearPin(String userId);
  Future<int> failedAttempts(String userId);
  Future<void> resetFailedAttempts(String userId);
}

class SecurePinCredentialStore implements PinCredentialStore {
  SecurePinCredentialStore({
    FlutterSecureStorage? storage,
    Random? random,
    PinLockService pinLockService = const PinLockService(),
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _random = random ?? Random.secure(),
       _pinLockService = pinLockService;

  final FlutterSecureStorage _storage;
  final Random _random;
  final PinLockService _pinLockService;

  static const _prefix = 'zinme.pin';

  @override
  Future<bool> hasPin(String userId) async {
    final verifier = await _storage.read(key: _verifierKey(userId));
    return verifier != null && verifier.isNotEmpty;
  }

  @override
  Future<void> setPin(String userId, String pin) async {
    if (!_pinLockService.isValidPinShape(pin)) {
      throw ArgumentError.value(pin, 'pin', 'PIN must be 4 to 8 digits.');
    }
    final salt = _newSalt();
    await _storage.write(
      key: _verifierKey(userId),
      value: '$salt:${_hashPin(salt, pin)}',
    );
    await resetFailedAttempts(userId);
  }

  @override
  Future<bool> verifyPin(String userId, String pin) async {
    final failures = await failedAttempts(userId);
    if (_pinLockService.shouldDisableQuickUnlock(failures)) {
      return false;
    }

    final verifier = await _storage.read(key: _verifierKey(userId));
    if (verifier == null || !verifier.contains(':')) {
      await _incrementFailedAttempts(userId);
      return false;
    }

    final parts = verifier.split(':');
    final salt = parts.first;
    final expected = parts.sublist(1).join(':');
    final matched = _hashPin(salt, pin) == expected;
    if (matched) {
      await resetFailedAttempts(userId);
      return true;
    }

    await _incrementFailedAttempts(userId);
    return false;
  }

  @override
  Future<void> clearPin(String userId) async {
    await Future.wait([
      _storage.delete(key: _verifierKey(userId)),
      _storage.delete(key: _attemptsKey(userId)),
    ]);
  }

  @override
  Future<int> failedAttempts(String userId) async {
    final raw = await _storage.read(key: _attemptsKey(userId));
    return int.tryParse(raw ?? '') ?? 0;
  }

  @override
  Future<void> resetFailedAttempts(String userId) async {
    await _storage.write(key: _attemptsKey(userId), value: '0');
  }

  Future<void> _incrementFailedAttempts(String userId) async {
    final next = await failedAttempts(userId) + 1;
    await _storage.write(key: _attemptsKey(userId), value: '$next');
  }

  String _newSalt() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hashPin(String salt, String pin) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }

  String _verifierKey(String userId) => '$_prefix.$userId.verifier';
  String _attemptsKey(String userId) => '$_prefix.$userId.failedAttempts';
}

class InMemoryPinCredentialStore implements PinCredentialStore {
  InMemoryPinCredentialStore({
    PinLockService pinLockService = const PinLockService(),
  }) : _pinLockService = pinLockService;

  final PinLockService _pinLockService;
  final Map<String, String> _verifiers = <String, String>{};
  final Map<String, int> _attempts = <String, int>{};
  int _saltCounter = 0;

  @override
  Future<bool> hasPin(String userId) async => _verifiers.containsKey(userId);

  @override
  Future<void> setPin(String userId, String pin) async {
    if (!_pinLockService.isValidPinShape(pin)) {
      throw ArgumentError.value(pin, 'pin', 'PIN must be 4 to 8 digits.');
    }
    final salt = 'test-salt-${_saltCounter++}';
    _verifiers[userId] = '$salt:${_hashPin(salt, pin)}';
    await resetFailedAttempts(userId);
  }

  @override
  Future<bool> verifyPin(String userId, String pin) async {
    final failures = await failedAttempts(userId);
    if (_pinLockService.shouldDisableQuickUnlock(failures)) {
      return false;
    }
    final verifier = _verifiers[userId];
    if (verifier == null || !verifier.contains(':')) {
      _attempts[userId] = failures + 1;
      return false;
    }
    final parts = verifier.split(':');
    final salt = parts.first;
    final expected = parts.sublist(1).join(':');
    final matched = _hashPin(salt, pin) == expected;
    if (matched) {
      await resetFailedAttempts(userId);
      return true;
    }
    _attempts[userId] = failures + 1;
    return false;
  }

  @override
  Future<void> clearPin(String userId) async {
    _verifiers.remove(userId);
    _attempts.remove(userId);
  }

  @override
  Future<int> failedAttempts(String userId) async => _attempts[userId] ?? 0;

  @override
  Future<void> resetFailedAttempts(String userId) async {
    _attempts[userId] = 0;
  }

  String _hashPin(String salt, String pin) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }
}
