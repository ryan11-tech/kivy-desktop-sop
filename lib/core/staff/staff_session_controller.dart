import 'package:flutter/foundation.dart';

import '../api/api_exceptions.dart';
import '../api/staff_api_client.dart';
import 'connectivity_probe.dart';
import 'secure_session_store.dart';
import 'shop.dart';
import 'staff_session_state.dart';
import 'staff_user.dart';

/// Owns the staff auth lifecycle and exposes it as a [ChangeNotifier].
///
/// Screens listen via Provider, transition between states, and never talk to
/// the API client directly. Persistence is delegated to [SecureSessionStore].
class StaffSessionController extends ChangeNotifier {
  StaffSessionController({
    required StaffApiClient apiClient,
    required SecureSessionStore store,
    ConnectivityProbe? connectivity,
  })  : _api = apiClient,
        _store = store,
        _connectivity = connectivity ?? ConnectivityProbe();

  final StaffApiClient _api;
  final SecureSessionStore _store;
  final ConnectivityProbe _connectivity;

  StaffSessionState _state = const StaffSessionState.initializing();
  StaffSessionState get state => _state;

  bool _disposed = false;

  void _emit(StaffSessionState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // ── Bootstrap ────────────────────────────────────────────────────────────

  /// Called once at app start. Resolves where the user should land.
  Future<void> bootstrap() async {
    final cachedUser = await _store.readUser();
    final cachedShops = await _store.readShops();
    final cachedActiveId = await _store.readActiveShopId();

    final online = await _connectivity.isOnline();
    if (!online) {
      if (cachedUser != null && cachedShops.isNotEmpty) {
        final active = _resolveActive(cachedShops, cachedActiveId);
        _emit(StaffSessionState(
          status: active == null
              ? StaffSessionStatus.needsShopSelection
              : StaffSessionStatus.ready,
          user: cachedUser,
          shops: cachedShops,
          activeShop: active,
          offline: true,
        ));
      } else {
        _emit(_state.copyWith(
          status: StaffSessionStatus.offlineBlocked,
          offline: true,
        ));
      }
      return;
    }

    await _refreshFromServer();
  }

  // ── Auth actions ─────────────────────────────────────────────────────────

  Future<void> login({required String email, required String password}) async {
    final result = await _api.login(email: email, password: password);
    await _store.saveUser(result.user);
    if (result.user.requiresPasswordChange) {
      _emit(_state.copyWith(
        status: StaffSessionStatus.needsPasswordChange,
        user: result.user,
        clearError: true,
      ));
      return;
    }
    if (result.user.requiresOtp) {
      _emit(_state.copyWith(
        status: StaffSessionStatus.needsOtp,
        user: result.user,
        clearError: true,
      ));
      return;
    }
    await _loadShopsAndAdvance(result.user);
  }

  Future<void> submitPasswordChange({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.changeInitialPassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    await _refreshFromServer();
  }

  Future<void> submitOtp({required String code}) async {
    await _api.verifyEmailOtp(code: code);
    await _refreshFromServer();
  }

  Future<void> selectShop(Shop shop, {bool persist = true}) async {
    if (persist) {
      await _store.saveActiveShopId(shop.id);
    }
    _emit(_state.copyWith(
      status: StaffSessionStatus.ready,
      activeShop: shop,
    ));
  }

  Future<void> signOut() async {
    await _api.clearSession();
    await _store.clear();
    _emit(const StaffSessionState(status: StaffSessionStatus.needsLogin));
  }

  Future<void> retryBootstrap() async {
    _emit(const StaffSessionState.initializing());
    await bootstrap();
  }

  // ── Internals ────────────────────────────────────────────────────────────

  Future<void> _refreshFromServer() async {
    try {
      final user = await _api.me();
      await _store.saveUser(user);
      if (user.requiresPasswordChange) {
        _emit(_state.copyWith(
          status: StaffSessionStatus.needsPasswordChange,
          user: user,
          offline: false,
          clearError: true,
        ));
        return;
      }
      if (user.requiresOtp) {
        _emit(_state.copyWith(
          status: StaffSessionStatus.needsOtp,
          user: user,
          offline: false,
          clearError: true,
        ));
        return;
      }
      await _loadShopsAndAdvance(user);
    } on UnauthorizedException {
      await _store.clear();
      _emit(const StaffSessionState(status: StaffSessionStatus.needsLogin));
    } on NetworkException catch (e) {
      _emit(_state.copyWith(
        status: StaffSessionStatus.offlineBlocked,
        offline: true,
        lastError: e.message,
      ));
    }
  }

  Future<void> _loadShopsAndAdvance(StaffUser user) async {
    final shops = await _api.myShops();
    await _store.saveShops(shops);
    if (shops.isEmpty) {
      _emit(_state.copyWith(
        status: StaffSessionStatus.blockedNoShops,
        user: user,
        shops: const <Shop>[],
        clearActiveShop: true,
        offline: false,
      ));
      return;
    }
    if (shops.length == 1) {
      await _store.saveActiveShopId(shops.first.id);
      _emit(_state.copyWith(
        status: StaffSessionStatus.ready,
        user: user,
        shops: shops,
        activeShop: shops.first,
        offline: false,
      ));
      return;
    }
    final persistedId = await _store.readActiveShopId();
    final resolved = _resolveActive(shops, persistedId);
    if (resolved != null) {
      _emit(_state.copyWith(
        status: StaffSessionStatus.ready,
        user: user,
        shops: shops,
        activeShop: resolved,
        offline: false,
      ));
      return;
    }
    _emit(_state.copyWith(
      status: StaffSessionStatus.needsShopSelection,
      user: user,
      shops: shops,
      clearActiveShop: true,
      offline: false,
    ));
  }

  Shop? _resolveActive(List<Shop> shops, String? activeId) {
    if (activeId == null || activeId.isEmpty) {
      return shops.length == 1 ? shops.first : null;
    }
    for (final s in shops) {
      if (s.id == activeId) return s;
    }
    return shops.length == 1 ? shops.first : null;
  }
}
