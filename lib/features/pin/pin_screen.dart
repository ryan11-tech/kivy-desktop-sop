import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({
    required this.pinLength,
    required this.onSubmit,
    required this.onSuccess,
    this.appTitle = 'Kitchen Guide',
    super.key,
  });

  final int pinLength;
  final Future<String?> Function(String pin) onSubmit;
  final VoidCallback onSuccess;
  final String appTitle;

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _entered = '';
  String _errorMsg = '';
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    const SizedBox(height: 60),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(widget.pinLength, (i) {
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
                    SizedBox(
                      height: 28,
                      child: Text(
                        _errorMsg,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                    if (_submitting)
                      const Padding(
                        padding: EdgeInsets.only(top: 36),
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    else
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
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _onKey(String key) {
    if (_submitting) return;
    setState(() {
      _errorMsg = '';
      if (key == 'CLR') {
        _entered = '';
      } else if (key == 'DEL') {
        if (_entered.isNotEmpty) {
          _entered = _entered.substring(0, _entered.length - 1);
        }
      } else {
        if (_entered.length < widget.pinLength) {
          _entered += key;
        }
      }
    });

    if (_entered.length == widget.pinLength) {
      _submitPin(_entered);
    }
  }

  Future<void> _submitPin(String pin) async {
    setState(() => _submitting = true);
    final error = await widget.onSubmit(pin);
    if (!mounted) return;
    if (error == null) {
      setState(() {
        _entered = '';
        _submitting = false;
      });
      widget.onSuccess();
      return;
    }
    setState(() {
      _errorMsg = error;
      _entered = '';
      _submitting = false;
    });
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({required this.keys, required this.onTap});

  final List<String> keys;
  final void Function(String) onTap;

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
