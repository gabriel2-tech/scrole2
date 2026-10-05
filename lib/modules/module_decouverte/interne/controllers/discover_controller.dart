import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../app/routes/app_pages.dart';
import '../../../module_activite/centre/models/activity_model.dart';
import '../../../module_activite/externe/repositories/activity_repository.dart';
import '../../../module_activite/interne/pages/activity_preview_screen.dart';
import '../../../module_communautes/centre/services/community_service.dart';
import '../../../module_evenement/centre/repositories/event_repository.dart';
import '../../../module_evenement/interne/pages/event_detail_page.dart';
import '../../centre/models/discover_models.dart';
import '../../centre/services/discover_service.dart';
import '../../../module_communautes/centre/models/news/community_discovery_model.dart';

class DiscoverController extends GetxController {
  final DiscoverService _service = Get.put(DiscoverService());
  final TextEditingController searchTextController = TextEditingController();
  final Rx<DiscoverState> state = DiscoverState.idle.obs;
  final RxString query = ''.obs;
  final RxString errorMessage = ''.obs;

  final RxList<SearchResultItem> accountResults = <SearchResultItem>[].obs;
  final RxList<SearchResultItem> eventResults = <SearchResultItem>[].obs;
  final RxList<SearchResultItem> communityResults = <SearchResultItem>[].obs;
  final RxList<SearchResultItem> activityResults = <SearchResultItem>[].obs;

  final RxList<CommunityDiscoveryModel> discoverCommunities = <CommunityDiscoveryModel>[].obs;
  final RxBool isDiscoverLoading = false.obs;
  final RxBool discoverHasMore = true.obs;
  int _discoverOffset = 0;

  Timer? _debounce;
  static const _debounceDuration = Duration(milliseconds: 500);

  @override
  void onInit() {
    super.onInit();
    searchTextController.addListener(() => onSearchChanged(searchTextController.text));
    loadDiscoverCommunities(refresh: true);
  }

  Future<void> loadDiscoverCommunities({bool refresh = false}) async {
    if (refresh) {
      _discoverOffset = 0;
      discoverHasMore.value = true;
    }
    if (isDiscoverLoading.value || (!discoverHasMore.value && !refresh)) return;

    try {
      isDiscoverLoading.value = true;
      final communityService = Get.isRegistered<CommunityService>()
          ? Get.find<CommunityService>()
          : Get.put(CommunityService(Get.find(), Get.find()));
      const limit = 10;
      final results = await communityService.getDiscoverCommunities(limit: limit, offset: _discoverOffset);

      if (refresh) {
        discoverCommunities.value = results;
      } else {
        discoverCommunities.addAll(results);
      }

      if (results.length < limit) {
        discoverHasMore.value = false;
      } else {
        _discoverOffset += limit;
      }
    } catch (e) {
      debugPrint('[DiscoverController] loadDiscoverCommunities error: $e');
    } finally {
      isDiscoverLoading.value = false;
    }
  }

  @override
  void onClose() {
    _debounce?.cancel();
    searchTextController.dispose();
    super.onClose();
  }

  void onSearchChanged(String value) {
    if (query.value == value) return;
    query.value = value;
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      state.value = DiscoverState.idle;
      accountResults.clear();
      eventResults.clear();
      communityResults.clear();
      activityResults.clear();
      return;
    }
    _debounce = Timer(_debounceDuration, () => _performSearch(value.trim()));
  }

  Future<void> _performSearch(String term) async {
    if (term.isEmpty) return;
    state.value = DiscoverState.loading;
    try {
      final results = await _service.searchAll(term);
      accountResults.assignAll(results.where((e) => e.category == 'user').toList());
      eventResults.assignAll(results.where((e) => e.category == 'event').toList());
      communityResults.assignAll(results.where((e) => e.category == 'community').toList());
      activityResults.assignAll(results.where((e) => e.category == 'activity').toList());
      state.value = DiscoverState.found;
    } catch (e) {
      debugPrint('[DiscoverController] _performSearch error: $e');
      errorMessage.value = 'discover_error_search'.tr;
      state.value = DiscoverState.error;
    }
  }

  void clearSearch() {
    searchTextController.clear();
    onSearchChanged('');
  }

  bool _isNavigatingCommunity = false;

  void onAccountTap(String userId) {
    if (userId.trim().isEmpty) return;
    Get.toNamed(AppPages.externalProfilePath(userId));
  }

  void onCommunityTap(String communityId) async {
    if (communityId.trim().isEmpty || _isNavigatingCommunity) return;

    _isNavigatingCommunity = true;
    try {
      final communityService = Get.find<CommunityService>();
      final previewData = await communityService.getCommunityPreviewData(communityId);

      final targetId = previewData.community.id.isNotEmpty ? previewData.community.id : communityId;

      if (previewData.isMember) {
        // Déjà membre -> Direction directe vers l'écran principal de la communauté (pas de Preview)
        Get.toNamed(AppPages.communityDetailPath(targetId));
      } else {
        // Pas encore membre -> Direction vers l'écran Preview de la communauté
        Get.toNamed(AppPages.communityPreviewPath(targetId));
      }
    } catch (e) {
      debugPrint('[DiscoverController] onCommunityTap error: $e');
      Get.snackbar(
        'error'.tr,
        'community_load_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
      );
    } finally {
      _isNavigatingCommunity = false;
    }
  }

  void onEventTap(String eventId) async {
    if (eventId.trim().isEmpty) return;
    try {
      final EventRepository repository = Get.isRegistered<EventRepository>()
          ? Get.find<EventRepository>()
          : Get.put(EventRepository(Get.find(), Get.find()));
      final event = await repository.getEventById(eventId);
      Get.to(() => EventDetailPage(event: event));
    } catch (e) {
      debugPrint('[DiscoverController] onEventTap error: $e');
    }
  }

  void onActivityTap(String activityId) async {
    if (activityId.trim().isEmpty) return;
    try {
      final ActivityRepository repository = Get.isRegistered<ActivityRepository>()
          ? Get.find<ActivityRepository>()
          : Get.put(ActivityRepository());
      final raw = await repository.getActivityPreviewRpc(activityId);
      final activity = Activity.fromJson(raw);
      Get.to(() => ActivityPreviewScreen(activity: activity));
    } catch (e) {
      debugPrint('[DiscoverController] onActivityTap error: $e');
    }
  }
}
