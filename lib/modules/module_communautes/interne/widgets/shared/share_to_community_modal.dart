import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrole/app/theme/app_colors.dart';
import 'package:scrole/shared/widgets/scrole_bottom_sheet.dart';
import '../../../centre/models/community_post.dart';
import '../../pages/community/create_community_post_screen.dart';

class ShareToCommunityModal extends StatelessWidget {
  final CommunityPost post;
  final List<String> userCommunities;

  const ShareToCommunityModal({
    super.key,
    required this.post,
    required this.userCommunities,
  });

  void _onCommunitySelected(String communityName) {
    Get.back();
    Get.to(
      () => CreateCommunityPostScreen(
        communityName: communityName,
        prefilledText: post.content,
        prefilledMediaUrl: post.media.isNotEmpty ? post.media.first.url : null,
      ),
      transition: Transition.rightToLeft,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScroleBottomSheet(
      showCancel: true,
      cancelLabel: 'cancel'.tr,
      child: ScroleBottomSheetGroup(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Publier dans une communauté',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sélectionnez la communauté cible pour reposter',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const ScroleBottomSheetDivider(),
          if (userCommunities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Vous ne faites partie d\'aucune communauté pour le moment.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            )
          else
            ...userCommunities.map((name) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScroleBottomSheetAction(
                    icon: Icons.groups_rounded,
                    label: 'r/$name',
                    color: AppColors.primary,
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onTap: () => _onCommunitySelected(name),
                  ),
                  if (name != userCommunities.last) const ScroleBottomSheetDivider(),
                ],
              );
            }),
        ],
      ),
    );
  }
}
