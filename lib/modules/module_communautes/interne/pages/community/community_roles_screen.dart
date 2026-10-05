import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrole/app/routes/app_pages.dart';
import 'package:scrole/app/theme/text_styles.dart';
import 'package:scrole/modules/module_authentification/centre/services/auth_service.dart';
import 'package:scrole/modules/module_communautes/interne/controllers/community/settings/community_settings_controller.dart';
import 'package:scrole/modules/module_communautes/interne/pages/community/settings/community_role_edit_screen.dart';
import 'package:scrole/shared/widgets/user_certified_badge.dart';

class CommunityRolesScreen extends GetView<CommunitySettingsController> {
  const CommunityRolesScreen({super.key});

  void _navigateToRoleEdit(String userId, String displayName, String currentRole, String photoUrl) {
    Get.to(() => const CommunityRoleEditScreen(), arguments: {
      'userId': userId,
      'displayName': displayName,
      'currentRole': currentRole,
      'photoUrl': photoUrl,
    });
  }

  void _showMemberModerationPopup(
    BuildContext context,
    String userId,
    String displayName,
    String rawRole,
    String photoUrl,
    bool isAdmin,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        alignment: Alignment.center,
        child: Container(
          width: 280,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  displayName,
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(height: 1),
              _PopupMenuItem(
                title: 'Voir le profil',
                onTap: () {
                  Navigator.of(ctx).pop();
                  Get.toNamed(AppPages.externalProfilePath(userId));
                },
              ),
              if (isAdmin) ...[
                _PopupMenuItem(
                  title: 'Promouvoir / Modifier le rôle',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _navigateToRoleEdit(userId, displayName, rawRole, photoUrl);
                  },
                ),
                _PopupMenuItem(
                  title: 'Retirer de la communauté',
                  textColor: colorScheme.error,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Get.dialog(
                      AlertDialog(
                        title: const Text('Retirer ce membre ?'),
                        content: Text('Voulez-vous vraiment retirer $displayName de la communauté ?'),
                        actions: [
                          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
                          ElevatedButton(
                            onPressed: () {
                              Get.back();
                              controller.removeMember(userId);
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error, foregroundColor: Colors.white),
                            child: const Text('Retirer'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final searchQuery = ''.obs;
    final currentUserId = Get.isRegistered<AuthService>() ? Get.find<AuthService>().userId : null;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text('community_members_title'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: (v) => searchQuery.value = v,
                decoration: const InputDecoration(
                  hintText: 'Rechercher un membre...',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              bool isAdmin = false;
              if (currentUserId != null) {
                final selfMember = controller.members.firstWhereOrNull((m) {
                  final profile = m['user_profiles'] is Map ? Map<String, dynamic>.from(m['user_profiles']) : <String, dynamic>{};
                  final uid = profile['user_id']?.toString() ?? profile['id']?.toString() ?? m['user_id']?.toString() ?? m['userId']?.toString() ?? '';
                  return uid == currentUserId;
                });
                if (selfMember != null) {
                  final selfRole = (selfMember['role'] ?? '').toString().toLowerCase();
                  isAdmin = selfRole == 'admin' || selfRole == 'moderator';
                }
              }

              final query = searchQuery.value.trim().toLowerCase();
              final allMembers = controller.members;
              final filtered = allMembers.where((m) {
                if (query.isEmpty) return true;
                final profile = m['user_profiles'] is Map ? Map<String, dynamic>.from(m['user_profiles']) : <String, dynamic>{};
                final username = profile['username']?.toString().toLowerCase() ?? '';
                final firstName = profile['first_name']?.toString().toLowerCase() ?? '';
                final lastName = profile['last_name']?.toString().toLowerCase() ?? '';
                final displayName = '$firstName $lastName'.trim();
                return username.contains(query) || displayName.contains(query);
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    'Aucun membre trouvé',
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 15),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtered.length,
                separatorBuilder: (_, index) => Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
                itemBuilder: (context, index) {
                  final member = filtered[index];
                  final profile = member['user_profiles'] is Map ? Map<String, dynamic>.from(member['user_profiles']) : <String, dynamic>{};
                  final userId = profile['user_id']?.toString() ?? profile['id']?.toString() ?? member['user_id']?.toString() ?? member['userId']?.toString() ?? '';
                  final username = profile['username']?.toString() ?? '';
                  final firstName = profile['first_name']?.toString() ?? '';
                  final lastName = profile['last_name']?.toString() ?? '';
                  final displayName = firstName.isNotEmpty || lastName.isNotEmpty ? '$firstName $lastName'.trim() : (username.isNotEmpty ? username : 'Membre');
                  final photoUrl = profile['photo_url']?.toString();
                  final isCertified = profile['is_certified'] == true || profile['is_certified'] == 1 || profile['is_certified']?.toString() == 'true' || member['is_certified'] == true || member['is_certified'] == 1 || member['is_certified']?.toString() == 'true';

                  final rawRole = (member['role'] ?? '').toString().toLowerCase();
                  String roleLabel = 'Membre';
                  if (rawRole == 'admin') {
                    roleLabel = 'Administrateur';
                  } else if (rawRole == 'moderator' || rawRole == 'modérateur') {
                    roleLabel = 'Modérateur';
                  }

                  final isSelf = currentUserId != null && currentUserId == userId;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                      backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null || photoUrl.isEmpty
                          ? Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold))
                          : null,
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCertified) ...[
                          const SizedBox(width: 4),
                          const UserCertifiedBadge(size: 14),
                        ],
                      ],
                    ),
                    subtitle: Text('$roleLabel • @$username', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                    onTap: () {
                      if (!isSelf && userId.isNotEmpty) {
                        Get.toNamed(AppPages.externalProfilePath(userId));
                      }
                    },
                    onLongPress: () {
                      if (isAdmin && !isSelf) {
                        _showMemberModerationPopup(context, userId, displayName, rawRole, photoUrl ?? '', isAdmin);
                      }
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _PopupMenuItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final Color? textColor;

  const _PopupMenuItem({
    required this.title,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: textColor ?? colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
