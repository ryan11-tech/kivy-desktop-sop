import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/staff/shop.dart';
import '../../core/staff/staff_session_controller.dart';
import '../../theme/app_colors.dart';

/// Two modes:
/// - [ShopSelectionMode.bootstrap] is the gated step right after login.
///   Confirming advances [StaffSessionController] to ready and the router
///   replaces the screen with the post-auth home.
/// - [ShopSelectionMode.standalone] is launched from Settings to switch
///   shops. Confirming persists and pops back.
enum ShopSelectionMode { bootstrap, standalone }

class ShopSelectionScreen extends StatefulWidget {
  const ShopSelectionScreen({super.key, this.mode = ShopSelectionMode.bootstrap});

  final ShopSelectionMode mode;

  @override
  State<ShopSelectionScreen> createState() => _ShopSelectionScreenState();
}

class _ShopSelectionScreenState extends State<ShopSelectionScreen> {
  String? _selectedId;
  bool _setAsDefault = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<StaffSessionController>().state;
    _selectedId = state.activeShop?.id;
  }

  Future<void> _confirm() async {
    if (_submitting) return;
    final controller = context.read<StaffSessionController>();
    final shops = controller.state.shops;
    final selected = shops.firstWhere(
      (s) => s.id == _selectedId,
      orElse: () => shops.first,
    );

    setState(() => _submitting = true);
    await controller.selectShop(selected, persist: _setAsDefault);
    if (!mounted) return;
    if (widget.mode == ShopSelectionMode.standalone) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StaffSessionController>().state;
    final shops = state.shops;
    final selectedId = _selectedId ?? (shops.isNotEmpty ? shops.first.id : null);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.mode == ShopSelectionMode.bootstrap
              ? 'Choose your shop'
              : 'Switch shop',
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: shops.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final shop = shops[index];
                  return _ShopTile(
                    shop: shop,
                    selected: shop.id == selectedId,
                    onTap: () => setState(() => _selectedId = shop.id),
                  );
                },
              ),
            ),
            if (widget.mode == ShopSelectionMode.bootstrap)
              SwitchListTile(
                value: _setAsDefault,
                onChanged: (v) => setState(() => _setAsDefault = v),
                title: const Text('Set as default for this device'),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton(
                onPressed: shops.isEmpty || _submitting ? null : _confirm,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopTile extends StatelessWidget {
  const _ShopTile({
    required this.shop,
    required this.selected,
    required this.onTap,
  });

  final Shop shop;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surfaceHigh : AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.primary : Colors.white38,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    if ((shop.role ?? '').isNotEmpty)
                      Text(
                        shop.role!,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
