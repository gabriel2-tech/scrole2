import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:scrole/app/theme/text_styles.dart';
import 'package:scrole/shared/widgets/app_cached_image.dart';
import 'package:scrole/shared/widgets/scrole_bottom_sheet.dart';
import 'package:scrole/shared/utils/number_formatter.dart';
import '../../../centre/services/community_service.dart';
import '../../controllers/community/community_feed_controller.dart';
import '../../controllers/community/settings/community_settings_controller.dart';
import '../../enums/community_role_enum.dart' as role_enum;
import '../../widgets/community/community_feed.dart';
import '../../widgets/community/community_header.dart';
import 'settings/community_settings_main_screen.dart';
import 'community_roles_screen.dart';
import 'settings/community_invite_member_screen.dart';
import 'platform_popular_posts_screen.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  late final CommunityFeedController feedController;
  late final String cId;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    cId = Get.parameters['id'] ?? '';
    feedController = Get.put(CommunityFeedController(Get.find<CommunityService>(), cId), tag: cId);
    if (!Get.isRegistered<CommunityFeedController>()) {
      Get.put(feedController);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: CommunityDrawer(controller: feedController),
      appBar: CommunityHeader(
        controller: feedController,
        onMenuTap: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      body: CommunityFeed(controller: feedController),
    );
  }
}

class CommunityDrawer extends StatelessWidget {
  final CommunityFeedController controller;

  const CommunityDrawer({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: colorScheme.surface,
      child: Obx(() {
        final c = controller.community.value;
        final name = c?.name ?? (controller.communityName.value.isNotEmpty ? controller.communityName.value : 'Communauté');
        final coverUrl = c?.bannerUrl;
        final avatarUrl = c?.avatarUrl;
        final memberCount = c?.memberCount ?? 0;
        final role = controller.currentUserRole.value;
        final isStaff = role == role_enum.CommunityRole.admin || role == role_enum.CommunityRole.moderator;

        return Column(
          children: [
            // Top Section (Header with cover background, avatar, name, members)
            Container(
              height: 230 + MediaQuery.of(context).padding.top,
              padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 20, 16, 20),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                image: coverUrl != null && coverUrl.isNotEmpty
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(coverUrl),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.45), BlendMode.darken),
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      ClipOval(
                        child: avatarUrl != null && avatarUrl.isNotEmpty
                            ? AppCachedImage(imageUrl: avatarUrl, width: 72, height: 72, fit: BoxFit.cover)
                            : Container(
                                width: 72,
                                height: 72,
                                color: colorScheme.primary,
                                alignment: Alignment.center,
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'C',
                                  style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                                ),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: AppTextStyles.h4.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${NumberFormatter.formatCount(memberCount)} membres',
                              style: AppTextStyles.body.copyWith(color: Colors.white70, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Middle Section (Scrollable items)
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: Icon(Icons.trending_up_rounded, color: colorScheme.primary),
                    title: Text('Ranking / Posts populaires', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                    onTap: () {
                      Get.back();
                      Get.to(() => const PlatformPopularPostsScreen(), transition: Transition.rightToLeft);
                    },
                  ),
                  const Divider(height: 1),
                  if (isStaff) ...[
                    ListTile(
                      leading: Icon(Icons.admin_panel_settings_rounded, color: colorScheme.primary),
                      title: Text('Gestion de la communauté', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                      onTap: () {
                        Get.back();
                        Get.to(() => const CommunitySettingsMainScreen(), arguments: controller.communityId);
                      },
                    ),
                    const Divider(height: 1),
                  ],
                  ListTile(
                    leading: Icon(Icons.group_rounded, color: colorScheme.onSurface),
                    title: Text('Voir la liste des membres', style: AppTextStyles.bodyLarge),
                    onTap: () {
                      Get.back();
                      if (!Get.isRegistered<CommunitySettingsController>()) {
                        Get.put(CommunitySettingsController(controller.communityId));
                      }
                      Get.to(() => const CommunityRolesScreen());
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.person_add_rounded, color: colorScheme.onSurface),
                    title: Text('Inviter un membre', style: AppTextStyles.bodyLarge),
                    onTap: () {
                      Get.back();
                      Get.to(() => const CommunityInviteMemberScreen(), arguments: controller.communityId);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.share_rounded, color: colorScheme.onSurface),
                    title: Text('Partager la communauté', style: AppTextStyles.bodyLarge),
                    onTap: () {
                      Get.back();
                      controller.shareCommunity();
                    },
                  ),
                ],
              ),
            ),

            // Bottom Section (Far down at the bottom: Report & Leave)
            const Divider(height: 1, thickness: 1),
            ListTile(
              leading: Icon(Icons.flag_rounded, color: colorScheme.outline),
              title: Text('Signaler la communauté', style: AppTextStyles.bodyLarge.copyWith(color: colorScheme.outline)),
              onTap: () {
                Get.back();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Signalement pris en compte.')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout_rounded, color: colorScheme.error),
              title: Text('Quitter la communauté', style: AppTextStyles.bodyLarge.copyWith(color: colorScheme.error, fontWeight: FontWeight.bold)),
              onTap: () {
                Get.back();
                ScroleBottomSheet.show(
                  context: context,
                  showCancel: true,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Quitter la communauté ?', style: AppTextStyles.h4),
                      const SizedBox(height: 8),
                      Text('Voulez-vous vraiment quitter $name ?', style: AppTextStyles.bodySmall),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error),
                        onPressed: () {
                          Get.back();
                          controller.leaveCommunity();
                        },
                        child: const Text('Quitter', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        );
      }),
    );
  }
}
