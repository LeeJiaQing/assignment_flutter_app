// lib/models/facility_model.dart

class Court {
  final String id;
  final String facilityId;
  final String name;

  const Court({
    required this.id,
    required this.facilityId,
    required this.name,
  });

  factory Court.fromJson(Map<String, dynamic> json) => Court(
    id: json['id'] as String,
    facilityId: json['facility_id'] as String,
    name: json['name'] as String,
  );
}

class Facility {
  final String id;
  final String name;
  final String address;
  final String? imageUrl;
  final int openHour;
  final int closeHour;
  final double pricePerSlot;
  final String category;
  final List<Court> courts;

  const Facility({
    required this.id,
    required this.name,
    required this.address,
    this.imageUrl,
    required this.openHour,
    required this.closeHour,
    required this.pricePerSlot,
    this.category = 'Other',
    this.courts = const [],
  });

  factory Facility.fromJson(Map<String, dynamic> json) => Facility(
    id: json['id'] as String,
    name: json['name'] as String,
    address: json['address'] as String,
    imageUrl: json['image_url'] as String?,
    openHour: json['open_hour'] as int,
    closeHour: json['close_hour'] as int,
    pricePerSlot: (json['price_per_slot'] as num).toDouble(),
    category: (json['category'] as String?) ?? 'Other',
    courts: (json['courts'] as List<dynamic>? ?? [])
        .map((c) => Court.fromJson(c as Map<String, dynamic>))
        .toList(),
  );
}
