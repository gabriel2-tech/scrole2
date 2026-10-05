import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrole/app/theme/app_colors.dart';
import 'package:scrole/app/theme/text_styles.dart';
import 'package:scrole/shared/utils/number_formatter.dart';
import 'package:scrole/shared/widgets/user_certified_badge.dart';
import 'package:scrole/shared/widgets/app_cached_image.dart';
import '../../../centre/models/community_post.dart';
import '../../controllers/community/community_feed_controller.dart';
import 'feed_post_card.dart';

enum CommentSortFilter { mostRecent, oldest, mostLiked }

class CommunityCommentsSheet extends StatefulWidget {
  final CommunityPost post;
  final CommunityFeedController controller;

  const CommunityCommentsSheet({
    super.key,
    required this.post,
    required this.controller,
  });

  @override
  State<CommunityCommentsSheet> createState() => _CommunityCommentsSheetState();
}

class _CommunityCommentsSheetState extends State<CommunityCommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  PostComment? _replyingToComment;
  CommentSortFilter _currentSortFilter = CommentSortFilter.mostRecent;

  @override
  void initState() {
    super.initState();
    widget.controller.loadCommentsForPost(widget.post.id);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    if (_replyingToComment != null) {
      widget.controller.addReplyToComment(widget.post.id, _replyingToComment!.id, text);
      _clearReply();
    } else {
      widget.controller.addCommentToPost(widget.post.id, text);
    }
    _commentController.clear();
    setState(() {});
  }

  void _setReplyTo(PostComment comment) {
    setState(() {
      _replyingToComment = comment;
    });
  }

  void _clearReply() {
    setState(() {
      _replyingToComment = null;
    });
  }

  void _showSortFilterMenu() {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'comments_sort_title'.tr,
                style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  Icons.schedule_rounded,
                  color: _currentSortFilter == CommentSortFilter.mostRecent ? AppColors.primary : colorScheme.onSurfaceVariant,
                ),
                title: Text('comments_sort_recent'.tr),
                trailing: _currentSortFilter == CommentSortFilter.mostRecent
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _currentSortFilter = CommentSortFilter.mostRecent);
                  Get.back();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.history_rounded,
                  color: _currentSortFilter == CommentSortFilter.oldest ? AppColors.primary : colorScheme.onSurfaceVariant,
                ),
                title: Text('comments_sort_oldest'.tr),
                trailing: _currentSortFilter == CommentSortFilter.oldest
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _currentSortFilter = CommentSortFilter.oldest);
                  Get.back();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.favorite_rounded,
                  color: _currentSortFilter == CommentSortFilter.mostLiked ? AppColors.primary : colorScheme.onSurfaceVariant,
                ),
                title: Text('comments_sort_top'.tr),
                trailing: _currentSortFilter == CommentSortFilter.mostLiked
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _currentSortFilter = CommentSortFilter.mostLiked);
                  Get.back();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PostComment> _getSortedComments(List<PostComment> rawComments) {
    final list = List<PostComment>.from(rawComments);
    switch (_currentSortFilter) {
      case CommentSortFilter.mostRecent:
        break;
      case CommentSortFilter.oldest:
        break;
      case CommentSortFilter.mostLiked:
        list.sort((a, b) => b.likesCount.compareTo(a.likesCount));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(75),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22),
                      onPressed: () => Get.back(),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'r/${widget.controller.communityName.value}',
                        style: AppTextStyles.h4.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search_rounded, size: 20),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune_rounded, size: 20),
                      onPressed: _showSortFilterMenu,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 0.5),
            ],
          ),
        ),
        body: Obx(() {
          final currentPost = widget.controller.posts.firstWhereOrNull((p) => p.id == widget.post.id) ?? widget.post;
          final rawComments = widget.controller.getCommentsForPost(widget.post.id);
          final comments = _getSortedComments(rawComments);
          final isLoading = widget.controller.commentsLoading[widget.post.id] == true;

          if (isLoading && comments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (comments.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.all(16),
              children: [
                FeedPostCard(
                  post: currentPost,
                  onReactionTap: (reaction) => widget.controller.toggleReaction(currentPost.id, reaction),
                  onCommentTap: () {},
                  onShareTap: () => widget.controller.sharePost(currentPost),
                ),
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    'Aucun commentaire pour le moment.\nSoyez le premier à commenter.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            itemCount: comments.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: FeedPostCard(
                    post: currentPost,
                    onReactionTap: (reaction) => widget.controller.toggleReaction(currentPost.id, reaction),
                    onCommentTap: () {},
                    onShareTap: () => widget.controller.sharePost(currentPost),
                  ),
                );
              }

              final comment = comments[index - 1];
              return _CommentThreadTile(
                comment: comment,
                postId: currentPost.id,
                controller: widget.controller,
                onReplyTap: _setReplyTo,
              );
            },
          );
        }),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyingToComment != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.reply_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'En réponse à @${_replyingToComment!.authorName}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: _clearReply,
                      child: const Icon(Icons.close_rounded, size: 18, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? AppColors.border : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _commentController,
                        style: AppTextStyles.input.copyWith(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: _replyingToComment != null
                              ? 'Répondre à @${_replyingToComment!.authorName}...'
                              : 'comments_add_hint'.tr,
                          hintStyle: AppTextStyles.inputHint.copyWith(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _submitComment(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: AppColors.primary,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: InkWell(
                      onTap: _submitComment,
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentThreadTile extends StatefulWidget {
  final PostComment comment;
  final String postId;
  final CommunityFeedController controller;
  final ValueChanged<PostComment> onReplyTap;
  final double indentPadding;
  final String? mainParentId;

  const _CommentThreadTile({
    required this.comment,
    required this.postId,
    required this.controller,
    required this.onReplyTap,
    this.indentPadding = 0.0,
    this.mainParentId,
  });

  @override
  State<_CommentThreadTile> createState() => _CommentThreadTileState();
}

class _CommentThreadTileState extends State<_CommentThreadTile> {
  bool _showReplies = true; // Automatically show replies if available

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final targetMainId = widget.mainParentId ?? widget.comment.id;
    final controllerReplies = widget.controller.repliesByCommentId[widget.comment.id] ?? [];
    final replies = controllerReplies.isNotEmpty ? controllerReplies : widget.comment.replies;
    final isLoadingReplies = widget.controller.loadingRepliesByCommentId[widget.comment.id] == true;

    return GestureDetector(
      onLongPress: () => _confirmDeleteComment(context),
      child: Container(
        margin: EdgeInsets.only(left: widget.indentPadding, bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.indentPadding > 0
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
              : colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar + Name + Certified Badge + OP + TimeAgo
            Row(
              children: [
                ClipOval(
                  child: widget.comment.avatarUrl != null && widget.comment.avatarUrl!.isNotEmpty
                      ? AppCachedImage(imageUrl: widget.comment.avatarUrl!, width: 28, height: 28, fit: BoxFit.cover)
                      : CircleAvatar(
                          radius: 14,
                          backgroundColor: widget.comment.authorColor.withValues(alpha: 0.2),
                          child: Text(
                            widget.comment.authorName.isNotEmpty ? widget.comment.authorName[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: widget.comment.authorColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          widget.comment.authorName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.comment.isCertified) ...[
                        const SizedBox(width: 4),
                        const UserCertifiedBadge(size: 13),
                      ],
                    ],
                  ),
                ),
                if (widget.comment.isOp) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'OP',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  widget.comment.timeAgo,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Comment text
            Padding(
              padding: const EdgeInsets.only(left: 36, right: 4),
              child: ExpandableTextWidget(
                text: widget.comment.content,
                maxLines: 4,
                style: TextStyle(
                  fontSize: 13.5,
                  color: colorScheme.onSurface,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Action row: Reply | Upvote + Score + Downvote
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () {
                    widget.onReplyTap(widget.comment.copyWith(id: targetMainId));
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.reply_outlined,
                          size: 15,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Répondre',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => widget.controller.toggleCommentReaction(widget.postId, widget.comment.id, PostReaction.like),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Icon(
                      Icons.north_rounded,
                      size: 16,
                      color: widget.comment.userReaction == PostReaction.like
                          ? Colors.orangeAccent
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (widget.comment.likesCount > 0)
                  Text(
                    NumberFormatter.formatCount(widget.comment.likesCount),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: widget.comment.userReaction == PostReaction.like
                          ? Colors.orangeAccent
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                InkWell(
                  onTap: () => widget.controller.toggleCommentReaction(widget.postId, widget.comment.id, PostReaction.dislike),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Icon(
                      Icons.south_rounded,
                      size: 16,
                      color: widget.comment.userReaction == PostReaction.dislike
                          ? Colors.blueAccent
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),

            // Load replies button / toggle
            if ((widget.comment.repliesCount > 0 || widget.comment.replies.isNotEmpty) && widget.indentPadding == 0.0) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showReplies = !_showReplies;
                    });
                    if (_showReplies && replies.isEmpty) {
                      widget.controller.loadRepliesForComment(widget.comment.id);
                    }
                  },
                  child: Row(
                    children: [
                      Text(
                        _showReplies
                            ? 'Masquer les réponses'
                            : 'Voir ${widget.comment.repliesCount > 0 ? widget.comment.repliesCount : replies.length} ${widget.comment.repliesCount > 1 || replies.length > 1 ? 'réponses' : 'réponse'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      if (isLoadingReplies) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            // Nested replies display
            if (_showReplies && replies.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...replies.map(
                (reply) => _CommentThreadTile(
                  comment: reply,
                  postId: widget.postId,
                  controller: widget.controller,
                  onReplyTap: widget.onReplyTap,
                  indentPadding: 16.0,
                  mainParentId: widget.comment.id,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDeleteComment(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le commentaire'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce commentaire ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.controller.deleteComment(widget.postId, widget.comment.id);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
