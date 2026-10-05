import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrole/app/theme/text_styles.dart';
import 'package:scrole/shared/utils/number_formatter.dart';
import 'package:scrole/shared/widgets/app_cached_image.dart';
import '../../controllers/community/community_feed_controller.dart';
import '../../pages/community/create_community_post_screen.dart';
import '../../pages/community/community_post_search_screen.dart';

class CommunityHeader extends StatelessWidget implements PreferredSizeWidget {
  final CommunityFeedController controller;
  final VoidCallback? onMenuTap;

  const CommunityHeader({
    super.key,
    required this.controller,
    this.onMenuTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 6);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(() {
      final c = controller.community.value;
      final name = c?.name ?? (controller.communityName.value.isNotEmpty ? controller.communityName.value : 'Communauté');
      final slug = c?.slug ?? '';
      final avatarUrl = c?.avatarUrl;
      final memberCount = c?.memberCount ?? 0;
      final isPrivate = c?.visibility == 'private';

      return AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        toolbarHeight: kToolbarHeight + 6,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Community avatar opening drawer
            InkWell(
              onTap: () {
                if (onMenuTap != null) {
                  onMenuTap!();
                } else {
                  Scaffold.maybeOf(context)?.openDrawer();
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: ClipOval(
                child: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? AppCachedImage(imageUrl: avatarUrl, width: 40, height: 40, fit: BoxFit.cover)
                    : Container(
                        width: 40,
                        height: 40,
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        alignment: Alignment.center,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'C',
                          style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: AppTextStyles.h5.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.5,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (slug.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          'r/$slug',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${NumberFormatter.formatCount(memberCount)} membres • ${isPrivate ? 'Privée' : 'Publique'}',
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // ＋ Button
            InkWell(
              onTap: () {
                Get.to(
                  () => CreateCommunityPostScreen(
                    communityName: name,
                    communityId: controller.communityId,
                  ),
                  transition: Transition.rightToLeft,
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.8)),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.add, size: 20, color: colorScheme.onSurface),
              ),
            ),
            const SizedBox(width: 8),
            // 🔍 Search Button -> CommunityPostSearchScreen
            InkWell(
              onTap: () {
                Get.to(
                  () => const CommunityPostSearchScreen(),
                  arguments: controller.communityId,
                  transition: Transition.rightToLeft,
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.8)),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.search_rounded, size: 20, color: colorScheme.onSurface),
              ),
            ),
          ],
        ),
      );
    });
  }
}
