import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/staff/staff_session_controller.dart';
import '../../core/staff/staff_session_state.dart';
import '../../theme/app_colors.dart';
import 'shop_selection_screen.dart';
import 'staff_change_password_screen.dart';
import 'staff_login_screen.dart';

/// Maps [StaffSessionStatus] to a screen.
///
/// Composed under the app root above the existing PIN gate. When status
/// reaches [StaffSessionStatus.ready] this delegates to [readyBuilder] —
/// usually the PIN gate followed by the home screen.
class StaffAuthRouter extends StatelessWidget {
  const StaffAuthRouter({super.key, required this.readyBuilder});

  final WidgetBuilder readyBuilder;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StaffSessionController>().state;
    switch (state.status) {
      case StaffSessionStatus.initializing:
        return const _SplashScreen();
      case StaffSessionStatus.needsLogin:
        return const StaffLoginScreen();
      case StaffSessionStatus.needsPasswordChange:
        return const StaffChangePasswordScreen();
      case StaffSessionStatus.needsShopSelection:
        return const ShopSelectionScreen();
      case StaffSessionStatus.blockedNoShops:
        return const _BlockedScreen(
          title: 'No shop assigned',
          body:
              'Your account is active but no shop has been linked yet.\n'
              'Please contact an administrator.',
        );
      case StaffSessionStatus.offlineBlocked:
        return const _OfflineScreen();
      case StaffSessionStatus.ready:
        return readyBuilder(context);
    }
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}

class _BlockedScreen extends StatelessWidget {
  const _BlockedScreen({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                body,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed:
                    () => context.read<StaffSessionController>().signOut(),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineScreen extends StatelessWidget {
  const _OfflineScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: Colors.white54),
              const SizedBox(height: 16),
              const Text(
                'No internet connection',
                style: TextStyle(color: Colors.white, fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Connect to the internet to sign in.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed:
                    () =>
                        context.read<StaffSessionController>().refreshSession(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
