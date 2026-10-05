import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/text_styles.dart';
import '../../../../shared/utils/number_formatter.dart';
import '../../../../shared/widgets/app_cached_image.dart';
import '../../centre/models/discover_models.dart';

class CommunityListTile extends StatelessWidget {
  final CommunitySuggestion community;
  final VoidCallback onTap;

  const CommunityListTile({
    super.key,
    required this.community,
    required this.onTap,
  });

  String? _formatMembersCount(int count) {
    if (count <= 0) return null;
    final formattedNum = NumberFormatter.formatCount(count);
    if (count == 1) return 'discover_members_count_one'.trParams({'count': formattedNum});
    return 'discover_members_count_plural'.trParams({'count': formattedNum});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final membersText = _formatMembersCount(community.membersCount);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: community.imageUrl != null && community.imageUrl!.isNotEmpty
                  ? AppCachedImage(
                      imageUrl: community.imageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.groups_rounded,
                        color: colorScheme.onSurfaceVariant,
                        size: 26,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    community.name,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (community.description != null &&
                      community.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      community.description!,
                      style: AppTextStyles.caption.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (membersText != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people_alt_rounded,
                          size: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          membersText,
                          style: AppTextStyles.caption.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'discover_explore_button'.tr,
                style: AppTextStyles.caption.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
