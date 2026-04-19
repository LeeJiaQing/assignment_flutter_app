// lib/features/admin/create_facility_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/repositories/facility_repository.dart';
import 'viewmodels/admin_facility_view_model.dart';

class CreateFacilityScreen extends StatefulWidget {
  const CreateFacilityScreen({super.key});

  @override
  State<CreateFacilityScreen> createState() => _CreateFacilityScreenState();
}

class _CreateFacilityScreenState extends State<CreateFacilityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _openHourController = TextEditingController(text: '8');
  final _closeHourController = TextEditingController(text: '22');
  final _priceController = TextEditingController();
  final _picker = ImagePicker();
  XFile? _selectedImage;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _openHourController.dispose();
    _closeHourController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          AdminFacilityViewModel(facilityRepository: FacilityRepository()),
      child: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(title: const Text('Create Facility')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _Field(
                      controller: _nameController, label: 'Facility Name'),
                  _Field(controller: _addressController, label: 'Address'),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Facility Photo (optional)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _ImagePickerRow(
                    selectedImageName: _selectedImage?.name,
                    onPickPressed: _pickImage,
                    onClearPressed: _selectedImage == null
                        ? null
                        : () => setState(() => _selectedImage = null),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _Field(
                          controller: _openHourController,
                          label: 'Open Hour (0–23)',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Field(
                          controller: _closeHourController,
                          label: 'Close Hour (0–23)',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  _Field(
                    controller: _priceController,
                    label: 'Price per Slot (RM)',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1C894E),
                        foregroundColor: Colors.white,
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _submit(context),
                      child: const Text('Create Facility'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    String? uploadedImagePath;
    if (_selectedImage != null) {
      final imageBytes = await _selectedImage!.readAsBytes();
      uploadedImagePath = await context
          .read<AdminFacilityViewModel>()
          .uploadFacilityImage(bytes: imageBytes, fileName: _selectedImage!.name);
      if (uploadedImagePath == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<AdminFacilityViewModel>().errorMessage ??
                  'Failed to upload image',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final success = await context.read<AdminFacilityViewModel>().createFacility({
      'name': _nameController.text.trim(),
      'address': _addressController.text.trim(),
      'image_url': uploadedImagePath,
      'open_hour': int.parse(_openHourController.text.trim()),
      'close_hour': int.parse(_closeHourController.text.trim()),
      'price_per_slot': double.parse(_priceController.text.trim()),
    });

    if (!context.mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<AdminFacilityViewModel>().errorMessage ??
                'Failed to create facility',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;
    setState(() => _selectedImage = image);
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.required = true,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool required;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }
}

class _ImagePickerRow extends StatelessWidget {
  const _ImagePickerRow({
    required this.selectedImageName,
    required this.onPickPressed,
    this.onClearPressed,
  });

  final String? selectedImageName;
  final VoidCallback onPickPressed;
  final VoidCallback? onClearPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            selectedImageName ?? 'No photo selected',
            style: TextStyle(
              color: selectedImageName == null ? Colors.grey : Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: onPickPressed,
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Pick Photo'),
        ),
        if (onClearPressed != null) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: onClearPressed,
            icon: const Icon(Icons.close),
            tooltip: 'Clear photo',
          ),
        ],
      ],
    );
  }
}
