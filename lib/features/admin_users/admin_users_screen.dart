import 'package:flutter/material.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User access')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search email, role, or status',
            ),
            onChanged: (_) {},
          ),
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              leading: Icon(Icons.admin_panel_settings_outlined),
              title: Text('Admin grants will use Cloud Functions'),
              subtitle: Text(
                'assignMemberByEmail, disableMember, and claims sync come next.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
