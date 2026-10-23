import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zinme_app/core/api/admin_api_models.dart';
import 'package:zinme_app/core/api/api_exceptions.dart';
import 'package:zinme_app/core/api/cookie_store.dart';
import 'package:zinme_app/core/api/staff_api_client.dart';

/// Cookie store rooted in a temp directory (no path_provider in unit tests).
class _TempCookieStore extends CookieStore {
  _TempCookieStore(this.dir);

  final Directory dir;
  PersistCookieJar? _jar;

  @override
  Future<PersistCookieJar> jar() async {
    return _jar ??= PersistCookieJar(storage: FileStorage(dir.path));
  }
}

/// Answers every request with one canned JSON response and records it.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.statusCode, this.body);

  final int statusCode;
  final Map<String, Object?> body;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _staffJson = <String, Object?>{
  'id': 'profile-1',
  'userId': 'user-1',
  'name': 'Mya',
  'email': 'mya@example.com',
  'accountRole': 'staff',
  'status': 'invited',
  'staffCode': null,
  'mustChangePassword': true,
  'shops': [
    {'id': 'shop-1', 'name': 'Silom', 'role': 'cashier'},
  ],
};

const _mutation = PortalStaffMutation(
  accountRole: 'staff',
  email: 'mya@example.com',
  name: 'Mya',
  shopMemberships: [
    PortalStaffMembershipInput(shopId: 'shop-1', role: 'cashier'),
  ],
);

void main() {
  late Directory cookieDir;

  setUp(() {
    cookieDir = Directory.systemTemp.createTempSync('zinme_cookies_');
  });

  tearDown(() {
    if (cookieDir.existsSync()) cookieDir.deleteSync(recursive: true);
  });

  StaffApiClient clientWith(_FakeAdapter adapter) {
    return StaffApiClient(
      baseUrl: 'https://example.test/api',
      cookieStore: _TempCookieStore(cookieDir),
      dio: Dio()..httpClientAdapter = adapter,
    );
  }

  test('createPortalStaffAccount sends no password and parses the '
      'one-time password', () async {
    final adapter = _FakeAdapter(201, const {
      'staff': _staffJson,
      'oneTimePassword': 'K7QM-4XPA',
      'expiresAt': '2026-10-31T07:05:00.000Z',
    });

    final result = await clientWith(
      adapter,
    ).createPortalStaffAccount(_mutation);

    final request = adapter.lastRequest!;
    expect(request.method, 'POST');
    expect(request.path, '/portal/staff');
    final sent = request.data as Map<String, Object?>;
    expect(sent.containsKey('temporaryPassword'), isFalse);
    expect(sent.containsKey('mustChangePassword'), isFalse);
    expect(sent.containsKey('status'), isFalse);

    expect(result.staff.id, 'profile-1');
    expect(result.oneTimePassword.password, 'K7QM-4XPA');
    expect(result.oneTimePassword.expiresAt, DateTime.utc(2026, 10, 31, 7, 5));
  });

  test('issuePortalStaffOneTimePassword posts to the account and parses '
      'the response', () async {
    final adapter = _FakeAdapter(200, const {
      'oneTimePassword': 'ZX9P-2MNB',
      'expiresAt': '2026-10-31T07:05:00.000Z',
    });

    final otp = await clientWith(
      adapter,
    ).issuePortalStaffOneTimePassword('profile-1');

    final request = adapter.lastRequest!;
    expect(request.method, 'POST');
    expect(request.path, '/portal/staff/profile-1/one-time-password');
    expect(otp.password, 'ZX9P-2MNB');
    expect(otp.expiresAt, DateTime.utc(2026, 10, 31, 7, 5));
  });

  test('issuePortalStaffOneTimePassword surfaces the server 403 '
      'message', () async {
    final adapter = _FakeAdapter(403, const {
      'message': 'Store managers cannot update another store manager',
      'code': 'FORBIDDEN',
    });

    await expectLater(
      clientWith(adapter).issuePortalStaffOneTimePassword('profile-2'),
      throwsA(
        isA<ClientApiException>()
            .having((e) => e.statusCode, 'statusCode', 403)
            .having(
              (e) => e.message,
              'message',
              'Store managers cannot update another store manager',
            ),
      ),
    );
  });

  test('updatePortalStaffAccount sends status only when set', () async {
    final adapter = _FakeAdapter(200, const {'staff': _staffJson});
    const suspend = PortalStaffMutation(
      accountRole: 'staff',
      email: 'mya@example.com',
      name: 'Mya',
      status: 'suspended',
      statusReason: 'Left the shop',
      shopMemberships: [
        PortalStaffMembershipInput(shopId: 'shop-1', role: 'cashier'),
      ],
    );

    await clientWith(adapter).updatePortalStaffAccount('profile-1', suspend);

    final sent = adapter.lastRequest!.data as Map<String, Object?>;
    expect(adapter.lastRequest!.method, 'PATCH');
    expect(sent['status'], 'suspended');
    expect(sent['statusReason'], 'Left the shop');
    expect(sent.containsKey('mustChangePassword'), isFalse);
  });
}
