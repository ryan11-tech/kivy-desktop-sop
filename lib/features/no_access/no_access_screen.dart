import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/staff/staff_session_controller.dart';

class NoAccessScreen extends StatelessWidget {
  const NoAccessScreen({required this.email, super.key});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('No access assigned')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(email, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            const Text('Ask an admin to grant access to this shop.'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed:
                  () => context.read<StaffSessionController>().refreshSession(),
              icon: const Icon(Icons.refresh),
              label: const Text('Check again'),
            ),
            TextButton.icon(
              onPressed: () => context.read<StaffSessionController>().signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
