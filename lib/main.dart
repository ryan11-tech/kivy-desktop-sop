import 'package:flutter/material.dart';

import 'app.dart';
import 'core/api/cookie_store.dart';
import 'core/api/staff_api_client.dart';
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

  // Kick bootstrap in the background; controller emits initializing first so
  // the splash screen renders immediately.
  sessionController.bootstrap();

  runApp(ZinmeApp(sessionController: sessionController));
}
