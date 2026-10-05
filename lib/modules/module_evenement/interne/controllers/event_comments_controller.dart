import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../centre/models/event_comment.dart';
import '../../centre/repositories/event_repository.dart';

enum EventCommentsState { initial, loading, loaded, empty, error }

class EventCommentsController extends GetxController {
  final EventRepository _repository = Get.find<EventRepository>();

  final RxList<EventComment> comments = <EventComment>[].obs;
  final Rx<EventCommentsState> state = EventCommentsState.initial.obs;
  final RxBool isSending = false.obs;
  final RxBool hasMoreComments = true.obs;
  final RxBool isLoadingMoreComments = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<EventComment?> replyingToComment = Rx<EventComment?>(null);
  final RxSet<String> likingCommentIds = <String>{}.obs;

  final TextEditingController commentTextController = TextEditingController();
  final FocusNode commentFocusNode = FocusNode();

  String? _currentEventId;

  void init(String eventId) {
    _currentEventId = eventId;
    fetchComments(eventId);
    _repository.subscribeToEventCommentsRealtime(eventId, () {
      refreshCommentsQuietly(eventId);
    });
  }

  Future<void> fetchComments(String eventId) async {
    state.value = EventCommentsState.loading;
    errorMessage.value = '';

    try {
      final list = await _repository.getEventComments(eventId: eventId, limit: 20);
      comments.value = list;
      hasMoreComments.value = list.length >= 20;

      if (list.isEmpty) {
        state.value = EventCommentsState.empty;
      } else {
        state.value = EventCommentsState.loaded;
      }
    } catch (e) {
      debugPrint('[EventCommentsController] fetchComments error: $e');
      errorMessage.value = 'Impossible de charger les commentaires.';
      state.value = EventCommentsState.error;
    }
  }

  Future<void> loadMoreComments(String eventId) async {
    if (!hasMoreComments.value || isLoadingMoreComments.value || comments.isEmpty) return;

    isLoadingMoreComments.value = true;
    final lastCreatedAt = comments.last.createdAt;

    try {
      final nextList = await _repository.getEventComments(
        eventId: eventId,
        limit: 20,
        beforeCreatedAt: lastCreatedAt,
      );

      final newItems = nextList.where((c) => !comments.any((existing) => existing.id == c.id)).toList();
      comments.addAll(newItems);
      hasMoreComments.value = nextList.length >= 20;
    } catch (e) {
      debugPrint('[EventCommentsController] loadMoreComments error: $e');
    } finally {
      isLoadingMoreComments.value = false;
    }
  }

  Future<void> refreshCommentsQuietly(String eventId) async {
    try {
      final list = await _repository.getEventComments(eventId: eventId, limit: 20);
      final Map<String, List<EventComment>> loadedRepliesMap = {};
      final Map<String, bool> loadedFlags = {};
      final Map<String, bool> hasMoreFlags = {};

      for (final existing in comments) {
        if (existing.areRepliesLoaded) {
          loadedRepliesMap[existing.id] = existing.replies;
          loadedFlags[existing.id] = true;
          hasMoreFlags[existing.id] = existing.hasMoreReplies;
        }
      }

      final updatedList = list.map((c) {
        if (loadedRepliesMap.containsKey(c.id)) {
          return c.copyWith(
            replies: loadedRepliesMap[c.id],
            areRepliesLoaded: true,
            hasMoreReplies: hasMoreFlags[c.id] ?? false,
          );
        }
        return c;
      }).toList();

      comments.value = updatedList;
      hasMoreComments.value = list.length >= 20;

      if (updatedList.isEmpty) {
        state.value = EventCommentsState.empty;
      } else {
        state.value = EventCommentsState.loaded;
      }
    } catch (e) {
      debugPrint('[EventCommentsController] refreshCommentsQuietly error: $e');
    }
  }

  Future<void> loadCommentReplies(EventComment comment) async {
    final index = comments.indexWhere((c) => c.id == comment.id);
    if (index == -1) return;

    final target = comments[index];
    comments[index] = target.copyWith(isLoadingReplies: true);

    try {
      final replies = await _repository.getEventCommentReplies(
        commentId: comment.id,
        limit: 20,
      );

      comments[index] = target.copyWith(
        replies: replies,
        areRepliesLoaded: true,
        isLoadingReplies: false,
        hasMoreReplies: replies.length >= 20,
      );
    } catch (e) {
      debugPrint('[EventCommentsController] loadCommentReplies error: $e');
      comments[index] = target.copyWith(isLoadingReplies: false);
    }
  }

  Future<void> loadMoreCommentReplies(EventComment comment) async {
    final index = comments.indexWhere((c) => c.id == comment.id);
    if (index == -1) return;

    final target = comments[index];
    if (!target.hasMoreReplies || target.isLoadingReplies || target.replies.isEmpty) return;

    comments[index] = target.copyWith(isLoadingReplies: true);
    final lastCreatedAt = target.replies.last.createdAt;

    try {
      final nextReplies = await _repository.getEventCommentReplies(
        commentId: comment.id,
        limit: 20,
        beforeCreatedAt: lastCreatedAt,
      );

      final newItems = nextReplies
          .where((r) => !target.replies.any((existing) => existing.id == r.id))
          .toList();

      final updatedReplies = [...target.replies, ...newItems];

      comments[index] = target.copyWith(
        replies: updatedReplies,
        areRepliesLoaded: true,
        isLoadingReplies: false,
        hasMoreReplies: nextReplies.length >= 20,
      );
    } catch (e) {
      debugPrint('[EventCommentsController] loadMoreCommentReplies error: $e');
      comments[index] = target.copyWith(isLoadingReplies: false);
    }
  }

  Future<void> toggleCommentLike(EventComment comment, {required bool isMainComment, String? parentCommentId}) async {
    if (likingCommentIds.contains(comment.id)) return;

    likingCommentIds.add(comment.id);
    final oldIsLiked = comment.isLiked;
    final oldLikesCount = comment.likesCount;
    final newIsLiked = !oldIsLiked;
    final newLikesCount = newIsLiked ? oldLikesCount + 1 : (oldLikesCount > 0 ? oldLikesCount - 1 : 0);

    if (isMainComment) {
      final index = comments.indexWhere((c) => c.id == comment.id);
      if (index != -1) {
        comments[index] = comments[index].copyWith(
          isLikedByMe: newIsLiked,
          likesCount: newLikesCount,
        );
      }
    } else if (parentCommentId != null) {
      final parentIndex = comments.indexWhere((c) => c.id == parentCommentId);
      if (parentIndex != -1) {
        final parent = comments[parentIndex];
        final replyIndex = parent.replies.indexWhere((r) => r.id == comment.id);
        if (replyIndex != -1) {
          final updatedReplies = List<EventComment>.from(parent.replies);
          updatedReplies[replyIndex] = updatedReplies[replyIndex].copyWith(
            isLikedByMe: newIsLiked,
            likesCount: newLikesCount,
          );
          comments[parentIndex] = parent.copyWith(replies: updatedReplies);
        }
      }
    }

    try {
      final res = newIsLiked
          ? await _repository.likeEventComment(comment.id)
          : await _repository.unlikeEventComment(comment.id);

      if (res != null) {
        final returnedLikes = (res['likes_count'] as num?)?.toInt() ?? newLikesCount;
        final returnedIsLiked = (res['is_liked'] ?? res['is_liked_by_me']) == true;

        if (isMainComment) {
          final index = comments.indexWhere((c) => c.id == comment.id);
          if (index != -1) {
            comments[index] = comments[index].copyWith(
              isLikedByMe: returnedIsLiked,
              likesCount: returnedLikes,
            );
          }
        } else if (parentCommentId != null) {
          final parentIndex = comments.indexWhere((c) => c.id == parentCommentId);
          if (parentIndex != -1) {
            final parent = comments[parentIndex];
            final replyIndex = parent.replies.indexWhere((r) => r.id == comment.id);
            if (replyIndex != -1) {
              final updatedReplies = List<EventComment>.from(parent.replies);
              updatedReplies[replyIndex] = updatedReplies[replyIndex].copyWith(
                isLikedByMe: returnedIsLiked,
                likesCount: returnedLikes,
              );
              comments[parentIndex] = parent.copyWith(replies: updatedReplies);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[EventCommentsController] toggleCommentLike error, rolling back: $e');
      if (isMainComment) {
        final index = comments.indexWhere((c) => c.id == comment.id);
        if (index != -1) {
          comments[index] = comments[index].copyWith(
            isLikedByMe: oldIsLiked,
            likesCount: oldLikesCount,
          );
        }
      } else if (parentCommentId != null) {
        final parentIndex = comments.indexWhere((c) => c.id == parentCommentId);
        if (parentIndex != -1) {
          final parent = comments[parentIndex];
          final replyIndex = parent.replies.indexWhere((r) => r.id == comment.id);
          if (replyIndex != -1) {
            final updatedReplies = List<EventComment>.from(parent.replies);
            updatedReplies[replyIndex] = updatedReplies[replyIndex].copyWith(
              isLikedByMe: oldIsLiked,
              likesCount: oldLikesCount,
            );
            comments[parentIndex] = parent.copyWith(replies: updatedReplies);
          }
        }
      }
    } finally {
      likingCommentIds.remove(comment.id);
    }
  }

  void setReplyTo(EventComment comment) {
    if (comment.parentCommentId != null && comment.parentCommentId!.isNotEmpty) {
      final rootComment = comments.firstWhereOrNull((c) => c.id == comment.parentCommentId);
      replyingToComment.value = rootComment ?? comment;
    } else {
      replyingToComment.value = comment;
    }
    commentFocusNode.requestFocus();
  }

  void cancelReply() {
    replyingToComment.value = null;
  }

  Future<void> sendComment(String eventId, BuildContext context) async {
    final text = commentTextController.text.trim();
    if (text.isEmpty || isSending.value) return;

    isSending.value = true;
    final parentId = replyingToComment.value?.id;

    try {
      final newComment = await _repository.createEventComment(
        eventId: eventId,
        content: text,
        parentCommentId: parentId,
      );

      commentTextController.clear();
      replyingToComment.value = null;
      commentFocusNode.unfocus();

      if (newComment != null) {
        if (parentId == null) {
          comments.insert(0, newComment);
          if (state.value == EventCommentsState.empty) {
            state.value = EventCommentsState.loaded;
          }
        } else {
          final parentIndex = comments.indexWhere((c) => c.id == parentId);
          if (parentIndex != -1) {
            final parent = comments[parentIndex];
            final updatedReplies = parent.areRepliesLoaded
                ? [...parent.replies, newComment]
                : parent.replies;

            comments[parentIndex] = parent.copyWith(
              repliesCount: parent.repliesCount + 1,
              replies: updatedReplies,
            );
          }
        }
      } else {
        await refreshCommentsQuietly(eventId);
      }
    } catch (e) {
      debugPrint('[EventCommentsController] sendComment error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Impossible d\'envoyer votre commentaire. Veuillez réessayer.',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      isSending.value = false;
    }
  }

  @override
  void onClose() {
    if (_currentEventId != null) {
      _repository.unsubscribeFromEventCommentsRealtime(_currentEventId!);
    }
    commentTextController.dispose();
    commentFocusNode.dispose();
    super.onClose();
  }
}
