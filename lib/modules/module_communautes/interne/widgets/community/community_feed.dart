import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrole/app/theme/app_colors.dart';
import 'package:scrole/app_controller.dart';
import 'package:scrole/shared/widgets/app_cached_image.dart';
import 'package:scrole/modules/module_communautes/interne/controllers/community/community_feed_controller.dart';
import 'package:scrole/modules/module_communautes/interne/pages/community/create_community_post_screen.dart';
import 'feed_post_card.dart';

class CommunityFeed extends StatelessWidget {
  final CommunityFeedController controller;

  const CommunityFeed({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appController = Get.find<AppController>();

    return RefreshIndicator(
      onRefresh: controller.refreshFeed,
      color: colorScheme.primary,
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
            controller.loadMoreFeed();
          }
          return false;
        },
        child: Obx(() {
          final profileRaw = appController.profile.value ?? {};
          final profile = (profileRaw['profile'] is Map)
              ? Map<String, dynamic>.from(profileRaw['profile'] as Map)
              : profileRaw;
          final userAvatarUrl = profile['photo_url']?.toString() ?? '';
          final userName = profile['username']?.toString() ?? 'U';
          final communityName = controller.community.value?.name ?? controller.communityName.value;

          if (controller.isLoading.value && controller.posts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: 1 + controller.posts.length + (controller.isLoadingMore.value ? 1 : 0),
            separatorBuilder: (_, index) => const SizedBox(height: 0),
            itemBuilder: (context, index) {
              if (index == 0) {
                // Quick Composer Widget (3 distinct aligned elements: Avatar -> Input Box -> Image Icon)
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border(
                      bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.25), width: 1),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. Left: Profile photo
                      ClipOval(
                        child: userAvatarUrl.isNotEmpty
                            ? AppCachedImage(imageUrl: userAvatarUrl, width: 40, height: 40, fit: BoxFit.cover)
                            : Container(
                                width: 40,
                                height: 40,
                                color: AppColors.primary.withValues(alpha: 0.15),
                                alignment: Alignment.center,
                                child: Text(
                                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),

                      // 2. Middle: Text box resembling an input field (NO background fill)
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Get.to(
                              () => CreateCommunityPostScreen(
                                communityName: communityName,
                                communityId: controller.communityId,
                              ),
                              transition: Transition.rightToLeft,
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 42,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                            ),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Quoi de neuf ?',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 3. Right: Separated image icon button (NO background fill)
                      InkWell(
                        onTap: () {
                          Get.to(
                            () => CreateCommunityPostScreen(
                              communityName: communityName,
                              communityId: controller.communityId,
                            ),
                            transition: Transition.rightToLeft,
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                          ),
                          alignment: Alignment.center,
                          child: Icon(Icons.image_outlined, size: 22, color: colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final postIndex = index - 1;
              if (postIndex >= controller.posts.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              final post = controller.posts[postIndex];
              return FeedPostCard(
                post: post,
                onReactionTap: (reaction) => controller.toggleReaction(post.id, reaction),
                onCommentTap: () => controller.openCommentsSheet(post),
                onShareTap: () => controller.sharePost(post),
              );
            },
          );
        }),
      ),
    );
  }
}
