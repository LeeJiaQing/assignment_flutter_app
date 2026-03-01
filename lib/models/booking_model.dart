import 'package:flutter/material.dart';

class Booking {
  int id;
  String name;
  String address;
  DateTime dateTime;
  String status;
  int userID;

  // Constructor
  Booking({
    required this.id,
    required this.name,
    required this.address,
    required this.dateTime,
    required this.status,
    required this.userID,
  });

  // Getters
  int get bookingID => id;
  String get bookingName => name;

  @override
  String toString() {
    return 'Booking #$id: $name, Status: $status, Date: $dateTime';
  }
}