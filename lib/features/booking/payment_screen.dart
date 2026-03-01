import 'package:flutter/material.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6DCC98);

    return Scaffold(
      backgroundColor: const Color(0xFFC8DFC3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC8DFC3),
        elevation: 0,
        title: const Text("Payment Details",
            style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          /// Booking Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Facility: Arena Pickleball Court 1"),
                Text("Date: 23/2/2026"),
                Text("Time: 10:00 AM - 11:00 AM"),
                Text("Total: RM 8.00"),
              ],
            ),
          ),

          const SizedBox(height: 30),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Select Payment Method",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),

          const SizedBox(height: 10),

          RadioListTile(
            value: 1,
            groupValue: 1,
            onChanged: (value) {},
            title: const Text("Touch 'n Go eWallet"),
          ),
          RadioListTile(
            value: 2,
            groupValue: 1,
            onChanged: (value) {},
            title: const Text("Credit/Debit Card"),
          ),
          RadioListTile(
            value: 3,
            groupValue: 1,
            onChanged: (value) {},
            title: const Text("Online Banking"),
          ),

          const Spacer(),

          /// Make Payment Button
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {},
              child: const Text("Make Payment  RM 16.00",
                  style: TextStyle(color: Colors.black)),
            ),
          )
        ],
      ),
    );
  }
}