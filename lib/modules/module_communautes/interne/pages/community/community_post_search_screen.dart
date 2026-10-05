import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrole/modules/module_communautes/centre/models/community_post.dart';
import 'package:scrole/modules/module_communautes/centre/services/community_service.dart';
import 'package:scrole/modules/module_communautes/interne/controllers/community/community_feed_controller.dart';
import 'package:scrole/modules/module_communautes/interne/widgets/community/feed_post_card.dart';

class CommunityPostSearchScreen extends StatefulWidget {
  const CommunityPostSearchScreen({super.key});

  @override
  State<CommunityPostSearchScreen> createState() => _CommunityPostSearchScreenState();
}

class _CommunityPostSearchScreenState extends State<CommunityPostSearchScreen> {
  late final String communityId;
  final TextEditingController _searchController = TextEditingController();
  final CommunityService _service = Get.find<CommunityService>();

  List<CommunityPost> _allPosts = [];
  List<CommunityPost> _filteredPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    communityId = Get.arguments?.toString() ?? Get.parameters['id'] ?? '';
    _loadPosts();
    _searchController.addListener(_filterPosts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      final res = await _service.getCommunityFeed(communityId, limit: 50);
      final rawItems = res['items'] as List? ?? [];
      final parsed = rawItems.map((p) => CommunityPost.fromJson(Map<String, dynamic>.from(p as Map))).toList();
      if (mounted) {
        setState(() {
          _allPosts = parsed;
          _filteredPosts = parsed;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[CommunityPostSearchScreen] error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterPosts() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredPosts = _allPosts);
      return;
    }

    final cleanQuery = query.startsWith('#') ? query.substring(1) : query;

    setState(() {
      _filteredPosts = _allPosts.where((p) {
        final contentMatch = p.content.toLowerCase().contains(cleanQuery);
        final hashtagMatch = p.hashtags.any((h) => h.name.toLowerCase().contains(cleanQuery));
        final authorMatch = p.authorName.toLowerCase().contains(cleanQuery);
        return contentMatch || hashtagMatch || authorMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Rechercher un post ou #hashtag...',
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: colorScheme.onSurfaceVariant),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _filterPosts();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredPosts.isEmpty
              ? Center(
                  child: Text(
                    'Aucune publication trouvée',
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 15),
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredPosts.length,
                  itemBuilder: (context, index) {
                    final post = _filteredPosts[index];
                    return FeedPostCard(
                      post: post,
                      onReactionTap: (reaction) {
                        try {
                          final feedController = Get.find<CommunityFeedController>();
                          feedController.toggleReaction(post.id, reaction);
                        } catch (_) {}
                      },
                      onCommentTap: () {
                        try {
                          final feedController = Get.find<CommunityFeedController>();
                          feedController.openCommentsSheet(post);
                        } catch (_) {}
                      },
                      onShareTap: () {
                        try {
                          final feedController = Get.find<CommunityFeedController>();
                          feedController.sharePost(post);
                        } catch (_) {}
                      },
                    );
                  },
                ),
    );
  }
}
