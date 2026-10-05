import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrole/app/theme/app_colors.dart';
import 'package:scrole/shared/utils/number_formatter.dart';
import 'package:scrole/shared/widgets/app_cached_image.dart';
import 'package:scrole/shared/widgets/user_certified_badge.dart';
import 'package:scrole/modules/module_authentification/centre/services/auth_service.dart';
import 'package:scrole/app/routes/app_pages.dart';
import '../../../centre/models/community_post.dart';
import '../../controllers/community/community_feed_controller.dart';
import '../shared/post_media_slider.dart';
import 'poll_card_widget.dart';

/// Composant de texte extensible avec bouton "Voir plus" / "Voir moins"
class ExpandableTextWidget extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle? style;

  const ExpandableTextWidget({
    super.key,
    required this.text,
    this.maxLines = 3,
    this.style,
  });

  @override
  State<ExpandableTextWidget> createState() => _ExpandableTextWidgetState();
}

class _ExpandableTextWidgetState extends State<ExpandableTextWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final defaultStyle = widget.style ??
        TextStyle(fontSize: 14, color: colorScheme.onSurface, height: 1.4);

    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(text: widget.text, style: defaultStyle);
        final tp = TextPainter(
          text: textSpan,
          maxLines: widget.maxLines,
          textDirection: TextDirection.ltr,
        );
        tp.layout(maxWidth: constraints.maxWidth);

        final isOverflowing = tp.didExceedMaxLines;

        if (!isOverflowing) {
          return Text(widget.text, style: defaultStyle);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Text(
                widget.text,
                maxLines: _isExpanded ? null : widget.maxLines,
                overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                style: defaultStyle,
              ),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Text(
                _isExpanded ? 'Voir moins' : 'Voir plus',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class FeedPostCard extends StatelessWidget {
  final CommunityPost post;
  final ValueChanged<PostReaction> onReactionTap;
  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;
  final VoidCallback? onMoreTap;

  const FeedPostCard({
    super.key,
    required this.post,
    required this.onReactionTap,
    required this.onCommentTap,
    required this.onShareTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final username = post.authorObj?.username ?? '';

    CommunityFeedController _getFeedController(String communityId) {
      try {
        return Get.find<CommunityFeedController>(tag: communityId);
      } catch (_) {
        try {
          return Get.find<CommunityFeedController>();
        } catch (_) {
          return Get.put(CommunityFeedController(Get.find(), communityId));
        }
      }
    }

    return Opacity(
      opacity: post.isPublishing ? 0.65 : 1.0,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.25), width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Avatar de l'auteur à gauche
            GestureDetector(
              onTap: () => _onAuthorTap(post),
              child: ClipOval(
                child: (post.authorObj?.photoUrl != null && post.authorObj!.photoUrl!.isNotEmpty)
                    ? AppCachedImage(imageUrl: post.authorObj!.photoUrl!, width: 44, height: 44, fit: BoxFit.cover)
                    : Container(
                        width: 44,
                        height: 44,
                        color: post.authorColor.withValues(alpha: 0.2),
                        alignment: Alignment.center,
                        child: Text(
                          post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : '?',
                          style: TextStyle(color: post.authorColor, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // 2. Colonne de droite (En-tête, Texte, Hashtags, Médias, Actions) alignée verticalement
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- En-tête sur une seule ligne ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _onAuthorTap(post),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  post.authorName,
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (post.authorObj?.isCertified == true) ...[
                                const SizedBox(width: 4),
                                const UserCertifiedBadge(size: 14),
                              ],
                              if (username.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '@$username',
                                    style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                              const SizedBox(width: 6),
                              Text(
                                '• ${post.timeAgo}',
                                style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: post.isPublishing ? null : (onMoreTap ?? () => _showPostOptions(context, post)),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.more_horiz_rounded,
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // --- Bandeau "Publication en cours…" ---
                  if (post.isPublishing) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Publication en cours…',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.primary),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // --- Texte de la publication ---
                  if (post.content.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    ExpandableTextWidget(
                      text: post.content,
                      maxLines: 4,
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14.5,
                        height: 1.45,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],

                  // --- Hashtags en bleu ---
                  if (post.hashtags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: post.hashtags
                          .map(
                            (h) => Text(
                              '#${h.name}',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],

                  // --- Zone Médias ---
                  if (post.media.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: PostMediaSlider(media: post.media),
                    ),
                  ],

                  // --- Zone Poll / Sondage ---
                  if (post.poll != null) ...[
                    const SizedBox(height: 10),
                    PollCardWidget(
                      poll: post.poll!,
                      postId: post.id,
                      controller: Get.find<CommunityFeedController>(),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // --- Barre de boutons d'action / interactions (isolée avec widget Stateful pour zéro scintillement) ---
                  _ReactionButtonsBar(
                    post: post,
                    onReactionTap: onReactionTap,
                    onCommentTap: onCommentTap,
                    onShareTap: onShareTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPostOptions(BuildContext context, CommunityPost post) {
    debugPrint('[COMMUNITY_POST_DELETE][UI] Options menu opened for post=${post.id}');
    final currentUserId = Get.isRegistered<AuthService>() ? Get.find<AuthService>().userId : null;
    final isAuthor = currentUserId != null && currentUserId == post.authorObj?.userId;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Signaler la publication'),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Merci, votre signalement a été transmis.')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copier le texte'),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            if (isAuthor)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Supprimer la publication', style: TextStyle(color: Colors.red)),
                onTap: () {
                  debugPrint('[COMMUNITY_POST_DELETE][UI] "Supprimer la publication" option tapped for post=${post.id}');
                  Navigator.of(context).pop();
                  _confirmDeletePost(context, post);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePost(BuildContext context, CommunityPost post) {
    debugPrint('[COMMUNITY_POST_DELETE][UI] Confirmation dialog opened for post=${post.id}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la publication'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette publication ?'),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('[COMMUNITY_POST_DELETE][UI] Deletion cancelled by user for post=${post.id}');
              Navigator.of(ctx).pop();
            },
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              debugPrint('[COMMUNITY_POST_DELETE][UI] Deletion confirmed by user for post=${post.id}');
              Navigator.of(ctx).pop();
              try {
                CommunityFeedController? feedController;
                try {
                  feedController = Get.find<CommunityFeedController>(tag: post.id);
                } catch (_) {
                  try {
                    feedController = Get.find<CommunityFeedController>();
                  } catch (e) {
                    debugPrint('[COMMUNITY_POST_DELETE][UI] Failed to find CommunityFeedController: $e');
                  }
                }
                if (feedController != null) {
                  feedController.deletePost(post.id);
                } else {
                  debugPrint('[COMMUNITY_POST_DELETE][UI] Error: CommunityFeedController not registered for post=${post.id}');
                }
              } catch (e) {
                debugPrint('[COMMUNITY_POST_DELETE][UI] Exception during delete dispatch: $e');
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _onAuthorTap(CommunityPost post) {
    final authorUserId = post.authorObj?.userId;
    if (authorUserId == null || authorUserId.isEmpty) return;
    final currentUserId = Get.isRegistered<AuthService>() ? Get.find<AuthService>().userId : null;
    if (authorUserId != currentUserId) {
      Get.toNamed(AppPages.externalProfilePath(authorUserId));
    }
  }
}

class _ReactionButtonsBar extends StatefulWidget {
  final CommunityPost post;
  final ValueChanged<PostReaction> onReactionTap;
  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;

  const _ReactionButtonsBar({
    required this.post,
    required this.onReactionTap,
    required this.onCommentTap,
    required this.onShareTap,
  });

  @override
  State<_ReactionButtonsBar> createState() => _ReactionButtonsBarState();
}

class _ReactionButtonsBarState extends State<_ReactionButtonsBar> {
  late PostReaction _userReaction;
  late int _likeCount;
  late int _dislikeCount;

  @override
  void initState() {
    super.initState();
    _userReaction = widget.post.userReaction;
    _likeCount = widget.post.likeCount;
    _dislikeCount = widget.post.dislikeCount;
  }

  @override
  void didUpdateWidget(covariant _ReactionButtonsBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post.userReaction != oldWidget.post.userReaction) {
      _userReaction = widget.post.userReaction;
    }
    if (widget.post.likeCount != oldWidget.post.likeCount) {
      _likeCount = widget.post.likeCount;
    }
    if (widget.post.dislikeCount != oldWidget.post.dislikeCount) {
      _dislikeCount = widget.post.dislikeCount;
    }
  }

  void _handleReaction(PostReaction reaction) {
    setState(() {
      if (_userReaction == reaction) {
        if (reaction == PostReaction.like) {
          _likeCount = (_likeCount > 0) ? _likeCount - 1 : 0;
        } else if (reaction == PostReaction.dislike) {
          _dislikeCount = (_dislikeCount > 0) ? _dislikeCount - 1 : 0;
        }
        _userReaction = PostReaction.none;
      } else {
        if (_userReaction == PostReaction.like) {
          _likeCount = (_likeCount > 0) ? _likeCount - 1 : 0;
        } else if (_userReaction == PostReaction.dislike) {
          _dislikeCount = (_dislikeCount > 0) ? _dislikeCount - 1 : 0;
        }

        if (reaction == PostReaction.like) {
          _likeCount++;
        } else if (reaction == PostReaction.dislike) {
          _dislikeCount++;
        }
        _userReaction = reaction;
      }
    });
    widget.onReactionTap(reaction);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 1. Upvote / Like
        InkWell(
          onTap: widget.post.isPublishing ? null : () => _handleReaction(PostReaction.like),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.north_rounded,
                  size: 18,
                  color: _userReaction == PostReaction.like
                      ? AppColors.primary
                      : colorScheme.onSurfaceVariant,
                ),
                if (_likeCount > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    NumberFormatter.formatCount(_likeCount),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: _userReaction == PostReaction.like
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: _userReaction == PostReaction.like
                          ? AppColors.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // 2. Downvote / Dislike
        InkWell(
          onTap: widget.post.isPublishing ? null : () => _handleReaction(PostReaction.dislike),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.south_rounded,
                  size: 18,
                  color: _userReaction == PostReaction.dislike
                      ? Colors.orangeAccent
                      : colorScheme.onSurfaceVariant,
                ),
                if (_dislikeCount > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    NumberFormatter.formatCount(_dislikeCount),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: _userReaction == PostReaction.dislike
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: _userReaction == PostReaction.dislike
                          ? Colors.orangeAccent
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // 3. Commenter
        InkWell(
          onTap: widget.post.isPublishing ? null : widget.onCommentTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 17,
                  color: colorScheme.onSurfaceVariant,
                ),
                if (widget.post.commentCount > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    NumberFormatter.formatCount(widget.post.commentCount),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // 4. Partager (avec compteur)
        InkWell(
          onTap: widget.post.isPublishing ? null : widget.onShareTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.ios_share_rounded,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                if (widget.post.shareCount > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    NumberFormatter.formatCount(widget.post.shareCount),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
