import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../shared/utils/number_formatter.dart';
import '../../../module_evenement/centre/models/event_model.dart';
import '../../centre/models/discover_models.dart';
import '../controllers/discover_controller.dart';
import '../../../module_communautes/centre/models/news/community_discovery_model.dart';
import '../widgets/account_list_tile.dart';
import '../widgets/activity_list_tile.dart';
import '../widgets/community_list_tile.dart';
import '../widgets/event_list_tile.dart';

class SearchScreen extends GetView<DiscoverController> {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<DiscoverController>()) Get.put(DiscoverController());
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _SearchBar(
              controller: controller.searchTextController,
              onClear: controller.clearSearch,
            ),
            Obx(() => controller.query.value.isNotEmpty
                ? const _SearchContent()
                : const _IdleContent()),
          ],
        ),
      ),
    );
  }
}

class _IdleContent extends GetView<DiscoverController> {
  const _IdleContent();

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;

    return Expanded(
      child: RefreshIndicator(
        onRefresh: () => controller.loadDiscoverCommunities(refresh: true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'discover_suggested_communities'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h4.copyWith(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                final communities = controller.discoverCommunities;
                if (communities.isEmpty && controller.isDiscoverLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (communities.isEmpty) {
                  return Center(child: Text('community_empty_title'.tr));
                }

                final leftCol = <CommunityDiscoveryModel>[];
                final rightCol = <CommunityDiscoveryModel>[];

                for (int i = 0; i < communities.length; i++) {
                  if (i % 2 == 0) {
                    leftCol.add(communities[i]);
                  } else {
                    rightCol.add(communities[i]);
                  }
                }

                return NotificationListener<ScrollNotification>(
                  onNotification: (scrollInfo) {
                    if (!controller.isDiscoverLoading.value &&
                        controller.discoverHasMore.value &&
                        scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                      controller.loadDiscoverCommunities();
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: leftCol
                                .map((c) => _PinterestCommunityCard(community: c, onTap: () => controller.onCommunityTap(c.id)))
                                .toList(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            children: rightCol
                                .map((c) => _PinterestCommunityCard(community: c, onTap: () => controller.onCommunityTap(c.id)))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinterestCommunityCard extends StatelessWidget {
  final CommunityDiscoveryModel community;
  final VoidCallback onTap;

  const _PinterestCommunityCard({required this.community, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: community.photoCover ?? community.photoProfile ?? '',
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: isDark ? AppColors.surfaceDark : Colors.grey[300],
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.4),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      community.visibility.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        if (community.photoProfile != null) ...[
                          CircleAvatar(
                            radius: 13,
                            backgroundImage: CachedNetworkImageProvider(community.photoProfile!),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            community.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.people_alt_rounded, size: 12, color: Colors.white70),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  NumberFormatter.formatCount(community.memberCount),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'discover_explore_button'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchContent extends StatefulWidget {
  const _SearchContent();

  @override
  State<_SearchContent> createState() => _SearchContentState();
}

class _SearchContentState extends State<_SearchContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final controller = Get.find<DiscoverController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return DateTime.now();
    try {
      final parts = raw.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          _SearchTabBar(controller: _tabController),
          Expanded(
            child: Obx(() {
              if (controller.state.value == DiscoverState.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.state.value == DiscoverState.error) {
                return Center(child: Text(controller.errorMessage.value));
              }
              return TabBarView(
                controller: _tabController,
                children: [
                  _ResultsList<SearchResultItem>(
                    items: controller.accountResults,
                    builder: (item) => AccountListTile(
                      account: AccountSuggestion(
                        id: item.id,
                        username: item.title,
                        displayName: (item.subtitle != null && item.subtitle!.trim().isNotEmpty)
                            ? item.subtitle!
                            : item.title,
                        avatarUrl: item.photoUrl,
                        friendCount: item.friendCount,
                        isVerified: item.isCertified,
                      ),
                      onTap: () => controller.onAccountTap(item.id),
                    ),
                  ),
                  _ResultsList<SearchResultItem>(
                    items: controller.eventResults,
                    builder: (item) => EventListTile(
                      event: EventModel(
                        id: item.id,
                        creatorId: '',
                        name: item.title,
                        slug: '',
                        coverImageUrl: item.photoUrl,
                        startsAt: _parseDate(item.subtitle),
                        createdAt: DateTime.now(),
                      ),
                      onTap: () => controller.onEventTap(item.id),
                    ),
                  ),
                  _ResultsList<SearchResultItem>(
                    items: controller.communityResults,
                    builder: (item) => CommunityListTile(
                      community: CommunitySuggestion(
                        id: item.id,
                        name: item.title,
                        imageUrl: item.photoUrl,
                        description: item.subtitle,
                      ),
                      onTap: () => controller.onCommunityTap(item.id),
                    ),
                  ),
                  _ResultsList<SearchResultItem>(
                    items: controller.activityResults,
                    builder: (item) => ActivityListTile(
                      item: item,
                      onTap: () => controller.onActivityTap(item.id),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ResultsList<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(T) builder;

  const _ResultsList({required this.items, required this.builder});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: Text('discover_no_results'.tr));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => builder(items[index]),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;

  const _SearchBar({required this.controller, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'discover_search_hint'.tr,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear_rounded),
            onPressed: onClear,
          ),
          filled: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _SearchTabBar extends StatelessWidget {
  final TabController controller;

  const _SearchTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _buildTabChip(context, 0, 'discover_tab_accounts'.tr),
            const SizedBox(width: 10),
            _buildTabChip(context, 1, 'discover_tab_events'.tr),
            const SizedBox(width: 10),
            _buildTabChip(context, 2, 'discover_tab_communities'.tr),
            const SizedBox(width: 10),
            _buildTabChip(context, 3, 'discover_tab_activities'.tr),
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip(BuildContext context, int index, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = controller.index == index;

    return GestureDetector(
      onTap: () => controller.animateTo(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primary.withValues(alpha: .15)
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive
                ? colorScheme.primary.withValues(alpha: .4)
                : colorScheme.outlineVariant.withValues(alpha: .5),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: isActive ? colorScheme.primary : colorScheme.onSurface,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
