import 'shop.dart';
import 'staff_user.dart';

/// Top-level states the staff auth gate can be in.
///
/// Driven by [StaffSessionController]. The router maps each state to a screen.
enum StaffSessionStatus {
  /// Initial state before bootstrap completes.
  initializing,

  /// No session — show login.
  needsLogin,

  /// Backend flagged the staff user must rotate their temporary password.
  needsPasswordChange,

  /// Staff has more than one shop and no valid persisted active id.
  needsShopSelection,

  /// Backend returned an empty shop list. Staff cannot proceed.
  blockedNoShops,

  /// Offline at bootstrap with no cached session.
  offlineBlocked,

  /// Authenticated, password OK, active shop resolved.
  ready,
}

class StaffSessionState {
  const StaffSessionState({
    required this.status,
    this.user,
    this.shops = const <Shop>[],
    this.activeShop,
    this.offline = false,
    this.lastError,
  });

  const StaffSessionState.initializing()
    : status = StaffSessionStatus.initializing,
      user = null,
      shops = const <Shop>[],
      activeShop = null,
      offline = false,
      lastError = null;

  final StaffSessionStatus status;
  final StaffUser? user;
  final List<Shop> shops;
  final Shop? activeShop;
  final bool offline;
  final String? lastError;

  StaffSessionState copyWith({
    StaffSessionStatus? status,
    StaffUser? user,
    List<Shop>? shops,
    Shop? activeShop,
    bool? offline,
    String? lastError,
    bool clearActiveShop = false,
    bool clearError = false,
  }) {
    return StaffSessionState(
      status: status ?? this.status,
      user: user ?? this.user,
      shops: shops ?? this.shops,
      activeShop: clearActiveShop ? null : (activeShop ?? this.activeShop),
      offline: offline ?? this.offline,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}
