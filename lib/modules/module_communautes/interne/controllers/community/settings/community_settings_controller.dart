import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:scrole/modules/module_communautes/centre/models/news/access_rule.dart';
import 'package:scrole/modules/module_communautes/centre/services/community_service.dart';

class CommunitySettingsController extends GetxController {
  final CommunityService _service = Get.find<CommunityService>();
  final String communityId;

  CommunitySettingsController(this.communityId);

  final RxBool isLoading = false.obs;

  // --- Filtres d'accès (UI States) ---
  final filterAge = false.obs;
  final minAge = 18.obs;
  final maxAge = 99.obs;

  final filterGender = false.obs;
  final allowedGenders = <String>[].obs; // 'male', 'female', 'other'

  final filterCountry = false.obs;
  final selectedCountries = <String>[].obs;

  final RxList<Map<String, dynamic>> members = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> roles = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadCurrentSettings();
    fetchMembersAndRoles();
  }

  Future<void> _loadCurrentSettings() async {
    try {
      isLoading.value = true;
      // TODO: Récupérer les règles d'accès réelles via une nouvelle méthode dans CommunityService
      // Pour l'instant on initialise par défaut
    } finally {
      isLoading.value = false;
    }
  }

  // --- Actions ---

  void toggleAgeFilter(bool value) => filterAge.value = value;
  void toggleGenderFilter(bool value) => filterGender.value = value;
  void toggleCountryFilter(bool value) => filterCountry.value = value;

  void updateAgeRange(int min, int max) {
    minAge.value = min;
    maxAge.value = max;
  }

  void toggleGender(String gender) {
    if (allowedGenders.contains(gender)) {
      allowedGenders.remove(gender);
    } else {
      allowedGenders.add(gender);
    }
  }

  // --- Persistence ---

  Future<void> saveRules() async {
    try {
      isLoading.value = true;

      // Construction de la structure AccessRule (AND de plusieurs conditions)
      final conditions = <AccessRule>[];

      if (filterAge.value) {
        conditions.add(AccessRule(type: RuleType.condition, field: 'age', operator: RuleOperator.gte, value: minAge.value));
        conditions.add(AccessRule(type: RuleType.condition, field: 'age', operator: RuleOperator.lte, value: maxAge.value));
      }

      if (filterGender.value && allowedGenders.isNotEmpty) {
        // OR pour les genres si plusieurs
        final genderConds = allowedGenders.map((g) => AccessRule(type: RuleType.condition, field: 'gender', operator: RuleOperator.eq, value: g)).toList();
        conditions.add(AccessRule(type: RuleType.or, conditions: genderConds));
      }

      if (filterCountry.value && selectedCountries.isNotEmpty) {
        final countryConds = selectedCountries.map((c) => AccessRule(type: RuleType.condition, field: 'country_id', operator: RuleOperator.eq, value: c)).toList();
        conditions.add(AccessRule(type: RuleType.or, conditions: countryConds));
      }

      final finalRules = AccessRule(type: RuleType.and, conditions: conditions);
      
      await _service.updateAccessRules(communityId, finalRules);
      
      Get.back();
      Get.snackbar('Succès', 'Restrictions d\'accès mises à jour');
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible d\'enregistrer les règles');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMembersAndRoles() async {
    try {
      isLoading.value = true;
      final rawMembers = await _service.getCommunityMembers(communityId);
      members.assignAll(rawMembers);
    } catch (e) {
      debugPrint('[CommunitySettingsController] fetchMembersAndRoles error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeMember(String userId) async {
    try {
      isLoading.value = true;
      await _service.removeCommunityMember(communityId, userId);
      members.removeWhere((m) {
        final profile = m['user_profiles'] is Map ? Map<String, dynamic>.from(m['user_profiles']) : {};
        final id = profile['user_id']?.toString() ?? profile['id']?.toString() ?? m['user_id']?.toString();
        return id == userId;
      });
      Get.snackbar('Succès', 'Le membre a été retiré de la communauté.', backgroundColor: Colors.black87, colorText: Colors.white);
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      Get.snackbar('Erreur', cleanMsg.isNotEmpty ? cleanMsg : 'Impossible de retirer le membre.', backgroundColor: Colors.red[900], colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateMemberRole(String userId, String newRole) async {
    try {
      isLoading.value = true;
      await _service.updateCommunityMemberRole(communityId, userId, newRole);
      final index = members.indexWhere((m) {
        final profile = m['user_profiles'] is Map ? Map<String, dynamic>.from(m['user_profiles']) : {};
        final id = profile['user_id']?.toString() ?? profile['id']?.toString() ?? m['user_id']?.toString();
        return id == userId;
      });
      if (index != -1) {
        final updated = Map<String, dynamic>.from(members[index]);
        updated['role'] = newRole;
        members[index] = updated;
      }
      Get.snackbar('Succès', 'Rôle mis à jour avec succès.', backgroundColor: Colors.black87, colorText: Colors.white);
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      Get.snackbar('Erreur', cleanMsg.isNotEmpty ? cleanMsg : 'Impossible de mettre à jour le rôle.', backgroundColor: Colors.red[900], colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
}
