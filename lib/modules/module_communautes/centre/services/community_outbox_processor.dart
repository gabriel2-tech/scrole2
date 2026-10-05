import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/local_storage/structured/app_cache_database.dart';
import '../../../../app/local_storage/structured/community_local_dao.dart';
import '../../../module_authentification/centre/services/auth_service.dart';
import '../../externe/repositories/community_repository.dart';
import 'community_service.dart';
import '../models/community_post.dart';
import '../../interne/controllers/community/community_feed_controller.dart';

/// Service pour la gestion de la file Outbox des communautés (réactions, votes, etc.)
/// avec coalescence (5s delay), UI optimiste, reprise hors-ligne et synchro à la fermeture.
class CommunityOutboxProcessor extends GetxService {
  final CommunityRepository _repository = Get.find<CommunityRepository>();
  final AuthService _authService = Get.find<AuthService>();
  late final CommunityLocalDao _dao = CommunityLocalDao(Get.find<AppDatabase>());

  final RxBool isProcessing = false.obs;
  Timer? _pollingTimer;
  final Map<String, Timer> _reactionDebouncers = {};
  final Map<String, Timer> _pollVoteDebouncers = {};

  @override
  void onInit() {
    super.onInit();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) => processPendingOperations());
    unawaited(processPendingOperations());
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    for (final timer in _reactionDebouncers.values) {
      timer.cancel();
    }
    _reactionDebouncers.clear();
    for (final timer in _pollVoteDebouncers.values) {
      timer.cancel();
    }
    _pollVoteDebouncers.clear();
    // Synchronisation de fermeture (§3)
    unawaited(processPendingOperations());
    super.onClose();
  }

  Future<void> enqueueReactionWithCoalescing({
    required String communityId,
    required String postId,
    required String reactionType,
  }) async {
    final userId = _authService.userId;
    if (userId == null) return;

    final key = 'reaction_${communityId}_${postId}_$userId';
    _reactionDebouncers[key]?.cancel();

    _reactionDebouncers[key] = Timer(const Duration(seconds: 5), () async {
      _reactionDebouncers.remove(key);
      await _dao.enqueueCommunityOutboxOperation(
        operationId: _repository.generateLocalId(),
        userId: userId,
        communityId: communityId,
        postId: postId,
        operationType: 'toggle_reaction',
        payload: {'reaction_type': reactionType},
      );
      unawaited(processPendingOperations());
    });
  }

  Future<void> enqueuePollVoteWithCoalescing({
    required String postId,
    required List<String> optionIds,
  }) async {
    final userId = _authService.userId;
    if (userId == null) return;

    final key = 'poll_vote_${postId}_$userId';
    _pollVoteDebouncers[key]?.cancel();

    _pollVoteDebouncers[key] = Timer(const Duration(seconds: 10), () async {
      _pollVoteDebouncers.remove(key);
      await _dao.deletePendingOperationByTypeAndPost(
        userId: userId,
        postId: postId,
        operationType: 'poll_vote',
      );
      await _dao.enqueueCommunityOutboxOperation(
        operationId: _repository.generateLocalId(),
        userId: userId,
        postId: postId,
        operationType: 'poll_vote',
        payload: {'option_ids': optionIds},
      );
      unawaited(processPendingOperations());
    });
  }

  Future<void> processPendingOperations() async {
    final userId = _authService.userId;
    if (userId == null || isProcessing.value) return;

    isProcessing.value = true;
    try {
      final pending = await _dao.getPendingCommunityOutboxOperations(userId);
      for (final item in pending) {
        final id = (item['id'] as num).toInt();
        final operationType = item['operation_type'].toString();
        final communityId = item['community_id']?.toString();
        final postId = item['post_id']?.toString();
        final attempts = (item['attempt_count'] as num).toInt();
        final payload = Map<String, dynamic>.from(jsonDecode(item['payload'].toString()));

        await _dao.lockCommunityOutboxOperation(id);

        try {
          if (operationType == 'toggle_reaction' && postId != null) {
            await Supabase.instance.client.rpc('toggle_post_reaction', params: {
              'p_post_id': postId,
              'p_reaction_type': payload['reaction_type'] ?? 'like',
            });
          } else if (operationType == 'create_post' && communityId != null) {
            await Supabase.instance.client.rpc('create_community_post', params: {
              'p_community_id': communityId,
              'p_content': payload['content'],
              'p_media_urls': payload['media_urls'],
            });
          } else if (operationType == 'poll_vote' && postId != null) {
            final optionIds = (payload['option_ids'] as List?)?.map((e) => e.toString()).toList() ?? [];
            final communityService = Get.find<CommunityService>();
            final res = await communityService.voteCommunityPoll(postId: postId, optionIds: optionIds);
            if (res.isNotEmpty && res['poll'] is Map) {
              final updatedPoll = CommunityPoll.fromJson(Map<String, dynamic>.from(res['poll'] as Map));
              try {
                final feedController = Get.find<CommunityFeedController>();
                final index = feedController.posts.indexWhere((p) => p.id == postId);
                if (index != -1) {
                  feedController.posts[index] = feedController.posts[index].copyWith(poll: updatedPoll);
                  feedController.posts.refresh();
                }
              } catch (_) {}
            }
          }

          await _dao.markCommunityOutboxOperationCompleted(id);
        } catch (e) {
          final errStr = e.toString();
          if (_isTerminalError(e)) {
            await _dao.markCommunityOutboxOperationFailed(id: id, lastError: errStr);
          } else {
            final nextAttempt = attempts + 1;
            final retryDelay = _calculateBackoff(nextAttempt);
            final nextRetryAt = DateTime.now().add(retryDelay).millisecondsSinceEpoch;
            await _dao.markCommunityOutboxOperationRetry(
              id: id,
              attemptCount: nextAttempt,
              nextRetryAt: nextRetryAt,
              lastError: errStr,
            );
          }
        }
      }
    } finally {
      isProcessing.value = false;
    }
  }

  bool _isTerminalError(dynamic error) {
    final str = error.toString().toLowerCase();
    return str.contains('permission denied') ||
        str.contains('not found') ||
        str.contains('42501') ||
        str.contains('403') ||
        str.contains('404');
  }

  Duration _calculateBackoff(int attempt) {
    switch (attempt) {
      case 1:
        return const Duration(seconds: 5);
      case 2:
        return const Duration(seconds: 15);
      case 3:
        return const Duration(seconds: 30);
      default:
        return const Duration(minutes: 2);
    }
  }
}
