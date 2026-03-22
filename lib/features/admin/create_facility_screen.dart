// lib/features/admin/create_facility_screen.dart
import 'package:flutter/material.dart';
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
  final _imageUrlController = TextEditingController();
  final _openHourController = TextEditingController(text: '8');
  final _closeHourController = TextEditingController(text: '22');
  final _priceController = TextEditingController();

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
                  _Field(
                      controller: _imageUrlController,
                      label: 'Image URL (optional)',
                      required: false),
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

    final success = await context.read<AdminFacilityViewModel>().createFacility({
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
                'Failed to create facility',
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