import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrole/modules/module_communautes/centre/services/community_service.dart';
import 'package:scrole/modules/module_communautes/interne/enums/community_role_enum.dart' as role_enum;
import 'package:scrole/modules/module_communautes/interne/pages/community/settings/community_settings_main_screen.dart';

class CommunityManagementController extends GetxController {
  final CommunityService _service;
  CommunityService get service => _service;

  CommunityManagementController(this._service);

  final communityNotificationsEnabled = true.obs;
  final Rxn<role_enum.CommunityRole> currentUserRole = Rxn<role_enum.CommunityRole>();

  // --- Paramètres de la communauté ---
  final communityVisibility = 'Publique'.obs;
  final communityDescription = 'Description de la communauté'.obs;
  final rules = <String>[].obs;

  final isLoading = false.obs;
  final communityId = Rxn<String>();
  final communityName = ''.obs;
  final communityAvatarUrl = Rxn<String>();
  final memberCount = 0.obs;
  final communityOnlineCount = 21.obs;
  final isVerified = true.obs;
  final Rxn<dynamic> selectedGroup = Rxn<dynamic>();

  void openEntitySettings() {
    final id = communityId.value;
    if (id != null) {
      Get.to(() => const CommunitySettingsMainScreen(), arguments: id);
    }
  }

  @override
  void onInit() {
    super.onInit();
    final id = Get.parameters['id'];
    communityId.value = id;
    if (id != null) {
      _loadRealCommunityInfo(id);
    }
    loadCommunity();
  }

  Future<void> _loadRealCommunityInfo(String id) async {
    final community = await _service.getCommunityById(id);
    if (community != null) {
      communityName.value = community.name;
      communityAvatarUrl.value = community.avatarUrl;
      memberCount.value = community.memberCount;
      communityVisibility.value = community.visibility == 'private' ? 'Privée' : 'Publique';
    }

    try {
      final membership = await _service.getMembership(id);
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
    } catch (e) {
      currentUserRole.value = role_enum.CommunityRole.member;
    }
  }

  @override
  void onClose() {
    super.onClose();
  }

  Future<void> loadCommunity() async {
    isLoading.value = true;
    final String cId = Get.parameters['id'] ?? '';
    if (cId.isNotEmpty) {
      communityId.value = cId;
    }
    isLoading.value = false;
  }

  void goBack() => Get.back();

  Future<void> deleteCommunity() async {
    final id = communityId.value;
    if (id == null) return;

    try {
      isLoading.value = true;
      await _service.deleteCommunity(id);
      Get.back();
      Get.back();
      Get.snackbar('Succès', 'La communauté a été supprimée.');
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de supprimer la communauté.');
    } finally {
      isLoading.value = false;
    }
  }

  void addRule(String rule) {
    if (rule.trim().isEmpty) return;
    rules.add(rule.trim());
  }

  void removeRule(int index) => rules.removeAt(index);
}
