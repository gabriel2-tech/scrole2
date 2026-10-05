import 'package:flutter/material.dart';

import '../../interne/enums/community_role_enum.dart';
import 'news/community_hashtag.dart';

enum PostReaction { none, like, dislike }

enum PostType { texte, image, quiz, poll }

class PostMedia {
  final String type; // 'photo' or 'video'
  final String? url;
  final String? videoId;
  final String? thumbnailUrl;
  final int? durationMs;
  final int? sizeBytes;
  final Color color;
  final bool isVideo;

  const PostMedia({
    this.type = 'photo',
    this.url,
    this.videoId,
    this.thumbnailUrl,
    this.durationMs,
    this.sizeBytes,
    this.color = Colors.grey,
    this.isVideo = false,
  });

  factory PostMedia.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] ?? 'photo').toString().toLowerCase();
    final url = (json['url'] ?? json['media_url'] ?? '').toString();
    final videoId = json['video_id']?.toString();
    final isVideo = type == 'video' || (videoId != null && videoId.isNotEmpty) || url.toLowerCase().endsWith('.mp4') || url.toLowerCase().endsWith('.mov') || url.toLowerCase().endsWith('.avi') || url.toLowerCase().endsWith('.m3u8');
    
    return PostMedia(
      type: isVideo ? 'video' : 'photo',
      url: url,
      videoId: videoId,
      thumbnailUrl: json['thumbnail_url']?.toString(),
      durationMs: (json['duration_ms'] as num?)?.toInt(),
      sizeBytes: (json['size_bytes'] as num?)?.toInt(),
      isVideo: isVideo,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        if (url != null && url!.isNotEmpty) 'url': url,
        if (videoId != null && videoId!.isNotEmpty) 'video_id': videoId,
        if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
        if (durationMs != null) 'duration_ms': durationMs,
        if (sizeBytes != null) 'size_bytes': sizeBytes,
      };
}

class PollOption {
  final String id;
  final String label;
  final int votes;
  final double percent;
  final bool isMine;
  final bool? isCorrect; // for quiz

  const PollOption({
    required this.id,
    required this.label,
    this.votes = 0,
    this.percent = 0.0,
    this.isMine = false,
    this.isCorrect,
  });

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? json['text'] ?? '').toString(),
      votes: (json['votes'] as num?)?.toInt() ?? 0,
      percent: (json['percent'] as num?)?.toDouble() ?? 0.0,
      isMine: json['is_mine'] == true || json['is_mine'] == 1,
      isCorrect: json['is_correct'] == true || json['is_correct'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'votes': votes,
        'percent': percent,
        'is_mine': isMine,
        if (isCorrect != null) 'is_correct': isCorrect,
      };
}

class CommunityPoll {
  final String kind; // single, multiple, quiz, this_or_that
  final DateTime? endsAt;
  final bool isClosed;
  final int votersCount;
  final bool hasVoted;
  final List<String> myOptionIds;
  final bool resultsVisible;
  final List<PollOption> options;
  final String? correctOptionId; // for quiz
  final String? explanation; // for quiz

  const CommunityPoll({
    required this.kind,
    this.endsAt,
    this.isClosed = false,
    this.votersCount = 0,
    this.hasVoted = false,
    this.myOptionIds = const [],
    this.resultsVisible = false,
    this.options = const [],
    this.correctOptionId,
    this.explanation,
  });

  factory CommunityPoll.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List? ?? [];
    final parsedOptions = rawOptions.map((o) => PollOption.fromJson(Map<String, dynamic>.from(o as Map))).toList();
    final myOpts = (json['my_option_ids'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return CommunityPoll(
      kind: (json['kind'] ?? json['type'] ?? 'single').toString(),
      endsAt: json['ends_at'] != null ? DateTime.tryParse(json['ends_at'].toString()) : null,
      isClosed: json['is_closed'] == true || json['is_closed'] == 1,
      votersCount: (json['voters_count'] as num?)?.toInt() ?? 0,
      hasVoted: json['has_voted'] == true || json['has_voted'] == 1,
      myOptionIds: myOpts,
      resultsVisible: json['results_visible'] == true || json['results_visible'] == 1,
      options: parsedOptions,
      correctOptionId: json['correct_option_id']?.toString(),
      explanation: json['explanation']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'kind': kind,
        if (endsAt != null) 'ends_at': endsAt?.toIso8601String(),
        'is_closed': isClosed,
        'voters_count': votersCount,
        'has_voted': hasVoted,
        'my_option_ids': myOptionIds,
        'results_visible': resultsVisible,
        'options': options.map((o) => o.toJson()).toList(),
        if (correctOptionId != null) 'correct_option_id': correctOptionId,
        if (explanation != null) 'explanation': explanation,
      };
}

class PostComment {
  final String id;
  final String authorName;
  final Color authorColor;
  final String? avatarUrl;
  final String timeAgo;
  final String content;
  final int likesCount;
  final int repliesCount;
  final bool isOp;
  final bool isCertified;
  final PostReaction userReaction;
  final List<PostComment> replies;

  const PostComment({
    required this.id,
    required this.authorName,
    required this.authorColor,
    this.avatarUrl,
    required this.timeAgo,
    required this.content,
    this.likesCount = 0,
    this.repliesCount = 0,
    this.isOp = false,
    this.isCertified = false,
    this.userReaction = PostReaction.none,
    this.replies = const [],
  });

  PostComment copyWith({
    String? id,
    int? likesCount,
    int? repliesCount,
    PostReaction? userReaction,
    List<PostComment>? replies,
    bool? isCertified,
  }) {
    return PostComment(
      id: id ?? this.id,
      authorName: authorName,
      authorColor: authorColor,
      avatarUrl: avatarUrl,
      timeAgo: timeAgo,
      content: content,
      likesCount: likesCount ?? this.likesCount,
      repliesCount: repliesCount ?? this.repliesCount,
      isOp: isOp,
      userReaction: userReaction ?? this.userReaction,
      replies: replies ?? this.replies,
      isCertified: isCertified ?? this.isCertified,
    );
  }

  factory PostComment.fromJson(Map<String, dynamic> json) {
    final authorMap = json['author'] is Map ? Map<String, dynamic>.from(json['author'] as Map) : <String, dynamic>{};
    final firstName = (authorMap['first_name'] ?? '').toString();
    final lastName = (authorMap['last_name'] ?? '').toString();
    final username = (authorMap['username'] ?? authorMap['pseudo'] ?? 'Membre').toString();
    final authorName = (firstName.isNotEmpty || lastName.isNotEmpty) ? '$firstName $lastName'.trim() : username;
    final avatarUrl = authorMap['photo_url']?.toString();
    final isCertified = authorMap['is_certified'] == true || authorMap['is_certified'] == 1 || json['is_certified'] == true;

    final rawReplies = json['replies'] as List? ?? [];
    final parsedReplies = rawReplies.map((r) => PostComment.fromJson(Map<String, dynamic>.from(r as Map))).toList();

    return PostComment(
      id: (json['id'] ?? '').toString(),
      authorName: authorName,
      authorColor: Colors.primaries[((json['id']?.hashCode ?? 0)).abs() % Colors.primaries.length],
      avatarUrl: avatarUrl,
      timeAgo: CommunityPost._formatTimeAgo(json['created_at']),
      content: (json['content'] ?? '').toString(),
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      repliesCount: (json['replies_count'] as num?)?.toInt() ?? parsedReplies.length,
      isCertified: isCertified,
      replies: parsedReplies,
    );
  }
}

class CommunityPostAuthor {
  final String userId;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? photoUrl;
  final bool isCertified;
  final String? pseudo;
  final String? bio;

  const CommunityPostAuthor({
    required this.userId,
    required this.username,
    this.firstName,
    this.lastName,
    this.photoUrl,
    this.isCertified = false,
    this.pseudo,
    this.bio,
  });

  factory CommunityPostAuthor.fromJson(Map<String, dynamic> json) {
    return CommunityPostAuthor(
      userId: (json['user_id'] ?? json['id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      photoUrl: json['photo_url']?.toString(),
      isCertified: json['is_certified'] == true || json['is_certified'] == 1,
      pseudo: json['pseudo']?.toString(),
      bio: json['bio']?.toString(),
    );
  }

  String get displayName {
    final fn = firstName ?? '';
    final ln = lastName ?? '';
    if (fn.isNotEmpty || ln.isNotEmpty) {
      return '$fn $ln'.trim();
    }
    return username.isNotEmpty ? username : (pseudo ?? 'Membre');
  }
}

class CommunityPost {
  final String id;
  final String authorName;
  final CommunityPostAuthor? authorObj;
  final CommunityRole authorRole;
  final Color authorColor;
  final String timeAgo;
  final String content;
  final List<PostMedia> media;
  final PostType type;
  final List<String> quizOptions;
  final int likeCount;
  final int dislikeCount;
  final int commentCount;
  final int shareCount;
  final List<PostComment> comments;
  final int viewCount;
  final PostReaction userReaction;
  final bool isPublishing;
  final String status; // 'en_attente', 'active', 'rejected'
  final bool commentsEnabled;
  final bool sharingEnabled;
  final List<CommunityHashtag> hashtags;
  final List<String> photos;
  final CommunityPoll? poll;

  const CommunityPost({
    required this.id,
    required this.authorName,
    this.authorObj,
    this.authorRole = CommunityRole.member,
    required this.authorColor,
    required this.timeAgo,
    required this.content,
    this.media = const [],
    this.type = PostType.texte,
    this.quizOptions = const [],
    this.likeCount = 0,
    this.dislikeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.comments = const [],
    this.viewCount = 0,
    this.userReaction = PostReaction.none,
    this.isPublishing = false,
    this.status = 'active',
    this.commentsEnabled = true,
    this.sharingEnabled = true,
    this.hashtags = const [],
    this.photos = const [],
    this.poll,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    final authorMap = json['author'] is Map ? Map<String, dynamic>.from(json['author'] as Map) : <String, dynamic>{};
    final authorObj = CommunityPostAuthor.fromJson(authorMap);
    final authorName = authorObj.displayName;
    
    List<PostMedia> mediaList = [];
    if (json['media'] is List) {
      mediaList = (json['media'] as List)
          .map((e) => e is Map ? PostMedia.fromJson(Map<String, dynamic>.from(e)) : null)
          .whereType<PostMedia>()
          .toList();
    } else {
      List<String> rawMediaUrls = [];
      if (json['photos'] is List) {
        rawMediaUrls = (json['photos'] as List).map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      } else if (json['photo'] != null) {
        final pStr = json['photo'].toString();
        if (pStr.isNotEmpty) {
          rawMediaUrls = pStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        }
      }
      mediaList = rawMediaUrls.map((u) => PostMedia(url: u, type: 'photo', isVideo: false)).toList();
      if (json['video'] != null && json['video'].toString().isNotEmpty) {
        mediaList.add(PostMedia(url: json['video'].toString(), type: 'video', isVideo: true));
      }
    }

    PostReaction reaction = PostReaction.none;
    final vr = json['viewer_reaction']?.toString().toLowerCase();
    if (vr == 'like') reaction = PostReaction.like;
    if (vr == 'dislike') reaction = PostReaction.dislike;

    final commentsEnabled = json['comments_enabled'] == true || json['comments_enabled'] == 1 || json['comments_enabled'] == null;
    final sharingEnabled = json['sharing_enabled'] == true || json['sharing_enabled'] == 1 || json['sharing_enabled'] == null;

    List<CommunityHashtag> hashtags = [];
    if (json['hashtags'] is List) {
      hashtags = (json['hashtags'] as List)
          .map((h) => h is Map ? CommunityHashtag.fromJson(Map<String, dynamic>.from(h)) : null)
          .whereType<CommunityHashtag>()
          .toList();
    }

    CommunityPoll? poll;
    if (json['poll'] is Map) {
      poll = CommunityPoll.fromJson(Map<String, dynamic>.from(json['poll'] as Map));
    }

    return CommunityPost(
      id: (json['id'] ?? '').toString(),
      authorName: authorName,
      authorObj: authorObj,
      authorColor: Colors.primaries[((json['id']?.hashCode ?? 0)).abs() % Colors.primaries.length],
      timeAgo: _formatTimeAgo(json['created_at']),
      content: (json['content'] ?? '').toString(),
      media: mediaList,
      type: poll != null ? PostType.poll : (mediaList.isNotEmpty ? PostType.image : PostType.texte),
      likeCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      dislikeCount: (json['dislikes_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comments_count'] as num?)?.toInt() ?? 0,
      shareCount: (json['shares_count'] as num?)?.toInt() ?? (json['share_count'] as num?)?.toInt() ?? 0,
      userReaction: reaction,
      status: (json['status'] ?? 'active').toString(),
      commentsEnabled: commentsEnabled,
      sharingEnabled: sharingEnabled,
      hashtags: hashtags,
      photos: mediaList.where((m) => !m.isVideo).map((m) => m.url ?? '').where((u) => u.isNotEmpty).toList(),
      poll: poll,
    );
  }

  static String _formatTimeAgo(dynamic dateVal) {
    if (dateVal == null) return '';
    try {
      final dt = DateTime.parse(dateVal.toString());
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'À l\'instant';
      if (diff.inHours < 1) return 'Il y a ${diff.inMinutes}m';
      if (diff.inDays < 1) return 'Il y a ${diff.inHours}h';
      if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  CommunityPost copyWith({
    int? likeCount,
    int? dislikeCount,
    int? commentCount,
    int? shareCount,
    List<PostComment>? comments,
    int? viewCount,
    PostReaction? userReaction,
    bool? isPublishing,
    CommunityPoll? poll,
    List<PostMedia>? media,
  }) {
    return CommunityPost(
      id: id,
      authorName: authorName,
      authorRole: authorRole,
      authorColor: authorColor,
      timeAgo: timeAgo,
      content: content,
      media: media ?? this.media,
      type: type,
      quizOptions: quizOptions,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      comments: comments ?? this.comments,
      viewCount: viewCount ?? this.viewCount,
      userReaction: userReaction ?? this.userReaction,
      isPublishing: isPublishing ?? this.isPublishing,
      poll: poll ?? this.poll,
    );
  }
}
