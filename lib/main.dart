import 'package:flutter/material.dart';

import 'app.dart';
import 'core/api/cookie_store.dart';
import 'core/api/staff_api_client.dart';
import 'core/config/app_config.dart';
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

  // Kick bootstrap in the background; controller emits initializing first so
  // the splash screen renders immediately.
  sessionController.bootstrap();

  runApp(
    ZinmeApp(
      sessionController: sessionController,
      sopRepository: sopRepository,
      recipeRepository: recipeRepository,
    ),
  );
}
