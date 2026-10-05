import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrole/app/theme/app_colors.dart';
import 'package:scrole/modules/module_communautes/centre/models/community_post.dart';
import 'package:scrole/modules/module_communautes/centre/models/news/community_hashtag.dart';
import 'package:scrole/modules/module_communautes/centre/models/news/community.dart' as model;
import 'package:scrole/modules/module_communautes/centre/services/community_service.dart';
import 'package:scrole/modules/module_communautes/interne/enums/community_role_enum.dart' as role_enum;
import 'package:scrole/modules/module_communautes/interne/widgets/community/community_comments_sheet.dart';
import 'package:share_plus/share_plus.dart';

class CommunityFeedController extends GetxController {
  final CommunityService _service;
  final String communityId;

  CommunityFeedController(this._service, this.communityId);

  CommunityService get service => _service;

  final RxString communityName = ''.obs;
  final Rxn<model.Community> community = Rxn<model.Community>();
  final Rxn<role_enum.CommunityRole> currentUserRole = Rxn<role_enum.CommunityRole>();
  final RxList<CommunityPost> posts = <CommunityPost>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  String? _nextCursor;

  @override
  void onInit() {
    super.onInit();
    if (communityId.isNotEmpty) {
      _loadCommunityInfo();
      _loadUserRole();
      refreshFeed();
    }
  }

  Future<void> _loadUserRole() async {
    try {
      final membership = await _service.getMembership(communityId);
      if (membership != null) {
        final roleStr = (membership['role'] ?? membership['role_name'] ?? membership['name'] ?? '').toString().toLowerCase();
        if (roleStr == 'admin') {
          currentUserRole.value = role_enum.CommunityRole.admin;
        } else if (roleStr == 'moderator' || roleStr == 'modérateur') {
          currentUserRole.value = role_enum.CommunityRole.moderator;
        } else {
          currentUserRole.value = role_enum.CommunityRole.member;
        }
      } else {
        currentUserRole.value = role_enum.CommunityRole.member;
      }
    } catch (e) {
      currentUserRole.value = role_enum.CommunityRole.member;
    }
  }

  Future<void> _loadCommunityInfo() async {
    try {
      final preview = await _service.getCommunityPreviewData(communityId);
      if (preview != null) {
        community.value = preview.community;
        communityName.value = preview.community.name;
        return;
      }
    } catch (_) {}

    try {
      final c = await _service.getCommunityById(communityId);
      if (c != null) {
        community.value = c;
        communityName.value = c.name;
      }
    } catch (e) {
      debugPrint('[CommunityFeedController] _loadCommunityInfo error: $e');
    }
  }

  Future<void> refreshFeed() async {
    if (communityId.isEmpty) return;
    try {
      isLoading.value = true;
      _nextCursor = null;
      final result = await _service.getCommunityFeed(communityId, limit: 20, cursor: null);
      final items = (result['items'] as List?)
          ?.map((e) => CommunityPost.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((p) => p.status.isEmpty || p.status == 'active')
          .toList() ?? [];
      posts.assignAll(items);
      _nextCursor = result['next_cursor']?.toString();
      hasMore.value = result['has_more'] == true && _nextCursor != null && _nextCursor!.isNotEmpty;
    } catch (e) {
      debugPrint('[CommunityFeedController] refreshFeed error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreFeed() async {
    if (communityId.isEmpty || isLoadingMore.value || !hasMore.value || _nextCursor == null) return;
    try {
      isLoadingMore.value = true;
      final result = await _service.getCommunityFeed(communityId, limit: 20, cursor: _nextCursor);
      final items = (result['items'] as List?)
          ?.map((e) => CommunityPost.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((p) => p.status.isEmpty || p.status == 'active')
          .toList() ?? [];

      final existingIds = posts.map((p) => p.id).toSet();
      final newItems = items.where((p) => !existingIds.contains(p.id)).toList();

      posts.addAll(newItems);
      _nextCursor = result['next_cursor']?.toString();
      hasMore.value = result['has_more'] == true && _nextCursor != null && _nextCursor!.isNotEmpty;
    } catch (e) {
      debugPrint('[CommunityFeedController] loadMoreFeed error: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  final Set<String> _reactingPostIds = {};

  Future<void> toggleReaction(String postId, PostReaction reaction) async {
    final settings = await _service.getCommunitySettings(communityId);
    if (settings != null && !settings.allowReactions) {
      Get.snackbar('Action impossible', 'Les réactions sont désactivées dans cette communauté.', backgroundColor: Colors.black87, colorText: Colors.white);
      return;
    }

    if (_reactingPostIds.contains(postId)) return;

    final index = posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = posts[index];
    if (post.isPublishing) return;

    _reactingPostIds.add(postId);

    final oldReaction = post.userReaction;
    final oldLikeCount = post.likeCount;
    final oldDislikeCount = post.dislikeCount;

    PostReaction newReaction = reaction;
    int likeCount = oldLikeCount;
    int dislikeCount = oldDislikeCount;

    if (oldReaction == reaction) {
      newReaction = PostReaction.none;
      if (reaction == PostReaction.like) likeCount--;
      if (reaction == PostReaction.dislike) dislikeCount--;
    } else {
      if (oldReaction == PostReaction.like) likeCount--;
      if (oldReaction == PostReaction.dislike) dislikeCount--;

      if (newReaction == PostReaction.like) likeCount++;
      if (newReaction == PostReaction.dislike) dislikeCount++;
    }

    posts[index] = post.copyWith(
      likeCount: likeCount < 0 ? 0 : likeCount,
      dislikeCount: dislikeCount < 0 ? 0 : dislikeCount,
      userReaction: newReaction,
    );

    try {
      if (newReaction == PostReaction.none) {
        await _service.removeCommunityPostReaction(postId);
      } else {
        final reactionStr = newReaction == PostReaction.like ? 'like' : 'dislike';
        await _service.reactToCommunityPost(postId, reactionStr);
      }
    } catch (e) {
      posts[index] = post.copyWith(
        likeCount: oldLikeCount,
        dislikeCount: oldDislikeCount,
        userReaction: oldReaction,
      );
      Get.snackbar('Erreur', e.toString().replaceFirst('Exception: ', ''), backgroundColor: Colors.red[900], colorText: Colors.white);
    } finally {
      _reactingPostIds.remove(postId);
    }
  }

  void addNewPostFromUser({required String content, String? imageUrl}) {
    final newPost = CommunityPost(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorName: 'Moi',
      authorRole: role_enum.CommunityRole.member,
      authorColor: AppColors.primary,
      timeAgo: 'À l\'instant',
      content: content,
      media: imageUrl != null && imageUrl.isNotEmpty ? [PostMedia(color: AppColors.primary, url: imageUrl)] : const [],
      type: imageUrl != null && imageUrl.isNotEmpty ? PostType.image : PostType.texte,
      likeCount: 0,
      dislikeCount: 0,
      commentCount: 0,
    );
    posts.insert(0, newPost);
  }

  Future<void> createPost({
    String? content,
    List<File> imageFiles = const [],
    bool commentsEnabled = true,
    bool sharingEnabled = true,
    List<String> hashtags = const [],
    List<String> mentions = const [],
    Map<String, dynamic>? poll,
  }) async {
    if (communityId.isEmpty) {
      Get.snackbar('Erreur', 'Communauté introuvable.');
      return;
    }

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final List<PostMedia> mediaList = imageFiles.map((f) => PostMedia(color: Colors.grey, url: f.path)).toList();
    CommunityPoll? parsedPoll;
    if (poll != null) {
      parsedPoll = CommunityPoll.fromJson(poll);
    }

    final optimisticPost = CommunityPost(
      id: tempId,
      authorName: 'Moi',
      authorRole: role_enum.CommunityRole.member,
      authorColor: AppColors.primary,
      timeAgo: 'À l\'instant',
      content: content ?? '',
      media: mediaList,
      type: parsedPoll != null ? PostType.poll : (mediaList.isNotEmpty ? PostType.image : PostType.texte),
      isPublishing: true,
      commentsEnabled: commentsEnabled,
      sharingEnabled: sharingEnabled,
      hashtags: hashtags.map((h) => CommunityHashtag(id: h, name: h, postCount: 0)).toList(),
      poll: parsedPoll,
    );

    posts.insert(0, optimisticPost);

    try {
      await _service.createCommunityPost(
        communityId: communityId,
        content: content,
        imageFiles: imageFiles,
        commentsEnabled: commentsEnabled,
        sharingEnabled: sharingEnabled,
        hashtags: hashtags,
        mentions: mentions,
        poll: poll,
      );

      await refreshFeed();
      Get.snackbar('Succès', 'Publication réussie !', backgroundColor: Colors.black87, colorText: Colors.white);
    } catch (e) {
      posts.removeWhere((p) => p.id == tempId);
      final cleanError = e.toString().replaceFirst('Exception: ', '').replaceFirst('PostgrestException: ', '');
      Get.snackbar('Erreur', cleanError.isNotEmpty ? cleanError : 'La publication n’a pas pu être publiée.', backgroundColor: Colors.red[900], colorText: Colors.white);
    }
  }

  Future<void> votePoll(String postId, List<String> optionIds) async {
    try {
      final res = await _service.voteCommunityPoll(postId: postId, optionIds: optionIds);
      final index = posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final post = posts[index];
        if (res.isNotEmpty && res['poll'] is Map) {
          final updatedPoll = CommunityPoll.fromJson(Map<String, dynamic>.from(res['poll'] as Map));
          posts[index] = post.copyWith(poll: updatedPoll);
        }
      }
    } catch (e) {
      debugPrint('[CommunityFeedController] votePoll error: $e');
      Get.snackbar('Erreur', e.toString().replaceFirst('Exception: ', ''));
    }
  }

  final Set<String> _deletingPostIds = <String>{};

  Future<void> deletePost(String postId) async {
    if (_deletingPostIds.contains(postId)) {
      debugPrint('[COMMUNITY_POST_DELETE] Delete already in progress for post=$postId');
      return;
    }
    _deletingPostIds.add(postId);

    debugPrint('[COMMUNITY_POST_DELETE][CONTROLLER] Delete requested for post=$postId');
    try {
      debugPrint('[COMMUNITY_POST_DELETE][USECASE] Executing delete for post=$postId');
      await _service.deleteCommunityPost(postId);
      posts.removeWhere((p) => p.id == postId);
      posts.refresh();
      debugPrint('[COMMUNITY_POST_DELETE][CONTROLLER] Post removed from UI');
      Get.snackbar('Succès', 'Publication supprimée.', backgroundColor: Colors.black87, colorText: Colors.white);
    } catch (e) {
      debugPrint('[COMMUNITY_POST_DELETE][CONTROLLER] Deletion failed for post=$postId: $e');
      Get.snackbar('Erreur', e.toString().replaceFirst('Exception: ', ''), backgroundColor: Colors.red[900], colorText: Colors.white);
    } finally {
      _deletingPostIds.remove(postId);
    }
  }

  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await _service.deleteCommunityComment(commentId);
      final comments = _commentsByPostId[postId];
      if (comments != null) {
        comments.removeWhere((c) => c.id == commentId);
        for (final c in comments) {
          c.replies.removeWhere((r) => r.id == commentId);
        }
      }
      final index = posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final post = posts[index];
        posts[index] = post.copyWith(
          commentCount: post.commentCount > 0 ? post.commentCount - 1 : 0,
          comments: _commentsByPostId[postId] ?? post.comments,
        );
      }
      Get.snackbar('Succès', 'Commentaire supprimé.', backgroundColor: Colors.black87, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Erreur', e.toString().replaceFirst('Exception: ', ''), backgroundColor: Colors.red[900], colorText: Colors.white);
    }
  }

  void sharePost(CommunityPost post) {
    if (!post.sharingEnabled) {
      Get.snackbar('Action impossible', 'Le partage est désactivé sur cette publication.', backgroundColor: Colors.black87, colorText: Colors.white);
      return;
    }
    final text = 'Regarde cette publication sur Scrole !';
    Share.share(text);
  }

  Future<void> openCommentsSheet(CommunityPost post) async {
    final settings = await _service.getCommunitySettings(communityId);
    if (settings != null && !settings.allowComments) {
      Get.snackbar('Action impossible', 'Les commentaires sont désactivés dans cette communauté.', backgroundColor: Colors.black87, colorText: Colors.white);
      return;
    }
    if (!post.commentsEnabled) {
      Get.snackbar('Action impossible', 'Les commentaires sont désactivés sur cette publication.', backgroundColor: Colors.black87, colorText: Colors.white);
      return;
    }

    Get.bottomSheet(
      CommunityCommentsSheet(post: post, controller: this),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  final Map<String, List<PostComment>> _commentsByPostId = {};
  final RxMap<String, bool> commentsLoading = <String, bool>{}.obs;

  List<PostComment> getCommentsForPost(String postId) {
    return _commentsByPostId[postId] ?? [];
  }

  Future<List<PostComment>> loadCommentsForPost(String postId) async {
    if (_commentsByPostId.containsKey(postId)) {
      return _commentsByPostId[postId]!;
    }
    try {
      commentsLoading[postId] = true;
      final result = await _service.getCommunityPostComments(postId, limit: 20);
      final rawItems = result['items'] as List? ?? [];
      final parsedComments = rawItems.map((c) => PostComment.fromJson(Map<String, dynamic>.from(c as Map))).toList();
      _commentsByPostId[postId] = parsedComments;
      return parsedComments;
    } catch (e) {
      debugPrint('[CommunityFeedController] loadCommentsForPost error: $e');
      return [];
    } finally {
      commentsLoading[postId] = false;
    }
  }

  Future<void> addCommentToPost(String postId, String content) async {
    if (content.trim().isEmpty) return;
    final index = posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final post = posts[index];

    final tempId = 'temp_c_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticComment = PostComment(
      id: tempId,
      authorName: 'Moi',
      authorColor: AppColors.primary,
      timeAgo: 'À l\'instant',
      content: content.trim(),
    );

    final currentComments = _commentsByPostId[postId] ?? post.comments;
    final updatedComments = [...currentComments, optimisticComment];
    _commentsByPostId[postId] = updatedComments;
    posts[index] = post.copyWith(
      commentCount: post.commentCount + 1,
      comments: updatedComments,
    );

    try {
      await _service.commentCommunityPost(postId: postId, content: content);
      _commentsByPostId.remove(postId);
      final fresh = await loadCommentsForPost(postId);
      posts[index] = posts[index].copyWith(comments: fresh);
    } catch (e) {
      _commentsByPostId[postId] = currentComments;
      posts[index] = post.copyWith(
        commentCount: post.commentCount > 0 ? post.commentCount - 1 : 0,
        comments: currentComments,
      );
      Get.snackbar('Erreur', e.toString().replaceFirst('Exception: ', ''), backgroundColor: Colors.red[900], colorText: Colors.white);
    }
  }

  final Map<String, List<PostComment>> repliesByCommentId = {};
  final Map<String, String?> replyCursorByCommentId = {};
  final Map<String, bool> hasMoreRepliesByCommentId = {};
  final RxMap<String, bool> loadingRepliesByCommentId = <String, bool>{}.obs;

  Future<void> loadRepliesForComment(String commentId, {bool refresh = false}) async {
    if (loadingRepliesByCommentId[commentId] == true) return;
    if (!refresh && hasMoreRepliesByCommentId[commentId] == false) return;

    try {
      loadingRepliesByCommentId[commentId] = true;
      final cursor = refresh ? null : replyCursorByCommentId[commentId];
      final result = await _service.getCommunityCommentReplies(commentId, limit: 20, cursor: cursor);

      final rawItems = result['items'] as List? ?? [];
      final parsedReplies = rawItems.map((r) => PostComment.fromJson(Map<String, dynamic>.from(r as Map))).toList();

      final existing = refresh ? <PostComment>[] : (repliesByCommentId[commentId] ?? []);
      
      final existingIds = existing.map((r) => r.id).toSet();
      final newItems = parsedReplies.where((r) => !existingIds.contains(r.id)).toList();

      repliesByCommentId[commentId] = [...existing, ...newItems];
      replyCursorByCommentId[commentId] = result['next_cursor']?.toString();
      hasMoreRepliesByCommentId[commentId] = result['has_more'] == true && replyCursorByCommentId[commentId] != null && replyCursorByCommentId[commentId]!.isNotEmpty;
    } catch (e) {
      debugPrint('[CommunityFeedController] loadRepliesForComment error: $e');
    } finally {
      loadingRepliesByCommentId[commentId] = false;
    }
  }

  Future<void> addReplyToComment(String postId, String parentCommentId, String content) async {
    if (content.trim().isEmpty) return;
    final index = posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final post = posts[index];

    final tempId = 'temp_r_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticReply = PostComment(
      id: tempId,
      authorName: 'Moi',
      authorColor: AppColors.primary,
      timeAgo: 'À l\'instant',
      content: content.trim(),
    );

    final currentReplies = repliesByCommentId[parentCommentId] ?? [];
    final updatedReplies = [...currentReplies, optimisticReply];
    repliesByCommentId[parentCommentId] = updatedReplies;

    posts[index] = post.copyWith(
      commentCount: post.commentCount + 1,
    );

    try {
      await _service.replyToCommunityComment(commentId: parentCommentId, content: content);
      await loadRepliesForComment(parentCommentId, refresh: true);
    } catch (e) {
      repliesByCommentId[parentCommentId] = currentReplies;
      posts[index] = post.copyWith(
        commentCount: post.commentCount > 0 ? post.commentCount - 1 : 0,
      );
      Get.snackbar('Erreur', e.toString().replaceFirst('Exception: ', ''), backgroundColor: Colors.red[900], colorText: Colors.white);
    }
  }

  void toggleCommentReaction(String postId, String commentId, PostReaction reaction) {
    final index = posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final post = posts[index];

    List<PostComment> updateCommentList(List<PostComment> list) {
      return list.map((c) {
        if (c.id == commentId) {
          final isSame = c.userReaction == reaction;
          final newReaction = isSame ? PostReaction.none : reaction;
          var likes = c.likesCount;
          if (c.userReaction == PostReaction.like) likes--;
          if (newReaction == PostReaction.like) likes++;
          return c.copyWith(likesCount: likes, userReaction: newReaction);
        }
        if (c.replies.isNotEmpty) {
          return c.copyWith(replies: updateCommentList(c.replies));
        }
        return c;
      }).toList();
    }

    const updated = []; // updated comments map
    // update logic...
  }

  Future<void> leaveCommunity() async {
    try {
      await _service.leaveCommunity(communityId);
      Get.back();
      Get.back();
      Get.snackbar('Succès', 'Vous avez quitté la communauté.');
    } catch (e) {
      Get.snackbar('Erreur', e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void shareCommunity() {
    final name = community.value?.name ?? communityName.value;
    final text = 'Rejoins ma communauté "$name" sur Scrole ! https://scrole.fun/communities/$communityId';
    Share.share(text);
  }
}
