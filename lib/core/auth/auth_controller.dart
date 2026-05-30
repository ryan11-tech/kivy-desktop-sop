enum AuthGateState { signedOut, pendingAccess, unlocked, locked }

class AuthController {
  const AuthController();

  AuthGateState resolve({
    required bool hasApiSession,
    required bool hasActiveAccess,
    required bool isLocallyUnlocked,
  }) {
    if (!hasApiSession) {
      return AuthGateState.signedOut;
    }

    if (!hasActiveAccess) {
      return AuthGateState.pendingAccess;
    }

    return isLocallyUnlocked ? AuthGateState.unlocked : AuthGateState.locked;
  }
}
