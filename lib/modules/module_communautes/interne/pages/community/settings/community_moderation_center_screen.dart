import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrole/app/theme/text_styles.dart';
import 'package:scrole/modules/module_communautes/centre/services/community_service.dart';
import 'community_join_requests_screen.dart';
import '../../../controllers/community/settings/community_join_requests_controller.dart';

class CommunityModerationCenterScreen extends StatelessWidget {
  const CommunityModerationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final String communityId = Get.arguments?.toString() ?? Get.parameters['id'] ?? '';

    if (communityId.isNotEmpty && !Get.isRegistered<CommunityJoinRequestsController>()) {
      Get.put(CommunityJoinRequestsController(communityId));
    }

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          title: Text('Centre de modération', style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.bold)),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: colorScheme.primary,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.6),
            tabs: const [
              Tab(text: 'Publications'),
              Tab(text: 'Adhésions'),
              Tab(text: 'Alertes'),
              Tab(text: 'Spam'),
              Tab(text: 'Signalements'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Publications en attente
            _PendingPostsTab(communityId: communityId),
            // Tab 2: Demandes d'adhésion
            const CommunityJoinRequestsScreenBody(),
            // Tab 3: Alertes de modération
            const _PlaceholderTab(title: 'Aucune alerte de modération'),
            // Tab 4: Spam potentiel
            const _PlaceholderTab(title: 'Aucun spam détecté'),
            // Tab 5: Contenu signalé
            const _PlaceholderTab(title: 'Aucun contenu signalé'),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String title;
  const _PlaceholderTab({required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          title,
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 15),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _PendingPostsTab extends StatefulWidget {
  final String communityId;
  const _PendingPostsTab({required this.communityId});

  @override
  State<_PendingPostsTab> createState() => _PendingPostsTabState();
}

class _PendingPostsTabState extends State<_PendingPostsTab> {
  bool isLoading = true;
  List<Map<String, dynamic>> pendingPosts = [];

  @override
  void initState() {
    super.initState();
    _loadPendingPosts();
  }

  Future<void> _loadPendingPosts() async {
    try {
      setState(() => isLoading = true);
      final service = Get.find<CommunityService>();
      final result = await service.getCommunityPendingPosts(widget.communityId);
      final list = result['posts'] is List ? List<Map<String, dynamic>>.from(result['posts'].map((e) => Map<String, dynamic>.from(e))) : <Map<String, dynamic>>[];
      setState(() {
        pendingPosts = list;
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _moderate(String postId, String action) async {
    try {
      final service = Get.find<CommunityService>();
      await service.moderateCommunityPost(postId, action);
      _loadPendingPosts();
      Get.snackbar('Succès', action == 'approve' ? 'Publication approuvée' : 'Publication rejetée', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Erreur', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (pendingPosts.isEmpty) {
      return Center(
        child: Text('Aucune publication en attente', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 15)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: pendingPosts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final post = pendingPosts[index];
        final content = post['content']?.toString() ?? '';
        final postId = post['id']?.toString() ?? '';
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(content.isNotEmpty ? content : '[Média / Publication]', style: AppTextStyles.body),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _moderate(postId, 'reject'),
                    style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error),
                    child: const Text('Rejeter'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _moderate(postId, 'approve'),
                    style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: Colors.white),
                    child: const Text('Approuver'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
