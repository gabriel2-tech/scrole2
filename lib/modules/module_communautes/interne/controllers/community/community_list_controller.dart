import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrole/modules/module_authentification/centre/services/auth_service.dart';

import '../../../../../app/routes/app_pages.dart';
import '../../../../module_principale/interne/controllers/main_layout_controller.dart';
import '../../../centre/models/communities_model.dart';
import '../../../centre/services/community_service.dart';
import '../../enums/community_status_enum.dart';

class CommunityListController extends GetxController {
  final CommunityService _service = Get.find<CommunityService>();
  final AuthService _authService = Get.find<AuthService>();
  final Rx<CommunityStatus> status = CommunityStatus.initial.obs;
  final RxList<CommunityModel> joinedCommunities = <CommunityModel>[].obs;
  final RxList<CommunityModel> suggestedCommunities = <CommunityModel>[].obs;
  final RxString errorMessage = ''.obs;
  final RxBool isJoining = false.obs;
  StreamSubscription? _communitiesSubscription;
  bool _isSyncing = false;

  @override
  void onInit() {
    super.onInit();
    ever(_authService.currentUser, (_) {
      joinedCommunities.clear();
      status.value = CommunityStatus.loading;
      _listenToLocalCommunities();
      refreshData();
    });
    joinedCommunities.clear();
    status.value = CommunityStatus.loading;
    _listenToLocalCommunities();
    refreshData();
  }

  @override
  void onClose() {
    _communitiesSubscription?.cancel();
    super.onClose();
  }

  Future<void> refreshData() async {
    final userId = _authService.userId;
    _isSyncing = true;
    if (joinedCommunities.isEmpty) {
      status.value = CommunityStatus.loading;
    }
    try {
      if (userId != null) {
        debugPrint('[Sync] Début de la synchronisation des communautés...');
        await Future.wait([
          loadSuggestedCommunities(),
          _service.refreshJoinedCommunities(userId)
        ]).timeout(const Duration(seconds: 10));
        debugPrint('[Sync] Synchronisation terminée');
      } else {
        await loadSuggestedCommunities().timeout(const Duration(seconds: 5));
      }
      _isSyncing = false;
      if (joinedCommunities.isNotEmpty) {
        status.value = CommunityStatus.success;
      } else {
        status.value = CommunityStatus.empty;
      }
    } catch (e) {
      _isSyncing = false;
      debugPrint('[Warning] [Sync] Erreur ou Timeout lors du refresh: $e');
      if (joinedCommunities.isEmpty) {
        status.value = CommunityStatus.error;
        errorMessage.value = e.toString();
      }
    }
  }

  void _listenToLocalCommunities() {
    final userId = _authService.userId;
    if (userId == null) {
      status.value = CommunityStatus.empty;
      return;
    }
    if (joinedCommunities.isEmpty) {
      status.value = CommunityStatus.loading;
    }
    _communitiesSubscription?.cancel();
    _communitiesSubscription =
        _service.watchJoinedCommunities(userId).listen((data) {
      joinedCommunities.value = data
          .map((c) => CommunityModel(
              id: c.id,
              name: c.name,
              avatarImage: c.avatarUrl ?? '',
              coverImage: c.bannerUrl ?? '',
              memberCount: c.memberCount,
              tags: [],
              isJoined: true,
              createdAt: c.createdAt ?? DateTime.now()))
          .toList();
      debugPrint('[MyCommunities] controller list = ${joinedCommunities.length}');
      if (joinedCommunities.isNotEmpty) {
        status.value = CommunityStatus.success;
      } else if (!_isSyncing) {
        status.value = CommunityStatus.empty;
      }
    }, onError: (e) {
      debugPrint('[MyCommunities] Error listening to local communities: $e');
      status.value = CommunityStatus.error;
      errorMessage.value = e.toString();
    });
  }

  Future<void> loadSuggestedCommunities() async {
    try {
      final data = await _service.discoverCommunities();
      suggestedCommunities.value = data
          .map((c) => CommunityModel(
              id: c.id,
              name: c.name,
              avatarImage: c.avatarUrl ?? '',
              coverImage: c.bannerUrl ?? '',
              memberCount: c.memberCount,
              tags: [],
              isJoined: false,
              createdAt: c.createdAt ?? DateTime.now()))
          .toList();
    } catch (e) {
      debugPrint('Erreur suggestions: $e');
    }
  }

  Future<void> joinCommunity(String communityId) async {
    try {
      isJoining.value = true;
      final joinStatus = await _service.joinCommunity(communityId);
      if (joinStatus == 'active') {
        Get.snackbar('Succès', 'Vous avez rejoint la communauté !');
      } else {
        Get.snackbar('Demande envoyée',
            'Votre demande est en attente de validation.');
      }
      suggestedCommunities.removeWhere((c) => c.id == communityId);
    } catch (e) {
      Get.snackbar('Erreur', e.toString().replaceAll('Exception: ', ''));
    } finally {
      isJoining.value = false;
    }
  }

  void exploreMoreCommunities() {
    Get.find<MainLayoutController>().changeTab(1);
  }

  void navigateToCreateCommunity() {
    Get.toNamed(AppPages.createcommunity);
  }

  void navigateToCommunityDetail(String communityId, {bool isJoined = false}) {
    if (isJoined) {
      Get.toNamed(AppPages.communityDetailPath(communityId));
    } else {
      Get.toNamed(AppPages.communityPreviewPath(communityId));
    }
  }
}
