import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:zinme_app/core/api/api_exceptions.dart';
import 'package:zinme_app/core/api/staff_api_client.dart';
import 'package:zinme_app/core/staff/staff_profile.dart';
import 'package:zinme_app/core/staff/staff_profile_controller.dart';

class _MockApi extends Mock implements StaffApiClient {}

StaffProfile _profile({String displayName = 'Su Su'}) {
  return StaffProfile(
    id: 'p1',
    email: 'su@example.com',
    displayName: displayName,
    accountRole: 'staff',
    status: 'active',
    staffCode: 'CS1234',
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(const StaffProfileUpdate(displayName: 'x'));
  });

  late _MockApi api;
  late StaffProfileController controller;

  setUp(() {
    api = _MockApi();
    controller = StaffProfileController(apiClient: api);
  });

  tearDown(() => controller.dispose());

  group('load', () {
    test('success exposes the loaded profile', () async {
      when(() => api.getStaffProfile()).thenAnswer((_) async => _profile());

      await controller.load();

      expect(controller.status, StaffProfileStatus.loaded);
      expect(controller.profile?.displayName, 'Su Su');
      expect(controller.error, isNull);
    });

    test('failure surfaces the error message', () async {
      when(
        () => api.getStaffProfile(),
      ).thenThrow(const ServerApiException('boom', statusCode: 500));

      await controller.load();

      expect(controller.status, StaffProfileStatus.error);
      expect(controller.error, 'boom');
      expect(controller.profile, isNull);
    });
  });

  group('save', () {
    test('success returns and stores the updated profile', () async {
      when(
        () => api.updateStaffProfile(any()),
      ).thenAnswer((_) async => _profile(displayName: 'New Name'));

      final result = await controller.save(
        const StaffProfileUpdate(displayName: 'New Name'),
      );

      expect(result?.displayName, 'New Name');
      expect(controller.profile?.displayName, 'New Name');
      expect(controller.saving, isFalse);
      expect(controller.saveError, isNull);
    });

    test('failure returns null and sets saveError', () async {
      when(
        () => api.updateStaffProfile(any()),
      ).thenThrow(const ClientApiException('bad input', statusCode: 400));

      final result = await controller.save(
        const StaffProfileUpdate(displayName: 'x'),
      );

      expect(result, isNull);
      expect(controller.saveError, 'bad input');
      expect(controller.saving, isFalse);
    });
  });
}
