import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/staff/staff_session_controller.dart';
import 'features/home/home_screen.dart';
import 'features/staff_auth/staff_auth_router.dart';
import 'theme/app_theme.dart';

class ZinmeApp extends StatelessWidget {
  const ZinmeApp({super.key, required this.sessionController});

  final StaffSessionController sessionController;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StaffSessionController>.value(
      value: sessionController,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ZinmeAPP',
        theme: AppTheme.dark(),
        home: StaffAuthRouter(
          readyBuilder: (context) => HomeScreen(),
        ),
      ),
    );
  }
}
