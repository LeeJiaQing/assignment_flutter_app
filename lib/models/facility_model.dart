import 'court_model.dart';

class Facility {
  final String id;
  final String name;
  final String address;
  final String imagePath;
  final List<Court> courts;

  /// Operating hours (24-hour). e.g. openHour = 8, closeHour = 22
  final int openHour;
  final int closeHour;

  /// Price per 1-hour slot in RM
  final double pricePerSlot;

  Facility({
    required this.id,
    required this.name,
    required this.address,
    required this.imagePath,
    required this.courts,
    this.openHour = 8,
    this.closeHour = 22,
    this.pricePerSlot = 8.0,
  });
}