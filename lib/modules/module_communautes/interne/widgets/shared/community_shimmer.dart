import 'package:flutter/material.dart';

import '../../../../../shared/widgets/shimmer.dart';

class CommunityShimmer extends StatelessWidget {
  const CommunityShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 4,
      itemBuilder: (_, __) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonShimmer(
                width: double.infinity,
                height: 140,
                borderRadius: 20,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SkeletonShimmer(width: 48, height: 48, borderRadius: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonShimmer(width: 140, height: 18, borderRadius: 4),
                              const SizedBox(height: 8),
                              SkeletonShimmer(width: 80, height: 14, borderRadius: 4),
                            ],
                          ),
                        ),
                        SkeletonShimmer(width: 80, height: 32, borderRadius: 16),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SkeletonShimmer(width: double.infinity, height: 14, borderRadius: 4),
                    const SizedBox(height: 6),
                    SkeletonShimmer(width: 200, height: 14, borderRadius: 4),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        SkeletonShimmer(width: 60, height: 24, borderRadius: 12),
                        const SizedBox(width: 8),
                        SkeletonShimmer(width: 60, height: 24, borderRadius: 12),
                        const SizedBox(width: 8),
                        SkeletonShimmer(width: 60, height: 24, borderRadius: 12),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}