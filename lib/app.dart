import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api/staff_api_client.dart';
import 'core/auth/pin_credential_store.dart';
import 'core/auth/pin_lock_service.dart';
import 'core/firestore/favorites_repository.dart';
import 'core/preferences/user_preferences_controller.dart';
import 'core/recipes/recipe_repository.dart';
import 'core/security/privacy_screen_guard.dart';
import 'core/sops/sop_repository.dart';
import 'core/staff/staff_session_controller.dart';
import 'core/staff/staff_session_state.dart';
import 'features/home/home_screen.dart';
import 'features/pin/pin_screen.dart';
import 'features/staff_auth/staff_auth_router.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

class ZinmeApp extends StatelessWidget {
  const ZinmeApp({
    super.key,
    required this.apiClient,
    required this.sessionController,
    required this.sopRepository,
    required this.recipeRepository,
    required this.favoritesRepository,
    required this.userPreferencesController,
    required this.pinCredentialStore,
    this.autoLockEnabled = true,
  });

  final StaffApiClient apiClient;
  final StaffSessionController sessionController;
  final SopRepository sopRepository;
  final RecipeRepository recipeRepository;
  final FavoritesRepository favoritesRepository;
  final UserPreferencesController userPreferencesController;
  final PinCredentialStore pinCredentialStore;

  // Background/inactivity auto-lock relies on a real Timer. Tests disable it so
  // the harness never leaves a pending timer after settling.
  final bool autoLockEnabled;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<StaffSessionController>.value(
          value: sessionController,
        ),
        Provider<StaffApiClient>.value(value: apiClient),
        Provider<SopRepository>.value(value: sopRepository),
        Provider<RecipeRepository>.value(value: recipeRepository),
        Provider<FavoritesRepository>.value(value: favoritesRepository),
        ChangeNotifierProvider<UserPreferencesController>.value(
          value: userPreferencesController,
        ),
        Provider<PinCredentialStore>.value(value: pinCredentialStore),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Kitchen Guide',
        theme: AppTheme.dark(),
        builder: (context, child) {
          final content = PrivacyScreenGuard(
            child: child ?? const SizedBox.shrink(),
          );
          // Apply the saved font-size preference app-wide (dialogs included).
          return Consumer<UserPreferencesController>(
            builder: (context, preferences, _) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(
                    _fontScaleFor(preferences.preferences.fontSize),
                  ),
                ),
                child: content,
              );
            },
          );
        },
        home: StaffAuthRouter(
          readyBuilder: (context) => _AppGate(autoLockEnabled: autoLockEnabled),
        ),
      ),
    );
  }
}

double _fontScaleFor(String fontSize) {
  switch (fontSize) {
    case 'Small':
      return 0.9;
    case 'Large':
      return 1.18;
    case 'Medium':
    default:
      return 1.0;
  }
}

class _AppGate extends StatefulWidget {
  const _AppGate({required this.autoLockEnabled});

  final bool autoLockEnabled;

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> with WidgetsBindingObserver {
  bool _unlocked = false;
  bool _checkingPin = true;
  String? _activeUserId;
  StaffSessionController? _session;

  final PinLockService _pinLockService = const PinLockService();

  // Re-lock after the app sits in the background this long, or after this much
  // foreground inactivity. Mirrors the PIN-unlock flow in ARCHITECTURE-flutter.
  static const Duration _backgroundLockAfter = Duration(seconds: 30);
  static const Duration _inactivityLockAfter = Duration(minutes: 15);
  DateTime? _backgroundedAt;
  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = context.read<StaffSessionController>();
    if (!identical(_session, session)) {
      _session?.removeListener(_onSessionChanged);
      _session = session..addListener(_onSessionChanged);
    }
    _syncUserGate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    _session?.removeListener(_onSessionChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.autoLockEnabled) return;
    if (state == AppLifecycleState.resumed) {
      final backgroundedAt = _backgroundedAt;
      _backgroundedAt = null;
      if (_unlocked &&
          backgroundedAt != null &&
          DateTime.now().difference(backgroundedAt) >= _backgroundLockAfter) {
        _autoLock();
      } else {
        _armInactivityTimer();
      }
      return;
    }
    _backgroundedAt ??= DateTime.now();
    _inactivityTimer?.cancel();
  }

  void _onUnlocked() {
    setState(() => _unlocked = true);
    _armInactivityTimer();
  }

  void _armInactivityTimer() {
    _inactivityTimer?.cancel();
    if (!widget.autoLockEnabled || !_unlocked) return;
    _inactivityTimer = Timer(_inactivityLockAfter, _autoLock);
  }

  // Background/inactivity lock. Only re-locks when a PIN can actually gate the
  // app; with PIN disabled there is nothing to fall back to, so it no-ops.
  Future<void> _autoLock() async {
    if (!_unlocked) return;
    final userId = _activeUserId;
    if (userId == null) return;
    final preferences = context.read<UserPreferencesController>().preferences;
    if (!preferences.pinEnabled) return;
    final pinStore = context.read<PinCredentialStore>();
    if (!await pinStore.hasPin(userId)) return;
    if (!mounted || !_unlocked) return;
    _inactivityTimer?.cancel();
    setState(() => _unlocked = false);
  }

  void _onSessionChanged() {
    final status = _session?.state.status;
    if (status != StaffSessionStatus.ready) {
      if (_activeUserId != null || _unlocked || !_checkingPin) {
        _inactivityTimer?.cancel();
        context.read<UserPreferencesController>().clearLoadedUser();
        setState(() {
          _activeUserId = null;
          _unlocked = false;
          _checkingPin = true;
        });
      }
      return;
    }
    _syncUserGate();
  }

  void _syncUserGate() {
    final userId = _session?.state.user?.id;
    if (userId == null || userId == _activeUserId) return;

    _activeUserId = userId;
    _unlocked = false;
    _checkingPin = true;
    _preparePinGate(userId);
  }

  Future<void> _preparePinGate(String userId) async {
    final preferences = await context
        .read<UserPreferencesController>()
        .loadForUser(userId);
    if (!mounted || _activeUserId != userId) return;

    if (!preferences.pinEnabled) {
      setState(() {
        _checkingPin = false;
        _unlocked = true;
      });
      return;
    }

    final pinStore = context.read<PinCredentialStore>();
    if (!await pinStore.hasPin(userId)) {
      await pinStore.setPin(userId, PinLockService.defaultPin);
    }
    if (!mounted || _activeUserId != userId) return;

    final failures = await pinStore.failedAttempts(userId);
    if (_pinLockService.shouldDisableQuickUnlock(failures)) {
      await _session?.signOut();
      await pinStore.resetFailedAttempts(userId);
      return;
    }

    if (mounted && _activeUserId == userId) {
      setState(() => _checkingPin = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingPin) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_unlocked) {
      return Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _armInactivityTimer(),
        child: HomeScreen(
          favoritesRepository: context.read<FavoritesRepository>(),
          onLock: () => _lockApp(),
        ),
      );
    }

    return PinScreen(
      pinLength: PinLockService.defaultPin.length,
      appTitle: 'Kitchen Guide',
      onSubmit: _verifyPin,
      onSuccess: _onUnlocked,
    );
  }

  Future<String?> _verifyPin(String pin) async {
    final userId = _activeUserId;
    if (userId == null) {
      return 'Sign in again to unlock.';
    }
    final pinStore = context.read<PinCredentialStore>();
    final matched = await pinStore.verifyPin(userId, pin);
    if (matched) return null;

    final failures = await pinStore.failedAttempts(userId);
    if (_pinLockService.shouldDisableQuickUnlock(failures)) {
      await _session?.signOut();
      await pinStore.resetFailedAttempts(userId);
      return 'PIN locked. Sign in again.';
    }
    return 'Wrong PIN. Try again.';
  }

  Future<void> _lockApp() async {
    _inactivityTimer?.cancel();
    final userId = _activeUserId;
    if (userId == null) return;
    final preferences = context.read<UserPreferencesController>().preferences;
    final pinStore = context.read<PinCredentialStore>();
    if (preferences.pinEnabled && await pinStore.hasPin(userId)) {
      if (!mounted) return;
      setState(() => _unlocked = false);
      return;
    }
    await _session?.signOut();
  }
}
