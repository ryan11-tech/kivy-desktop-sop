import 'package:flutter/material.dart';

import 'app.dart';
import 'core/api/cookie_store.dart';
import 'core/api/staff_api_client.dart';
import 'core/attendance/attendance_repository.dart';
import 'core/auth/pin_credential_store.dart';
import 'core/config/app_config.dart';
import 'core/firestore/favorites_repository.dart';
import 'core/preferences/user_preferences_controller.dart';
import 'core/preferences/user_preferences_repository.dart';
import 'core/recipes/fallback_recipe_repository.dart';
import 'core/recipes/recipe_repository.dart';
import 'core/recipes/remote_recipe_repository.dart';
import 'core/sops/fallback_sop_repository.dart';
import 'core/sops/remote_sop_repository.dart';
import 'core/sops/sop_repository.dart';
import 'core/staff/secure_session_store.dart';
import 'core/staff/staff_session_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final cookieStore = CookieStore();
  final apiClient = StaffApiClient(
    baseUrl: StaffApiClient.defaultBaseUrl,
    cookieStore: cookieStore,
  );
  final sessionController = StaffSessionController(
    apiClient: apiClient,
    store: SecureSessionStore(),
  );
  final SopRepository sopRepository = FallbackSopRepository(
    RemoteSopRepository(apiClient),
    useMock: AppConfig.useMockSops,
  );
  final RecipeRepository recipeRepository = FallbackRecipeRepository(
    RemoteRecipeRepository(apiClient),
    useMock: AppConfig.useMockRecipes,
  );
  final AttendanceRepository attendanceRepository = RemoteAttendanceRepository(
    apiClient,
  );
  final FavoritesRepository favoritesRepository =
      SharedPreferencesFavoritesRepository(
        shopIdProvider:
            () => sessionController.state.activeShop?.id ?? 'no-shop',
      );
  final userPreferencesController = UserPreferencesController(
    repository: SharedPreferencesUserPreferencesRepository(),
  );
  final pinCredentialStore = SecurePinCredentialStore();

  // Kick bootstrap in the background; controller emits initializing first so
  // the splash screen renders immediately.
  sessionController.bootstrap();

  runApp(
    ZinmeApp(
      apiClient: apiClient,
      sessionController: sessionController,
      sopRepository: sopRepository,
      recipeRepository: recipeRepository,
      attendanceRepository: attendanceRepository,
      favoritesRepository: favoritesRepository,
      userPreferencesController: userPreferencesController,
      pinCredentialStore: pinCredentialStore,
    ),
  );
}
