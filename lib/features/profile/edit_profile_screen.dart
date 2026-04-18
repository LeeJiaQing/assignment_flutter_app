// lib/features/profile/edit_profile_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'viewmodels/profile_view_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  bool _initialised = false;

  // Image state
  File? _pickedImage;        // local file chosen from gallery
  String? _existingAvatarUrl; // current remote URL (if any)
  bool _uploadingImage = false;
  bool _removeAvatar = false; // user tapped "Remove photo"

  final _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _init(ProfileViewModel vm) {
    if (_initialised) return;
    _nameController = TextEditingController(text: vm.profile?.fullName ?? '');
    _existingAvatarUrl = vm.profile?.avatarUrl;
    _initialised = true;
  }

  // ── Pick image from gallery ────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final result = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,   // compress a bit to save bandwidth
      maxWidth: 512,
      maxHeight: 512,
    );
    if (result == null) return;
    setState(() {
      _pickedImage = File(result.path);
      _removeAvatar = false;
    });
  }

  void _removePhoto() {
    setState(() {
      _pickedImage = null;
      _removeAvatar = true;
    });
  }

  // ── Save ───────────────────────────────────────────────────────────────────
  Future<void> _save(BuildContext context, ProfileViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _uploadingImage = true);

    String? finalAvatarUrl = _existingAvatarUrl;

    // Upload new image if user picked one
    if (_pickedImage != null) {
      final uploaded = await vm.uploadAvatar(_pickedImage!);
      if (uploaded == null && context.mounted) {
        setState(() => _uploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload image. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      finalAvatarUrl = uploaded;
    } else if (_removeAvatar) {
      finalAvatarUrl = null;
    }

    setState(() => _uploadingImage = false);

    final success = await vm.updateProfile(
      fullName: _nameController.text.trim(),
      avatarUrl: finalAvatarUrl,
    );

    if (!context.mounted) return;
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Color(0xFF1C894E),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'Update failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    _init(vm);

    final bool isBusy = _uploadingImage || vm.status == ProfileStatus.loading;

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFFF4FAF6),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // ── Avatar picker ────────────────────────────────────────────
              _AvatarPicker(
                pickedImage: _pickedImage,
                existingAvatarUrl:
                _removeAvatar ? null : _existingAvatarUrl,
                onPick: _pickImage,
                onRemove: (_pickedImage != null ||
                    (!_removeAvatar &&
                        _existingAvatarUrl != null &&
                        _existingAvatarUrl!.isNotEmpty))
                    ? _removePhoto
                    : null,
              ),

              const SizedBox(height: 32),

              // ── Full name field ──────────────────────────────────────────
              _buildLabel('Full Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration(
                  hint: 'Enter your full name',
                  icon: Icons.person_outline,
                ),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),

              const SizedBox(height: 32),

              // ── Save button ──────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C894E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: isBusy ? null : () => _save(context, vm),
                  child: isBusy
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : const Text(
                    'Save Changes',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1C3A2A),
      ),
    ),
  );

  InputDecoration _inputDecoration(
      {required String hint, required IconData icon}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: const Color(0xFF1C894E), size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1C894E), width: 1.5),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}

// ── Avatar Picker Widget ───────────────────────────────────────────────────

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.pickedImage,
    required this.existingAvatarUrl,
    required this.onPick,
    this.onRemove,
  });

  final File? pickedImage;
  final String? existingAvatarUrl;
  final VoidCallback onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            // Avatar display
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFF1C894E).withOpacity(0.3), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(child: _buildAvatarContent()),
            ),

            // Camera button overlay
            GestureDetector(
              onTap: onPick,
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFF1C894E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt,
                    color: Colors.white, size: 18),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.photo_library_outlined, size: 16),
              label: const Text('Change Photo',
                  style: TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1C894E)),
            ),
            if (onRemove != null) ...[
              const Text('·', style: TextStyle(color: Colors.grey)),
              TextButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Remove', style: TextStyle(fontSize: 13)),
                style:
                TextButton.styleFrom(foregroundColor: Colors.red.shade400),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarContent() {
    // Priority: newly picked local file > existing remote URL > placeholder
    if (pickedImage != null) {
      return Image.file(pickedImage!,
          width: 110, height: 110, fit: BoxFit.cover);
    }
    if (existingAvatarUrl != null && existingAvatarUrl!.isNotEmpty) {
      return Image.network(
        existingAvatarUrl!,
        width: 110,
        height: 110,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
    color: const Color(0xFFD6F0E0),
    child: const Icon(Icons.person, size: 60, color: Color(0xFF1C894E)),
  );
}