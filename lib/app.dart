import 'package:flutter/material.dart';

import 'features/home/home_screen.dart';
import 'theme/app_theme.dart';

class ZinmeApp extends StatelessWidget {
  const ZinmeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ZinmeAPP',
      theme: AppTheme.dark(),
      home: HomeScreen(),
    );
  }
}
