import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:scrole/app/theme/text_styles.dart';
import 'package:scrole/modules/module_communautes/centre/services/community_service.dart';
import 'package:scrole/modules/module_communautes/interne/enums/community_role_enum.dart' as role_enum;
import 'package:scrole/shared/widgets/app_cached_image.dart';
import 'package:scrole/shared/widgets/media_gallery_sheet.dart';
import 'community_interests_screen.dart';

class CommunityInfoSettingsController extends GetxController {
  final CommunityService _service = Get.find<CommunityService>();
  final String communityId;

  CommunityInfoSettingsController(this.communityId);

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final RxString visibility = 'public'.obs; // 'public' or 'private'
  final RxBool isLoading = false.obs;
  final Rxn<role_enum.CommunityRole> currentUserRole = Rxn<role_enum.CommunityRole>();

  final avatarImage = Rxn<File>();
  final bannerImage = Rxn<File>();
  final RxString avatarUrl = ''.obs;
  final RxString bannerUrl = ''.obs;

  bool get isAdmin => currentUserRole.value == role_enum.CommunityRole.admin;

  @override
  void onInit() {
    super.onInit();
    _loadInfo();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final membership = await _service.getMembership(communityId);
      if (membership != null) {
        final roleStr = (membership['role'] ?? membership['role_name'] ?? membership['name'] ?? '').toString().toLowerCase();
        if (roleStr == 'admin') {
          currentUserRole.value = role_enum.CommunityRole.admin;
        } else if (roleStr == 'moderator' || roleStr == 'modérateur') {
          currentUserRole.value = role_enum.CommunityRole.moderator;
        } else {
          currentUserRole.value = role_enum.CommunityRole.member;
        }
      } else {
        currentUserRole.value = role_enum.CommunityRole.member;
      }
    } catch (_) {
      currentUserRole.value = role_enum.CommunityRole.member;
    }
  }

  Future<void> _loadInfo() async {
    try {
      isLoading.value = true;
      final c = await _service.getCommunityById(communityId);
      if (c != null) {
        nameController.text = c.name;
        descriptionController.text = c.description ?? '';
        visibility.value = c.visibility.isNotEmpty ? c.visibility : 'public';
        avatarUrl.value = c.avatarUrl ?? '';
        bannerUrl.value = c.bannerUrl ?? '';
      }
    } catch (e) {
      debugPrint('[CommunityInfoSettingsController] load error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void removeAvatar() {
    if (!isAdmin) return;
    avatarImage.value = null;
    avatarUrl.value = '';
  }

  void removeBanner() {
    if (!isAdmin) return;
    bannerImage.value = null;
    bannerUrl.value = '';
  }

  Future<void> saveTextInfo() async {
    if (!isAdmin) return;
    try {
      isLoading.value = true;
      final name = nameController.text.trim();
      final desc = descriptionController.text.trim();
      final vis = visibility.value;
      final manualApproval = vis == 'private';

      if (name.isEmpty) {
        Get.snackbar('Erreur', 'Le nom ne peut pas être vide.');
        return;
      }

      await _service.updateCommunityInfo(
        id: communityId,
        name: name,
        description: desc,
        photoProfile: avatarUrl.value.isNotEmpty ? avatarUrl.value : null,
        photoCover: bannerUrl.value.isNotEmpty ? bannerUrl.value : null,
      );

      await _service.updateCommunitySettings(
        communityId: communityId,
        visibility: vis,
        requireManualApproval: manualApproval,
      );

      Get.back();
      Get.snackbar('Succès', 'Informations textuelles mises à jour.');
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de mettre à jour les informations.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveMediaInfo() async {
    if (!isAdmin) return;
    try {
      isLoading.value = true;
      String? uploadedAvatarUrl;
      String? uploadedBannerUrl;

      if (avatarImage.value != null) {
        uploadedAvatarUrl = await _service.uploadCommunityAvatar(avatarImage.value!, communityId);
      }
      if (bannerImage.value != null) {
        uploadedBannerUrl = await _service.uploadCommunityBanner(bannerImage.value!, communityId);
      }

      await _service.updateCommunityInfo(
        id: communityId,
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        photoProfile: uploadedAvatarUrl ?? (avatarUrl.value.isNotEmpty ? avatarUrl.value : null),
        photoCover: uploadedBannerUrl ?? (bannerUrl.value.isNotEmpty ? bannerUrl.value : null),
      );

      Get.back();
      Get.snackbar('Succès', 'Photos mises à jour.');
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de mettre à jour les photos.');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}

class CommunityInfoHubScreen extends StatelessWidget {
  const CommunityInfoHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final String communityId = Get.arguments?.toString() ?? Get.parameters['id'] ?? '';
    if (communityId.isNotEmpty && !Get.isRegistered<CommunityInfoSettingsController>()) {
      Get.put(CommunityInfoSettingsController(communityId));
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Informations de la communauté', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HubCategoryTile(
            icon: Icons.text_fields_rounded,
            title: 'Nom, description et visibilité',
            subtitle: 'Modifier le nom, la description et les règles d\'adhésion/visibilité',
            onTap: () => Get.to(() => const CommunityTextInfoScreen()),
          ),
          const SizedBox(height: 12),
          _HubCategoryTile(
            icon: Icons.image_rounded,
            title: 'Photos de profil et de couverture',
            subtitle: 'Modifier l\'avatar et la bannière de la communauté',
            onTap: () => Get.to(() => const CommunityMediaInfoScreen()),
          ),
          const SizedBox(height: 12),
          _HubCategoryTile(
            icon: Icons.interests_rounded,
            title: 'Centres d\'intérêt',
            subtitle: 'Gérer les centres d\'intérêt de la communauté',
            onTap: () => Get.to(() => const CommunityInterestsScreen(), arguments: communityId),
          ),
        ],
      ),
    );
  }
}

class CommunityTextInfoScreen extends GetView<CommunityInfoSettingsController> {
  const CommunityTextInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Nom, description et visibilité'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          Obx(() => controller.isAdmin
              ? TextButton(
                  onPressed: controller.saveTextInfo,
                  child: const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.bold)),
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: controller.nameController,
              enabled: controller.isAdmin,
              decoration: InputDecoration(
                labelText: 'Nom de la communauté',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.descriptionController,
              enabled: controller.isAdmin,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            Text('Visibilité et Adhésion', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: controller.visibility.value,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'public', child: Text('Publique (Tout le monde peut rejoindre)', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'private', child: Text('Privée (Sur approbation manuelle)', overflow: TextOverflow.ellipsis)),
              ],
              onChanged: controller.isAdmin ? (v) => controller.visibility.value = v ?? 'public' : null,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class CommunityMediaInfoScreen extends GetView<CommunityInfoSettingsController> {
  const CommunityMediaInfoScreen({super.key});

  Future<void> _pickImage(BuildContext context, bool isAvatar) async {
    if (!controller.isAdmin) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MediaGallerySheet(
        maxSelection: 1,
        onSelected: (files) {
          if (files.isNotEmpty) {
            final file = File(files.first.path);
            if (isAvatar) {
              controller.avatarImage.value = file;
            } else {
              controller.bannerImage.value = file;
            }
          }
          Get.back();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Photos de profil et de couverture'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          Obx(() => controller.isAdmin
              ? TextButton(
                  onPressed: controller.saveMediaInfo,
                  child: const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.bold)),
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final bannerFile = controller.bannerImage.value;
        final bannerUrlStr = controller.bannerUrl.value;
        final avatarFile = controller.avatarImage.value;
        final avatarUrlStr = controller.avatarUrl.value;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // --- Cover Banner ---
                  GestureDetector(
                    onTap: controller.isAdmin ? () => _pickImage(context, false) : null,
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                        image: bannerFile != null
                            ? DecorationImage(image: FileImage(bannerFile), fit: BoxFit.cover)
                            : (bannerUrlStr.isNotEmpty
                                ? DecorationImage(image: CachedNetworkImageProvider(bannerUrlStr), fit: BoxFit.cover)
                                : null),
                      ),
                      child: bannerFile == null && bannerUrlStr.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_outlined, size: 36, color: colorScheme.onSurfaceVariant),
                                const SizedBox(height: 8),
                                Text('Ajouter une photo de couverture', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                              ],
                            )
                          : null,
                    ),
                  ),
                  // Cover Edit Pencil Button
                  if (controller.isAdmin)
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: GestureDetector(
                        onTap: () => _pickImage(context, false),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ),

                  // --- Avatar (overlapping bottom center) ---
                  Positioned(
                    bottom: -50,
                    child: GestureDetector(
                      onTap: controller.isAdmin ? () => _pickImage(context, true) : null,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.surface,
                              border: Border.all(color: colorScheme.surface, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: avatarFile != null
                                  ? Image.file(avatarFile, fit: BoxFit.cover)
                                  : (avatarUrlStr.isNotEmpty
                                      ? AppCachedImage(imageUrl: avatarUrlStr, fit: BoxFit.cover)
                                      : Container(
                                          color: colorScheme.primary.withValues(alpha: 0.15),
                                          alignment: Alignment.center,
                                          child: Icon(Icons.person, size: 48, color: colorScheme.primary),
                                        )),
                            ),
                          ),
                          // Avatar Edit Pencil Button
                          if (controller.isAdmin)
                            Positioned(
                              right: 2,
                              bottom: 2,
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: colorScheme.surface, width: 2),
                                ),
                                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 70),
            Center(
              child: Text(
                'Appuyez sur les images pour choisir depuis la galerie interne',
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _HubCategoryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HubCategoryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
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
