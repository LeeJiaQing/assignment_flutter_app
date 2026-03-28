// lib/core/widgets/offline_banner.dart
import 'package:flutter/material.dart';

import '../services/connectivity_service.dart';

/// Slim banner shown at the top of screens when the device is offline.
/// Disappears automatically when connectivity is restored.
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner>
    with SingleTickerProviderStateMixin {
  final _connectivity = ConnectivityService.instance;
  late bool _isOnline;
  late final AnimationController _controller;
  late final Animation<double> _heightFactor;

  @override
  void initState() {
    super.initState();
    _isOnline = _connectivity.isOnline;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: _isOnline ? 0.0 : 1.0,
    );

    _heightFactor = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _connectivity.onConnectivityChanged.listen((online) {
      if (!mounted) return;
      setState(() => _isOnline = online);
      if (online) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _heightFactor,
      axisAlignment: -1,
      child: Container(
        color: const Color(0xFFE53935),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: Row(
          children: const [
            Icon(Icons.wifi_off, color: Colors.white, size: 14),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'You\'re offline — showing cached data',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wraps a [child] with an [OfflineBanner] above it in a Column.
class WithOfflineBanner extends StatelessWidget {
  const WithOfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const OfflineBanner(),
        Expanded(child: child),
      ],
    );
  }
}