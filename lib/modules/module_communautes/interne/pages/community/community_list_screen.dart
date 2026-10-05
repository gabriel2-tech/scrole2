import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../app/theme/text_styles.dart';
import '../../../../../shared/widgets/shimmer.dart';
import '../../controllers/community/community_list_controller.dart';
import '../../enums/community_status_enum.dart';
import '../../etats/community_empty_state.dart';
import '../../etats/community_error_states.dart';
import '../../widgets/community/community_grid_cards.dart';

class CommunityListScreen extends GetView<CommunityListController> {
  const CommunityListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CommunityListController>()) {
      Get.put(CommunityListController());
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Obx(() {
        final currentStatus = controller.status.value;

        if (currentStatus == CommunityStatus.loading || currentStatus == CommunityStatus.initial) {
          return const _CommunityGridShimmer();
        }

        switch (currentStatus) {
          case CommunityStatus.error:
            return CommunityError(controller: controller);

          case CommunityStatus.empty:
            return CommunityEmpty(controller: controller);

          case CommunityStatus.success:
            return _CommunityGrid(controller: controller);

          default:
            return const _CommunityGridShimmer();
        }
      }),
    );
  }
}

// =========================================
// GRILLE AVEC PULL TO REFRESH
// =========================================
class _CommunityGrid extends StatelessWidget {
  final CommunityListController controller;

  const _CommunityGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: controller.refreshData,
      color: colorScheme.primary,
      backgroundColor: colorScheme.surface,
      strokeWidth: 3,
      displacement: 60,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(), // Important pour le pull-to-refresh
        slivers: [
          // --- Header (sans icône refresh) ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Text(
                'community_my_communities'.tr,
                style: AppTextStyles.h3.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),

          // --- Grille 2 colonnes ---
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: Obx(() {
              return SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final community = controller.joinedCommunities[index];
                    return CommunityGridCard(
                      community: community,
                      onTap: () => controller.navigateToCommunityDetail(community.id, isJoined: true),
                    );
                  },
                  childCount: controller.joinedCommunities.length,
                ),
              );
            }),
          ),

          // --- Découvrir plus de communautés ---
          SliverToBoxAdapter(
            child: _DiscoverMoreSection(
              onExplore: controller.exploreMoreCommunities,
            ),
          ),

          // --- Espace réduit pour la nav flottante ---
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).padding.bottom + 24,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================
// SHIMMER GRILLE
// =========================================
class _CommunityGridShimmer extends StatelessWidget {
  const _CommunityGridShimmer();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: SkeletonShimmer(width: 180, height: 32, borderRadius: 8),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            delegate: SliverChildBuilderDelegate(
                  (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: const SkeletonShimmer(
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: 20,
                ),
              ),
              childCount: 6,
            ),
          ),
        ),
      ],
    );
  }
}

// =========================================
// SECTION "DÉCOUVRIR PLUS DE COMMUNAUTÉS"
// =========================================
class _DiscoverMoreSection extends StatelessWidget {
  final VoidCallback onExplore;

  const _DiscoverMoreSection({required this.onExplore});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        children: [
          Divider(
            color: colorScheme.outline.withValues(alpha: 0.3),
            thickness: 1,
            height: 1,
          ),
          const SizedBox(height: 20),
          Text(
            'community_discover_more_text'.tr,
            style: AppTextStyles.body.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: onExplore,
            child: Text(
              'community_discover_button'.tr,
              style: AppTextStyles.link.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}