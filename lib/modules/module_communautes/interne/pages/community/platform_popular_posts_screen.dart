import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scrole/app/theme/app_colors.dart';
import 'package:scrole/app/theme/text_styles.dart';
import 'package:scrole/modules/module_communautes/centre/models/community_post.dart';
import 'package:scrole/modules/module_communautes/interne/widgets/community/feed_post_card.dart';

class PlatformPopularPostsScreen extends StatefulWidget {
  const PlatformPopularPostsScreen({super.key});

  @override
  State<PlatformPopularPostsScreen> createState() => _PlatformPopularPostsScreenState();
}

class _PlatformPopularPostsScreenState extends State<PlatformPopularPostsScreen> {
  bool _isLoading = true;
  List<CommunityPost> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadPopularPosts();
  }

  Future<void> _loadPopularPosts() async {
    try {
      setState(() => _isLoading = true);
      final client = Supabase.instance.client;
      final response = await client
          .from('community_posts')
          .select('*, user_profiles(*), community_post_reactions(*), community_post_comments(*)')
          .order('like_count', ascending: false)
          .limit(50);

      final list = (response as List).map((m) => CommunityPost.fromJson(Map<String, dynamic>.from(m))).toList();
      if (mounted) {
        setState(() {
          _posts = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[PlatformPopularPosts] error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Posts les plus populaires'),
        titleTextStyle: AppTextStyles.h5.copyWith(color: colorScheme.onSurface),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _posts.isEmpty
              ? Center(child: Text('Aucun post populaire trouvé.', style: AppTextStyles.body.copyWith(color: colorScheme.outline)))
              : RefreshIndicator(
                  onRefresh: _loadPopularPosts,
                  child: ListView.builder(
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      final post = _posts[index];
                      return FeedPostCard(
                        post: post,
                        onReactionTap: (_) {},
                        onCommentTap: () {},
                        onShareTap: () {},
                      );
                    },
                  ),
                ),
    );
  }
}
