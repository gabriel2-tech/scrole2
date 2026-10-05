import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:scrole/modules/module_communautes/centre/models/news/community_preview_data.dart';
import 'package:scrole/modules/module_communautes/centre/services/community_service.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../../app/routes/app_pages.dart';
import '../../../centre/models/news/access_rule.dart';

enum CommunityActionUiState {
  loading,
  memberWithProfile,
  memberWithoutProfile,
  pendingRequest,
  notMemberEligible,
  notMemberNotEligible,
}

enum PreviewStatus { initial, loading, loaded, joining, error, notFound }

class CommunityPreviewController extends GetxController {
  final CommunityService _service;
  final String communityId;

  CommunityPreviewController(this._service, this.communityId);

  final Rx<PreviewStatus> status = PreviewStatus.initial.obs;
  final Rxn<CommunityPreviewData> previewData = Rxn<CommunityPreviewData>();
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadPreview();
  }

  CommunityActionUiState get actionUiState {
    final data = previewData.value;
    if (data == null || status.value == PreviewStatus.loading) {
      return CommunityActionUiState.loading;
    }

    if (data.isMember) {
      if (data.memberStatus == 'profile_incomplete') {
        return CommunityActionUiState.memberWithoutProfile;
      }
      return CommunityActionUiState.memberWithProfile;
    }

    if (data.requestStatus == 'en_attente' || data.isPending) {
      return CommunityActionUiState.pendingRequest;
    }

    if (data.canJoin) {
      return CommunityActionUiState.notMemberEligible;
    }

    return CommunityActionUiState.notMemberNotEligible;
  }

  Future<void> loadPreview() async {
    try {
      status.value = PreviewStatus.loading;
      final data = await _service.getCommunityPreviewData(communityId);
      previewData.value = data;

      debugPrint('[CommunityPreview] slug/id = $communityId');
      debugPrint('[CommunityPreview] isMember = ${data.isMember}');
      debugPrint('[CommunityPreview] isEligible = ${data.isEligible}');
      debugPrint('[CommunityPreview] showJoinButton = ${data.showJoinButton}');
      debugPrint('[CommunityPreview] memberStatus = ${data.memberStatus}');
      debugPrint('[CommunityPreview] requestId = ${data.requestId}');
      debugPrint('[CommunityPreview] requestStatus = ${data.requestStatus}');
      debugPrint('[CommunityPreview] actionUiState = $actionUiState');

      status.value = PreviewStatus.loaded;
    } catch (e) {
      debugPrint('[CommunityPreview] Error loading preview for $communityId: $e');
      if (e.toString().contains('introuvable')) {
        status.value = PreviewStatus.notFound;
      } else {
        status.value = PreviewStatus.error;
        errorMessage.value = e.toString().replaceAll('Exception: ', '');
      }
    }
  }

  Future<void> joinCommunity() async {
    if (previewData.value == null || status.value == PreviewStatus.joining) return;

    try {
      status.value = PreviewStatus.joining;
      final result = await _service.joinCommunityWithDetails(communityId);

      final joinStatus = (result['status'] ?? '').toString().toLowerCase();
      final reqId = result['id']?.toString() ?? result['request_id']?.toString();

      if (joinStatus == 'active' || joinStatus == 'accepted') {
        Get.snackbar('community_joined_success_title'.tr, 'community_joined_success_message'.tr);
        // Redirection vers le chat de la communauté
        Get.offNamed(AppPages.communityDetailPath(communityId));
      } else if (joinStatus == 'pending' || joinStatus == 'en_attente') {
        // Mettre à jour immédiatement l'état local en mémoire et en cache
        final current = previewData.value!;
        final updated = CommunityPreviewData(
          community: current.community,
          settings: current.settings,
          accessRules: current.accessRules,
          goldRules: current.goldRules,
          friendAvatars: current.friendAvatars,
          memberStatus: current.memberStatus,
          isEligible: current.isEligible,
          showJoinButton: current.showJoinButton,
          requiresApproval: current.requiresApproval,
          canJoin: current.canJoin,
          requestId: reqId ?? current.requestId,
          requestStatus: 'en_attente',
        );
        previewData.value = updated;
        await _service.savePreviewToCache(updated);
        Get.snackbar('community_request_sent_title'.tr, 'community_request_sent_message'.tr);
      } else {
        await loadPreview();
      }
      status.value = PreviewStatus.loaded;
    } catch (e) {
      Get.snackbar('error'.tr, e.toString().replaceAll('Exception: ', ''));
      status.value = PreviewStatus.loaded;
    }
  }

  Future<void> cancelJoinRequest() async {
    final reqId = previewData.value?.requestId;
    if (reqId == null || reqId.isEmpty || status.value == PreviewStatus.joining) return;

    try {
      status.value = PreviewStatus.joining;
      await _service.cancelCommunityJoinRequest(reqId);

      final current = previewData.value!;
      final updated = CommunityPreviewData(
        community: current.community,
        settings: current.settings,
        accessRules: current.accessRules,
        goldRules: current.goldRules,
        friendAvatars: current.friendAvatars,
        memberStatus: current.memberStatus,
        isEligible: current.isEligible,
        showJoinButton: current.showJoinButton,
        requiresApproval: current.requiresApproval,
        canJoin: current.canJoin,
        requestId: null,
        requestStatus: null,
      );
      previewData.value = updated;
      await _service.savePreviewToCache(updated);

      Get.snackbar('Succès', 'Demande d\'adhésion annulée.');
      status.value = PreviewStatus.loaded;
    } catch (e) {
      Get.snackbar('Erreur', e.toString().replaceAll('Exception: ', ''));
      status.value = PreviewStatus.loaded;
    }
  }

  List<String> getAccessBadges() {
    final rules = previewData.value?.accessRules;
    if (rules == null || rules.conditions == null) return [];

    final badges = <String>[];
    for (final cond in rules.conditions!) {
      if (cond.field == 'age' && cond.value != null) {
        if (cond.operator == RuleOperator.gte) {
          badges.add('Âge minimum : ${cond.value} ans');
        } else if (cond.operator == RuleOperator.lte) {
          badges.add('Âge maximum : ${cond.value} ans');
        }
      } else if (cond.field == 'country_id' && cond.value != null) {
        badges.add('Pays autorisé : ${cond.value}');
      } else if (cond.field == 'gender' && cond.value != null) {
        String gender = cond.value.toString();
        if (gender == 'male') gender = 'Hommes uniquement';
        if (gender == 'female') gender = 'Femmes uniquement';
        badges.add(gender);
      }
    }
    return badges;
  }

  void goBack() => Get.back();

  void shareCommunity() {
    if (previewData.value == null) return;
    final community = previewData.value!.community;
    final text = 'Rejoins ma communauté "${community.name}" sur Scrole ! https://scrole.fun/communities/${community.slug}';
    Share.share(text);
  }

  void reportCommunity() {
    if (previewData.value == null) return;
    final community = previewData.value!.community;
    Get.snackbar('Signaler', 'Le signalement pour "${community.name}" a été pris en compte.');
  }
}
