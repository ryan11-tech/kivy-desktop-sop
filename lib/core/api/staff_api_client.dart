import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import '../models/content_item.dart';
import '../staff/shop.dart';
import '../staff/staff_user.dart';
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
    defaultValue: 'http://localhost/api',
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
    final userJson = data['user'] as Map<String, Object?>? ?? data;
    return LoginResult(user: StaffUser.fromJson(userJson));
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

  Future<void> verifyEmailOtp({required String code}) async {
    await _send(
      () => _dio.post<Map<String, Object?>>(
        '/staff/verify-email-otp',
        data: <String, Object?>{'code': code},
      ),
    );
  }

  Future<StaffUser> me() async {
    final res = await _send(() => _dio.get<Map<String, Object?>>('/staff/me'));
    final data = res.data ?? const <String, Object?>{};
    final userJson = data['user'] as Map<String, Object?>? ?? data;
    return StaffUser.fromJson(userJson);
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

  Future<void> clearSession() async {
    await _cookieStore.clear();
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
      throw ClientApiException(
        message ?? 'Request failed',
        statusCode: status,
        code: code,
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
