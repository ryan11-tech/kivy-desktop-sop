import 'package:flutter_test/flutter_test.dart';
import 'package:zinme_app/core/auth/pin_credential_store.dart';
import 'package:zinme_app/core/auth/pin_lock_service.dart';

void main() {
  test('stores verifier and validates correct PIN', () async {
    final store = InMemoryPinCredentialStore();

    await store.setPin('u1', '2468');

    expect(await store.hasPin('u1'), isTrue);
    expect(await store.verifyPin('u1', '2468'), isTrue);
    expect(await store.failedAttempts('u1'), 0);
  });

  test('rejects invalid PIN shape', () async {
    final store = InMemoryPinCredentialStore();

    expect(() => store.setPin('u1', '12ab'), throwsArgumentError);
    expect(() => store.setPin('u1', '123'), throwsArgumentError);
  });

  test('tracks failures and locks out after five attempts', () async {
    final store = InMemoryPinCredentialStore();

    await store.setPin('u1', '2468');
    for (var i = 0; i < PinLockService.maxFailedAttempts; i += 1) {
      expect(await store.verifyPin('u1', '0000'), isFalse);
    }

    expect(await store.failedAttempts('u1'), PinLockService.maxFailedAttempts);
    expect(await store.verifyPin('u1', '2468'), isFalse);

    await store.resetFailedAttempts('u1');
    expect(await store.verifyPin('u1', '2468'), isTrue);
  });

  test('clearPin removes credential and attempts', () async {
    final store = InMemoryPinCredentialStore();

    await store.setPin('u1', '2468');
    await store.verifyPin('u1', '0000');
    await store.clearPin('u1');

    expect(await store.hasPin('u1'), isFalse);
    expect(await store.failedAttempts('u1'), 0);
  });
}
