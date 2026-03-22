// lib/features/admin/edit_facility_screen.dart
import 'package:flutter/material.dart';
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
  late final TextEditingController _imageUrlController;
  late final TextEditingController _openHourController;
  late final TextEditingController _closeHourController;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    final f = widget.facility;
    _nameController = TextEditingController(text: f.name);
    _addressController = TextEditingController(text: f.address);
    _imageUrlController = TextEditingController(text: f.imageUrl ?? '');
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
    _imageUrlController.dispose();
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
          appBar: AppBar(title: const Text('Edit Facility')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _Field(controller: _nameController, label: 'Facility Name'),
                  _Field(controller: _addressController, label: 'Address'),
                  _Field(
                    controller: _imageUrlController,
                    label: 'Image URL (optional)',
                    required: false,
                  ),
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1C894E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _submit(context),
                      child: const Text('Save Changes'),
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

    final success = await context
        .read<AdminFacilityViewModel>()
        .updateFacility(widget.facility.id, {
      'name': _nameController.text.trim(),
      'address': _addressController.text.trim(),
      'image_url': _imageUrlController.text.trim().isEmpty
          ? null
          : _imageUrlController.text.trim(),
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
                'Failed to update facility',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

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