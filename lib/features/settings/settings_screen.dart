import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/staff/staff_session_controller.dart';
import '../../theme/app_colors.dart';
import '../staff_auth/shop_selection_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({this.isAdmin = false, super.key});

  final bool isAdmin;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDark = true;
  String _primaryHex = '#8B0000';
  String _fontSize = 'Medium';
  String _language = 'English';
  bool _pinEnabled = true;

  late final TextEditingController _primaryHexController =
      TextEditingController(text: _primaryHex);

  @override
  void dispose() {
    _primaryHexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StaffSessionController>().state;
    final user = state.user;
    final hasMultipleShops = state.shops.length > 1;
    final activeName = state.activeShop?.name ?? 'Not selected';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 32),
        children: [
          const _SectionLabel(text: 'ACCOUNT'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              if (user != null)
                _InfoRow(
                  icon: Icons.person_outline,
                  title:
                      user.displayName.isEmpty ? user.email : user.displayName,
                  subtitle: user.email,
                ),
              if (user != null) const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.storefront_outlined,
                title: 'Active shop',
                subtitle: activeName,
                trailing:
                    hasMultipleShops
                        ? const Icon(Icons.chevron_right, color: Colors.white38)
                        : null,
                onTap:
                    hasMultipleShops
                        ? () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder:
                                (_) => const ShopSelectionScreen(
                                  mode: ShopSelectionMode.standalone,
                                ),
                          ),
                        )
                        : null,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      () => context.read<StaffSessionController>().signOut(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF6B6B),
                    side: const BorderSide(color: Color(0x55FF6B6B)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const _SectionLabel(text: 'THEME'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              const _FieldLabel(text: 'DISPLAY MODE'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _PillBtn(
                      label: 'Dark',
                      isSelected: _isDark,
                      onTap: () => setState(() => _isDark = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PillBtn(
                      label: 'Light',
                      isSelected: !_isDark,
                      onTap: () => setState(() => _isDark = false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              const _FieldLabel(text: 'PRIMARY COLOR'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _primaryHexController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceHigh,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) => setState(() => _primaryHex = value),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _parseColor(_primaryHex),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              const _FieldLabel(text: 'QUICK SELECT'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    const [
                      '#8B0000',
                      '#C9A84C',
                      '#E8A020',
                      '#A8A8B0',
                      '#22B55A',
                      '#2278E8',
                    ].map((hex) {
                      return GestureDetector(
                        onTap: () => _setPrimaryHex(hex),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _parseColor(hex),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                _primaryHex == hex
                                    ? Border.all(color: Colors.white, width: 2)
                                    : null,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const _SectionLabel(text: 'DISPLAY'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              const _FieldLabel(text: 'FONT SIZE'),
              const SizedBox(height: 8),
              Row(
                children:
                    ['Small', 'Medium', 'Large'].map((size) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _PillBtn(
                            label: size,
                            isSelected: _fontSize == size,
                            onTap: () => setState(() => _fontSize = size),
                          ),
                        ),
                      );
                    }).toList(),
              ),

              const SizedBox(height: 16),

              const _FieldLabel(text: 'LANGUAGE'),
              const SizedBox(height: 8),
              Row(
                children:
                    ['English', 'Myanmar'].map((lang) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _PillBtn(
                            label: lang,
                            isSelected: _language == lang,
                            onTap: () => setState(() => _language = lang),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const _SectionLabel(text: 'SECURITY'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'PIN Lock',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _pinEnabled
                              ? const Color(0xFF22B55A)
                              : Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _pinEnabled ? 'ENABLED' : 'DISABLED',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _pinEnabled ? 'Required on app start' : 'App opens without PIN',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _PillBtn(
                      label: 'Enable',
                      isSelected: _pinEnabled,
                      activeColor: const Color(0xFF22B55A),
                      onTap: () => setState(() => _pinEnabled = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PillBtn(
                      label: 'Disable',
                      isSelected: !_pinEnabled,
                      activeColor: Colors.red,
                      onTap: _confirmDisablePin,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _pinEnabled ? _showChangePinDialog : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        _pinEnabled ? Colors.white : Colors.white24,
                    side: BorderSide(
                      color: _pinEnabled ? Colors.white38 : Colors.white12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Change PIN'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'SAVE AND APPLY',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 12),

          OutlinedButton(
            onPressed: _resetDefaults,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white38,
              side: const BorderSide(color: Colors.white12),
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Reset to Default'),
          ),
        ],
      ),
    );
  }

  void _setPrimaryHex(String hex) {
    _primaryHexController.value = TextEditingValue(
      text: hex,
      selection: TextSelection.collapsed(offset: hex.length),
    );
    setState(() => _primaryHex = hex);
  }

  void _saveSettings() {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Saved', style: TextStyle(color: Colors.white)),
            content: const Text(
              'Settings saved! Restart app to apply fully.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _resetDefaults() {
    _primaryHexController.value = const TextEditingValue(
      text: '#8B0000',
      selection: TextSelection.collapsed(offset: 7),
    );
    setState(() {
      _isDark = true;
      _primaryHex = '#8B0000';
      _fontSize = 'Medium';
      _language = 'English';
      _pinEnabled = true;
    });
  }

  void _confirmDisablePin() {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text(
              'Disable PIN Lock',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Anyone can open the app without a PIN.\nAre you sure?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white38),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() => _pinEnabled = false);
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Yes, Disable'),
              ),
            ],
          ),
    );
  }

  void _showChangePinDialog() {
    final curCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String errorMsg = '';

    showDialog<void>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setLocal) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text(
                    'Change PIN',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PinField(controller: curCtrl, label: 'Current PIN'),
                      const SizedBox(height: 8),
                      _PinField(controller: newCtrl, label: 'New PIN'),
                      const SizedBox(height: 8),
                      _PinField(
                        controller: confirmCtrl,
                        label: 'Confirm New PIN',
                      ),
                      if (errorMsg.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          errorMsg,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white38),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (newCtrl.text.length < 4) {
                          setLocal(
                            () => errorMsg = 'PIN must be at least 4 digits.',
                          );
                          return;
                        }
                        if (newCtrl.text != confirmCtrl.text) {
                          setLocal(() => errorMsg = 'New PINs do not match.');
                          return;
                        }
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('PIN changed successfully!'),
                            backgroundColor: Color(0xFF22B55A),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
          ),
    ).whenComplete(() {
      curCtrl.dispose();
      newCtrl.dispose();
      confirmCtrl.dispose();
    });
  }

  Color _parseColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _PillBtn extends StatelessWidget {
  const _PillBtn({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.activeColor,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final active = activeColor ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? active : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white38,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  const _PinField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          obscureText: true,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
