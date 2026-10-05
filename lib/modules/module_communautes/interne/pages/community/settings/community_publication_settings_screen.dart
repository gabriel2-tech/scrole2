import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrole/modules/module_communautes/centre/services/community_service.dart';
import 'package:scrole/modules/module_communautes/interne/enums/community_role_enum.dart' as role_enum;

class CommunityPublicationSettingsController extends GetxController {
  final CommunityService _service = Get.find<CommunityService>();
  final String communityId;

  CommunityPublicationSettingsController(this.communityId);

  final RxString postPermission = 'everyone'.obs; // 'everyone', 'admins_and_moderators', 'nobody'
  final RxBool postsRequireApproval = false.obs;
  final RxBool isLoading = false.obs;
  final Rxn<role_enum.CommunityRole> currentUserRole = Rxn<role_enum.CommunityRole>();

  bool get isAdmin => currentUserRole.value == role_enum.CommunityRole.admin;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
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

  Future<void> _loadSettings() async {
    try {
      isLoading.value = true;
      final c = await _service.getCommunityById(communityId);
      if (c != null) {
        // Load settings if available
      }
    } catch (_) {} finally {
      isLoading.value = false;
    }
  }

  Future<void> save() async {
    if (!isAdmin) return;
    try {
      isLoading.value = true;
      await _service.updateCommunityPostSettings(
        communityId: communityId,
        postPermission: postPermission.value,
        postsRequireApproval: postsRequireApproval.value,
      );
      Get.back();
      Get.snackbar('Succès', 'Paramètres de publication mis à jour.');
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de mettre à jour les paramètres de publication.');
    } finally {
      isLoading.value = false;
    }
  }
}

class CommunityPublicationSettingsScreen extends StatelessWidget {
  const CommunityPublicationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CommunityPublicationSettingsController(Get.arguments));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres de publication'),
        actions: [
          Obx(() => controller.isAdmin
              ? TextButton(
                  onPressed: controller.save,
                  child: const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.bold)),
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final readOnly = !controller.isAdmin;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Qui peut publier ?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            AbsorbPointer(
              absorbing: readOnly,
              child: DropdownButtonFormField<String>(
                value: controller.postPermission.value,
                items: const [
                  DropdownMenuItem(value: 'everyone', child: Text('Tout le monde (Everyone)')),
                  DropdownMenuItem(value: 'admins_and_moderators', child: Text('Admins et Modérateurs uniquement')),
                  DropdownMenuItem(value: 'nobody', child: Text('Personne (Nobody)')),
                ],
                onChanged: (v) {
                  if (v != null) controller.postPermission.value = v;
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Approbation requise pour les publications', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Les publications doivent être approuvées par un modérateur ou un admin.'),
              value: controller.postsRequireApproval.value,
              onChanged: readOnly ? null : (val) => controller.postsRequireApproval.value = val,
            ),
          ],
        );
      }),
    );
  }
}
