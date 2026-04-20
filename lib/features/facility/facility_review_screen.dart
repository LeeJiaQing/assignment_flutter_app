// lib/features/facility/facility_review_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'viewmodels/facility_review_view_model.dart';
import 'widgets/review_card.dart';

class FacilityReviewScreen extends StatelessWidget {
  const FacilityReviewScreen({super.key, required this.facilityId});

  final String facilityId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
      FacilityReviewViewModel(facilityId: facilityId)
        ..loadReviews(),
      child: const _ReviewView(),
    );
  }
}

class _ReviewView extends StatelessWidget {
  const _ReviewView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FacilityReviewViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      appBar: AppBar(title: const Text('Reviews')),
      body: switch (vm.status) {
        ReviewStatus.initial ||
        ReviewStatus.loading =>
        const Center(child: CircularProgressIndicator()),
        ReviewStatus.error => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(vm.errorMessage ?? 'Failed to load reviews',
                  style: TextStyle(color: Colors.grey.shade600)),
              TextButton(
                onPressed: () => context
                    .read<FacilityReviewViewModel>()
                    .loadReviews(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        ReviewStatus.loaded => Column(
          children: [
            if (vm.reviews.isNotEmpty)
              _RatingSummary(
                  average: vm.averageRating,
                  count: vm.reviews.length),
            Expanded(
              child: vm.reviews.isEmpty
                  ? const Center(
                child: Text('No reviews yet.',
                    style: TextStyle(color: Colors.grey)),
              )
                  : RefreshIndicator(
                onRefresh: () => context
                    .read<FacilityReviewViewModel>()
                    .loadReviews(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vm.reviews.length,
                  itemBuilder: (_, i) =>
                      ReviewCard(review: vm.reviews[i]),
                ),
              ),
            ),
          ],
        ),
      },
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReviewSheet(context),
        icon: const Icon(Icons.rate_review_outlined),
        label: const Text('Write Review'),
        backgroundColor: const Color(0xFF1C894E),
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showReviewSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<FacilityReviewViewModel>(),
        child: const _WriteReviewSheet(),
      ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({required this.average, required this.count});
  final double average;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            average.toStringAsFixed(1),
            style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C3A2A)),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(
                  5,
                      (i) => Icon(
                    i < average.round()
                        ? Icons.star
                        : Icons.star_border,
                    color: const Color(0xFFFFC107),
                    size: 18,
                  ),
                ),
              ),
              Text(
                '$count review${count != 1 ? 's' : ''}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WriteReviewSheet extends StatefulWidget {
  const _WriteReviewSheet();

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  final _commentController = TextEditingController();
  int _rating = 5;
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Write a Review',
            style:
            TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = star),
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    star <= _rating ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFFC107),
                    size: 32,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Share your experience…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1C894E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _submitting ? null : () => _submit(context),
              child: _submitting
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : const Text('Submit Review'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a comment.')),
      );
      return;
    }

    setState(() => _submitting = true);

    final success = await context.read<FacilityReviewViewModel>().submitReview(
      rating: _rating,
      comment: _commentController.text,
    );

    if (!context.mounted) return;
    setState(() => _submitting = false);

    if (success) {
      Navigator.pop(context);
    } else {
      final error = context.read<FacilityReviewViewModel>().errorMessage;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to submit review. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}