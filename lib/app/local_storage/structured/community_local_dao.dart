import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../modules/module_communautes/centre/models/news/community.dart';
import '../../../modules/module_communautes/centre/models/news/community_membership.dart';
import '../../../modules/module_communautes/centre/models/news/community_roles.dart';
import '../../../modules/module_communautes/centre/models/news/community_settings.dart';
import '../../../modules/module_communautes/centre/models/news/create_community_result.dart';
import 'app_cache_database.dart';
import 'community_with_role.dart';

/// DAO pour la gestion locale des communautés.
class CommunityLocalDao {
  final AppDatabase _appDb;

  CommunityLocalDao(this._appDb);

  Future<Database> get _db async => _appDb.database;

  final StreamController<void> _changesController = StreamController<void>.broadcast();
  Stream<void> get changes => _changesController.stream;

  void notifyChanges() {
    if (!_changesController.isClosed) {
      _changesController.add(null);
    }
  }

  // ---------------------------------------------------------------------
  // Écriture
  // ---------------------------------------------------------------------

  /// Sauvegarde le résultat de la création d'une communauté.
  Future<void> saveCreateCommunityResult(CreateCommunityResult result) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.insert(
        'communities',
        _communityRow(result.community, now),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.insert(
        'community_settings',
        _settingsRow(result.community.id, result.settings),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (final role in _rolesRows(result.community.id, result.roles)) {
        await txn.insert(
          'community_roles',
          role,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await txn.insert(
        'community_members',
        _membershipRow(result.community.id, result.membership, now),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
    notifyChanges();
  }

  /// Mise à jour des communautés.
  Future<void> upsertCommunities(List<Community> communities) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = db.batch();
    for (final c in communities) {
      batch.insert(
        'communities',
        _communityRow(c, now),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    notifyChanges();
  }

  // ---------------------------------------------------------------------
  // Lecture — jointures
  // ---------------------------------------------------------------------

  /// Récupère les communautés de l'utilisateur avec son rôle.
  Future<List<CommunityWithRole>> getMyCommunities(String userId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      '''
      SELECT
        c.id, c.name, c.slug, c.description, c.avatar_url, c.banner_url,
        c.visibility, c.status, c.member_count,
        r.name AS role_name,
        m.status AS membership_status
      FROM communities c
      INNER JOIN community_members m ON m.community_id = c.id
      LEFT JOIN community_roles r ON r.id = m.role_id
      WHERE m.user_id = ?
      ORDER BY c.name COLLATE NOCASE
    ''',
      [userId],
    );

    return rows.map(_communityWithRoleFromRow).toList();
  }

  /// Récupère une communauté avec ses réglages.
  Future<({Community community, CommunitySettings? settings})?>
  getCommunityWithSettings(String communityId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      '''
      SELECT
        c.id, c.name, c.slug, c.description, c.avatar_url, c.banner_url,
        c.visibility, c.status, c.member_count,
        s.post_permission, s.posts_require_approval, s.members_list_visible,
        s.allow_reports, s.allow_comments, s.allow_reactions
      FROM communities c
      LEFT JOIN community_settings s ON s.community_id = c.id
      WHERE c.id = ?
      LIMIT 1
    ''',
      [communityId],
    );

    if (rows.isEmpty) return null;
    final row = rows.first;

    return (
      community: _communityFromRow(row),
      settings: row['post_permission'] == null
          ? null
          : CommunitySettings(
              postPermission: row['post_permission'].toString(),
              postsRequireApproval: (row['posts_require_approval'] as int) == 1,
              membersListVisible: (row['members_list_visible'] as int) == 1,
              allowReports: (row['allow_reports'] as int) == 1,
              allowComments: row['allow_comments'] == null ? true : (row['allow_comments'] as int) == 1,
              allowReactions: row['allow_reactions'] == null ? true : (row['allow_reactions'] as int) == 1,
            ),
    );
  }

  /// Récupère les membres d'une communauté avec leur rôle.
  Future<List<Map<String, dynamic>>> getMembersWithRole(
    String communityId,
  ) async {
    final db = await _db;
    return db.rawQuery(
      '''
      SELECT m.id, m.user_id, m.status, r.name AS role_name
      FROM community_members m
      INNER JOIN community_roles r ON r.id = m.role_id
      WHERE m.community_id = ?
      ORDER BY
        CASE r.name
          WHEN 'Owner' THEN 0
          WHEN 'Admin' THEN 1
          WHEN 'Moderator' THEN 2
          ELSE 3
        END,
        m.id
    ''',
      [communityId],
    );
  }

  // ---------------------------------------------------------------------
  // Lecture — simple
  // ---------------------------------------------------------------------

  Future<Community?> getCommunityById(String id) async {
    final db = await _db;
    final rows = await db.query(
      'communities',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : _communityFromRow(rows.first);
  }

  Future<List<Community>> getAllCommunities() async {
    final db = await _db;
    final rows = await db.query('communities', orderBy: 'name COLLATE NOCASE');
    return rows.map(_communityFromRow).toList();
  }

  // ---------------------------------------------------------------------
  // Suppression
  // ---------------------------------------------------------------------

  /// Supprime une communauté et ses données liées.
  Future<void> deleteCommunity(String id) async {
    final db = await _db;
    await db.delete('communities', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await _db;
    await db.transaction((txn) async {
      // L'ordre ne compte pas grâce au CASCADE, mais on vide explicitement
      // pour rester lisible / robuste si le CASCADE est un jour retiré.
      await txn.delete('community_members');
      await txn.delete('community_roles');
      await txn.delete('community_settings');
      await txn.delete('communities');
    });
  }

  // ---------------------------------------------------------------------
  // Mapping Map<String,dynamic> (ligne SQL) <-> modèles
  // ---------------------------------------------------------------------

  Map<String, dynamic> _communityRow(Community c, int cachedAt) => {
    'id': c.id,
    'name': c.name,
    'slug': c.slug,
    'description': c.description,
    'avatar_url': c.avatarUrl,
    'banner_url': c.bannerUrl,
    'visibility': c.visibility,
    'status': c.status,
    'member_count': c.memberCount,
    'cached_at': cachedAt,
  };

  Community _communityFromRow(Map<String, dynamic> row) => Community(
    id: row['id'] as String,
    name: row['name'] as String,
    slug: row['slug'] as String,
    description: row['description'] as String?,
    avatarUrl: row['avatar_url'] as String?,
    bannerUrl: row['banner_url'] as String?,
    visibility: row['visibility'] as String,
    status: row['status'] as String,
    memberCount: row['member_count'] as int,
  );

  Map<String, dynamic> _settingsRow(String communityId, CommunitySettings s) =>
      {
        'community_id': communityId,
        'post_permission': s.postPermission,
        'posts_require_approval': s.postsRequireApproval ? 1 : 0,
        'members_list_visible': s.membersListVisible ? 1 : 0,
        'allow_reports': s.allowReports ? 1 : 0,
        'allow_comments': s.allowComments ? 1 : 0,
        'allow_reactions': s.allowReactions ? 1 : 0,
      };

  List<Map<String, dynamic>> _rolesRows(
    String communityId,
    CommunityRoles roles,
  ) => [
    {'id': roles.ownerId, 'community_id': communityId, 'name': 'Owner'},
    {'id': roles.adminId, 'community_id': communityId, 'name': 'Admin'},
    {'id': roles.moderatorId, 'community_id': communityId, 'name': 'Moderator'},
    {'id': roles.memberId, 'community_id': communityId, 'name': 'Member'},
  ];

  Map<String, dynamic> _membershipRow(
    String communityId,
    CommunityMembership m,
    int cachedAt,
  ) => {
    'id': m.id,
    'community_id': communityId,
    'user_id': m.userId,
    'role_id': m.roleId,
    'status': m.status,
    'cached_at': cachedAt,
  };

  CommunityWithRole _communityWithRoleFromRow(Map<String, dynamic> row) =>
      CommunityWithRole(
        community: _communityFromRow(row),
        roleName: (row['role_name'] ?? 'Membre').toString(),
        membershipStatus: (row['membership_status'] ?? 'active').toString(),
      );

  /// Récupère une preview cachée par ID ou slug
  Future<Map<String, dynamic>?> getCachedPreview(String communityIdOrSlug) async {
    final db = await _db;
    final rows = await db.query(
      'community_preview_cache',
      where: 'community_id = ? OR slug = ?',
      whereArgs: [communityIdOrSlug, communityIdOrSlug],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    final communityId = row['community_id'] as String;
    
    await db.update(
      'community_preview_cache',
      {'last_accessed_at': DateTime.now().millisecondsSinceEpoch},
      where: 'community_id = ?',
      whereArgs: [communityId],
    );

    final payloadStr = row['payload'] as String;
    return jsonDecode(payloadStr) as Map<String, dynamic>;
  }

  /// Sauvegarde une preview et applique l'éviction LRU (max 10 entrées)
  Future<void> saveCachedPreview(String communityId, String slug, Map<String, dynamic> payloadMap) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.insert(
        'community_preview_cache',
        {
          'community_id': communityId,
          'slug': slug,
          'payload': jsonEncode(payloadMap),
          'cached_at': now,
          'last_accessed_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.execute('''
        DELETE FROM community_preview_cache
        WHERE community_id NOT IN (
          SELECT community_id FROM community_preview_cache
          ORDER BY last_accessed_at DESC
          LIMIT 10
        )
      ''');
    });
  }

  // --- OUTBOX & FEED CACHE ---

  Future<int> enqueueCommunityOutboxOperation({
    required String operationId,
    required String userId,
    String? communityId,
    String? postId,
    String? commentId,
    required String operationType,
    required Map<String, dynamic> payload,
  }) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    return await db.insert('community_outbox', {
      'operation_id': operationId,
      'user_id': userId,
      'community_id': communityId,
      'post_id': postId,
      'comment_id': commentId,
      'operation_type': operationType,
      'payload': jsonEncode(payload),
      'status': 'pending',
      'attempt_count': 0,
      'next_retry_at': 0,
      'last_error': null,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingCommunityOutboxOperations(String userId) async {
    final db = await _db;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return await db.query(
      'community_outbox',
      where: 'user_id = ? AND status = ? AND next_retry_at <= ?',
      whereArgs: [userId, 'pending', nowMs],
      orderBy: 'id ASC',
    );
  }

  Future<void> lockCommunityOutboxOperation(int id) async {
    final db = await _db;
    await db.update(
      'community_outbox',
      {'status': 'processing', 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markCommunityOutboxOperationCompleted(int id) async {
    final db = await _db;
    await db.delete('community_outbox', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markCommunityOutboxOperationRetry({
    required int id,
    required int attemptCount,
    required int nextRetryAt,
    required String lastError,
  }) async {
    final db = await _db;
    await db.update(
      'community_outbox',
      {
        'status': 'pending',
        'attempt_count': attemptCount,
        'next_retry_at': nextRetryAt,
        'last_error': lastError,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markCommunityOutboxOperationFailed({
    required int id,
    required String lastError,
  }) async {
    final db = await _db;
    await db.update(
      'community_outbox',
      {
        'status': 'failed',
        'last_error': lastError,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePendingOperationByTypeAndPost({
    required String userId,
    required String postId,
    required String operationType,
  }) async {
    final db = await _db;
    await db.delete(
      'community_outbox',
      where: 'user_id = ? AND post_id = ? AND operation_type = ? AND status = ?',
      whereArgs: [userId, postId, operationType, 'pending'],
    );
  }

  Future<Map<String, dynamic>?> getCachedFeed(String communityId) async {
    final db = await _db;
    final rows = await db.query(
      'community_feed_cache',
      where: 'community_id = ?',
      whereArgs: [communityId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['payload'] as String) as Map<String, dynamic>;
  }

  Future<void> saveCachedFeed(String communityId, Map<String, dynamic> payloadMap) async {
    final db = await _db;
    await db.insert(
      'community_feed_cache',
      {
        'community_id': communityId,
        'payload': jsonEncode(payloadMap),
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
