import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/staff/staff_profile.dart';
import '../../core/staff/staff_profile_controller.dart';
import '../../core/staff/staff_session_controller.dart';
import '../../theme/app_colors.dart';

/// Edits the four self-service fields. On save it updates the profile
/// controller and the session user, then returns to the profile screen.
class EditStaffProfileScreen extends StatefulWidget {
  const EditStaffProfileScreen({required this.profile, super.key});

  final StaffProfile profile;

  @override
  State<EditStaffProfileScreen> createState() => _EditStaffProfileScreenState();
}

class _EditStaffProfileScreenState extends State<EditStaffProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayName;
  late final TextEditingController _preferredName;
  late final TextEditingController _phone;
  late final TextEditingController _lineId;

  @override
  void initState() {
    super.initState();
    _displayName = TextEditingController(text: widget.profile.displayName);
    _preferredName = TextEditingController(
      text: widget.profile.preferredName ?? '',
    );
    _phone = TextEditingController(text: widget.profile.phone ?? '');
    _lineId = TextEditingController(text: widget.profile.lineId ?? '');
  }

  @override
  void dispose() {
    _displayName.dispose();
    _preferredName.dispose();
    _phone.dispose();
    _lineId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.watch<StaffProfileController>().saving;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: saving ? null : () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Field(
                  controller: _displayName,
                  label: 'Display name',
                  maxLength: 80,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Display name is required';
                    }
                    if (value!.trim().length > 80) {
                      return 'Display name must be 80 characters or fewer';
                    }
                    return null;
                  },
                ),
                _Field(
                  controller: _preferredName,
                  label: 'Preferred name',
                  maxLength: 80,
                  textInputAction: TextInputAction.next,
                  validator: (value) => _maxLen(value, 80, 'Preferred name'),
                ),
                _Field(
                  controller: _phone,
                  label: 'Phone',
                  maxLength: 40,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: (value) => _maxLen(value, 40, 'Phone'),
                ),
                _Field(
                  controller: _lineId,
                  label: 'LINE ID',
                  maxLength: 80,
                  textInputAction: TextInputAction.done,
                  validator: (value) => _maxLen(value, 80, 'LINE ID'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Email and work information are managed by your manager.',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      saving
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            'SAVE',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _maxLen(String? value, int max, String label) {
    if ((value ?? '').trim().length > max) {
      return '$label must be $max characters or fewer';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final profileController = context.read<StaffProfileController>();
    final session = context.read<StaffSessionController>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final saved = await profileController.save(
      StaffProfileUpdate(
        displayName: _displayName.text,
        preferredName: _preferredName.text,
        phone: _phone.text,
        lineId: _lineId.text,
      ),
    );

    if (!mounted) return;

    if (saved == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            profileController.saveError ?? 'Could not save your profile.',
          ),
        ),
      );
      return;
    }

    await session.applyProfileUpdate(
      displayName: saved.displayName,
      preferredName: saved.preferredName,
      phone: saved.phone,
      lineId: saved.lineId,
    );

    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Profile updated.'),
        backgroundColor: Color(0xFF22B55A),
      ),
    );
    navigator.pop();
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.maxLength,
    this.validator,
    this.keyboardType,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final int maxLength;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            maxLength: maxLength,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              counterText: '',
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
      ),
    );
  }
}
