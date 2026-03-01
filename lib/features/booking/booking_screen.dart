import 'package:flutter/material.dart';
import '../../models/booking_model.dart';

final List<Booking> test = [
  Booking(
  id: 1,
  name: "Haircut",
  address: "123 Street",
  dateTime: DateTime(2026, 3, 1, 14, 30),
  status: "Booked",
  userID: 1001,
  ),
  Booking(
    id: 2,
    name: "Haircut",
    address: "123 Street",
    dateTime: DateTime(2026, 3, 1, 14, 30),
    status: "Booked",
    userID: 1001,
  ),
  Booking(
    id: 3,
    name: "Haircut",
    address: "123 Street",
    dateTime: DateTime(2026, 3, 1, 14, 30),
    status: "Booked",
    userID: 1001,
  ),
];

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});
  final String image = 'assets/images/facility/facility.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 10),
          const Text(
            "My Bookings",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C894E),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFC8DFC3),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: test.length,
                itemBuilder: (context, index) {
                  final booking = test[index];
                  return Column(
                    children: [
                      BookingCard(
                        status: booking.status,
                        facilityImage: image,
                        facilityName: booking.name,
                        dateTime: booking.dateTime,
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  final String status;
  final String facilityImage;
  final String facilityName;
  final DateTime dateTime;

  const BookingCard({
    super.key,
    required this.status,
    required this.facilityImage,
    required this.facilityName,
    required this.dateTime,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;

    switch (status) {
      case "Booked":
        statusColor = Colors.green;
        break;
      case "Pending":
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.red;
    }

    // Format date and time nicely
    String formattedDate =
        "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}";
    String formattedTime =
        "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(facilityImage),
          Text("Facility: $facilityName"),
          Text("Date: $formattedDate"),
          Text("Time: $formattedTime"),
          Text("Status: $status", style: TextStyle(color: statusColor)),
        ],
      ),
    );
  }
}