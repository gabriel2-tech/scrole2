import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:scrole/modules/module_communautes/interne/controllers/community/community_management_controller.dart';
import 'package:scrole/modules/module_communautes/interne/enums/community_role_enum.dart' as role_enum;
import 'community_info_settings_screen.dart';
import 'community_publication_settings_screen.dart';
import 'community_moderation_center_screen.dart';

class CommunitySettingsMainScreen extends GetView<CommunityManagementController> {
  const CommunitySettingsMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? communityId = controller.communityId.value;

    return Scaffold(
      appBar: AppBar(title: Text('community_settings_title'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _SettingsCategoryTile(
            icon: Icons.info_outline,
            title: 'Informations',
            subtitle: 'Nom, description, visibilité et photos',
            onTap: () {
              if (communityId != null) {
                Get.to(() => const CommunityInfoHubScreen(), arguments: communityId);
              }
            },
          ),
          const SizedBox(height: 10),
          _SettingsCategoryTile(
            icon: Icons.post_add_outlined,
            title: 'Publication',
            subtitle: 'Permissions de publication et approbation',
            onTap: () {
              if (communityId != null) {
                Get.to(() => const CommunityPublicationSettingsScreen(), arguments: communityId);
              }
            },
          ),
          const SizedBox(height: 10),
          _SettingsCategoryTile(
            icon: Icons.security_rounded,
            title: 'Centre de modération',
            subtitle: 'Publications, adhésions, alertes, spam et signalements',
            onTap: () {
              if (communityId != null) {
                Get.to(() => const CommunityModerationCenterScreen(), arguments: communityId);
              }
            },
          ),
          const SizedBox(height: 10),

          // --- Zone de danger (Suppression) ---
          Obx(() {
            if (controller.currentUserRole.value != role_enum.CommunityRole.admin) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Text(
                  'Zone de danger',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _SettingsCategoryTile(
                  icon: Icons.delete_forever_outlined,
                  title: 'Supprimer la communauté',
                  subtitle: 'Cette action est irréversible',
                  iconColor: Theme.of(context).colorScheme.error,
                  onTap: () => _showDeleteConfirmation(context),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Text('community_delete_dialog_title'.tr),
        content: Text('community_delete_dialog_content'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteCommunity();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text('community_delete_confirm'.tr),
          ),
        ],
      ),
    );
  }
}

class _SettingsCategoryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  const _SettingsCategoryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: iconColor ?? colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.bodyMedium?.copyWith(
                      fontSize: 14, 
                      fontWeight: FontWeight.w600,
                      color: iconColor,
                    )),
                    const SizedBox(height: 2),
                    Text(subtitle, style: textTheme.bodySmall?.copyWith(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
