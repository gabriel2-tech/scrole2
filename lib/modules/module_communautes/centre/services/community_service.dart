import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../../app/local_storage/structured/app_cache_database.dart';
import '../../../../app/local_storage/structured/community_local_dao.dart';
import '../../../../app/repository_global/storage_repository.dart';
import 'package:scrole/shared/models/interest_model.dart';
import 'package:scrole/modules/module_authentification/centre/services/auth_service.dart';
import '../../externe/repositories/community_repository.dart';
import 'bunny_video_service.dart';
import '../models/news/access_rule.dart' as model;
import '../models/news/community.dart' as model;
import '../models/news/community_preview_data.dart';
import '../models/news/create_community_request.dart';
import '../models/news/create_community_result.dart';
import '../models/news/community_discovery_model.dart';
import '../models/news/community_hashtag.dart';
import '../models/news/community_settings.dart' as model;

class CommunityServiceException implements Exception {
  final String message;
  const CommunityServiceException(this.message);
  @override
  String toString() => message;
}

class CommunityService extends GetxService {
  final CommunityRepository _repository;
  final AppDatabase _db;
  late final CommunityLocalDao _localDao = CommunityLocalDao(_db);
  final StorageRepository _storage = StorageRepository();
  late final BunnyVideoService _bunnyVideoService = BunnyVideoService(_repository.client);
  CommunityService(this._repository, this._db);

  Future<bool> isMember(String communityId) async {
    final userId = Get.find<AuthService>().userId;
    if (userId == null) return false;
    final rows = await _db.database.then((db) => db.query('community_members',
        where: 'community_id=? AND user_id=? AND status=?',
        whereArgs: [communityId, userId, 'active'],
        limit: 1));
    return rows.isNotEmpty;
  }

  final Map<String, Future<CommunityPreviewData>> _inFlightPreviews = {};

  Future<CommunityPreviewData> getCommunityPreviewData(String communityIdOrSlug) async {
    if (_inFlightPreviews.containsKey(communityIdOrSlug)) {
      return _inFlightPreviews[communityIdOrSlug]!;
    }

    final completer = Completer<CommunityPreviewData>();
    _inFlightPreviews[communityIdOrSlug] = completer.future;

    try {
      final cachedJson = await _localDao.getCachedPreview(communityIdOrSlug);
      CommunityPreviewData? cachedData;
      if (cachedJson != null) {
        cachedData = _parsePreviewDataMap(cachedJson);
      }

      if (cachedData != null) {
        completer.complete(cachedData);
        _refreshPreviewInBackground(communityIdOrSlug);
        _inFlightPreviews.remove(communityIdOrSlug);
        return cachedData;
      }

      final freshData = await _fetchAndSavePreview(communityIdOrSlug);
      completer.complete(freshData);
      _inFlightPreviews.remove(communityIdOrSlug);
      return freshData;
    } catch (e) {
      _inFlightPreviews.remove(communityIdOrSlug);
      if (!completer.isCompleted) completer.completeError(e);
      rethrow;
    }
  }

  Future<void> _refreshPreviewInBackground(String communityIdOrSlug) async {
    try {
      await _fetchAndSavePreview(communityIdOrSlug);
    } catch (e) {
      debugPrint('[CommunityService] Background refresh failed for $communityIdOrSlug: $e');
    }
  }

  Future<CommunityPreviewData> _fetchAndSavePreview(String communityIdOrSlug) async {
    final raw = await _repository.getPublicCommunityData(communityIdOrSlug);
    final data = _parsePreviewDataMap(raw);
    await _localDao.saveCachedPreview(data.community.id, data.community.slug, raw);
    return data;
  }

  Future<void> savePreviewToCache(CommunityPreviewData data) async {
    final raw = {
      'community': data.community.toJson(),
      'settings': data.settings.toJson(),
      'is_member': data.isMember,
      'member_status': data.memberStatus,
      'is_eligible': data.isEligible,
      'show_join_button': data.showJoinButton,
      'requires_approval': data.requiresApproval,
      'can_join': data.canJoin,
      'request_id': data.requestId,
      'request_status': data.requestStatus,
    };
    await _localDao.saveCachedPreview(data.community.id, data.community.slug, raw);
  }

  CommunityPreviewData _parsePreviewDataMap(Map<String, dynamic> raw) {
    final isMemberFromRpc = raw['is_member'] == true;
    final rawStatus = raw['member_status']?.toString() ??
        raw['status']?.toString() ??
        raw['membership_status']?.toString() ??
        (raw['membership'] is Map ? (raw['membership']['status']?.toString()) : null);

    final String memberStatus = isMemberFromRpc
        ? 'active'
        : (rawStatus != null && rawStatus.isNotEmpty ? rawStatus : 'none');

    final communityMap = raw.containsKey('community') && raw['community'] is Map
        ? Map<String, dynamic>.from(raw['community'])
        : raw;

    final community = model.Community.fromJson(communityMap);

    Map<String, dynamic> settingsMap = {};
    if (raw.containsKey('settings') && raw['settings'] is Map) {
      settingsMap = Map<String, dynamic>.from(raw['settings']);
    }

    final settings = model.CommunitySettings.fromJson(settingsMap);

    model.AccessRule? accessRules;
    final ar = communityMap['community_access_rules'] ?? raw['community_access_rules'];
    if (ar != null && ar['rules_logic'] != null) {
      accessRules = model.AccessRule.fromJson(
          Map<String, dynamic>.from(ar['rules_logic']));
    }

    final String? requestId = raw['request_id']?.toString() ??
        raw['requestId']?.toString() ??
        (raw['membership'] is Map ? (raw['membership']['id']?.toString()) : null);

    final String? requestStatus = raw['request_status']?.toString() ??
        raw['requestStatus']?.toString() ??
        raw['member_status']?.toString() ??
        raw['status']?.toString() ??
        (raw['membership'] is Map ? (raw['membership']['status']?.toString()) : null);

    return CommunityPreviewData(
      community: community,
      settings: settings,
      accessRules: accessRules,
      goldRules: const [
        'Respectez les autres membres.',
        'Pas de spam ou de publicité.',
        'Restez dans le thème du salon.'
      ],
      friendAvatars: const [
        'https://i.pravatar.cc/150?u=1',
        'https://i.pravatar.cc/150?u=2',
        'https://i.pravatar.cc/150?u=3'
      ],
      memberStatus: memberStatus,
      isEligible: raw['is_eligible'] == true || raw['is_eligible'] == null,
      showJoinButton: raw['show_join_button'] == true || raw['show_join_button'] == null,
      requiresApproval: raw['requires_approval'] == true || community.visibility.toLowerCase() == 'prive',
      canJoin: raw['can_join'] == true || raw['can_join'] == null,
      requestId: requestId,
      requestStatus: requestStatus,
    );
  }

  Future<CreateCommunityResult> createCommunity({
    required CreateCommunityRequest request,
    File? avatarFile,
    File? bannerFile,
  }) async {
    try {
      String? photoProfile, photoCover;
      if (avatarFile != null) {
        photoProfile = await _storage.uploadCommunityAvatar(avatarFile);
      }
      if (bannerFile != null) {
        photoCover = await _storage.uploadCommunityBanner(bannerFile);
      }

      final finalRequest = CreateCommunityRequest(
        id: request.id.isNotEmpty ? request.id : _repository.generateLocalId(),
        name: request.name,
        slug: request.slug,
        description: request.description,
        photoProfile: photoProfile,
        photoCover: photoCover,
        visibility: request.visibility,
      );

      final raw = await _repository.createCommunity(finalRequest);
      final result = CreateCommunityResult.fromJson(raw);
      await _localDao.saveCreateCommunityResult(result);
      return result;
    } on PostgrestException catch (e) {
      throw CommunityServiceException(e.message);
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '').replaceFirst('PostgrestException: ', '');
      throw CommunityServiceException(cleanMsg);
    }
  }

  Future<model.Community?> getCommunityById(String id) =>
      _localDao.getCommunityById(id);

  Future<model.CommunitySettings?> getCommunitySettings(String communityId) async {
    try {
      final res = await _localDao.getCommunityWithSettings(communityId);
      return res?.settings;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getCommunityMembers(String communityId) =>
      _repository.getCommunityMembers(communityId);
  Future<List<Map<String, dynamic>>> getCommunityRoles(String communityId) =>
      _repository.getCommunityRoles(communityId);
  Future<Map<String, dynamic>> getCommunityJoinRequests(
    String communityId, {
    int limit = 20,
    String? cursor,
  }) => _repository.getCommunityJoinRequests(communityId, limit: limit, cursor: cursor);
  Future<void> respondCommunityJoinRequest(String requestId, bool accepted) =>
      _repository.respondCommunityJoinRequest(requestId, accepted);
  Future<void> removeCommunityMember(String communityId, String userId) =>
      _repository.removeCommunityMember(communityId, userId);
  Future<void> updateCommunityMemberRole(String communityId, String userId, String role) =>
      _repository.updateCommunityMemberRole(communityId, userId, role);
  Future<void> inviteToCommunity(String communityId, String userId) =>
      _repository.inviteToCommunity(communityId, userId);
  Future<String> uploadCommunityAvatar(File file, String communityId) =>
      _storage.uploadCommunityAvatar(file, communityId: communityId);
  Future<String> uploadCommunityBanner(File file, String communityId) =>
      _storage.uploadCommunityBanner(file, communityId: communityId);

  Stream<List<model.Community>> watchJoinedCommunities(String userId) async* {
    yield await _localDao
        .getMyCommunities(userId)
        .then((v) => v.map((e) => e.community).toList());
    await for (final _ in _localDao.changes) {
      yield await _localDao
          .getMyCommunities(userId)
          .then((v) => v.map((e) => e.community).toList());
    }
  }

  Future<void> refreshJoinedCommunities(String userId) async {
    try {
      debugPrint('[MyCommunities] refreshJoinedCommunities for $userId');
      final raw = await _repository.getMyCommunities();
      debugPrint('[MyCommunities] RPC returned ${raw.length} communities');
      final db = await _db.database;

      await db.transaction((txn) async {
        for (final row in raw) {
          try {
            // raw est directement la liste des communautés renvoyées par get_my_communities()
            final community = model.Community.fromJson(row);

            // 1. Sauvegarder la communauté dans SQLite
            await txn.insert('communities', {
              'id': community.id,
              'name': community.name,
              'slug': community.slug,
              'description': community.description,
              'avatar_url': community.avatarUrl,
              'banner_url': community.bannerUrl,
              'visibility': community.visibility,
              'status': community.status,
              'member_count': community.memberCount,
              'cached_at': DateTime.now().millisecondsSinceEpoch,
            }, conflictAlgorithm: ConflictAlgorithm.replace);

            // 2. Sauvegarder le membership dans SQLite pour l'utilisateur courant
            await txn.insert('community_members', {
              'id': row['member_id'] ?? '${community.id}_$userId',
              'community_id': community.id,
              'user_id': userId,
              'role_id': row['role_id'],
              'status': row['status'] ?? 'active',
              'cached_at': DateTime.now().millisecondsSinceEpoch,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          } catch (e) {
            debugPrint('[MyCommunities] Failed to process community row: $e');
          }
        }
      });
      _localDao.notifyChanges();
      debugPrint('[MyCommunities] SQLite persisted ${raw.length} communities');
    } catch (e) {
      debugPrint('[MyCommunities] Error in refreshJoinedCommunities: $e');
    }
  }

  Future<void> updateCommunityInfo({
    required String id,
    required String name,
    required String description,
    String? photoProfile,
    String? photoCover,
  }) => _repository.updateCommunityInfo(
        id: id,
        name: name,
        description: description,
        photoProfile: photoProfile,
        photoCover: photoCover,
      );

  Future<void> updateAccessRules(String communityId, model.AccessRule rules) async {
    await _repository.client.from('community_access_rules').upsert({
      'community_id': communityId,
      'rules_logic': rules.toJson(),
      'updated_at': DateTime.now().toIso8601String()
    });
  }

  Future<void> updateCommunityAccessRules({
    required String communityId,
    required bool countriesEnabled,
    required List<String> allowedCountries,
    required bool citiesEnabled,
    required List<String> allowedCities,
    required bool certificationRequired,
    String? genderRestriction,
    int? ageMin,
    int? ageMax,
  }) => _repository.updateCommunityAccessRules(
        communityId: communityId,
        countriesEnabled: countriesEnabled,
        allowedCountries: allowedCountries,
        citiesEnabled: citiesEnabled,
        allowedCities: allowedCities,
        certificationRequired: certificationRequired,
        genderRestriction: genderRestriction,
        ageMin: ageMin,
        ageMax: ageMax,
      );

  Future<void> updateCommunitySettings({
    required String communityId,
    required String visibility,
    required bool requireManualApproval,
  }) => _repository.updateCommunitySettings(
        communityId: communityId,
        visibility: visibility,
        requireManualApproval: requireManualApproval,
      );

  Future<void> updateCommunityPostSettings({
    required String communityId,
    required String postPermission,
    required bool postsRequireApproval,
  }) => _repository.updateCommunityPostSettings(
        communityId: communityId,
        postPermission: postPermission,
        postsRequireApproval: postsRequireApproval,
      );

  Future<void> updateCommunityInterests({
    required String communityId,
    required List<String> interestIds,
  }) => _repository.updateCommunityInterests(
        communityId: communityId,
        interestIds: interestIds,
      );

  Future<List<Interest>> getCommunityInterests(String communityId) =>
      _repository.getCommunityInterests(communityId);

  Future<void> updateSettings(String communityId, Map<String, dynamic> settings) async {
    await _repository.client
        .from('community_settings')
        .update(settings)
        .eq('community_id', communityId);
  }

  Future<String> joinCommunity(String communityId) async {
    final result = await _repository.joinCommunity(communityId);
    final status = (result['status'] ?? '').toString().toLowerCase();
    final id = result['id']?.toString() ?? '';
    final uid = Get.find<AuthService>().userId;

    final isAccepted = status == 'acceptee' || status == 'accepted' || status == 'active';
    final isPending = status == 'en_attente' || status == 'pending';

    if (uid != null && isAccepted) {
      await (await _db.database).insert('community_members', {
        'id': id.isNotEmpty ? id : '${communityId}_$uid',
        'community_id': communityId,
        'user_id': uid,
        'status': 'active',
        'cached_at': DateTime.now().millisecondsSinceEpoch
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    if (isPending) return 'pending';
    if (isAccepted) return 'active';
    return status;
  }

  Future<Map<String, dynamic>> joinCommunityWithDetails(String communityId) async {
    final result = await _repository.joinCommunity(communityId);
    final status = (result['status'] ?? '').toString().toLowerCase();
    final id = result['id']?.toString() ?? result['request_id']?.toString() ?? '';
    final uid = Get.find<AuthService>().userId;

    final isAccepted = status == 'acceptee' || status == 'accepted' || status == 'active';

    if (uid != null && isAccepted) {
      await (await _db.database).insert('community_members', {
        'id': id.isNotEmpty ? id : '${communityId}_$uid',
        'community_id': communityId,
        'user_id': uid,
        'status': 'active',
        'cached_at': DateTime.now().millisecondsSinceEpoch
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    return result;
  }

  Future<void> cancelCommunityJoinRequest(String requestId) async {
    await _repository.cancelCommunityJoinRequest(requestId);
  }

  Future<Map<String, dynamic>> getCommunityPendingPosts(String communityId, {int limit = 20, int offset = 0}) async {
    try {
      return await _repository.getCommunityPendingPosts(communityId, limit: limit, offset: offset);
    } catch (e) {
      debugPrint('[Error] getCommunityPendingPosts: $e');
      return {'items': [], 'has_more': false};
    }
  }

  Future<void> moderateCommunityPost(String postId, String action) async {
    await _repository.moderateCommunityPost(postId, action);
  }

  Future<void> deleteCommunityPost(String postId) async {
    debugPrint('[COMMUNITY_POST_DELETE][SERVICE] Executing delete for post=$postId');
    try {
      await _repository.deleteCommunityPost(postId);
      debugPrint('[COMMUNITY_POST_DELETE][SERVICE] Deletion completed for post=$postId');
    } catch (e) {
      debugPrint('[COMMUNITY_POST_DELETE][SERVICE] Deletion failed for post=$postId: $e');
      rethrow;
    }
  }

  Future<void> leaveCommunity(String communityId) async {
    await _repository.leaveCommunity(communityId);
    await _localDao.deleteCommunity(communityId);
  }

  Future<void> deleteCommunity(String communityId) async {
    // 1. Suppression locale immédiate (Optimiste)
    await _localDao.deleteCommunity(communityId);
    
    // 2. Propagation au backend
    try {
      await _repository.deleteCommunity(communityId);
    } catch (e) {
      debugPrint('[Error] Échec propagation suppression communauté: $e');
    }
  }

  Future<Map<String, dynamic>?> getMembership(String communityId) =>
      _repository.getMembership(communityId);

  Future<List<CommunityDiscoveryModel>> getDiscoverCommunities({int limit = 10, int offset = 0}) async {
    try {
      final raw = await _repository.getDiscoverCommunities(limit: limit, offset: offset);
      return raw.map((e) => CommunityDiscoveryModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('[Error] getDiscoverCommunities: $e');
      return [];
    }
  }

  Future<List<model.Community>> discoverCommunities() async {
    try {
      final raw = await _repository.discoverCommunities();
      final communities = raw.map((e) => model.Community.fromJson(e)).toList();
      await _localDao.upsertCommunities(communities);
      return communities;
    } catch (e) {
      debugPrint('[Error] discoverCommunities: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getCommunityFeed(String communityId, {int limit = 20, String? cursor}) async {
    try {
      return await _repository.getCommunityFeed(communityId, limit: limit, cursor: cursor);
    } catch (e) {
      debugPrint('[Error] getCommunityFeed: $e');
      return {'items': [], 'has_more': false, 'next_cursor': null};
    }
  }

  Future<File?> _compressImage(File file) async {
    try {
      final filePath = file.absolute.path;
      final dir = await getTemporaryDirectory();
      final targetPath = p.join(
        dir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}_${p.basename(filePath)}',
      );

      var result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        targetPath,
        quality: 80,
        minWidth: 1920,
        minHeight: 1920,
        autoCorrectionAngle: true,
      );

      if (result != null) {
        return File(result.path);
      }
      return file;
    } catch (e) {
      debugPrint('[CommunityService] Compression error: $e');
      return file;
    }
  }

  Future<Map<String, dynamic>> createCommunityPost({
    required String communityId,
    String? content,
    List<File> imageFiles = const [],
    bool commentsEnabled = true,
    bool sharingEnabled = true,
    bool reactionsEnabled = true,
    List<String> hashtags = const [],
    List<String> mentions = const [],
    Map<String, dynamic>? poll,
  }) async {
    debugPrint('[VIDEO_TEST] selected video count: ${imageFiles.where((f) {
      final p = f.path.toLowerCase();
      return p.endsWith('.mp4') || p.endsWith('.mov') || p.endsWith('.avi') || p.endsWith('.webm') || p.endsWith('.mkv') || p.endsWith('.3gp') || p.endsWith('.m4v');
    }).length}');
    for (final f in imageFiles) {
      debugPrint('[VIDEO_TEST] selected video path: ${f.path}');
      debugPrint('[VIDEO_TEST] selected video name: ${f.path.split('/').last}');
    }

    final postId = _repository.generateLocalId();
    final List<Map<String, dynamic>> mediaPayload = [];
    try {
      final userId = _repository.client.auth.currentUser?.id ?? '';
      for (final file in imageFiles) {
        final pathLower = file.path.toLowerCase();
        final isVideo = pathLower.endsWith('.mp4') ||
            pathLower.endsWith('.mov') ||
            pathLower.endsWith('.avi') ||
            pathLower.endsWith('.webm') ||
            pathLower.endsWith('.mkv') ||
            pathLower.endsWith('.3gp') ||
            pathLower.endsWith('.m4v');

        if (isVideo) {
          final clientMediaId = _repository.generateLocalId();
          debugPrint('[VIDEO_TEST] compression START for clientMediaId=$clientMediaId');
          debugPrint('[VIDEO_TEST] source path: ${file.path}');
          
          if (pathLower.endsWith('.webm')) {
            throw CommunityServiceException('Le format WebM n\'est pas supporté. Veuillez sélectionner une vidéo MP4.');
          }

          final compressed = await VideoCompress.compressVideo(
            file.path,
            quality: VideoQuality.MediumQuality,
            deleteOrigin: false,
          );
          final videoFile = compressed?.file ?? file;
          debugPrint('[VIDEO_TEST] compression END');
          debugPrint('[VIDEO_TEST] compressed path: ${videoFile.path}');

          final sizeBytes = await videoFile.length();
          if (sizeBytes > 52428800) {
            throw CommunityServiceException('La vidéo ne peut pas dépasser 50 Mo.');
          }

          debugPrint('[VIDEO_TEST] media info START');
          int? durationMs;
          try {
            final mediaInfo = await VideoCompress.getMediaInfo(videoFile.path);
            final rawDur = mediaInfo.duration;
            debugPrint('[VIDEO META] raw duration = $rawDur');
            if (rawDur != null && rawDur > 0) {
              durationMs = rawDur < 1000 ? (rawDur * 1000).toInt() : rawDur.toInt();
            }
            debugPrint('[VIDEO META] duration_ms = $durationMs');
            debugPrint('[VIDEO META] duration_ms type = ${durationMs.runtimeType}');
          } catch (e) {
            debugPrint('[VIDEO META] raw duration = null');
            debugPrint('[VIDEO META] duration_ms = null');
            debugPrint('[VIDEO META] duration_ms type = Null');
            debugPrint('[VIDEO_METADATA] duration error: $e');
          }

          if (durationMs == null || durationMs <= 0) {
            try {
              final playerController = VideoPlayerController.file(videoFile);
              await playerController.initialize();
              durationMs = playerController.value.duration.inMilliseconds;
              await playerController.dispose();
              debugPrint('[VIDEO META] VideoPlayerController duration_ms = $durationMs');
            } catch (e) {
              debugPrint('[VIDEO META] VideoPlayerController error: $e');
            }
          }

          if (durationMs == null || durationMs <= 0) {
            durationMs = 10000;
          }

          debugPrint('[MEDIA PREPARE] duration_ms=$durationMs');
          debugPrint('[MEDIA PREPARE] size_bytes=$sizeBytes');
          debugPrint('[MEDIA PREPARE] client_media_id=$clientMediaId');

          if (durationMs > 120000) {
            throw CommunityServiceException('La vidéo ne peut pas dépasser 2 minutes.');
          }

          final ext = videoFile.path.split('.').last.toLowerCase();
          if (ext == 'webm') {
            throw CommunityServiceException('Erreur: la compression a produit du WebM, non supporté par Bunny.');
          }

          debugPrint('file path: ${videoFile.path}');
          debugPrint('extension: $ext');
          debugPrint('mime type: video/mp4');
          debugPrint('size: $sizeBytes');
          debugPrint('duration: $durationMs');
          debugPrint('container: MP4');
          debugPrint('video codec: H.264');

          // Request upload session (prepare) from Bunny via Edge Function
          final session = await _bunnyVideoService.requestUploadSession(
            communityId: communityId,
            postId: postId,
            clientMediaId: clientMediaId,
            filename: videoFile.path.split('/').last,
            mimeType: 'video/mp4',
            sizeBytes: sizeBytes,
            durationMs: durationMs ?? 10000,
          );

          debugPrint('Supabase Storage appelé pour vidéo : NON');
          debugPrint('Bunny upload appelé : OUI');
          debugPrint('mime envoyé à bunny-video-upload : video/mp4');

          debugPrint('[VIDEO_TEST] video upload START (Bunny TUS)');
          debugPrint('[VIDEO_TEST] video local path: ${videoFile.path}');
          await _bunnyVideoService.uploadVideoTus(
            file: videoFile,
            session: session,
            onProgress: (progress) {
              debugPrint('[BUNNY_UPLOAD] Progress: ${(progress * 100).toStringAsFixed(1)}%');
            },
          );
          debugPrint('TUS : PASS');
          debugPrint('[VIDEO_TEST] video upload END');
          debugPrint('[VIDEO_TEST] bunny videoId: ${session.videoId}');

          debugPrint('TUS : PASS');
          debugPrint('[VIDEO_TEST] video upload END');
          debugPrint('[VIDEO_TEST] bunny videoId: ${session.videoId}');

          // Poll Bunny status until 'ready'
          bool isReady = false;
          Map<String, dynamic> statusRes = {};
          int attempts = 0;
          const maxAttempts = 60; // Up to 5 minutes with backoff

          while (!isReady && attempts < maxAttempts) {
            attempts++;
            final delay = attempts == 1 ? const Duration(seconds: 1) :
                          attempts == 2 ? const Duration(seconds: 2) :
                          attempts == 3 ? const Duration(seconds: 3) :
                          const Duration(seconds: 5);
            await Future.delayed(delay);

            try {
              statusRes = await _bunnyVideoService.checkVideoStatus(
                postId: postId,
                clientMediaId: clientMediaId,
              );

              final status = (statusRes['status'] ?? statusRes['video_status'] ?? '').toString().toLowerCase();
              final progress = statusRes['encode_progress'] ?? statusRes['progress'] ?? 0;
              debugPrint('[BUNNY] Checking video status... status=$status progress=$progress (attempt $attempts)');

              if (status == 'ready' || status == 'finished' || status == 'success' || status == 'encoded') {
                isReady = true;
                debugPrint('[BUNNY] status=ready');
              } else if (status == 'failed' || status == 'error') {
                throw CommunityServiceException('Le traitement vidéo Bunny a échoué.');
              }
            } catch (e) {
              debugPrint('[BUNNY] Status check error (attempt $attempts): $e');
              if (attempts >= maxAttempts) rethrow;
            }
          }

          if (!isReady) {
            throw CommunityServiceException('Délai d’attente dépassé pour le traitement de la vidéo par Bunny.');
          }

          final playbackUrl = statusRes['playback_url']?.toString() ??
              'https://iframe.mediadelivery.net/play/${session.libraryId}/${session.videoId}';
          final thumbnailUrl = statusRes['thumbnail_url']?.toString() ??
              'https://iframe.mediadelivery.net/play/${session.libraryId}/${session.videoId}/thumbnail.jpg';

          final rawDuration = statusRes['duration_ms'] ?? statusRes['durationMs'] ?? statusRes['duration'] ?? statusRes['length'];
          int? bunnyDurationMs;
          double? durationSeconds;
          if (rawDuration != null) {
            final numVal = num.tryParse(rawDuration.toString()) ?? 0.0;
            if (numVal > 0) {
              if (numVal < 1000) {
                durationSeconds = numVal.toDouble();
                bunnyDurationMs = (numVal * 1000).toInt();
              } else {
                durationSeconds = numVal / 1000.0;
                bunnyDurationMs = numVal.toInt();
              }
            }
          }

          debugPrint('[BUNNY] status=ready');
          debugPrint('[BUNNY] duration_seconds=$durationSeconds');

          final resolvedDuration = durationMs ?? bunnyDurationMs;
          debugPrint('[VIDEO MEDIA] final duration_ms=$resolvedDuration');
          debugPrint('[VIDEO MEDIA] playback_url=$playbackUrl');
          debugPrint('[VIDEO MEDIA] thumbnail_url=$thumbnailUrl');

          if (resolvedDuration == null || resolvedDuration <= 0) {
            throw CommunityServiceException('Impossible de récupérer la durée valide de la vidéo.');
          }
          if (playbackUrl.isEmpty) {
            throw CommunityServiceException('URL de lecture Bunny invalide.');
          }

          final mediaItem = {
            'type': 'video',
            'storage': 'bunny',
            'client_media_id': clientMediaId,
            'video_id': session.videoId,
            'url': playbackUrl,
            'thumbnail_url': thumbnailUrl,
            'duration_ms': resolvedDuration,
            'size_bytes': sizeBytes,
          };
          debugPrint('[POST] p_media=$mediaItem');
          mediaPayload.add(mediaItem);
        } else {
          final compressed = await _compressImage(file);
          final url = await _storage.uploadCommunityPostMedia(compressed ?? file, communityId: communityId);
          if (url.isNotEmpty) {
            final photoItem = {
              'type': 'photo',
              'storage': 'supabase',
              'url': url,
            };
            debugPrint('[POST] p_media=$photoItem');
            mediaPayload.add(photoItem);
          }
        }
      }

      debugPrint('[VIDEO_TEST] RPC create_community_post START');
      debugPrint('[VIDEO_TEST] p_video_url: null');
      debugPrint('[VIDEO_TEST] p_video_thumbnail_url: null');
      debugPrint('[VIDEO_TEST] p_video_duration_ms: null');
      debugPrint('[VIDEO_TEST] p_video_size_bytes: null');
      debugPrint('[VIDEO_TEST] p_media: $mediaPayload');

      final result = await _repository.createCommunityPost(
        id: postId,
        communityId: communityId,
        content: content,
        media: mediaPayload,
        commentsEnabled: commentsEnabled,
        sharingEnabled: sharingEnabled,
        reactionsEnabled: reactionsEnabled,
        hashtags: hashtags,
        mentions: mentions,
        poll: poll,
      );

      debugPrint('[VIDEO_TEST] RPC create_community_post SUCCESS');
      debugPrint('[VIDEO_TEST] returned post id: $postId');
      debugPrint('[VIDEO_TEST] POST CREATED');
      debugPrint('[VIDEO_TEST] post_id: $postId');
      debugPrint('[VIDEO_TEST] stored media: $mediaPayload');

      return result;
    } catch (e) {
      debugPrint('[VIDEO_TEST] RPC create_community_post ERROR');
      debugPrint('[VIDEO_TEST] error: $e');
      for (final m in mediaPayload) {
        final url = m['url']?.toString();
        if (url != null && url.isNotEmpty) {
          try {
            await _storage.deletePublicFile(bucket: 'community-media', publicUrl: url);
          } catch (_) {}
        }
      }
      final cleanMsg = e.toString().replaceFirst('Exception: ', '').replaceFirst('PostgrestException: ', '');
      throw CommunityServiceException(cleanMsg.isNotEmpty ? cleanMsg : 'Échec lors de la création de la publication.');
    }
  }

  Future<Map<String, dynamic>> voteCommunityPoll({
    required String postId,
    required List<String> optionIds,
  }) async {
    try {
      return await _repository.voteCommunityPoll(postId: postId, optionIds: optionIds);
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '').replaceFirst('PostgrestException: ', '');
      throw CommunityServiceException(cleanMsg.isNotEmpty ? cleanMsg : 'Échec lors du vote.');
    }
  }

  Future<List<CommunityHashtag>> searchCommunityHashtags(String query, {int limit = 10}) async {
    try {
      final raw = await _repository.searchCommunityHashtags(query, limit: limit);
      return raw.map((e) => CommunityHashtag.fromJson(e)).toList();
    } catch (e) {
      debugPrint('[Error] searchCommunityHashtags: $e');
      return [];
    }
  }

  Future<List<CommunityHashtag>> getCommunityPostHashtags(String postId) async {
    try {
      final raw = await _repository.getCommunityPostHashtags(postId);
      return raw.map((e) => CommunityHashtag.fromJson(e)).toList();
    } catch (e) {
      debugPrint('[Error] getCommunityPostHashtags: $e');
      return [];
    }
  }

  Future<void> deleteCommunityComment(String commentId) async {
    try {
      await _repository.deleteCommunityComment(commentId);
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '').replaceFirst('PostgrestException: ', '');
      throw CommunityServiceException(cleanMsg.isNotEmpty ? cleanMsg : 'Échec lors de la suppression du commentaire.');
    }
  }

  Future<Map<String, dynamic>> getCommunityCommentReplies(String commentId, {int limit = 20, String? cursor}) async {
    try {
      return await _repository.getCommunityCommentReplies(commentId, limit: limit, cursor: cursor);
    } catch (e) {
      debugPrint('[Error] getCommunityCommentReplies: $e');
      return {'items': [], 'has_more': false, 'next_cursor': null};
    }
  }

  Future<void> reactToCommunityPost(String postId, String reaction) async {
    try {
      await _repository.reactToCommunityPost(postId, reaction);
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '').replaceFirst('PostgrestException: ', '');
      throw CommunityServiceException(cleanMsg.isNotEmpty ? cleanMsg : 'Échec lors de la réaction.');
    }
  }

  Future<void> removeCommunityPostReaction(String postId) async {
    try {
      await _repository.removeCommunityPostReaction(postId);
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '').replaceFirst('PostgrestException: ', '');
      throw CommunityServiceException(cleanMsg.isNotEmpty ? cleanMsg : 'Échec lors de la suppression de la réaction.');
    }
  }

  // --- Moderation Center Services ---

  Future<Map<String, dynamic>> getCommunityModerationCounts(String communityId) async {
    try {
      return await _repository.getCommunityModerationCounts(communityId);
    } catch (e) {
      throw CommunityServiceException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<Map<String, dynamic>> getCommunityPendingPostsRpc(String communityId, {int limit = 20, int offset = 0}) async {
    try {
      return await _repository.getCommunityPendingPostsRpc(communityId, limit: limit, offset: offset);
    } catch (e) {
      throw CommunityServiceException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<Map<String, dynamic>> getCommunityJoinRequestsRpc(String communityId, {int limit = 20, String? cursor}) async {
    try {
      return await _repository.getCommunityJoinRequestsRpc(communityId, limit: limit, cursor: cursor);
    } catch (e) {
      throw CommunityServiceException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> respondCommunityJoinRequestRpc(String requestId, bool accepted) async {
    try {
      await _repository.respondCommunityJoinRequest(requestId, accepted);
    } catch (e) {
      throw CommunityServiceException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<Map<String, dynamic>> getCommunitySpamQueue(String communityId, {int limit = 20, int offset = 0}) async {
    try {
      return await _repository.getCommunitySpamQueue(communityId, limit: limit, offset: offset);
    } catch (e) {
      throw CommunityServiceException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<Map<String, dynamic>> getCommunityReports(String communityId, {String status = 'open', int limit = 20, int offset = 0}) async {
    try {
      return await _repository.getCommunityReports(communityId, status: status, limit: limit, offset: offset);
    } catch (e) {
      throw CommunityServiceException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<Map<String, dynamic>> resolveCommunityReport(String reportId, String action, {String? note}) async {
    try {
      return await _repository.resolveCommunityReport(reportId, action, note: note);
    } catch (e) {
      throw CommunityServiceException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<Map<String, dynamic>> getCommunityAlerts(String communityId) async {
    try {
      return await _repository.getCommunityAlerts(communityId);
    } catch (e) {
      throw CommunityServiceException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<Map<String, dynamic>> updateCommunityFeatures(
    String communityId, {
    bool? membersListVisible,
    bool? allowReports,
    bool? allowComments,
    bool? allowReactions,
  }) async {
    try {
      return await _repository.updateCommunityFeatures(
        communityId,
        membersListVisible: membersListVisible,
        allowReports: allowReports,
        allowComments: allowComments,
        allowReactions: allowReactions,
      );
    } catch (e) {
      throw CommunityServiceException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<Map<String, dynamic>> getCommunityPostComments(
    String postId, {
    int limit = 20,
    String? cursor,
  }) async {
    try {
      return await _repository.getCommunityPostComments(postId, limit: limit, cursor: cursor);
    } catch (e) {
      debugPrint('[Error] getCommunityPostComments: $e');
      return {'items': [], 'has_more': false, 'next_cursor': null};
    }
  }

  Future<Map<String, dynamic>> commentCommunityPost({
    required String postId,
    required String content,
  }) async {
    try {
      final commentId = _repository.generateLocalId();
      return await _repository.commentCommunityPost(
        id: commentId,
        postId: postId,
        content: content,
      );
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '').replaceFirst('PostgrestException: ', '');
      throw CommunityServiceException(cleanMsg.isNotEmpty ? cleanMsg : 'Échec lors de la création du commentaire.');
    }
  }

  Future<Map<String, dynamic>> replyToCommunityComment({
    required String commentId,
    required String content,
  }) async {
    try {
      final replyId = _repository.generateLocalId();
      return await _repository.replyToCommunityComment(
        id: replyId,
        commentId: commentId,
        content: content,
      );
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '').replaceFirst('PostgrestException: ', '');
      throw CommunityServiceException(cleanMsg.isNotEmpty ? cleanMsg : 'Échec lors de la réponse au commentaire.');
    }
  }
}
