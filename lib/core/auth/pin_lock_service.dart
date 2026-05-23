class PinLockService {
  const PinLockService();

  static const String defaultPin = '2222';
  static const int maxFailedAttempts = 5;

  bool isValidPinShape(String pin) {
    return RegExp(r'^\d{4,8}$').hasMatch(pin);
  }

  bool shouldDisableQuickUnlock(int failedAttempts) {
    return failedAttempts >= maxFailedAttempts;
  }
}
