import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scrole/shared/models/interest_model.dart';

import '../../centre/models/news/community_exception.dart';
import '../../centre/models/news/create_community_request.dart';

/// Repository responsable UNIQUEMENT de l'appel Supabase pour la création
/// de communauté.
class CommunityRepository {
  final SupabaseClient client;

  CommunityRepository(this.client);

  /// Génère un UUID v4 côté client.
  String generateLocalId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    return '${_hex(bytes.sublist(0, 4))}-${_hex(bytes.sublist(4, 6))}-${_hex(bytes.sublist(6, 8))}-${_hex(bytes.sublist(8, 10))}-${_hex(bytes.sublist(10, 16))}';
  }

  String _hex(List<int> bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// Crée une communauté avec la RPC `create_community`.
  Future<Map<String, dynamic>> createCommunity(CreateCommunityRequest request) async {
    try {
      final response = await client.rpc(
        'create_community',
        params: request.toParams(),
      );
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      throw Exception('Erreur lors de la création de la communauté: $e');
    }
  }

  /// Récupère les communautés de l'utilisateur via la RPC `get_my_communities`.
  Future<List<Map<String, dynamic>>> getMyCommunities() async {
    try {
      final response = await client.rpc('get_my_communities');
      debugPrint('[MyCommunities] RPC get_my_communities returned ${(response as List).length} rows');
      return List<Map<String, dynamic>>.from(
        (response as List).map((row) => Map<String, dynamic>.from(row as Map)),
      );
    } catch (e) {
      debugPrint('[MyCommunities] Erreur getMyCommunities RPC: $e');
      throw Exception('Erreur récupération communautés: $e');
    }
  }

  /// Rejoindre une communauté via la RPC `join_community`.
  Future<Map<String, dynamic>> joinCommunity(String communityId) async {
    try {
      final response = await client.rpc(
        'join_community',
        params: {
          'p_community_id': communityId,
        },
      );
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return {};
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Échec lors de la demande d\'adhésion: $e');
    }
  }

  /// Annule une demande d'adhésion via la RPC `cancel_community_join_request`.
  Future<void> cancelCommunityJoinRequest(String requestId) async {
    try {
      await client.rpc(
        'cancel_community_join_request',
        params: {
          'p_request_id': requestId,
        },
      );
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Échec lors de l\'annulation de la demande d\'adhésion: $e');
    }
  }

  /// Quitter une communauté
  Future<void> leaveCommunity(String communityId) async {
    try {
      await client
          .from('community_members')
          .delete()
          .eq('community_id', communityId)
          .eq('user_id', client.auth.currentUser!.id);
    } catch (e) {
      throw Exception('Erreur lors de la sortie de la communauté: $e');
    }
  }

  /// Met à jour les informations d'une communauté via la RPC `update_community_info` (version complète avec description).
  Future<Map<String, dynamic>> updateCommunityInfo({
    required String id,
    required String name,
    required String description,
    String? photoProfile,
    String? photoCover,
  }) async {
    try {
      final response = await client.rpc(
        'update_community_info',
        params: {
          'p_id': id,
          'p_name': name,
          'p_description': description,
          if (photoProfile != null && photoProfile.isNotEmpty) 'p_photo_profile': photoProfile,
          if (photoCover != null && photoCover.isNotEmpty) 'p_photo_cover': photoCover,
        },
      );
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return {'id': id};
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Erreur mise à jour infos communauté: $e');
    }
  }

  /// Met à jour les règles d'accès d'une communauté via la RPC `update_community_access_rules`.
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
  }) async {
    try {
      await client.rpc(
        'update_community_access_rules',
        params: {
          'p_id': communityId,
          'p_countries_enabled': countriesEnabled,
          'p_allowed_countries': allowedCountries,
          'p_cities_enabled': citiesEnabled,
          'p_allowed_cities': allowedCities,
          'p_certification_required': certificationRequired,
          if (genderRestriction != null && genderRestriction.isNotEmpty) 'p_gender_restriction': genderRestriction,
          if (ageMin != null) 'p_age_min': ageMin,
          if (ageMax != null) 'p_age_max': ageMax,
        },
      );
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Erreur mise à jour règles d\'accès: $e');
    }
  }

  /// Supprimer une communauté (doit être propriétaire)
  Future<void> deleteCommunity(String communityId) async {
    try {
      // On utilise une RPC pour s'assurer que toutes les tables liées
      // (settings, roles, members, rooms) sont nettoyées proprement.
      await client.rpc('supprimer_communaute', params: {'p_community_id': communityId});
    } catch (e) {
      // Fallback si la RPC n'existe pas : suppression directe
      try {
        await client.from('communities').delete().eq('id', communityId);
      } catch (inner) {
        throw Exception('Erreur lors de la suppression de la communauté: $inner');
      }
    }
  }

  /// Récupère les membres d'une communauté
  Future<List<Map<String, dynamic>>> getCommunityMembers(String communityId) async {
    try {
      final response = await client
          .from('community_members')
          .select('*, user_profiles(*)')
          .eq('community_id', communityId);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Erreur récupération membres: $e');
    }
  }

  /// Retire un membre d'une communauté via la RPC `remove_community_member`.
  Future<void> removeCommunityMember(String communityId, String userId) async {
    try {
      await client.rpc(
        'remove_community_member',
        params: {
          'p_community_id': communityId,
          'p_user_id': userId,
        },
      );
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Erreur lors du retrait du membre: $e');
    }
  }

  /// Met à jour le rôle d'un membre d'une communauté via la RPC `update_community_member_role`.
  Future<void> updateCommunityMemberRole(String communityId, String userId, String role) async {
    try {
      await client.rpc(
        'update_community_member_role',
        params: {
          'p_community_id': communityId,
          'p_user_id': userId,
          'p_role': role,
        },
      );
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du rôle: $e');
    }
  }

  /// Invite un utilisateur dans une communauté via la RPC `invite_to_community`.
  Future<void> inviteToCommunity(String communityId, String userId) async {
    try {
      await client.rpc(
        'invite_to_community',
        params: {
          'p_community_id': communityId,
          'p_user_id': userId,
        },
      );
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Erreur lors de l\'invitation: $e');
    }
  }

  /// Met à jour les paramètres généraux d'une communauté via la RPC `update_community_settings`.
  Future<void> updateCommunitySettings({
    required String communityId,
    required String visibility,
    required bool requireManualApproval,
  }) async {
    try {
      await client.rpc(
        'update_community_settings',
        params: {
          'p_id': communityId,
          'p_visibility': visibility,
          'p_require_manual_approval': requireManualApproval,
        },
      );
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Erreur mise à jour paramètres communauté: $e');
    }
  }

  /// Met à jour les paramètres de publication d'une communauté via la RPC `update_community_post_settings`.
  Future<void> updateCommunityPostSettings({
    required String communityId,
    required String postPermission,
    required bool postsRequireApproval,
  }) async {
    try {
      await client.rpc(
        'update_community_post_settings',
        params: {
          'p_community_id': communityId,
          'p_post_permission': postPermission,
          'p_posts_require_approval': postsRequireApproval,
        },
      );
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Erreur mise à jour paramètres de publication: $e');
    }
  }

  /// Met à jour les intérêts d'une communauté via la RPC `update_community_interests`.
  Future<void> updateCommunityInterests({
    required String communityId,
    required List<String> interestIds,
  }) async {
    try {
      await client.rpc(
        'update_community_interests',
        params: {
          'p_community_id': communityId,
          'p_interest_ids': interestIds,
        },
      );
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Erreur mise à jour intérêts communauté: $e');
    }
  }

  /// Récupère les centres d'intérêt d'une communauté.
  Future<List<Interest>> getCommunityInterests(String communityId) async {
    try {
      final data = await client
          .from('community_interests')
          .select('interest_id, interests(*)')
          .eq('community_id', communityId);
      final List<Interest> list = [];
      for (final row in data) {
        if (row['interests'] is Map) {
          list.add(Interest.fromJson(Map<String, dynamic>.from(row['interests'] as Map)));
        }
      }
      return list;
    } catch (e) {
      debugPrint('[CommunityRepository] getCommunityInterests error: $e');
      return [];
    }
  }

  /// Récupère tous les rôles définis pour une communauté
  Future<List<Map<String, dynamic>>> getCommunityRoles(String communityId) async {
    try {
      final response = await client
          .from('community_roles')
          .select()
          .eq('community_id', communityId);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Erreur récupération rôles: $e');
    }
  }

  /// Récupère les demandes d'adhésion en attente d'une communauté via la RPC `get_community_join_requests`.
  Future<Map<String, dynamic>> getCommunityJoinRequests(
    String communityId, {
    int limit = 20,
    String? cursor,
  }) async {
    try {
      final response = await client.rpc(
        'get_community_join_requests',
        params: {
          'p_community_id': communityId,
          'p_limit': limit,
          if (cursor != null && cursor.isNotEmpty) 'p_cursor': cursor,
        },
      );
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return {'items': [], 'has_more': false, 'next_cursor': null};
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Erreur récupération demandes d\'adhésion: $e');
    }
  }

  /// Accepte ou refuse une demande d'adhésion via la RPC `respond_community_join_request`.
  Future<void> respondCommunityJoinRequest(String requestId, bool accepted) async {
    try {
      await client.rpc(
        'respond_community_join_request',
        params: {
          'p_request_id': requestId,
          'p_accepted': accepted,
        },
      );
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Erreur traitement demande d\'adhésion: $e');
    }
  }

  /// Rechercher des communautés (Découverte)
  Future<List<Map<String, dynamic>>> discoverCommunities() async {
    try {
      final response = await client
          .from('communities')
          .select()
          .eq('visibility', 'public')
          .eq('status', 'active')
          .limit(20);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Erreur lors de la recherche de communautés: $e');
    }
  }

  /// Rechercher des communautés par nom ou slug
  Future<List<Map<String, dynamic>>> searchCommunities(String term) async {
    try {
      final response = await client
          .from('communities')
          .select()
          .or('name.ilike.%$term%,slug.ilike.%$term%')
          .eq('visibility', 'public')
          .eq('status', 'active')
          .limit(20);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Erreur recherche communautés: $e');
      return [];
    }
  }

  /// La RPC `get_community_preview` renvoie `member_count` à la racine de la
  /// ligne, à côté de l'objet `community` (et non dedans). On le recopie
  /// dans `community` pour que `Community.fromJson` lise la vraie valeur
  /// au lieu de retomber sur son défaut. Les clés racine sont conservées.
  Map<String, dynamic> _normalizePreviewRow(Map raw) {
    final row = Map<String, dynamic>.from(raw);
    final community = row['community'];
    if (community is Map) {
      final communityMap = Map<String, dynamic>.from(community);
      if (row['member_count'] != null) {
        communityMap['member_count'] = row['member_count'];
      }
      row['community'] = communityMap;
    }
    return row;
  }

  /// Récupère les données de prévisualisation d'une communauté via la RPC `get_community_preview`.
  Future<Map<String, dynamic>> getPublicCommunityData(String communityIdOrSlug) async {
    String slug = communityIdOrSlug;

    // Si la chaîne passée est un UUID (ex: depuis les résultats de search_all), on résout le vrai slug depuis `communities`
    if (RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(communityIdOrSlug)) {
      try {
        final comm = await client
            .from('communities')
            .select('slug')
            .eq('id', communityIdOrSlug)
            .maybeSingle();
        if (comm != null && comm['slug'] != null && comm['slug'].toString().isNotEmpty) {
          slug = comm['slug'].toString();
        }
      } catch (e) {
        debugPrint('[CommunityRepository] Résolution slug par ID ($communityIdOrSlug) échouée: $e');
      }
    }

    debugPrint('[CommunityRepository] Appel get_community_preview avec p_slug = "$slug"');

    try {
      final response = await client.rpc(
        'get_community_preview',
        params: {'p_slug': slug},
      );

      debugPrint('[CommunityRepository] RPC get_community_preview response type: ${response.runtimeType}, value: $response');

      if (response != null) {
        if (response is List) {
          debugPrint('[CommunityRepository] RPC response type = List, length = ${response.length}');
          if (response.isNotEmpty) {
            final first = response.first;
            if (first is Map) {
              debugPrint('[CommunityRepository] get_community_preview success (List[0]) pour "$slug"');
              return _normalizePreviewRow(first);
            }
          }
        } else if (response is Map) {
          debugPrint('[CommunityRepository] get_community_preview success (Map) pour "$slug"');
          return _normalizePreviewRow(response);
        }
      }

      throw Exception('Communauté introuvable pour le slug: $slug');
    } catch (e) {
      debugPrint('[CommunityRepository] get_community_preview error pour "$slug": $e');
      rethrow;
    }
  }

  /// Récupère l'adhésion complète de l'utilisateur pour une communauté donnée
  Future<Map<String, dynamic>?> getMembership(String communityId) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) return null;

      // On joint via communities pour accéder aux settings
      return await client
          .from('community_members')
          .select('*, communities(community_settings(*))')
          .eq('community_id', communityId)
          .eq('user_id', userId)
          .maybeSingle();
    } catch (e) {
      debugPrint('Erreur getMembership: $e');
      return null;
    }
  }

  /// Vérifie le statut d'adhésion d'un utilisateur à une communauté
  /// Retourne 'active', 'pending', 'refused' ou 'none'.
  Future<String> getMemberStatus(String communityId) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) return 'none';

      final response = await client
          .from('community_members')
          .select('status')
          .eq('community_id', communityId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return 'none';
      return response['status']?.toString() ?? 'none';
    } catch (e) {
      debugPrint('Erreur vérification statut membre: $e');
      return 'none';
    }
  }

  /// Récupère le feed d'une communauté via la RPC `get_community_feed` avec pagination par curseur.
  Future<Map<String, dynamic>> getCommunityFeed(String communityId, {int limit = 20, String? cursor}) async {
    try {
      final response = await client.rpc(
        'get_community_feed',
        params: {
          'p_community_id': communityId,
          'p_limit': limit,
          if (cursor != null) 'p_cursor': cursor,
        },
      );
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      } else if (response is List) {
        return {'items': response, 'has_more': false, 'next_cursor': null};
      }
      return {'items': [], 'has_more': false, 'next_cursor': null};
    } catch (e) {
      throw Exception('Erreur lors du chargement du feed: $e');
    }
  }

  /// Récupère les communautés à découvrir via la RPC `get_discover_communities`.
  Future<List<Map<String, dynamic>>> getDiscoverCommunities({int limit = 10, int offset = 0}) async {
    try {
      final response = await client.rpc(
        'get_discover_communities',
        params: {
          'p_limit': limit,
          'p_offset': offset,
        },
      );
      if (response is List) {
        return List<Map<String, dynamic>>.from(
          response.map((row) => Map<String, dynamic>.from(row as Map)),
        );
      }
      return [];
    } catch (e) {
      throw Exception('Erreur lors de la récupération des communautés à découvrir: $e');
    }
  }

  /// Crée une publication dans une communauté via la RPC `create_community_post`.
  Future<Map<String, dynamic>> createCommunityPost({
    required String id,
    required String communityId,
    String? content,
    List<Map<String, dynamic>> media = const [],
    bool commentsEnabled = true,
    bool sharingEnabled = true,
    bool reactionsEnabled = true,
    List<String> hashtags = const [],
    List<String> mentions = const [],
    Map<String, dynamic>? poll,
  }) async {
    try {
      final response = await client.rpc(
        'create_community_post',
        params: {
          'p_id': id,
          'p_community_id': communityId,
          'p_content': (content != null && content.trim().isNotEmpty) ? content.trim() : null,
          'p_photos': <String>[],
          'p_comments_enabled': commentsEnabled,
          'p_sharing_enabled': sharingEnabled,
          'p_hashtags': hashtags,
          'p_mentions': mentions,
          'p_reactions_enabled': reactionsEnabled,
          'p_video_url': null,
          'p_video_thumbnail_url': null,
          'p_video_duration_ms': null,
          'p_video_size_bytes': null,
          'p_poll': poll,
          'p_media': media,
        },
      );
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return {'id': id, 'community_id': communityId};
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Échec lors de la création de la publication: $e');
    }
  }

  /// Vote sur un sondage via la RPC `vote_community_poll`.
  Future<Map<String, dynamic>> voteCommunityPoll({
    required String postId,
    required List<String> optionIds,
  }) async {
    try {
      final response = await client.rpc(
        'vote_community_poll',
        params: {
          'p_post_id': postId,
          'p_option_ids': optionIds,
        },
      );
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return {};
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Échec du vote: $e');
    }
  }

  /// Recherche des hashtags via la RPC `search_community_hashtags`.
  Future<List<Map<String, dynamic>>> searchCommunityHashtags(String query, {int limit = 10}) async {
    try {
      final response = await client.rpc(
        'search_community_hashtags',
        params: {
          'p_query': query,
          'p_limit': limit,
        },
      );
      if (response is List) {
        return List<Map<String, dynamic>>.from(
          response.map((row) => Map<String, dynamic>.from(row as Map)),
        );
      }
      return [];
    } catch (e) {
      debugPrint('[CommunityRepository] searchCommunityHashtags error: $e');
      return [];
    }
  }

  /// Récupère les hashtags d'une publication via la RPC `get_community_post_hashtags`.
  Future<List<Map<String, dynamic>>> getCommunityPostHashtags(String postId) async {
    try {
      final response = await client.rpc(
        'get_community_post_hashtags',
        params: {
          'p_post_id': postId,
        },
      );
      if (response is List) {
        return List<Map<String, dynamic>>.from(
          response.map((row) => Map<String, dynamic>.from(row as Map)),
        );
      }
      return [];
    } catch (e) {
      debugPrint('[CommunityRepository] getCommunityPostHashtags error: $e');
      return [];
    }
  }

  /// Supprime un commentaire ou une réponse via la RPC `delete_community_comment`.
  Future<void> deleteCommunityComment(String commentId) async {
    try {
      await client.rpc(
        'delete_community_comment',
        params: {
          'p_id': commentId,
        },
      );
    } catch (e) {
      throw Exception('Erreur lors de la suppression du commentaire: $e');
    }
  }

  /// Récupère les réponses à un commentaire via la RPC `get_community_comment_replies`.
  Future<Map<String, dynamic>> getCommunityCommentReplies(String commentId, {int limit = 20, String? cursor}) async {
    try {
      final response = await client.rpc(
        'get_community_comment_replies',
        params: {
          'p_comment_id': commentId,
          'p_limit': limit,
          if (cursor != null) 'p_cursor': cursor,
        },
      );
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      } else if (response is List) {
        return {'items': response, 'has_more': false, 'next_cursor': null};
      }
      return {'items': [], 'has_more': false, 'next_cursor': null};
    } catch (e) {
      throw Exception('Erreur lors du chargement des réponses: $e');
    }
  }

  /// Récupère les publications en attente de modération via la RPC `get_community_pending_posts`.
  Future<Map<String, dynamic>> getCommunityPendingPosts(String communityId, {int limit = 20, int offset = 0}) async {
    try {
      final response = await client.rpc(
        'get_community_pending_posts',
        params: {
          'p_community_id': communityId,
          'p_limit': limit,
          'p_offset': offset,
        },
      );
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      } else if (response is List) {
        return {'items': response, 'has_more': false};
      }
      return {'items': [], 'has_more': false};
    } catch (e) {
      throw Exception('Erreur lors du chargement des publications en attente: $e');
    }
  }

  /// Modère une publication via la RPC `moderate_community_post` ('approve' / 'reject').
  Future<void> moderateCommunityPost(String postId, String action) async {
    try {
      await client.rpc(
        'moderate_community_post',
        params: {
          'p_post_id': postId,
          'p_action': action,
        },
      );
    } catch (e) {
      throw Exception('Erreur lors de la modération de la publication: $e');
    }
  }

  /// Supprime définitivement une publication via l'Edge Function `delete-community-post`.
  Future<void> deleteCommunityPost(String postId) async {
    debugPrint('[COMMUNITY_POST_DELETE][REPOSITORY] Deleting post=$postId');
    debugPrint('[COMMUNITY_POST_DELETE][SERVICE] Calling backend for post=$postId');
    debugPrint('[COMMUNITY_POST_DELETE] Starting deletion');
    debugPrint('[COMMUNITY_POST_DELETE] postId=$postId');
    debugPrint('[COMMUNITY_POST_DELETE] Calling delete-community-post');
    debugPrint('[COMMUNITY_POST_DELETE] Service request started');
    debugPrint('[COMMUNITY_POST_DELETE] Endpoint=delete-community-post');

    try {
      debugPrint('[COMMUNITY_POST_DELETE][REPOSITORY] Invoking Edge Function delete-community-post with post_id: $postId');
      final response = await client.functions.invoke(
        'delete-community-post',
        body: {'post_id': postId},
      );

      debugPrint('[COMMUNITY_POST_DELETE] Response received');
      debugPrint('[COMMUNITY_POST_DELETE] status=${response.status}');
      debugPrint('[COMMUNITY_POST_DELETE][SERVICE] Backend returned status=${response.status}');

      if (response.status == 200) {
        debugPrint('[COMMUNITY_POST_DELETE] Backend deletion SUCCESS');
        debugPrint('[COMMUNITY_POST_DELETE] postId=$postId');
        debugPrint('[COMMUNITY_POST_DELETE][REPOSITORY] Deletion succeeded');
      } else {
        final errorMsg = response.data?.toString() ?? 'Statut ${response.status}';
        debugPrint('[COMMUNITY_POST_DELETE] Backend deletion FAILED');
        debugPrint('[COMMUNITY_POST_DELETE] status=${response.status}');
        debugPrint('[COMMUNITY_POST_DELETE] error=$errorMsg');
        throw Exception(errorMsg);
      }
    } on PostgrestException catch (e) {
      debugPrint('[COMMUNITY_POST_DELETE] Backend deletion FAILED');
      debugPrint('[COMMUNITY_POST_DELETE] error=${e.message}');
      throw Exception(e.message);
    } catch (e) {
      debugPrint('[COMMUNITY_POST_DELETE] Backend deletion FAILED');
      debugPrint('[COMMUNITY_POST_DELETE] error=$e');
      throw Exception('Erreur lors de la suppression de la publication: $e');
    }
  }

  /// Réagit à une publication (like ou dislike) via la RPC `react_to_community_post`.
  Future<void> reactToCommunityPost(String postId, String reaction) async {
    try {
      await client.rpc(
        'react_to_community_post',
        params: {
          'p_post_id': postId,
          'p_reaction': reaction,
        },
      );
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Erreur lors de la réaction: $e');
    }
  }

  /// Retire la réaction d'une publication via la RPC `remove_community_post_reaction`.
  Future<void> removeCommunityPostReaction(String postId) async {
    try {
      await client.rpc(
        'remove_community_post_reaction',
        params: {
          'p_post_id': postId,
        },
      );
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Échec lors de la suppression de la réaction: $e');
    }
  }

  /// Récupère les commentaires d'une publication via la RPC `get_community_post_comments`.
  Future<Map<String, dynamic>> getCommunityPostComments(
      String postId, {
        int limit = 20,
        String? cursor,
      }) async {
    try {
      final response = await client.rpc(
        'get_community_post_comments',
        params: {
          'p_post_id': postId,
          'p_limit': limit,
          'p_cursor': cursor,
        },
      );
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      } else if (response is List) {
        return {'items': response, 'has_more': false, 'next_cursor': null};
      }
      return {'items': [], 'has_more': false, 'next_cursor': null};
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Erreur lors du chargement des commentaires: $e');
    }
  }

  /// Crée un commentaire principal via la RPC `comment_community_post`.
  Future<Map<String, dynamic>> commentCommunityPost({
    required String id,
    required String postId,
    required String content,
  }) async {
    try {
      final response = await client.rpc(
        'comment_community_post',
        params: {
          'p_id': id,
          'p_post_id': postId,
          'p_content': content.trim(),
        },
      );
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return {'id': id, 'post_id': postId, 'content': content};
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Échec lors de la création du commentaire: $e');
    }
  }

  /// Crée une réponse à un commentaire via la RPC `reply_to_community_comment`.
  Future<Map<String, dynamic>> replyToCommunityComment({
    required String id,
    required String commentId,
    required String content,
  }) async {
    try {
      final response = await client.rpc(
        'reply_to_community_comment',
        params: {
          'p_id': id,
          'p_comment_id': commentId,
          'p_content': content.trim(),
        },
      );
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return {'id': id, 'parent_comment_id': commentId, 'content': content};
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Échec lors de la réponse au commentaire: $e');
    }
  }

  // --- MODERATION CENTER RPCs ---

  Future<Map<String, dynamic>> getCommunityModerationCounts(String communityId) async {
    try {
      final res = await client.rpc('get_community_moderation_counts', params: {'p_community_id': communityId});
      if (res is Map) return Map<String, dynamic>.from(res);
      return {};
    } catch (e) {
      throw Exception('Erreur counts modération: $e');
    }
  }

  Future<Map<String, dynamic>> getCommunityPendingPostsRpc(String communityId, {int limit = 20, int offset = 0}) async {
    try {
      final res = await client.rpc('get_community_pending_posts', params: {'p_community_id': communityId, 'p_limit': limit, 'p_offset': offset});
      if (res is Map) return Map<String, dynamic>.from(res);
      if (res is List) return {'items': res, 'has_more': false};
      return {'items': [], 'has_more': false};
    } catch (e) {
      throw Exception('Erreur pending posts: $e');
    }
  }

  Future<Map<String, dynamic>> getCommunityJoinRequestsRpc(String communityId, {int limit = 20, String? cursor}) async {
    try {
      final params = <String, dynamic>{'p_community_id': communityId, 'p_limit': limit};
      if (cursor != null && cursor.isNotEmpty) params['p_cursor'] = cursor;
      final res = await client.rpc('get_community_join_requests', params: params);
      if (res is Map) return Map<String, dynamic>.from(res);
      if (res is List) return {'items': res, 'has_more': false};
      return {'items': [], 'has_more': false};
    } catch (e) {
      throw Exception('Erreur join requests: $e');
    }
  }

  Future<Map<String, dynamic>> getCommunitySpamQueue(String communityId, {int limit = 20, int offset = 0}) async {
    try {
      final res = await client.rpc('get_community_spam_queue', params: {'p_community_id': communityId, 'p_limit': limit, 'p_offset': offset});
      if (res is Map) return Map<String, dynamic>.from(res);
      if (res is List) return {'items': res, 'has_more': false};
      return {'items': [], 'has_more': false};
    } catch (e) {
      throw Exception('Erreur spam queue: $e');
    }
  }

  Future<Map<String, dynamic>> getCommunityReports(String communityId, {String status = 'open', int limit = 20, int offset = 0}) async {
    try {
      final res = await client.rpc('get_community_reports', params: {'p_community_id': communityId, 'p_status': status, 'p_limit': limit, 'p_offset': offset});
      if (res is Map) return Map<String, dynamic>.from(res);
      if (res is List) return {'items': res, 'has_more': false};
      return {'items': [], 'has_more': false};
    } catch (e) {
      throw Exception('Erreur reports: $e');
    }
  }

  Future<Map<String, dynamic>> resolveCommunityReport(String reportId, String action, {String? note}) async {
    try {
      final params = <String, dynamic>{'p_report_id': reportId, 'p_action': action};
      if (note != null && note.isNotEmpty) params['p_note'] = note;
      final res = await client.rpc('resolve_community_report', params: params);
      if (res is Map) return Map<String, dynamic>.from(res);
      return {};
    } catch (e) {
      throw Exception('Erreur résolution report: $e');
    }
  }

  Future<Map<String, dynamic>> getCommunityAlerts(String communityId) async {
    try {
      final res = await client.rpc('get_community_alerts', params: {'p_community_id': communityId});
      if (res is Map) return Map<String, dynamic>.from(res);
      if (res is List) return {'items': res, 'count': res.length};
      return {'items': [], 'count': 0};
    } catch (e) {
      throw Exception('Erreur alerts: $e');
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
      final params = <String, dynamic>{'p_community_id': communityId};
      if (membersListVisible != null) params['p_members_list_visible'] = membersListVisible;
      if (allowReports != null) params['p_allow_reports'] = allowReports;
      if (allowComments != null) params['p_allow_comments'] = allowComments;
      if (allowReactions != null) params['p_allow_reactions'] = allowReactions;

      final res = await client.rpc('update_community_features', params: params);
      if (res is Map) return Map<String, dynamic>.from(res);
      return {};
    } catch (e) {
      throw Exception('Erreur update features: $e');
    }
  }

  /// Heuristique de classification des erreurs Postgres/PostgREST.
  /// À affiner si la RPC renvoie des codes d'erreur applicatifs dédiés
  /// (ex: via `RAISE EXCEPTION USING ERRCODE = ...`).
  CommunityErrorCode _mapPostgrestCode(PostgrestException e) {
    final message = e.message.toLowerCase();
    final code = e.code ?? '';

    if (code == '23505' || message.contains('duplicate') || message.contains('unique')) {
      if (message.contains('slug')) return CommunityErrorCode.duplicateSlug;
    }
    if (message.contains('slug')) return CommunityErrorCode.invalidSlug;
    if (message.contains('name')) return CommunityErrorCode.invalidName;
    if (message.contains('visibility')) return CommunityErrorCode.invalidVisibility;
    if (code == '401' || message.contains('jwt') || message.contains('auth')) {
      return CommunityErrorCode.unauthenticated;
    }
    return CommunityErrorCode.unknown;
  }
}