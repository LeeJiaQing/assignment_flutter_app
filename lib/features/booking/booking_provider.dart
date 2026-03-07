//jq
import 'package:assignment/models/booking_model.dart';
import 'package:flutter/material.dart';

//Providing change notification to its listeners
class BookingProvider extends ChangeNotifier {
  final List<Booking> bookingList = [];

  void add(Booking booking){
    bookingList.add(booking);
    notifyListeners();
  }

  void remove(Booking booking){
    bookingList.remove(booking);
    notifyListeners();
  }
}