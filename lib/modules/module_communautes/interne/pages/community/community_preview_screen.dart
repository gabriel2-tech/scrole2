import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:scrole/app/routes/app_pages.dart';
import 'package:scrole/app/theme/app_colors.dart';
import 'package:scrole/app/theme/text_styles.dart';
import 'package:scrole/modules/module_communautes/centre/models/news/community.dart';
import 'package:scrole/modules/module_communautes/centre/models/news/community_preview_data.dart';
import 'package:scrole/modules/module_communautes/interne/controllers/community/community_preview_controller.dart';
import 'package:scrole/shared/utils/number_formatter.dart';
import 'package:scrole/shared/widgets/app_cached_image.dart';
import 'package:scrole/shared/widgets/expandable_text_widget.dart';

class CommunityPreviewScreen extends GetView<CommunityPreviewController> {
  const CommunityPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Obx(() {
        switch (controller.status.value) {
          case PreviewStatus.initial:
          case PreviewStatus.loading:
            return const _LoadingView();
          case PreviewStatus.error:
            return _ErrorView(
              message: controller.errorMessage.value,
              onRetry: controller.loadPreview,
            );
          case PreviewStatus.notFound:
            return const _NotFoundView();
          case PreviewStatus.loaded:
          case PreviewStatus.joining:
            return _ContentView(controller: controller);
        }
      }),
    );
  }
}

class _ContentView extends StatelessWidget {
  final CommunityPreviewController controller;
  const _ContentView({required this.controller});

  @override
  Widget build(BuildContext context) {
    final data = controller.previewData.value!;
    final community = data.community;
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: controller.loadPreview,
      color: colorScheme.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ===== STICKY TOP HEADER BAR =====
          SliverAppBar(
            pinned: true,
            floating: false,
            elevation: 0,
            scrolledUnderElevation: 2,
            backgroundColor: colorScheme.surface,
            leading: Center(
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: controller.goBack,
                tooltip: 'Retour',
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    community.name,
                    style: AppTextStyles.h5.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _HeaderActionButton(controller: controller, data: data),
              ],
            ),
          ),

          // ===== PAGE CONTENT =====
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Cover & Avatar
                _CoverAndAvatarHeader(community: community, colorScheme: colorScheme),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. Name & Slug & Visibility Badge
                      _buildNameSlugAndVisibility(community, colorScheme),
                      const SizedBox(height: 14),

                      // 3. Lightweight Inline Members Count & Creation Date
                      _InlineMetadataRow(community: community, colorScheme: colorScheme),
                      const SizedBox(height: 20),

                      // 4. Ineligibility Notice Banner (if not eligible)
                      if (controller.actionUiState == CommunityActionUiState.notMemberNotEligible) ...[
                        _IneligibleNoticeCard(colorScheme: colorScheme),
                        const SizedBox(height: 20),
                      ],

                      // 5. Contacts / Friends Presence Card
                      if (data.friendAvatars.isNotEmpty) ...[
                        _FriendsPresenceCard(
                          avatars: data.friendAvatars,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 6. About / Description Section
                      Text(
                        'community_about_title'.tr.toUpperCase(),
                        style: AppTextStyles.overline.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ExpandableText(
                        text: community.description ?? 'community_no_description'.tr,
                        maxLines: 3,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: colorScheme.onSurface,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // 7. Access Conditions Section
                      if (controller.getAccessBadges().isNotEmpty) ...[
                        Text(
                          'condition_access_title'.tr.toUpperCase(),
                          style: AppTextStyles.overline.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _AccessConditionsCard(
                          badges: controller.getAccessBadges(),
                          colorScheme: colorScheme,
                        ),
                        if (data.requiresApproval) ...[
                          const SizedBox(height: 10),
                          _ApprovalNotice(colorScheme: colorScheme),
                        ],
                        const SizedBox(height: 28),
                      ],

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameSlugAndVisibility(Community community, ColorScheme colorScheme) {
    final isPublic = community.visibility == 'public';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                community.name,
                style: AppTextStyles.h2.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPublic ? Icons.public : Icons.lock_outline_rounded,
                    size: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isPublic
                        ? 'community_visibility_public'.tr
                        : 'community_visibility_private'.tr,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '@${community.slug}',
          style: AppTextStyles.body.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ===== COMPACT ACTION BUTTON IN STICKY HEADER =====

class _HeaderActionButton extends StatelessWidget {
  final CommunityPreviewController controller;
  final CommunityPreviewData data;

  const _HeaderActionButton({
    required this.controller,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isJoining = controller.status.value == PreviewStatus.joining;
    final uiState = controller.actionUiState;

    switch (uiState) {
      case CommunityActionUiState.loading:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );

      case CommunityActionUiState.memberWithProfile:
      case CommunityActionUiState.memberWithoutProfile:
        return FilledButton.icon(
          onPressed: () => Get.offNamed(AppPages.communityDetailPath(data.community.id)),
          icon: const Icon(Icons.arrow_forward_rounded, size: 14),
          label: Text('community_action_access'.tr),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            textStyle: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        );

      case CommunityActionUiState.pendingRequest:
        return FilledButton(
          onPressed: isJoining ? null : controller.cancelJoinRequest,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.errorContainer,
            foregroundColor: colorScheme.onErrorContainer,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            textStyle: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: isJoining
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Annuler la demande'),
        );

      case CommunityActionUiState.notMemberEligible:
        final label = data.requiresApproval
            ? 'community_request_join_action'.tr
            : 'community_join_action'.tr;

        return FilledButton(
          onPressed: isJoining ? null : controller.joinCommunity,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            textStyle: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
          ),
          child: isJoining
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(label),
        );

      case CommunityActionUiState.notMemberNotEligible:
        return const SizedBox.shrink();
    }
  }
}

// ===== COVER & AVATAR HEADER =====

class _CoverAndAvatarHeader extends StatelessWidget {
  final Community community;
  final ColorScheme colorScheme;

  const _CoverAndAvatarHeader({required this.community, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Banner
          SizedBox(
            height: 160,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (community.bannerUrl != null && community.bannerUrl!.isNotEmpty)
                  AppCachedImage(
                    imageUrl: community.bannerUrl!,
                    fit: BoxFit.cover,
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colorScheme.primary, colorScheme.secondary],
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.groups_rounded, size: 56, color: Colors.white24),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.25),
                        Colors.transparent,
                        colorScheme.surface.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Avatar
          Positioned(
            bottom: 0,
            left: 20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.surface, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                child: community.avatarUrl != null && community.avatarUrl!.isNotEmpty
                    ? AppCachedImage(
                        imageUrl: community.avatarUrl!,
                        width: 80,
                        height: 80,
                        borderRadius: BorderRadius.circular(40),
                        fit: BoxFit.cover,
                      )
                    : Text(
                        community.name.isNotEmpty
                            ? community.name.characters.first.toUpperCase()
                            : '?',
                        style: AppTextStyles.h2.copyWith(color: colorScheme.primary),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== LIGHTWEIGHT INLINE METADATA ROW =====

class _InlineMetadataRow extends StatelessWidget {
  final Community community;
  final ColorScheme colorScheme;

  const _InlineMetadataRow({required this.community, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final formattedMembers = NumberFormatter.formatCount(community.memberCount);
    final formattedDate = community.createdAt != null
        ? DateFormat('MMM yyyy').format(community.createdAt!)
        : null;

    return Row(
      children: [
        Icon(Icons.people_alt_rounded, size: 16, color: colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          '$formattedMembers membres',
          style: AppTextStyles.labelMedium.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (formattedDate != null) ...[
          const SizedBox(width: 12),
          Text(
            '•',
            style: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          ),
          const SizedBox(width: 12),
          Icon(Icons.calendar_today_rounded, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            'Depuis $formattedDate',
            style: AppTextStyles.caption.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

// ===== INELIGIBLE NOTICE CARD =====

class _IneligibleNoticeCard extends StatelessWidget {
  final ColorScheme colorScheme;
  const _IneligibleNoticeCard({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: colorScheme.onSurfaceVariant, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'community_ineligible_notice'.tr,
              style: AppTextStyles.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== FRIENDS PRESENCE CARD =====

class _FriendsPresenceCard extends StatelessWidget {
  final List<String> avatars;
  final ColorScheme colorScheme;

  const _FriendsPresenceCard({required this.avatars, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.people_alt_outlined, size: 18, color: colorScheme.primary),
          const SizedBox(width: 10),
          Text(
            'community_friends_joined'.tr,
            style: AppTextStyles.labelMedium.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 28,
            width: avatars.length * 20.0 + 8,
            child: Stack(
              children: avatars.take(4).toList().asMap().entries.map((e) {
                return Positioned(
                  left: e.key * 16.0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.surfaceContainerLow, width: 2),
                    ),
                    child: AppCachedImage(
                      imageUrl: e.value,
                      width: 28,
                      height: 28,
                      borderRadius: BorderRadius.circular(14),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== ACCESS CONDITIONS CARDS =====

class _AccessConditionsCard extends StatelessWidget {
  final List<String> badges;
  final ColorScheme colorScheme;

  const _AccessConditionsCard({required this.badges, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: badges.asMap().entries.map((entry) {
          final isLast = entry.key == badges.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.value,
                    style: AppTextStyles.bodySmall.copyWith(color: colorScheme.onSurface),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ApprovalNotice extends StatelessWidget {
  final ColorScheme colorScheme;
  const _ApprovalNotice({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.info_outline_rounded, size: 15, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'community_approval_notice'.tr,
            style: AppTextStyles.caption.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

// ===== LOADING, ERROR & NOT FOUND VIEWS =====

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: AppColors.disabled),
            const SizedBox(height: 16),
            Text('community_not_found'.tr, style: AppTextStyles.bodyLarge),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}
