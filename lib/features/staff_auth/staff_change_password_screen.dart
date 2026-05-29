import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exceptions.dart';
import '../../core/staff/staff_session_controller.dart';
import '../../theme/app_colors.dart';

class StaffChangePasswordScreen extends StatefulWidget {
  const StaffChangePasswordScreen({super.key});

  @override
  State<StaffChangePasswordScreen> createState() =>
      _StaffChangePasswordScreenState();
}

class _StaffChangePasswordScreenState extends State<StaffChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateStrength(String? value) {
    final v = value ?? '';
    if (v.length < 8) return 'At least 8 characters.';
    if (!RegExp(r'[A-Za-z]').hasMatch(v)) return 'Include a letter.';
    if (!RegExp(r'\d').hasMatch(v)) return 'Include a number.';
    return null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_newController.text != _confirmController.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final controller = context.read<StaffSessionController>();
    try {
      await controller.submitPasswordChange(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      );
    } on UnauthorizedException {
      setState(() => _error = 'Session expired. Sign in again.');
    } on ClientApiException catch (e) {
      setState(() => _error = e.message);
    } on NetworkException {
      setState(() => _error = 'No internet connection. Try again.');
    } on ServerApiException {
      setState(() => _error = 'Server error. Please try again shortly.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Set a new password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'For security, choose a new password. Your temporary password will be replaced.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _currentController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current (temporary) password',
                    ),
                    validator:
                        (v) =>
                            (v ?? '').isEmpty
                                ? 'Current password is required.'
                                : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _newController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New password',
                    ),
                    validator: _validateStrength,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm new password',
                    ),
                    validator:
                        (v) =>
                            (v ?? '').isEmpty ? 'Confirm your password.' : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: Color(0xFFFF6B6B),
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child:
                        _submitting
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('Update password'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
