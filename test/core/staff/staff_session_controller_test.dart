import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:zinme_app/core/api/api_exceptions.dart';
import 'package:zinme_app/core/api/staff_api_client.dart';
import 'package:zinme_app/core/staff/connectivity_probe.dart';
import 'package:zinme_app/core/staff/secure_session_store.dart';
import 'package:zinme_app/core/staff/shop.dart';
import 'package:zinme_app/core/staff/staff_session_controller.dart';
import 'package:zinme_app/core/staff/staff_session_state.dart';
import 'package:zinme_app/core/staff/staff_user.dart';

class _MockApi extends Mock implements StaffApiClient {}

class _MockStore extends Mock implements SecureSessionStore {}

class _MockConnectivity extends Mock implements ConnectivityProbe {}

StaffUser _user({bool requiresPassword = false, bool requiresOtp = false}) {
  return StaffUser(
    id: 'u1',
    email: 'a@b.c',
    displayName: 'A',
    requiresPasswordChange: requiresPassword,
    requiresOtp: requiresOtp,
  );
}

Shop _shop(String id, [String name = 'Shop']) {
  return Shop(id: id, name: '$name $id');
}

void main() {
  late _MockApi api;
  late _MockStore store;
  late _MockConnectivity connectivity;
  late StaffSessionController controller;

  setUp(() {
    api = _MockApi();
    store = _MockStore();
    connectivity = _MockConnectivity();
    controller = StaffSessionController(
      apiClient: api,
      store: store,
      connectivity: connectivity,
    );

    when(() => store.saveUser(any())).thenAnswer((_) async {});
    when(() => store.saveShops(any())).thenAnswer((_) async {});
    when(() => store.saveActiveShopId(any())).thenAnswer((_) async {});
    when(() => store.clear()).thenAnswer((_) async {});
    when(() => store.readShops()).thenAnswer((_) async => const <Shop>[]);
    when(() => store.readUser()).thenAnswer((_) async => null);
    when(() => store.readActiveShopId()).thenAnswer((_) async => null);
    when(() => api.clearSession()).thenAnswer((_) async {});
  });

  tearDown(() {
    controller.dispose();
  });

  group('bootstrap', () {
    test('offline with no cache -> offlineBlocked', () async {
      when(() => connectivity.isOnline()).thenAnswer((_) async => false);

      await controller.bootstrap();

      expect(controller.state.status, StaffSessionStatus.offlineBlocked);
      expect(controller.state.offline, isTrue);
    });

    test('offline with cached user + shops + active id -> ready offline', () async {
      when(() => connectivity.isOnline()).thenAnswer((_) async => false);
      when(() => store.readUser()).thenAnswer((_) async => _user());
      when(() => store.readShops())
          .thenAnswer((_) async => [_shop('s1'), _shop('s2')]);
      when(() => store.readActiveShopId()).thenAnswer((_) async => 's2');

      await controller.bootstrap();

      expect(controller.state.status, StaffSessionStatus.ready);
      expect(controller.state.activeShop?.id, 's2');
      expect(controller.state.offline, isTrue);
    });

    test('online + 401 from /me -> needsLogin and clears store', () async {
      when(() => connectivity.isOnline()).thenAnswer((_) async => true);
      when(() => api.me()).thenThrow(const UnauthorizedException('nope'));

      await controller.bootstrap();

      expect(controller.state.status, StaffSessionStatus.needsLogin);
      verify(() => store.clear()).called(1);
    });

    test('online + requiresPasswordChange -> needsPasswordChange', () async {
      when(() => connectivity.isOnline()).thenAnswer((_) async => true);
      when(() => api.me()).thenAnswer((_) async => _user(requiresPassword: true));

      await controller.bootstrap();

      expect(controller.state.status, StaffSessionStatus.needsPasswordChange);
    });

    test('online + requiresOtp -> needsOtp', () async {
      when(() => connectivity.isOnline()).thenAnswer((_) async => true);
      when(() => api.me()).thenAnswer((_) async => _user(requiresOtp: true));

      await controller.bootstrap();

      expect(controller.state.status, StaffSessionStatus.needsOtp);
    });

    test('online + no shops -> blockedNoShops', () async {
      when(() => connectivity.isOnline()).thenAnswer((_) async => true);
      when(() => api.me()).thenAnswer((_) async => _user());
      when(() => api.myShops()).thenAnswer((_) async => const <Shop>[]);

      await controller.bootstrap();

      expect(controller.state.status, StaffSessionStatus.blockedNoShops);
    });

    test('online + single shop -> ready (auto-persisted)', () async {
      when(() => connectivity.isOnline()).thenAnswer((_) async => true);
      when(() => api.me()).thenAnswer((_) async => _user());
      when(() => api.myShops()).thenAnswer((_) async => [_shop('only')]);

      await controller.bootstrap();

      expect(controller.state.status, StaffSessionStatus.ready);
      expect(controller.state.activeShop?.id, 'only');
      verify(() => store.saveActiveShopId('only')).called(1);
    });

    test('online + multi shop without persisted id -> needsShopSelection', () async {
      when(() => connectivity.isOnline()).thenAnswer((_) async => true);
      when(() => api.me()).thenAnswer((_) async => _user());
      when(() => api.myShops())
          .thenAnswer((_) async => [_shop('a'), _shop('b')]);
      when(() => store.readActiveShopId()).thenAnswer((_) async => null);

      await controller.bootstrap();

      expect(controller.state.status, StaffSessionStatus.needsShopSelection);
    });

    test('online + multi shop with valid persisted id -> ready', () async {
      when(() => connectivity.isOnline()).thenAnswer((_) async => true);
      when(() => api.me()).thenAnswer((_) async => _user());
      when(() => api.myShops())
          .thenAnswer((_) async => [_shop('a'), _shop('b')]);
      when(() => store.readActiveShopId()).thenAnswer((_) async => 'b');

      await controller.bootstrap();

      expect(controller.state.status, StaffSessionStatus.ready);
      expect(controller.state.activeShop?.id, 'b');
    });

    test('online + multi shop with stale persisted id -> needsShopSelection',
        () async {
      when(() => connectivity.isOnline()).thenAnswer((_) async => true);
      when(() => api.me()).thenAnswer((_) async => _user());
      when(() => api.myShops())
          .thenAnswer((_) async => [_shop('a'), _shop('b')]);
      when(() => store.readActiveShopId()).thenAnswer((_) async => 'gone');

      await controller.bootstrap();

      expect(controller.state.status, StaffSessionStatus.needsShopSelection);
    });
  });

  group('login', () {
    test('login + requiresPasswordChange -> needsPasswordChange', () async {
      when(() => api.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => LoginResult(user: _user(requiresPassword: true)));

      await controller.login(email: 'a@b.c', password: 'x');

      expect(controller.state.status, StaffSessionStatus.needsPasswordChange);
    });

    test('login + requiresOtp -> needsOtp', () async {
      when(() => api.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => LoginResult(user: _user(requiresOtp: true)));

      await controller.login(email: 'a@b.c', password: 'x');

      expect(controller.state.status, StaffSessionStatus.needsOtp);
    });

    test('login success + single shop -> ready', () async {
      when(() => api.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => LoginResult(user: _user()));
      when(() => api.myShops()).thenAnswer((_) async => [_shop('only')]);

      await controller.login(email: 'a@b.c', password: 'x');

      expect(controller.state.status, StaffSessionStatus.ready);
    });
  });

  group('selectShop', () {
    test('persists active id and emits ready', () async {
      // Pre-set state to needsShopSelection via bootstrap.
      when(() => connectivity.isOnline()).thenAnswer((_) async => true);
      when(() => api.me()).thenAnswer((_) async => _user());
      when(() => api.myShops())
          .thenAnswer((_) async => [_shop('a'), _shop('b')]);
      await controller.bootstrap();
      expect(controller.state.status, StaffSessionStatus.needsShopSelection);

      await controller.selectShop(controller.state.shops.last);

      expect(controller.state.status, StaffSessionStatus.ready);
      expect(controller.state.activeShop?.id, 'b');
      verify(() => store.saveActiveShopId('b')).called(1);
    });
  });

  group('signOut', () {
    test('clears api + store and returns to needsLogin', () async {
      await controller.signOut();

      verify(() => api.clearSession()).called(1);
      verify(() => store.clear()).called(1);
      expect(controller.state.status, StaffSessionStatus.needsLogin);
    });
  });
}
