import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../app/local_storage/fast/fast_cache_key.dart';
import '../../../../app/local_storage/fast/fast_cache_service.dart';
import '../../../../app/service_global/supabse_service.dart';
import '../../../module_discussion_direct/centre/persistence/social_local_dao.dart';
import '../../../module_discussion_direct/externe/repositories/social_repository.dart';
import '../../centre/models/external_profile_model.dart';

class ExternalProfileRepository {
  final _client = Get.find<SupabaseService>().client;
  final SocialRepository _socialRepo = SocialRepository();

  FastCacheService? get _cache =>
      Get.isRegistered<FastCacheService>() ? Get.find<FastCacheService>() : null;

  static const Duration _cacheTtl = Duration(minutes: 5);

  Future<ExternalProfileModel?> getProfile(String userId) async {
    final cacheKey = FastCacheKey.externalProfile(userId);

    // 1. Check if a valid (< 5 min) cached profile exists
    final cachedMap = _cache?.get<Map<String, dynamic>>(cacheKey, maxAge: _cacheTtl);
    if (cachedMap != null && cachedMap.isNotEmpty) {
      debugPrint('[ExternalProfileRepository] Returning valid 5-min cache for $userId');
      return ExternalProfileModel.fromJson(cachedMap);
    }

    // 2. Cache is missing or expired (>= 5 min): Request fresh data from backend
    Map<String, dynamic>? rawJson;

    try {
      final response = await _client.rpc('get_external_profile', params: {'p_user_id': userId});
      if (response is Map && response['user_id'] != null) {
        rawJson = Map<String, dynamic>.from(response);
      }
    } catch (e) {
      debugPrint('[ExternalProfileRepository] RPC get_external_profile error for $userId: $e');
    }

    // Fallback if RPC failed
    if (rawJson == null) {
      try {
        final row = await _client
            .from('user_profiles')
            .select('user_id, username, first_name, last_name, photo_url, cover_url, bio, slogan')
            .eq('user_id', userId)
            .maybeSingle();

        if (row != null) {
          RelationState relationState = RelationState.none;
          try {
            relationState = await _socialRepo.getRelationState(userId);
          } catch (_) {}

          rawJson = {
            'user_id': userId,
            'username': row['username'] ?? '',
            'first_name': row['first_name'] ?? '',
            'last_name': row['last_name'] ?? '',
            'photo_url': row['photo_url'],
            'cover_url': row['cover_url'],
            'bio': row['bio'],
            'slogan': row['slogan'],
            'is_private': false,
            'is_blocked': relationState == RelationState.blockedByMe,
            'is_connected': relationState == RelationState.friend,
            'connection_request_sent': relationState == RelationState.requestSent,
            'incoming_connection_request': relationState == RelationState.requestReceived,
            'is_following': false,
            'is_certified': false,
            'can_message': relationState == RelationState.friend,
            'friend_count': 0,
            'interests': [],
          };
        }
      } catch (e) {
        debugPrint('[ExternalProfileRepository] Fallback query error for $userId: $e');
      }
    }

    // If fresh fetch succeeded, populate user activities and save to cache
    if (rawJson != null) {
      final modelTmp = ExternalProfileModel.fromJson(rawJson);
      if (!modelTmp.isPrivate && !modelTmp.isBlocked) {
        final acts = await fetchUserActivities(userId);
        if (acts.isNotEmpty) {
          rawJson['activities'] = acts;
        }
      }

      await _cache?.set(cacheKey, rawJson);
      return ExternalProfileModel.fromJson(rawJson);
    }

    // 3. Network/RPC failed and cache was expired: Return stale cache if available
    final staleMap = _cache?.get<Map<String, dynamic>>(cacheKey);
    if (staleMap != null && staleMap.isNotEmpty) {
      debugPrint('[ExternalProfileRepository] Network failed for $userId, returning stale cache');
      return ExternalProfileModel.fromJson(staleMap);
    }

    return null;
  }

  /// Updates local cached profile map when a relationship action is performed.
  Future<void> updateCachedProfile(ExternalProfileModel model) async {
    final cacheKey = FastCacheKey.externalProfile(model.userId);
    await _cache?.set(cacheKey, model.toJson());
  }

  Future<List<Map<String, dynamic>>> fetchUserActivities(String userId) async {
    try {
      final response = await _client
          .from('activities')
          .select('id, name, base_price, currency_code, photo_url')
          .eq('user_id', userId)
          .limit(10);

      if (response is List) {
        return response
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (e) {
      debugPrint('[ExternalProfileRepository] fetchUserActivities error: $e');
    }
    return [];
  }

  Future<void> sendConnectionRequest(String userId) async {
    await _socialRepo.sendFriendRequest(userId);
  }

  Future<void> cancelConnection(String userId) async {
    await _socialRepo.removeFriendship(userId);
  }

  Future<void> respondConnectionRequest(String requestId, bool accept) async {
    await _socialRepo.respondFriendRequest(requestId, accept);
  }

  Future<bool> follow(String userId) async {
    try {
      await _client.rpc('follow_public_certified_profile', params: {'p_user_id': userId});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unfollow(String userId) async {
    try {
      await _client.rpc('unfollow_profile', params: {'p_user_id': userId});
      return true;
    } catch (_) {
      return false;
    }
  }
}
