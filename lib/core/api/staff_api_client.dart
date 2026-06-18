import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import '../attendance/attendance_models.dart';
import '../booking/booking_models.dart';
import '../models/content_item.dart';
import '../staff/shop.dart';
import '../staff/staff_profile.dart';
import '../staff/staff_user.dart';
import 'admin_api_models.dart';
import 'api_exceptions.dart';
import 'cookie_store.dart';

/// Result of `POST /api/staff/login`.
class LoginResult {
  const LoginResult({required this.user});

  final StaffUser user;
}

/// Talks to the staff endpoints on the Zinme backend.
///
/// Uses a Dio client backed by a persistent cookie jar (Better Auth session
/// cookie) so subsequent calls authenticate automatically. All non-2xx
/// responses are translated into the typed exceptions in [api_exceptions].
class StaffApiClient {
  StaffApiClient({
    required String baseUrl,
    required CookieStore cookieStore,
    Dio? dio,
  }) : _cookieStore = cookieStore,
       _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = baseUrl
      ..connectTimeout = const Duration(seconds: 10)
      ..receiveTimeout = const Duration(seconds: 15)
      ..sendTimeout = const Duration(seconds: 15)
      ..headers['Accept'] = 'application/json'
      ..headers['Content-Type'] = 'application/json'
      ..validateStatus = (_) => true;
  }

  static const String defaultBaseUrl = String.fromEnvironment(
    'ZINME_API_BASE',
    defaultValue: 'https://zinmeteahouse.com/api',
  );

  final Dio _dio;
  final CookieStore _cookieStore;
  bool _cookieReady = false;

  Future<void> _ensureCookieManager() async {
    if (_cookieReady) return;
    final jar = await _cookieStore.jar();
    _dio.interceptors.add(CookieManager(jar));
    _cookieReady = true;
  }

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final res = await _send(
      () => _dio.post<Map<String, Object?>>(
        '/staff/login',
        data: <String, Object?>{'email': email, 'password': password},
      ),
    );
    final data = res.data ?? const <String, Object?>{};
    final requiresPasswordChange =
        data['requiresPasswordChange'] as bool? ?? false;
    final staffState = await me();
    return LoginResult(
      user: staffState.copyWith(
        email: staffState.email.isEmpty ? email : staffState.email,
        requiresPasswordChange: requiresPasswordChange,
      ),
    );
  }

  Future<void> changeInitialPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _send(
      () => _dio.post<Map<String, Object?>>(
        '/staff/change-initial-password',
        data: <String, Object?>{
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      ),
    );
  }

  Future<StaffUser> me() async {
    final res = await _send(() => _dio.get<Map<String, Object?>>('/staff/me'));
    final data = res.data ?? const <String, Object?>{};
    return StaffUser.fromStaffSessionJson(data);
  }

  Future<List<Shop>> myShops() async {
    final res = await _send(
      () => _dio.get<Map<String, Object?>>('/staff/me/shops'),
    );
    final data = res.data ?? const <String, Object?>{};
    final list = (data['shops'] as List<Object?>?) ?? const <Object?>[];
    return list
        .whereType<Map<String, Object?>>()
        .map(Shop.fromJson)
        .toList(growable: false);
  }

  /// The signed-in staff member's self-service profile (`GET /staff/profile`).
  Future<StaffProfile> getStaffProfile() async {
    final res = await _send(
      () => _dio.get<Map<String, Object?>>('/staff/profile'),
    );
    return StaffProfile.fromJson(res.data ?? const <String, Object?>{});
  }

  /// Updates the editable personal fields (`PATCH /staff/profile`).
  Future<StaffProfile> updateStaffProfile(StaffProfileUpdate update) async {
    final res = await _send(
      () => _dio.patch<Map<String, Object?>>(
        '/staff/profile',
        data: update.toJson(),
      ),
    );
    return StaffProfile.fromJson(res.data ?? const <String, Object?>{});
  }

  /// Lists published SOPs assigned to [shopId], shaped as [ContentItem]s.
  ///
  /// The backend returns each item with its stable `publicId` under the `id`
  /// key, which becomes [ContentItem.id].
  Future<List<ContentItem>> listShopSops(String shopId) async {
    final res = await _send(
      () => _dio.get<Map<String, Object?>>('/staff/shops/$shopId/sops'),
    );
    final data = res.data ?? const <String, Object?>{};
    final list = (data['sops'] as List<Object?>?) ?? const <Object?>[];
    return list
        .whereType<Map<String, Object?>>()
        .map((json) => ContentItem.fromJson(json['id'] as String? ?? '', json))
        .toList(growable: false);
  }

  /// Lists published recipes assigned to [shopId], shaped as [ContentItem]s.
  ///
  /// Same envelope as [listShopSops]: each item carries its stable `publicId`
  /// under the `id` key, which becomes [ContentItem.id].
  Future<List<ContentItem>> listShopRecipes(String shopId) async {
    final res = await _send(
      () => _dio.get<Map<String, Object?>>('/staff/shops/$shopId/recipes'),
    );
    final data = res.data ?? const <String, Object?>{};
    final list = (data['recipes'] as List<Object?>?) ?? const <Object?>[];
    return list
        .whereType<Map<String, Object?>>()
        .map((json) => ContentItem.fromJson(json['id'] as String? ?? '', json))
        .toList(growable: false);
  }

  /// Current attendance state for [shopId] (`GET /staff/attendance/status`).
  Future<AttendanceStatus> getAttendanceStatus(String shopId) async {
    final res = await _send(
      () => _dio.get<Map<String, Object?>>(
        '/staff/attendance/status',
        queryParameters: <String, Object?>{'shopId': shopId},
      ),
    );
    return AttendanceStatus.fromJson(_map(res.data));
  }

  /// Clocks in at [shopId] with an optional captured location.
  Future<ClockInResult> clockInAttendance({
    required String shopId,
    double? latitude,
    double? longitude,
    int? accuracyMeters,
    DateTime? capturedAt,
  }) async {
    final res = await _send(
      () => _dio.post<Map<String, Object?>>(
        '/staff/attendance/clock-in',
        data: _attendancePayload(
          shopId,
          latitude,
          longitude,
          accuracyMeters,
          capturedAt,
        ),
      ),
    );
    return ClockInResult.fromJson(_map(res.data));
  }

  /// Clocks out of the open session at [shopId] with an optional location.
  Future<ClockOutResult> clockOutAttendance({
    required String shopId,
    double? latitude,
    double? longitude,
    int? accuracyMeters,
    DateTime? capturedAt,
  }) async {
    final res = await _send(
      () => _dio.post<Map<String, Object?>>(
        '/staff/attendance/clock-out',
        data: _attendancePayload(
          shopId,
          latitude,
          longitude,
          accuracyMeters,
          capturedAt,
        ),
      ),
    );
    return ClockOutResult.fromJson(_map(res.data));
  }

  /// The signed-in staff member's own attendance history.
  Future<List<AttendanceSession>> listMyAttendance({
    DateTime? from,
    DateTime? to,
  }) async {
    final res = await _send(
      () => _dio.get<Map<String, Object?>>(
        '/staff/attendance/my',
        queryParameters: <String, Object?>{
          if (from != null) 'from': _ymd(from),
          if (to != null) 'to': _ymd(to),
        },
      ),
    );
    final list = (res.data?['items'] as List<Object?>?) ?? const <Object?>[];
    return list
        .whereType<Map<String, Object?>>()
        .map(AttendanceSession.fromJson)
        .toList(growable: false);
  }

  // ── Staff self-service booking (`/staff/scheduling/*`) ──────────────────────

  /// Browse open slots for [shopId]. Optional [positionId] (role) and [date]
  /// (`YYYY-MM-DD`) narrow the list. Backend returns only published, future
  /// slots with a free seat; each carries `remaining` and a `tooSoon` flag.
  Future<List<OpenSlot>> listOpenSlots({
    required String shopId,
    String? positionId,
    DateTime? date,
  }) async {
    final res = await _send(
      () => _dio.get<Map<String, Object?>>(
        '/staff/scheduling/shift-slots',
        queryParameters: <String, Object?>{
          'shopId': shopId,
          if (positionId != null) 'positionId': positionId,
          if (date != null) 'date': _ymd(date),
        },
      ),
    );
    final list = (res.data?['slots'] as List<Object?>?) ?? const <Object?>[];
    return list
        .whereType<Map<String, Object?>>()
        .map(OpenSlot.fromJson)
        .toList(growable: false);
  }

  /// Slot detail including the `overlap` flag versus the caller's bookings.
  Future<OpenSlot> getSlot(String slotId) async {
    final res = await _send(
      () => _dio.get<Map<String, Object?>>(
        '/staff/scheduling/shift-slots/$slotId',
      ),
    );
    return OpenSlot.fromJson(_map(res.data?['slot']));
  }

  /// Book [shiftSlotId]. Throws [ClientApiException] with a `code` of
  /// `TOO_SOON` / `SLOT_FULL` / `OVERLAP` / `ALREADY_BOOKED` on rule violations.
  Future<String> createBooking(String shiftSlotId) async {
    final res = await _send(
      () => _dio.post<Map<String, Object?>>(
        '/staff/scheduling/bookings',
        data: <String, Object?>{'shiftSlotId': shiftSlotId},
      ),
    );
    return res.data?['bookingId'] as String? ?? '';
  }

  /// The caller's upcoming bookings, soonest first.
  Future<List<MyBooking>> listMyBookings() async {
    final res = await _send(
      () => _dio.get<Map<String, Object?>>('/staff/scheduling/bookings/my'),
    );
    final list = (res.data?['bookings'] as List<Object?>?) ?? const <Object?>[];
    return list
        .whereType<Map<String, Object?>>()
        .map(MyBooking.fromJson)
        .toList(growable: false);
  }

  /// Cancel own booking. Throws [ClientApiException] with code
  /// `CANCEL_WINDOW_CLOSED` when inside the 48h window.
  Future<void> cancelBooking(String bookingId) async {
    await _send(
      () => _dio.delete<Map<String, Object?>>(
        '/staff/scheduling/bookings/$bookingId',
      ),
    );
  }

  /// Schedule-change alerts for the signed-in staff member.
  Future<List<ScheduleAlert>> listScheduleAlerts() async {
    final res = await _send(
      () => _dio.get<Map<String, Object?>>('/staff/scheduling/alerts'),
    );
    final list = (res.data?['alerts'] as List<Object?>?) ?? const <Object?>[];
    return list
        .whereType<Map<String, Object?>>()
        .map(ScheduleAlert.fromJson)
        .toList(growable: false);
  }

  /// Mark a schedule alert read.
  Future<void> markAlertRead(String alertId) async {
    await _send(
      () => _dio.post<Map<String, Object?>>(
        '/staff/scheduling/alerts/$alertId/read',
      ),
    );
  }

  Future<void> clearSession() async {
    await _cookieStore.clear();
  }

  Future<List<PortalShop>> listPortalShops() async {
    final res = await _send(
      () => _dio.get<Map<String, Object?>>('/portal/shops'),
    );
    final list = (res.data?['shops'] as List<Object?>?) ?? const <Object?>[];
    return list
        .whereType<Map<String, Object?>>()
        .map(PortalShop.fromJson)
        .toList();
  }

  Future<List<PortalStaffAccount>> listPortalStaffAccounts() async {
    final res = await _send(
      () => _dio.get<Map<String, Object?>>('/portal/staff'),
    );
    final list = (res.data?['staff'] as List<Object?>?) ?? const <Object?>[];
    return list
        .whereType<Map<String, Object?>>()
        .map(PortalStaffAccount.fromJson)
        .toList();
  }

  Future<PortalStaffAccount> createPortalStaffAccount(
    PortalStaffMutation payload,
  ) async {
    final res = await _send(
      () => _dio.post<Map<String, Object?>>(
        '/portal/staff',
        data: payload.toCreateJson(),
      ),
    );
    return PortalStaffAccount.fromJson(_map(res.data?['staff']));
  }

  Future<PortalStaffAccount> updatePortalStaffAccount(
    String staffProfileId,
    PortalStaffMutation payload,
  ) async {
    final res = await _send(
      () => _dio.patch<Map<String, Object?>>(
        '/portal/staff/$staffProfileId',
        data: payload.toUpdateJson(),
      ),
    );
    return PortalStaffAccount.fromJson(_map(res.data?['staff']));
  }

  Future<void> deletePortalStaffAccount(String staffProfileId) async {
    await _send(
      () => _dio.delete<Map<String, Object?>>('/portal/staff/$staffProfileId'),
    );
  }

  Future<List<PortalCategory>> listPortalCategories(
    PortalContentKind kind,
  ) async {
    final path =
        kind == PortalContentKind.sop
            ? '/portal/sops/categories'
            : '/portal/recipes/categories';
    final res = await _send(() => _dio.get<Map<String, Object?>>(path));
    final list =
        (res.data?['categories'] as List<Object?>?) ?? const <Object?>[];
    return list
        .whereType<Map<String, Object?>>()
        .map(
          kind == PortalContentKind.sop
              ? PortalCategory.fromSopJson
              : PortalCategory.fromRecipeJson,
        )
        .toList();
  }

  Future<PortalCategory> createPortalCategory(
    PortalContentKind kind, {
    required String name,
    required String slug,
  }) async {
    final path =
        kind == PortalContentKind.sop
            ? '/portal/sops/categories'
            : '/portal/recipes/categories';
    final data = <String, Object?>{
      if (slug.trim().isNotEmpty) 'slug': slug.trim(),
      'name': name.trim(),
      if (kind == PortalContentKind.recipe) 'icon': null,
      if (kind == PortalContentKind.sop) 'description': null,
      'sortOrder': 0,
    };
    final res = await _send(
      () => _dio.post<Map<String, Object?>>(path, data: data),
    );
    final json = _map(res.data?['category']);
    return kind == PortalContentKind.sop
        ? PortalCategory.fromSopJson(json)
        : PortalCategory.fromRecipeJson(json);
  }

  Future<List<PortalContentItem>> listPortalContent(
    PortalContentKind kind,
  ) async {
    final path =
        kind == PortalContentKind.sop ? '/portal/sops' : '/portal/recipes';
    final res = await _send(() => _dio.get<Map<String, Object?>>(path));
    final key = kind == PortalContentKind.sop ? 'sops' : 'recipes';
    final list = (res.data?[key] as List<Object?>?) ?? const <Object?>[];
    return list
        .whereType<Map<String, Object?>>()
        .map(
          kind == PortalContentKind.sop
              ? PortalContentItem.fromSopJson
              : PortalContentItem.fromRecipeJson,
        )
        .toList();
  }

  Future<PortalContentItem> getPortalContent(
    PortalContentKind kind,
    String id,
  ) async {
    final path =
        kind == PortalContentKind.sop
            ? '/portal/sops/$id'
            : '/portal/recipes/$id';
    final key = kind == PortalContentKind.sop ? 'sop' : 'recipe';
    final res = await _send(() => _dio.get<Map<String, Object?>>(path));
    final json = _map(res.data?[key]);
    return kind == PortalContentKind.sop
        ? PortalContentItem.fromSopJson(json)
        : PortalContentItem.fromRecipeJson(json);
  }

  Future<PortalContentItem> createPortalContent(
    PortalContentMutation payload,
  ) async {
    final path =
        payload.kind == PortalContentKind.sop
            ? '/portal/sops'
            : '/portal/recipes';
    final key = payload.kind == PortalContentKind.sop ? 'sop' : 'recipe';
    final res = await _send(
      () => _dio.post<Map<String, Object?>>(path, data: payload.toJson()),
    );
    final json = _map(res.data?[key]);
    return payload.kind == PortalContentKind.sop
        ? PortalContentItem.fromSopJson(json)
        : PortalContentItem.fromRecipeJson(json);
  }

  Future<PortalContentItem> updatePortalContent(
    String id,
    PortalContentMutation payload,
  ) async {
    final path =
        payload.kind == PortalContentKind.sop
            ? '/portal/sops/$id'
            : '/portal/recipes/$id';
    final key = payload.kind == PortalContentKind.sop ? 'sop' : 'recipe';
    final res = await _send(
      () => _dio.patch<Map<String, Object?>>(path, data: payload.toJson()),
    );
    final json = _map(res.data?[key]);
    return payload.kind == PortalContentKind.sop
        ? PortalContentItem.fromSopJson(json)
        : PortalContentItem.fromRecipeJson(json);
  }

  Future<PortalContentItem> publishPortalContent(
    PortalContentKind kind,
    String id,
  ) async {
    return _togglePortalContent(kind, id, publish: true);
  }

  Future<PortalContentItem> unpublishPortalContent(
    PortalContentKind kind,
    String id,
  ) async {
    return _togglePortalContent(kind, id, publish: false);
  }

  Future<void> archivePortalContent(PortalContentKind kind, String id) async {
    final path =
        kind == PortalContentKind.sop
            ? '/portal/sops/$id'
            : '/portal/recipes/$id';
    await _send(() => _dio.delete<Map<String, Object?>>(path));
  }

  Future<PortalContentItem> _togglePortalContent(
    PortalContentKind kind,
    String id, {
    required bool publish,
  }) async {
    final noun = kind == PortalContentKind.sop ? 'sops' : 'recipes';
    final key = kind == PortalContentKind.sop ? 'sop' : 'recipe';
    final action = publish ? 'publish' : 'unpublish';
    final res = await _send(
      () => _dio.post<Map<String, Object?>>('/portal/$noun/$id/$action'),
    );
    final json = _map(res.data?[key]);
    return kind == PortalContentKind.sop
        ? PortalContentItem.fromSopJson(json)
        : PortalContentItem.fromRecipeJson(json);
  }

  Future<Response<Map<String, Object?>>> _send(
    Future<Response<Map<String, Object?>>> Function() call,
  ) async {
    await _ensureCookieManager();
    try {
      final res = await call();
      return _validate(res);
    } on DioException catch (e) {
      throw _mapDioError(e);
    } on SocketException catch (e) {
      throw NetworkException('Network unavailable', cause: e);
    }
  }

  Response<Map<String, Object?>> _validate(Response<Map<String, Object?>> res) {
    final status = res.statusCode ?? 0;
    if (status >= 200 && status < 300) {
      return res;
    }
    final data = res.data;
    final message =
        (data is Map<String, Object?>) ? data['message'] as String? : null;
    final code =
        (data is Map<String, Object?>) ? data['code'] as String? : null;
    if (status == 401) {
      throw UnauthorizedException(message ?? 'Unauthorized');
    }
    if (status >= 400 && status < 500) {
      final body = data is Map<String, Object?> ? data : null;
      throw ClientApiException(
        message ?? 'Request failed',
        statusCode: status,
        code: code,
        distanceMeters: _intFrom(body?['distanceMeters']),
        allowedRadiusMeters: _intFrom(body?['allowedRadiusMeters']),
      );
    }
    throw ServerApiException(message ?? 'Server error', statusCode: status);
  }

  ApiException _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NetworkException('Network unavailable', cause: e);
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return NetworkException(e.message ?? 'Network error', cause: e);
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode ?? 0;
        if (status == 401) {
          return UnauthorizedException('Unauthorized', cause: e);
        }
        if (status >= 500) {
          return ServerApiException(
            'Server error',
            statusCode: status,
            cause: e,
          );
        }
        return ClientApiException(
          e.message ?? 'Request failed',
          statusCode: status,
          cause: e,
        );
    }
  }
}

Map<String, Object?> _map(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return value.cast<String, Object?>();
  return const <String, Object?>{};
}

Map<String, Object?> _attendancePayload(
  String shopId,
  double? latitude,
  double? longitude,
  int? accuracyMeters,
  DateTime? capturedAt,
) {
  return <String, Object?>{
    'shopId': shopId,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
    if (capturedAt != null) 'capturedAt': capturedAt.toUtc().toIso8601String(),
  };
}

String _ymd(DateTime date) {
  final local = date.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year.toString().padLeft(4, '0')}-$month-$day';
}

int? _intFrom(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
