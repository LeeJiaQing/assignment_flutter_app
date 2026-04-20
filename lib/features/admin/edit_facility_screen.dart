// lib/features/admin/edit_facility_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/repositories/facility_repository.dart';
import '../../models/facility_model.dart';
import 'viewmodels/admin_facility_view_model.dart';

class EditFacilityScreen extends StatefulWidget {
  const EditFacilityScreen({super.key, required this.facility});

  final Facility facility;

  @override
  State<EditFacilityScreen> createState() => _EditFacilityScreenState();
}

class _EditFacilityScreenState extends State<EditFacilityScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _courtCountController;
  late final TextEditingController _openHourController;
  late final TextEditingController _closeHourController;
  late final TextEditingController _priceController;

  final _picker = ImagePicker();
  XFile? _selectedImage;

  // Track whether the admin explicitly wants to clear the existing image
  bool _clearExistingImage = false;

  @override
  void initState() {
    super.initState();
    final f = widget.facility;
    _nameController = TextEditingController(text: f.name);
    _addressController = TextEditingController(text: f.address);
    _courtCountController = TextEditingController(
      text: f.courts.length.toString(),
    );
    _openHourController =
        TextEditingController(text: f.openHour.toString());
    _closeHourController =
        TextEditingController(text: f.closeHour.toString());
    _priceController =
        TextEditingController(text: f.pricePerSlot.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _courtCountController.dispose();
    _openHourController.dispose();
    _closeHourController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;
    setState(() {
      _selectedImage = image;
      _clearExistingImage = false;
    });
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _clearExistingImage = true;
    });
  }

  /// Returns a short display label for the current photo state.
  String get _photoLabel {
    if (_selectedImage != null) return _selectedImage!.name;
    if (_clearExistingImage) return 'No photo (cleared)';
    final url = widget.facility.imageUrl;
    if (url != null && url.isNotEmpty) return 'Current photo kept';
    return 'No photo selected';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          AdminFacilityViewModel(facilityRepository: FacilityRepository()),
      child: Builder(builder: (context) {
        final vm = context.watch<AdminFacilityViewModel>();
        return Scaffold(
          appBar: AppBar(title: const Text('Edit Facility')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Field(
                      controller: _nameController, label: 'Facility Name'),
                  _Field(controller: _addressController, label: 'Address'),
                  _Field(
                    controller: _courtCountController,
                    label: 'Court Count (e.g. 5)',
                    keyboardType: TextInputType.number,
                  ),

                  // ── Photo picker ────────────────────────────────────────
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: double.infinity,
                      height: 140,
                      child: _selectedImage != null
                          ? Image.file(
                              File(_selectedImage!.path),
                              fit: BoxFit.cover,
                            )
                          : (widget.facility.imageUrl ?? '').isNotEmpty &&
                                  !_clearExistingImage
                              ? Image.network(
                                  widget.facility.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                )
                              : Image.asset(
                                  'assets/images/logo.png',
                                  fit: BoxFit.contain,
                                ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ImagePickerRow(
                    label: _photoLabel,
                    onPickPressed: _pickImage,
                    onClearPressed:
                    (_selectedImage != null ||
                        (!_clearExistingImage &&
                            (widget.facility.imageUrl ?? '').isNotEmpty))
                        ? _clearImage
                        : null,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _Field(
                          controller: _openHourController,
                          label: 'Open Hour',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Field(
                          controller: _closeHourController,
                          label: 'Close Hour',
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

                  if (vm.errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        vm.errorMessage!,
                        style:
                        TextStyle(color: Colors.red.shade700, fontSize: 13),
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1C894E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      onPressed:
                      vm.status == AdminFacilityStatus.loading
                          ? null
                          : () => _submit(context, vm),
                      child: vm.status == AdminFacilityStatus.loading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                          : const Text('Save Changes'),
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

  Future<void> _submit(
      BuildContext context, AdminFacilityViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;
    final courtCount = int.tryParse(_courtCountController.text.trim());
    if (courtCount == null || courtCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Court count must be a number greater than 0'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ── Resolve final image URL ───────────────────────────────────────────
    String? finalImageUrl = widget.facility.imageUrl;

    if (_selectedImage != null) {
      // Upload new photo
      final imageBytes = await _selectedImage!.readAsBytes();
      final uploaded = await vm.uploadFacilityImage(
          bytes: imageBytes, fileName: _selectedImage!.name);
      if (uploaded == null) {
        // uploadFacilityImage already sets vm.errorMessage
        return;
      }
      finalImageUrl = uploaded;
    } else if (_clearExistingImage) {
      finalImageUrl = null;
    }
    // else: keep existing URL unchanged

    final success = await vm.updateFacility(widget.facility.id, {
      'name': _nameController.text.trim(),
      'address': _addressController.text.trim(),
      'image_url': finalImageUrl,
      'open_hour': int.parse(_openHourController.text.trim()),
      'close_hour': int.parse(_closeHourController.text.trim()),
      'price_per_slot': double.parse(_priceController.text.trim()),
      'court_names':
          List<String>.generate(courtCount, (index) => 'Court ${index + 1}'),
    });

    if (!context.mounted) return;
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Facility updated successfully!'),
          backgroundColor: Color(0xFF1C894E),
        ),
      );
    }
    // On failure, vm.errorMessage is shown in the UI above the button.
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.required = true,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
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
    required this.label,
    required this.onPickPressed,
    this.onClearPressed,
  });

  final String label;
  final VoidCallback onPickPressed;
  final VoidCallback? onClearPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: label.contains('No photo')
                  ? Colors.grey
                  : Colors.black87,
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
