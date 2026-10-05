import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrole/modules/module_communautes/centre/models/news/community_join_request.dart';
import 'package:scrole/modules/module_communautes/centre/services/community_service.dart';

class CommunityJoinRequestsController extends GetxController {
  final CommunityService _service = Get.find<CommunityService>();
  final String communityId;

  CommunityJoinRequestsController(this.communityId);

  final RxList<CommunityJoinRequest> requests = <CommunityJoinRequest>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  String? _nextCursor;

  @override
  void onInit() {
    super.onInit();
    fetchRequests(refresh: true);
  }

  Future<void> fetchRequests({bool refresh = false}) async {
    if (isLoading.value || isLoadingMore.value) return;
    if (!refresh && !hasMore.value) return;

    try {
      if (refresh) {
        isLoading.value = true;
        _nextCursor = null;
      } else {
        isLoadingMore.value = true;
      }

      final result = await _service.getCommunityJoinRequests(
        communityId,
        limit: 20,
        cursor: _nextCursor,
      );

      final items = (result['items'] as List?)
          ?.map((e) => CommunityJoinRequest.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList() ?? [];

      if (refresh) {
        requests.assignAll(items);
      } else {
        requests.addAll(items);
      }

      _nextCursor = result['next_cursor']?.toString();
      hasMore.value = result['has_more'] == true && _nextCursor != null && _nextCursor!.isNotEmpty;
    } catch (e) {
      debugPrint('[CommunityJoinRequestsController] error: $e');
      if (refresh) {
        Get.snackbar('Erreur', 'Impossible de charger les demandes d\'adhésion.');
      }
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> respondRequest(String requestId, bool accepted) async {
    try {
      await _service.respondCommunityJoinRequest(requestId, accepted);
      requests.removeWhere((r) => r.id == requestId);
      Get.snackbar(
        'Succès',
        accepted ? 'Demande acceptée.' : 'Demande refusée.',
        backgroundColor: Colors.black87,
        colorText: Colors.white,
      );
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      Get.snackbar(
        'Erreur',
        cleanMsg.isNotEmpty ? cleanMsg : 'Action impossible. Veuillez réessayer.',
        backgroundColor: Colors.red[900],
        colorText: Colors.white,
      );
    }
  }
}
