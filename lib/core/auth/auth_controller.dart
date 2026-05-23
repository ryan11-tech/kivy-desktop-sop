enum AuthGateState { signedOut, pendingAccess, unlocked, locked }

class AuthController {
  const AuthController();

  AuthGateState resolve({
    required bool hasFirebaseSession,
    required bool hasActiveAccess,
    required bool isLocallyUnlocked,
  }) {
    if (!hasFirebaseSession) {
      return AuthGateState.signedOut;
    }

    if (!hasActiveAccess) {
      return AuthGateState.pendingAccess;
    }

    return isLocallyUnlocked ? AuthGateState.unlocked : AuthGateState.locked;
  }
}
