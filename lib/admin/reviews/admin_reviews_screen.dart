import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:keychain_shop/models/review_model.dart';
import 'package:keychain_shop/services/firestore_service.dart';
import 'package:keychain_shop/theme/app_theme.dart';
import 'package:keychain_shop/utils/formatters.dart';

enum _ReviewFilter { all, pending, approved }

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  _ReviewFilter _filter = _ReviewFilter.all;

  Future<void> _setApproved(ReviewModel review, bool approved) async {
    try {
      await context
          .read<FirestoreService>()
          .setReviewApproved(review.id, approved);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  Future<void> _delete(ReviewModel review) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete review?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<FirestoreService>().deleteReview(review.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SegmentedButton<_ReviewFilter>(
            segments: const [
              ButtonSegment(value: _ReviewFilter.all, label: Text('All')),
              ButtonSegment(
                value: _ReviewFilter.pending,
                label: Text('Pending'),
              ),
              ButtonSegment(
                value: _ReviewFilter.approved,
                label: Text('Approved'),
              ),
            ],
            selected: {_filter},
            onSelectionChanged: (s) => setState(() => _filter = s.first),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ReviewModel>>(
            stream: context.read<FirestoreService>().watchAllReviews(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              var reviews = snapshot.data ?? [];
              switch (_filter) {
                case _ReviewFilter.pending:
                  reviews = reviews.where((r) => !r.isApproved).toList();
                case _ReviewFilter.approved:
                  reviews = reviews.where((r) => r.isApproved).toList();
                case _ReviewFilter.all:
                  break;
              }

              if (reviews.isEmpty) {
                return const Center(child: Text('No reviews found.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: reviews.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    title: Text(
                      '${review.userName ?? 'Customer'} · '
                      '${review.rating.toStringAsFixed(1)}★',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${review.comment}\n'
                      'Product ${review.productId.length > 8 ? review.productId.substring(0, 8) : review.productId}'
                      ' · ${Formatters.date(review.createdAt)}'
                      '${review.isApproved ? '' : ' · Pending'}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'approve':
                            _setApproved(review, true);
                          case 'reject':
                            _setApproved(review, false);
                          case 'delete':
                            _delete(review);
                        }
                      },
                      itemBuilder: (context) => [
                        if (!review.isApproved)
                          const PopupMenuItem(
                            value: 'approve',
                            child: Text('Approve'),
                          ),
                        if (review.isApproved)
                          const PopupMenuItem(
                            value: 'reject',
                            child: Text('Unapprove'),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
