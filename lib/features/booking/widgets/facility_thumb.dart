// lib/features/booking/widgets/facility_thumb.dart
import 'package:flutter/material.dart';

class FacilityThumb extends StatelessWidget {
  const FacilityThumb({super.key, this.imageUrl, this.height = 160});

  final String? imageUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
    height: height,
    color: const Color(0xFFD6F0E0),
    child: const Center(
      child: Icon(Icons.sports_tennis,
          size: 48, color: Color(0xFF1C894E)),
    ),
  );
}