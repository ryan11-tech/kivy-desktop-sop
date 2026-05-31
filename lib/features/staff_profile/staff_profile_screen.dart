import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/staff/staff_profile.dart';
import '../../core/staff/staff_profile_controller.dart';
import '../../core/staff/staff_session_controller.dart';
import '../../theme/app_colors.dart';
import 'edit_staff_profile_screen.dart';

/// Read-only self-service profile. Personal info is editable via the edit
/// screen; work info is backend-controlled and shown for reference only.
class StaffProfileScreen extends StatefulWidget {
  const StaffProfileScreen({super.key});

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = context.read<StaffProfileController>();
      if (controller.profile == null &&
          controller.status != StaffProfileStatus.loading) {
        controller.load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StaffProfileController>();
    final profile = controller.profile;
    final activeShop =
        context.watch<StaffSessionController>().state.activeShop?.name;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (profile != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              tooltip: 'Edit profile',
              onPressed: () => _openEdit(context, profile),
            ),
        ],
      ),
      body: _buildBody(context, controller, profile, activeShop),
    );
  }

  Widget _buildBody(
    BuildContext context,
    StaffProfileController controller,
    StaffProfile? profile,
    String? activeShop,
  ) {
    if (profile == null) {
      if (controller.status == StaffProfileStatus.error) {
        return _ErrorState(
          message: controller.error ?? 'Could not load your profile.',
          onRetry: () => controller.load(),
        );
      }
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionLabel(text: 'PERSONAL INFO'),
            const SizedBox(height: 8),
            _ProfileCard(
              children: [
                _ProfileField(
                  label: 'Display name',
                  value: profile.displayName,
                ),
                _ProfileField(
                  label: 'Preferred name',
                  value: profile.preferredName,
                ),
                _ProfileField(label: 'Phone', value: profile.phone),
                _ProfileField(label: 'LINE ID', value: profile.lineId),
                _ProfileField(
                  label: 'Email',
                  value: profile.email,
                  hint: 'Email is managed by your manager.',
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _SectionLabel(text: 'WORK INFO'),
            const SizedBox(height: 8),
            _ProfileCard(
              children: [
                _ProfileField(label: 'Staff code', value: profile.staffCode),
                _ProfileField(
                  label: 'Role',
                  value: _humanize(profile.accountRole),
                ),
                _ProfileField(
                  label: 'Status',
                  value: _humanize(profile.status),
                ),
                _ProfileField(
                  label: 'Active shop',
                  value: activeShop,
                  isLast: profile.shops.isEmpty,
                ),
                if (profile.shops.isNotEmpty)
                  _AssignedShops(
                    shops: profile.shops,
                    accountRole: profile.accountRole,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.white38, size: 14),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Work information is managed by your manager.',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEdit(BuildContext context, StaffProfile profile) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EditStaffProfileScreen(profile: profile),
      ),
    );
  }
}

String _humanize(String? value) {
  if (value == null || value.isEmpty) return '—';
  return value
      .split(RegExp(r'[_\s]+'))
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

class _AssignedShops extends StatelessWidget {
  const _AssignedShops({required this.shops, required this.accountRole});

  final List<StaffProfileShop> shops;
  final String accountRole;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assigned shops',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 6),
          ...shops.map(
            (shop) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.storefront_outlined,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      shop.name,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  Text(
                    _humanize(shop.role ?? accountRole),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.value,
    this.hint,
    this.isLast = false,
  });

  final String label;
  final String? value;
  final String? hint;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final display = (value == null || value!.isEmpty) ? '—' : value!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border:
            isLast
                ? null
                : const Border(
                  bottom: BorderSide(color: Colors.white12, width: 1),
                ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            display,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(
              hint!,
              style: const TextStyle(color: Colors.white30, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.primary,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white38, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
