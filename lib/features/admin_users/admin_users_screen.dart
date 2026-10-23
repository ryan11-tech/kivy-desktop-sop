import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api/admin_api_models.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/api/staff_api_client.dart';
import '../../core/staff/staff_session_controller.dart';
import '../../core/staff/staff_user.dart';
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

  /// Account id whose new one-time password is being requested. While set,
  /// the key buttons are disabled and the screen cannot be left, so the
  /// password dialog always gets shown.
  String? _issuingFor;

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

    return PopScope(
      canPop: _issuingFor == null,
      child: Scaffold(
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
                Padding(
                  padding: const EdgeInsets.only(top: 80),
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
                if (!_isSignedInUser(staff))
                  IconButton(
                    tooltip: 'New one-time password',
                    onPressed:
                        _issuingFor == null
                            ? () => _confirmNewOneTimePassword(staff)
                            : null,
                    icon:
                        _issuingFor == staff.id
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.key_outlined),
                  ),
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
    final caller = _signedInUser;
    final saved = await showDialog<_EditorSaved>(
      context: context,
      // A pending Save must not be dismissed: a create's one-time password
      // is only ever shown after the dialog pops with it.
      barrierDismissible: false,
      builder:
          (_) => _StaffEditorDialog(
            account: account,
            shops: _shops,
            api: context.read<StaffApiClient>(),
            isOwnAccount: account != null && _isSignedInUser(account),
            // Unknown caller (no session) keeps the hint.
            showLiftSuspensionHint: caller?.isAdmin != true,
          ),
    );
    if (saved == null || !mounted) return;
    final reload = _load();
    final created = saved.created;
    if (created != null) {
      await _showOneTimePassword(
        created.staff.name.isEmpty ? saved.name : created.staff.name,
        created.oneTimePassword,
      );
    }
    await reload;
  }

  /// Whether [account] belongs to the signed-in user, who cannot give
  /// themselves a new one-time password. False when no session is available.
  bool _isSignedInUser(PortalStaffAccount account) {
    final user = _signedInUser;
    if (user == null) return false;
    if (user.staffProfileId.isNotEmpty && user.staffProfileId == account.id) {
      return true;
    }
    return user.id.isNotEmpty && user.id == account.userId;
  }

  /// The signed-in staff user, or null when no session is available.
  StaffUser? get _signedInUser =>
      Provider.of<StaffSessionController?>(context, listen: false)?.state.user;

  Future<void> _confirmNewOneTimePassword(PortalStaffAccount account) async {
    if (_issuingFor != null) return;
    final api = context.read<StaffApiClient>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text(
              'New one-time password?',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'This signs ${account.name} out on every device. '
              'Their current password stops working.',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('New password'),
              ),
            ],
          ),
    );
    // A second tap that queued its own confirm dialog is ignored here.
    if (confirmed != true || !mounted || _issuingFor != null) return;

    setState(() => _issuingFor = account.id);
    final PortalOneTimePassword issued;
    try {
      issued = await api.issuePortalStaffOneTimePassword(account.id);
    } on ApiException catch (e) {
      _endIssuing();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    } catch (_) {
      _endIssuing();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not make a one-time password.')),
      );
      return;
    }
    _endIssuing();
    if (!mounted) return;
    final reload = _load();
    await _showOneTimePassword(account.name, issued);
    await reload;
  }

  void _endIssuing() {
    if (!mounted) return;
    setState(() => _issuingFor = null);
  }

  /// Shows a one-time password once. It lives only in this dialog: never
  /// stored, logged, or kept after the dialog closes.
  Future<void> _showOneTimePassword(
    String personName,
    PortalOneTimePassword otp,
  ) async {
    final expiresAt = otp.expiresAt;
    final expiryText =
        expiresAt == null
            ? otp.expiresAtText
            : '${formatBangkokDateTime(expiresAt)} (Bangkok time)';
    var copied = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => StatefulBuilder(
            // Only Done closes it (system back is ignored), so the password
            // is not lost by accident.
            builder:
                (dialogContext, setDialogState) => PopScope(
                  canPop: false,
                  child: AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: const Text(
                      'One-time password',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: SizedBox(
                      width: 420,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'For $personName',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceHigh,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: SelectableText(
                              otp.password,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Expires $expiryText',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Give this to the person. They sign in at the staff '
                            'clock page and set their own password. It works '
                            'once, for 7 days.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: otp.password),
                          );
                          if (!dialogContext.mounted) return;
                          setDialogState(() => copied = true);
                        },
                        icon: Icon(copied ? Icons.check : Icons.copy),
                        label: Text(copied ? 'Copied' : 'Copy'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
          ),
    );
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
}

/// Formats an instant as Asia/Bangkok wall time, e.g. `Oct 31, 2026, 14:05`.
///
/// Bangkok is UTC+7 all year (no daylight saving), so a fixed offset is exact
/// and the device's own time zone does not matter.
@visibleForTesting
String formatBangkokDateTime(DateTime instant) {
  final bangkok = instant.toUtc().add(const Duration(hours: 7));
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = bangkok.hour.toString().padLeft(2, '0');
  final minute = bangkok.minute.toString().padLeft(2, '0');
  return '${months[bangkok.month - 1]} ${bangkok.day}, ${bangkok.year}, '
      '$hour:$minute';
}

String _label(String value) {
  return value.replaceAll('_', ' ');
}

/// What the editor dialog pops with after a successful save.
class _EditorSaved {
  const _EditorSaved({required this.name, this.created});

  final String name;

  /// Set after a create: the new account and its one-time password.
  final PortalStaffCreateResult? created;
}

/// Create / edit dialog. Owns its text controllers so they are disposed only
/// after the dialog route is fully gone.
class _StaffEditorDialog extends StatefulWidget {
  const _StaffEditorDialog({
    required this.account,
    required this.shops,
    required this.api,
    required this.isOwnAccount,
    required this.showLiftSuspensionHint,
  });

  final PortalStaffAccount? account;
  final List<PortalShop> shops;
  final StaffApiClient api;

  /// The signed-in user's own account: no Active / Suspended switch.
  final bool isOwnAccount;

  /// Shows "Only an admin can lift a suspension." (hidden for admins).
  final bool showLiftSuspensionHint;

  @override
  State<_StaffEditorDialog> createState() => _StaffEditorDialogState();
}

class _StaffEditorDialogState extends State<_StaffEditorDialog> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.account?.name ?? '',
  );
  late final TextEditingController _emailController = TextEditingController(
    text: widget.account?.email ?? '',
  );
  final TextEditingController _reasonController = TextEditingController();
  late String _accountRole = widget.account?.accountRole ?? 'staff';
  late final bool _wasSuspended = widget.account?.status == 'suspended';
  late bool _suspended = _wasSuspended;
  late final Map<String, String> _selectedRoles = <String, String>{
    for (final membership
        in widget.account?.shops ?? const <PortalStaffMembership>[])
      membership.shopId: membership.role,
  };
  bool _reasonChecked = false;
  bool _saving = false;
  String? _error;

  bool get _isCreate => widget.account == null;
  bool get _suspending => _suspended && !_wasSuspended;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty || email.isEmpty) {
      setState(() => _error = 'Name and email are required.');
      return;
    }
    if (_accountRole == 'staff' && _selectedRoles.isEmpty) {
      setState(() => _error = 'Staff accounts need at least one shop.');
      return;
    }
    if (_suspending && validateSuspendReason(_reasonController.text) != null) {
      setState(() {
        _reasonChecked = true;
        _error = null;
      });
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final navigator = Navigator.of(context);
    final payload = PortalStaffMutation(
      accountRole: _accountRole,
      email: email,
      name: name,
      // Only sent when it changes; the server turns 'active' into invited /
      // active by itself.
      status:
          _suspended == _wasSuspended
              ? null
              : _suspended
              ? 'suspended'
              : 'active',
      statusReason: _suspending ? _reasonController.text.trim() : null,
      shopMemberships:
          _accountRole == 'admin'
              ? const <PortalStaffMembershipInput>[]
              : _selectedRoles.entries
                  .map(
                    (entry) => PortalStaffMembershipInput(
                      shopId: entry.key,
                      role: entry.value,
                    ),
                  )
                  .toList(),
    );
    try {
      final account = widget.account;
      if (account == null) {
        final created = await widget.api.createPortalStaffAccount(payload);
        if (!mounted) return;
        navigator.pop(_EditorSaved(name: name, created: created));
        return;
      }
      await widget.api.updatePortalStaffAccount(account.id, payload);
      if (!mounted) return;
      navigator.pop(_EditorSaved(name: name));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _saving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not save staff account.';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    final reasonLength = suspendReasonLength(_reasonController.text);
    // Back / Escape cannot close the dialog while Save is pending; the pop
    // with the result still goes through (Navigator.pop ignores PopScope).
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          _isCreate ? 'Create staff' : 'Edit staff',
          style: const TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DialogField(controller: _nameController, label: 'Name'),
                const SizedBox(height: 10),
                _DialogField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _Dropdown(
                  label: 'Account',
                  value: _accountRole,
                  values: const ['staff', 'admin'],
                  onChanged: (value) => setState(() => _accountRole = value),
                ),
                if (account == null) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'No password to type. After saving you get a one-time '
                    'password to give them.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ] else ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text(
                        'Status',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(width: 8),
                      _Chip(text: 'NOW ${account.status.toUpperCase()}'),
                    ],
                  ),
                  if (!widget.isOwnAccount) ...[
                    const SizedBox(height: 8),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: false,
                          label: Text('Active'),
                          icon: Icon(Icons.check_circle_outline),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text('Suspended'),
                          icon: Icon(Icons.block),
                        ),
                      ],
                      selected: {_suspended},
                      onSelectionChanged:
                          _saving
                              ? null
                              : (selection) =>
                                  setState(() => _suspended = selection.first),
                    ),
                    if (_suspending) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _reasonController,
                        minLines: 2,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white),
                        // Rebuild so the inline error follows the text once Save
                        // was tried.
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Reason',
                          helperText: 'Signs them out on every device.',
                          // Counted like the server (trimmed, UTF-16), not with
                          // maxLength, which counts graphemes and truncates.
                          counterText: '$reasonLength/$suspendReasonMaxLength',
                          counterStyle: TextStyle(
                            color:
                                reasonLength > suspendReasonMaxLength
                                    ? const Color(0xFFFF6B6B)
                                    : Colors.white54,
                            fontSize: 12,
                          ),
                          errorText:
                              _reasonChecked
                                  ? validateSuspendReason(
                                    _reasonController.text,
                                  )
                                  : null,
                          filled: true,
                          fillColor: AppColors.surfaceHigh,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                    if (!_suspended &&
                        _wasSuspended &&
                        widget.showLiftSuspensionHint) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Only an admin can lift a suspension.',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ],
                ],
                if (_accountRole == 'staff') ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Shop memberships',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  ...widget.shops.map((shop) {
                    final selected = _selectedRoles.containsKey(shop.id);
                    return CheckboxListTile(
                      value: selected,
                      onChanged:
                          (value) => setState(() {
                            if (value == true) {
                              _selectedRoles[shop.id] =
                                  _selectedRoles[shop.id] ?? 'cashier';
                            } else {
                              _selectedRoles.remove(shop.id);
                            }
                          }),
                      title: Text(
                        shop.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle:
                          selected
                              ? DropdownButton<String>(
                                value: _selectedRoles[shop.id],
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
                                    (role) => setState(() {
                                      if (role != null) {
                                        _selectedRoles[shop.id] = role;
                                      }
                                    }),
                              )
                              : null,
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  }),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFFF6B6B)),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child:
                _saving
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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
        style: TextStyle(color: AppColors.primary, fontSize: 10),
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
