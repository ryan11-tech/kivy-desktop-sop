class PinLockService {
  const PinLockService();

  static const String defaultPin = '2222';
  static const int maxFailedAttempts = 5;

  // PINs are exactly 4 digits for now: the unlock keypad is fixed at 4 and the
  // shared default is 2222. Keeping the accepted shape in lockstep with the
  // keypad length prevents a set-a-longer-PIN-then-cannot-unlock lockout.
  // Per-user, server-issued PINs (and any variable length) come later.
  bool isValidPinShape(String pin) {
    return RegExp(r'^\d{4}$').hasMatch(pin);
  }

  bool shouldDisableQuickUnlock(int failedAttempts) {
    return failedAttempts >= maxFailedAttempts;
  }
}
