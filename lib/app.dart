import 'package:flutter/material.dart';

import 'features/home/home_screen.dart';
import 'features/pin/pin_screen.dart';
import 'theme/app_theme.dart';

class ZinmeApp extends StatelessWidget {
  const ZinmeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kitchen Guide',
      theme: AppTheme.dark(),
      home: const _AppGate(),
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
