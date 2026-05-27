import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({
    required this.correctPin,
    required this.onSuccess,
    this.appTitle = 'Kitchen Guide',
    super.key,
  });

  final String correctPin;
  final VoidCallback onSuccess;
  final String appTitle;

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _entered = '';
  String _errorMsg = '';

  @override
  Widget build(BuildContext context) {
    final pinLen = widget.correctPin.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),

            // Logo / Icon
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.local_cafe,
                color: Colors.white,
                size: 48,
              ),
            ),

            const SizedBox(height: 18),

            // App title
            Text(
              widget.appTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Enter PIN to continue',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),

            const SizedBox(height: 28),

            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pinLen, (i) {
                final filled = i < _entered.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 9),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color:
                        filled
                            ? AppColors.primary
                            : Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),

            const SizedBox(height: 8),

            // Error message
            SizedBox(
              height: 28,
              child: Text(
                _errorMsg,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),

            const SizedBox(height: 12),

            // Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Column(
                children: [
                  _KeyRow(keys: const ['1', '2', '3'], onTap: _onKey),
                  const SizedBox(height: 12),
                  _KeyRow(keys: const ['4', '5', '6'], onTap: _onKey),
                  const SizedBox(height: 12),
                  _KeyRow(keys: const ['7', '8', '9'], onTap: _onKey),
                  const SizedBox(height: 12),
                  _KeyRow(
                    keys: const ['CLR', '0', 'DEL'],
                    onTap: _onKey,
                    isSpecial: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onKey(String key) {
    setState(() {
      _errorMsg = '';
      if (key == 'CLR') {
        _entered = '';
      } else if (key == 'DEL') {
        if (_entered.isNotEmpty) {
          _entered = _entered.substring(0, _entered.length - 1);
        }
      } else {
        if (_entered.length < widget.correctPin.length) {
          _entered += key;
        }
      }

      // Auto check when full
      if (_entered.length == widget.correctPin.length) {
        if (_entered == widget.correctPin) {
          _entered = '';
          widget.onSuccess();
        } else {
          _errorMsg = 'Wrong PIN. Try again.';
          _entered = '';
        }
      }
    });
  }
}

// ── Key Row ───────────────────────────────────────────────────────────────────

class _KeyRow extends StatelessWidget {
  const _KeyRow({
    required this.keys,
    required this.onTap,
    this.isSpecial = false,
  });

  final List<String> keys;
  final void Function(String) onTap;
  final bool isSpecial;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:
          keys.map((key) {
            final isAction = key == 'CLR' || key == 'DEL';
            return _KeyBtn(
              label: key,
              isAction: isAction,
              onTap: () => onTap(key),
            );
          }).toList(),
    );
  }
}

// ── Key Button ────────────────────────────────────────────────────────────────

class _KeyBtn extends StatelessWidget {
  const _KeyBtn({
    required this.label,
    required this.onTap,
    this.isAction = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isAction;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isAction ? Colors.red : Colors.white,
            fontSize: isAction ? 13 : 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
