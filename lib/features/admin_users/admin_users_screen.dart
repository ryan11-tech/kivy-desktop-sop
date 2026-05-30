import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/admin_api_models.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/api/staff_api_client.dart';
import '../../theme/app_colors.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<PortalStaffAccount> _staff = const <PortalStaffAccount>[];
  List<PortalShop> _shops = const <PortalShop>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<StaffApiClient>();
      final results = await Future.wait([
        api.listPortalStaffAccounts(),
        api.listPortalShops(),
      ]);
      if (!mounted) return;
      setState(() {
        _staff = results[0] as List<PortalStaffAccount>;
        _shops = results[1] as List<PortalShop>;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load user access.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final visible =
        query.isEmpty
            ? _staff
            : _staff.where((staff) {
              return staff.name.toLowerCase().contains(query) ||
                  staff.email.toLowerCase().contains(query) ||
                  staff.accountRole.toLowerCase().contains(query) ||
                  staff.status.toLowerCase().contains(query);
            }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('User access'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _shops.isEmpty ? null : () => _openEditor(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add'),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
          children: [
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search email, role, or status',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_error != null)
              _StateCard(
                icon: Icons.error_outline,
                title: 'Could not load staff',
                message: _error!,
                actionLabel: 'Retry',
                onAction: _load,
              )
            else if (visible.isEmpty)
              const _StateCard(
                icon: Icons.people_outline,
                title: 'No staff found',
                message: 'Create a staff account or adjust the search.',
              )
            else
              ...visible.map(_buildStaffCard),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffCard(PortalStaffAccount staff) {
    final shopText =
        staff.accountRole == 'admin'
            ? 'Global admin'
            : staff.shops.isEmpty
            ? 'No shop assignment'
            : staff.shops
                .map((shop) => '${shop.shopName} (${_label(shop.role)})')
                .join(', ');

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    staff.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _Chip(text: staff.accountRole.toUpperCase()),
                const SizedBox(width: 6),
                _Chip(text: staff.status.toUpperCase()),
              ],
            ),
            const SizedBox(height: 4),
            Text(staff.email, style: const TextStyle(color: Colors.white60)),
            const SizedBox(height: 6),
            Text(
              shopText,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (staff.mustChangePassword)
                  const _Chip(text: 'PASSWORD CHANGE'),
                const Spacer(),
                IconButton(
                  tooltip: 'Edit',
                  onPressed: () => _openEditor(staff),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () => _confirmDelete(staff),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor([PortalStaffAccount? account]) async {
    final isCreate = account == null;
    final nameController = TextEditingController(text: account?.name ?? '');
    final emailController = TextEditingController(text: account?.email ?? '');
    final passwordController = TextEditingController();
    var accountRole = account?.accountRole ?? 'staff';
    var status = account?.status ?? 'invited';
    var mustChangePassword = account?.mustChangePassword ?? true;
    final selectedRoles = <String, String>{
      for (final membership
          in account?.shops ?? const <PortalStaffMembership>[])
        membership.shopId: membership.role,
    };
    var saving = false;
    String? localError;

    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (dialogContext, setDialogState) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: Text(
                    isCreate ? 'Create staff' : 'Edit staff',
                    style: const TextStyle(color: Colors.white),
                  ),
                  content: SizedBox(
                    width: 520,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _DialogField(
                            controller: nameController,
                            label: 'Name',
                          ),
                          const SizedBox(height: 10),
                          _DialogField(
                            controller: emailController,
                            label: 'Email',
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 10),
                          _DialogField(
                            controller: passwordController,
                            label:
                                isCreate
                                    ? 'Temporary password'
                                    : 'New password (optional)',
                            obscureText: true,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _Dropdown(
                                  label: 'Account',
                                  value: accountRole,
                                  values: const ['staff', 'admin'],
                                  onChanged:
                                      (value) => setDialogState(() {
                                        accountRole = value;
                                      }),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _Dropdown(
                                  label: 'Status',
                                  value: status,
                                  values: const [
                                    'invited',
                                    'active',
                                    'suspended',
                                  ],
                                  onChanged:
                                      (value) => setDialogState(() {
                                        status = value;
                                      }),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SwitchListTile(
                            value: mustChangePassword,
                            onChanged:
                                (value) => setDialogState(() {
                                  mustChangePassword = value;
                                }),
                            title: const Text(
                              'Force password change',
                              style: TextStyle(color: Colors.white),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (accountRole == 'staff') ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Shop memberships',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 6),
                            ..._shops.map((shop) {
                              final selected = selectedRoles.containsKey(
                                shop.id,
                              );
                              return CheckboxListTile(
                                value: selected,
                                onChanged:
                                    (value) => setDialogState(() {
                                      if (value == true) {
                                        selectedRoles[shop.id] =
                                            selectedRoles[shop.id] ?? 'cashier';
                                      } else {
                                        selectedRoles.remove(shop.id);
                                      }
                                    }),
                                title: Text(
                                  shop.name,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle:
                                    selected
                                        ? DropdownButton<String>(
                                          value: selectedRoles[shop.id],
                                          dropdownColor: AppColors.surface,
                                          isExpanded: true,
                                          items:
                                              staffRoleOptions
                                                  .map(
                                                    (role) => DropdownMenuItem(
                                                      value: role,
                                                      child: Text(_label(role)),
                                                    ),
                                                  )
                                                  .toList(),
                                          onChanged:
                                              (role) => setDialogState(() {
                                                if (role != null) {
                                                  selectedRoles[shop.id] = role;
                                                }
                                              }),
                                        )
                                        : null,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              );
                            }),
                          ],
                          if (localError != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              localError!,
                              style: const TextStyle(color: Color(0xFFFF6B6B)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          saving
                              ? null
                              : () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed:
                          saving
                              ? null
                              : () async {
                                final name = nameController.text.trim();
                                final email = emailController.text.trim();
                                final password = passwordController.text;
                                if (name.isEmpty || email.isEmpty) {
                                  setDialogState(
                                    () =>
                                        localError =
                                            'Name and email are required.',
                                  );
                                  return;
                                }
                                if (isCreate && password.length < 8) {
                                  setDialogState(
                                    () =>
                                        localError =
                                            'Temporary password must be at least 8 characters.',
                                  );
                                  return;
                                }
                                if (accountRole == 'staff' &&
                                    selectedRoles.isEmpty) {
                                  setDialogState(
                                    () =>
                                        localError =
                                            'Staff accounts need at least one shop.',
                                  );
                                  return;
                                }
                                setDialogState(() {
                                  saving = true;
                                  localError = null;
                                });
                                final api = context.read<StaffApiClient>();
                                final navigator = Navigator.of(dialogContext);
                                try {
                                  final payload = PortalStaffMutation(
                                    accountRole: accountRole,
                                    email: email,
                                    name: name,
                                    status: status,
                                    mustChangePassword: mustChangePassword,
                                    temporaryPassword:
                                        password.isEmpty ? null : password,
                                    shopMemberships:
                                        accountRole == 'admin'
                                            ? const <
                                              PortalStaffMembershipInput
                                            >[]
                                            : selectedRoles.entries
                                                .map(
                                                  (entry) =>
                                                      PortalStaffMembershipInput(
                                                        shopId: entry.key,
                                                        role: entry.value,
                                                      ),
                                                )
                                                .toList(),
                                  );
                                  if (isCreate) {
                                    await api.createPortalStaffAccount(payload);
                                  } else {
                                    await api.updatePortalStaffAccount(
                                      account.id,
                                      payload,
                                    );
                                  }
                                  if (!dialogContext.mounted) return;
                                  navigator.pop();
                                  await _load();
                                } on ApiException catch (e) {
                                  setDialogState(() {
                                    localError = e.message;
                                    saving = false;
                                  });
                                } catch (_) {
                                  setDialogState(() {
                                    localError =
                                        'Could not save staff account.';
                                    saving = false;
                                  });
                                }
                              },
                      child:
                          saving
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Save'),
                    ),
                  ],
                ),
          ),
    );

    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  Future<void> _confirmDelete(PortalStaffAccount account) async {
    final api = context.read<StaffApiClient>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text(
              'Delete staff?',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Delete ${account.email}? This removes the auth user and staff profile.',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    try {
      await api.deletePortalStaffAccount(account.id);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  String _label(String value) {
    return value.replaceAll('_', ' ');
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: AppColors.surface,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      items:
          values
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
      onChanged: (item) {
        if (item != null) onChanged(item);
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.primary, fontSize: 10),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(icon, color: Colors.white24, size: 42),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(color: Colors.white54),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
