import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/recipes/recipe_repository.dart';
import 'core/sops/sop_repository.dart';
import 'core/staff/staff_session_controller.dart';
import 'features/home/home_screen.dart';
import 'features/pin/pin_screen.dart';
import 'features/staff_auth/staff_auth_router.dart';
import 'theme/app_theme.dart';

class ZinmeApp extends StatelessWidget {
  const ZinmeApp({
    super.key,
    required this.sessionController,
    required this.sopRepository,
    required this.recipeRepository,
  });

  final StaffSessionController sessionController;
  final SopRepository sopRepository;
  final RecipeRepository recipeRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<StaffSessionController>.value(
          value: sessionController,
        ),
        Provider<SopRepository>.value(value: sopRepository),
        Provider<RecipeRepository>.value(value: recipeRepository),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Kitchen Guide',
        theme: AppTheme.dark(),
        home: StaffAuthRouter(readyBuilder: (context) => const _AppGate()),
      ),
    );
  }
}

class _AppGate extends StatefulWidget {
  const _AppGate();

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  bool _unlocked = false;

  @override
  Widget build(BuildContext context) {
    if (_unlocked) {
      return HomeScreen();
    }

    return PinScreen(
      correctPin: '2222',
      appTitle: 'Kitchen Guide',
      onSuccess: () => setState(() => _unlocked = true),
    );
  }
}
