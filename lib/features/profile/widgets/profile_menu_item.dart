// lib/features/profile/widgets/profile_menu_item.dart
import 'package:flutter/material.dart';

class ProfileMenuItem extends StatelessWidget {
  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color =
    isDestructive ? Colors.red : const Color(0xFF1C3A2A);

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withOpacity(0.1)
              : const Color(0xFFD6F0E0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : const Color(0xFF1C894E),
          size: 20,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
            color: color, fontWeight: FontWeight.w500, fontSize: 14),
      ),
      trailing:
      trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
}