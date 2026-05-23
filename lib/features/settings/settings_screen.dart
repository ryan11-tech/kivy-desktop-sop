import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: <Widget>[
          SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: const Text('Dark mode'),
          ),
          ListTile(
            leading: const Icon(Icons.pin_outlined),
            title: const Text('Personal PIN'),
            subtitle: const Text(
              'Secure storage wiring will be added with Firebase setup.',
            ),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
