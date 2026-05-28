import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/staff/staff_session_controller.dart';
import '../staff_auth/shop_selection_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StaffSessionController>().state;
    final hasMultipleShops = state.shops.length > 1;
    final activeName = state.activeShop?.name ?? 'Not selected';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: <Widget>[
          if (state.user != null)
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(state.user!.displayName.isEmpty
                  ? state.user!.email
                  : state.user!.displayName),
              subtitle: Text(state.user!.email),
            ),
          if (hasMultipleShops)
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: const Text('Active shop'),
              subtitle: Text(activeName),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ShopSelectionScreen(
                    mode: ShopSelectionMode.standalone,
                  ),
                ),
              ),
            ),
          SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: const Text('Dark mode'),
          ),
          ListTile(
            leading: const Icon(Icons.pin_outlined),
            title: const Text('Personal PIN'),
            subtitle: const Text('Set or change your local unlock PIN.'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFFF6B6B)),
            title: const Text('Sign out',
                style: TextStyle(color: Color(0xFFFF6B6B))),
            onTap: () => context.read<StaffSessionController>().signOut(),
          ),
        ],
      ),
    );
  }
}
