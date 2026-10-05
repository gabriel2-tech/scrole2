import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scrole/app/theme/app_colors.dart';
import 'package:scrole/app/theme/text_styles.dart';
import 'package:scrole/shared/widgets/app_cached_image.dart';
import 'package:scrole/shared/widgets/user_certified_badge.dart';
import 'package:scrole/modules/module_communautes/centre/services/community_service.dart';
import 'package:scrole/modules/module_discussion_direct/externe/repositories/social_repository.dart';

class CommunityInviteController extends GetxController {
  final CommunityService _service = Get.find<CommunityService>();
  final SocialRepository _socialRepository = SocialRepository();
  final String communityId = Get.arguments?.toString() ?? Get.parameters['id'] ?? '';

  final contacts = <Map<String, dynamic>>[].obs;
  final filteredContacts = <Map<String, dynamic>>[].obs;
  final invitedUserIds = <String>{}.obs;
  final isLoading = true.obs;
  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadFriends();
    searchController.addListener(_filterContacts);
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadFriends() async {
    isLoading.value = true;
    try {
      final friends = await _socialRepository.getAcceptedConnections();
      contacts.value = friends;
      filteredContacts.value = friends;
    } catch (e) {
      debugPrint('[CommunityInvite] Error loading friends: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _filterContacts() {
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      filteredContacts.value = contacts;
    } else {
      filteredContacts.value = contacts.where((f) {
        final username = (f['username'] ?? f['user_profiles']?['username'] ?? '').toString().toLowerCase();
        final firstName = (f['first_name'] ?? f['user_profiles']?['first_name'] ?? '').toString().toLowerCase();
        final lastName = (f['last_name'] ?? f['user_profiles']?['last_name'] ?? '').toString().toLowerCase();
        return username.contains(query) || firstName.contains(query) || lastName.contains(query);
      }).toList();
    }
  }

  Future<void> inviteContact(String userId, String name) async {
    try {
      await _service.inviteToCommunity(communityId, userId);
      invitedUserIds.add(userId);
      Get.snackbar('Invitation envoyée', 'Invitation transmise à $name avec succès.', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Erreur', e.toString().replaceFirst('Exception: ', ''), snackPosition: SnackPosition.BOTTOM);
    }
  }
}

class CommunityInviteMemberScreen extends StatelessWidget {
  const CommunityInviteMemberScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CommunityInviteController());
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text('Inviter des membres', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: controller.searchController,
                decoration: const InputDecoration(
                  hintText: 'Rechercher un ami...',
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
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              if (controller.filteredContacts.isEmpty) {
                return Center(child: Text('Aucun ami trouvé.', style: AppTextStyles.body.copyWith(color: colors.onSurfaceVariant)));
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.filteredContacts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final f = controller.filteredContacts[index];
                  final userId = (f['user_id'] ?? f['id'] ?? '').toString();
                  final username = (f['username'] ?? f['user_profiles']?['username'] ?? 'Ami').toString();
                  final firstName = (f['first_name'] ?? f['user_profiles']?['first_name'] ?? '').toString();
                  final lastName = (f['last_name'] ?? f['user_profiles']?['last_name'] ?? '').toString();
                  final displayName = (firstName.isNotEmpty || lastName.isNotEmpty) ? '$firstName $lastName'.trim() : username;
                  final photoUrl = (f['photo_url'] ?? f['user_profiles']?['photo_url'])?.toString();
                  final isCertified = f['is_certified'] == true;
                  final isInvited = controller.invitedUserIds.contains(userId);

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: photoUrl != null && photoUrl.isNotEmpty
                              ? AppCachedImage(imageUrl: photoUrl, width: 52, height: 52, fit: BoxFit.cover)
                              : Container(
                                  width: 52,
                                  height: 52,
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  alignment: Alignment.center,
                                  child: Text(
                                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A',
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      displayName,
                                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
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
                              const SizedBox(height: 2),
                              Text(
                                '@$username',
                                style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 36,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isInvited ? colors.surfaceContainerHighest : AppColors.primary,
                              foregroundColor: isInvited ? colors.onSurfaceVariant : Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: isInvited ? null : () => controller.inviteContact(userId, displayName),
                            icon: Icon(
                              isInvited ? Icons.check_rounded : Icons.person_add_rounded,
                              size: 16,
                            ),
                            label: Text(
                              isInvited ? 'Invité' : 'Inviter',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
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
