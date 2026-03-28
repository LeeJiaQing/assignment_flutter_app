// lib/core/widgets/cached_facility_image.dart
import 'dart:io';

import 'package:flutter/material.dart';

import '../local/image_cache_service.dart';

/// Drop-in replacement for facility images.
///
/// If a locally-cached file exists it is shown immediately.
/// Otherwise the image is fetched from [remoteUrl] and cached for future use.
/// Shows a green placeholder when both sources fail (offline, no cache).
class CachedFacilityImage extends StatefulWidget {
  const CachedFacilityImage({
    super.key,
    required this.facilityId,
    required this.remoteUrl,
    this.height = 160,
    this.width = double.infinity,
    this.fit = BoxFit.cover,
  });

  final String facilityId;
  final String remoteUrl;
  final double height;
  final double width;
  final BoxFit fit;

  @override
  State<CachedFacilityImage> createState() => _CachedFacilityImageState();
}

class _CachedFacilityImageState extends State<CachedFacilityImage> {
  final _imageCache = ImageCacheService.instance;
  late Future<String?> _pathFuture;

  @override
  void initState() {
    super.initState();
    _pathFuture =
        _imageCache.resolve(widget.facilityId, widget.remoteUrl);
  }

  @override
  void didUpdateWidget(CachedFacilityImage old) {
    super.didUpdateWidget(old);
    if (old.remoteUrl != widget.remoteUrl ||
        old.facilityId != widget.facilityId) {
      _pathFuture =
          _imageCache.resolve(widget.facilityId, widget.remoteUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _pathFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _placeholder(showSpinner: true);
        }

        final path = snapshot.data;
        if (path == null) return _placeholder();

        final file = File(path);

        // Local file exists → display it
        if (file.existsSync()) {
          return Image.file(
            file,
            height: widget.height,
            width: widget.width,
            fit: widget.fit,
            errorBuilder: (_, __, ___) => _placeholder(),
          );
        }

        // Path resolved but file gone → fall back to network
        return Image.network(
          widget.remoteUrl,
          height: widget.height,
          width: widget.width,
          fit: widget.fit,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      },
    );
  }

  Widget _placeholder({bool showSpinner = false}) => Container(
    height: widget.height,
    width: widget.width,
    color: const Color(0xFFD6F0E0),
    child: Center(
      child: showSpinner
          ? const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF1C894E),
        ),
      )
          : const Icon(Icons.sports_tennis,
          size: 48, color: Color(0xFF1C894E)),
    ),
  );
}

/// Null-safe wrapper: renders [CachedFacilityImage] when [remoteUrl] is
/// non-null, otherwise falls back to the green placeholder directly.
class FacilityImageWithCache extends StatelessWidget {
  const FacilityImageWithCache({
    super.key,
    required this.facilityId,
    this.remoteUrl,
    this.height = 160,
  });

  final String facilityId;
  final String? remoteUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (remoteUrl == null || remoteUrl!.isEmpty) {
      return _Placeholder(height: height);
    }
    return CachedFacilityImage(
      facilityId: facilityId,
      remoteUrl: remoteUrl!,
      height: height,
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    color: const Color(0xFFD6F0E0),
    child: const Center(
      child: Icon(Icons.sports_tennis,
          size: 48, color: Color(0xFF1C894E)),
    ),
  );
}