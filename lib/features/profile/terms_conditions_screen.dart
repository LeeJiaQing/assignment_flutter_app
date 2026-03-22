// lib/features/profile/terms_conditions_screen.dart
import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _SectionTitle('1. Acceptance of Terms'),
          _SectionBody(
            'By using CourtNow, you agree to these terms and conditions. '
                'If you do not agree, please do not use the application.',
          ),
          _SectionTitle('2. Bookings & Payments'),
          _SectionBody(
            'All bookings are subject to availability. Payments are processed '
                'securely. Cancellations must be made at least 24 hours before the '
                'scheduled session to receive a refund.',
          ),
          _SectionTitle('3. User Responsibilities'),
          _SectionBody(
            'Users are responsible for arriving on time and treating facilities '
                'with respect. Any damage caused to facilities may result in '
                'suspension of your account.',
          ),
          _SectionTitle('4. Privacy Policy'),
          _SectionBody(
            'We collect only the data necessary to operate the service. '
                'Your data is never sold to third parties. See our Privacy Policy '
                'for full details.',
          ),
          _SectionTitle('5. Changes to Terms'),
          _SectionBody(
            'We reserve the right to update these terms at any time. '
                'Continued use of the application after changes constitutes '
                'acceptance of the new terms.',
          ),
          SizedBox(height: 32),
          Center(
            child: Text(
              'Last updated: March 2026',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1C3A2A),
        ),
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  const _SectionBody(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        color: Colors.black87,
        height: 1.6,
      ),
    );
  }
}