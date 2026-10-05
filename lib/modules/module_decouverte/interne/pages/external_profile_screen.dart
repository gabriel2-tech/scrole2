import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrole/app/theme/app_colors.dart';
import 'package:scrole/app/theme/text_styles.dart';
import 'package:scrole/shared/models/interest_model.dart';
import 'package:scrole/shared/utils/number_formatter.dart';
import 'package:scrole/shared/widgets/app_cached_image.dart';
import 'package:scrole/shared/widgets/user_certified_badge.dart';
import '../controllers/external_profile_controller.dart';

class ExternalProfileScreen extends GetView<ExternalProfileController> {
  const ExternalProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value)
            return Center(
              child: CircularProgressIndicator(color: colors.primary),
            );
          if (controller.error.value.isNotEmpty)
            return Center(child: Text(controller.error.value));
          final profile = controller.profile.value;
          if (profile == null) return const SizedBox.shrink();
          if (profile.isBlocked)
            return _PrivateProfile(
              message: 'profile_blocked_msg'.tr,
            );
          return RefreshIndicator(
            onRefresh: controller.loadProfile,
            color: colors.primary,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const _ReactiveHeader(),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _ReactiveIdentity(),
                      const SizedBox(height: 12),
                      const _ReactiveProfileBody(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _ReactiveHeader extends GetView<ExternalProfileController> {
  const _ReactiveHeader();
  @override
  Widget build(BuildContext context) =>
      Obx(() => _Header(profile: controller.profile.value!));
}

class _Header extends StatelessWidget {
  const _Header({required this.profile});
  final dynamic profile;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 185,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            height: 140,
            width: double.infinity,
            child: profile.coverUrl == null || profile.coverUrl!.isEmpty
                ? Container(color: AppColors.secondary.withValues(alpha: .25))
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      AppCachedImage(
                        imageUrl: profile.coverUrl!,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: .30),
                              Colors.transparent,
                              colors.surface.withValues(alpha: .35),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          Positioned(
            top: 12,
            left: 16,
            child: _HeaderButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: Get.back,
            ),
          ),
          Positioned(
            top: 12,
            right: 16,
            child: _HeaderButton(
              icon: Icons.more_horiz_rounded,
              onTap: () => _showProfileMenu(context),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.surface, width: 5),
                color: colors.primary,
              ),
              child: ClipOval(
                child: profile.photoUrl == null || profile.photoUrl!.isEmpty
                    ? const Icon(
                        Icons.person_rounded,
                        size: 48,
                        color: Colors.white,
                      )
                    : AppCachedImage(
                        imageUrl: profile.photoUrl!,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .35),
      builder: (_) => const _ProfileMenuSheet(),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.black.withValues(alpha: .42),
    shape: const CircleBorder(),
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 38,
        height: 38,
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    ),
  );
}

class _ReactiveIdentity extends GetView<ExternalProfileController> {
  const _ReactiveIdentity();
  @override
  Widget build(BuildContext context) => Obx(() {
    final p = controller.profile.value!;
    final name = p.displayName.trim();
    final displayName = name.isEmpty
        ? name
        : '${name[0].toUpperCase()}${name.substring(1)}';
    return _Identity(
      profile: p,
      displayName: displayName,
      controller: controller,
    );
  });
}

class _Identity extends StatelessWidget {
  const _Identity({
    required this.profile,
    required this.displayName,
    required this.controller,
  });
  final dynamic profile;
  final String displayName;
  final ExternalProfileController controller;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      displayName,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h4.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (profile.isCertified) ...[
                    const SizedBox(width: 6),
                    const UserCertifiedBadge(size: 20),
                  ],
                ],
              ),
              if ((profile.username ?? '').toString().trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  '@${profile.username}',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if ((profile.city ?? '').toString().trim().isNotEmpty ||
                  (profile.country ?? '').toString().trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        [profile.city, profile.country]
                            .where((s) => s != null && s.toString().trim().isNotEmpty)
                            .join(', '),
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (!profile.isPrivate) ...[
          const SizedBox(width: 10),
          _ProfileActions(controller: controller),
        ],
      ],
    );
  }
}

class _ProfileActions extends GetView<ExternalProfileController> {
  const _ProfileActions({required this.controller});
  final ExternalProfileController controller;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Obx(() {
      final p = controller.profile.value!;
      final pending = p.connectionRequestSent;
      final connected = p.isConnected;
      final busy = controller.isSendingRequest.value;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ConnectionButton(
            connected: connected,
            pending: pending,
            busy: busy,
            colors: colors,
            onTap: busy ? null : controller.handleConnectionTap,
          ),
          if (p.canMessage) ...[
            const SizedBox(width: 6),
            _CompactActionButton(
              icon: Icons.chat_bubble_outline_rounded,
              foreground: colors.onSurface,
              background: colors.surfaceContainerHigh,
              onTap: controller.openConversation,
            ),
          ],
        ],
      );
    });
  }
}

class _ConnectionButton extends StatelessWidget {
  const _ConnectionButton({
    required this.connected,
    required this.pending,
    required this.busy,
    required this.colors,
    required this.onTap,
  });
  final bool connected, pending, busy;
  final ColorScheme colors;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final labeled = pending || connected;
    final label = connected ? 'profile_action_friends'.tr : 'profile_action_sent'.tr;
    final icon = busy
        ? Icons.hourglass_top_rounded
        : connected
        ? Icons.check_rounded
        : pending
        ? Icons.hourglass_top_rounded
        : Icons.person_add_alt_1_rounded;
    return Material(
      color: connected
          ? colors.primary.withValues(alpha: .12)
          : pending
          ? colors.surfaceContainerHigh
          : colors.primary,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 36,
          constraints: BoxConstraints(minWidth: labeled ? 142 : 36),
          padding: EdgeInsets.symmetric(horizontal: labeled ? 12 : 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: connected
                    ? colors.primary
                    : pending
                    ? colors.onSurfaceVariant
                    : colors.onPrimary,
                size: 18,
              ),
              if (labeled) ...[
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    color: connected ? colors.primary : colors.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    required this.icon,
    required this.foreground,
    required this.background,
    required this.onTap,
  });
  final IconData icon;
  final Color foreground;
  final Color background;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: background,
    borderRadius: BorderRadius.circular(9),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(icon, color: foreground, size: 18),
      ),
    ),
  );
}

class _ReactiveProfileBody extends GetView<ExternalProfileController> {
  const _ReactiveProfileBody();
  @override
  Widget build(BuildContext context) => Obx(() {
    final p = controller.profile.value!;
    if (p.isPrivate)
      return _PrivateProfile(
        message: 'profile_private_msg'.tr,
      );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((p.bio ?? '').isNotEmpty) Text(p.bio!),
        if (p.interests.isNotEmpty) ...[
          const SizedBox(height: 14),
          _ProfileInterests(interests: p.interests),
        ],
        const SizedBox(height: 14),
        _ProfileStats(profile: p),
        if (p.activities.isNotEmpty) ...[
          const SizedBox(height: 14),
          _ProfileActivitiesSection(activities: p.activities),
        ],
        if ((p.slogan ?? '').isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(p.slogan!, style: TextStyle(fontStyle: FontStyle.italic)),
        ],
      ],
    );
  });
}

class _ProfileInterests extends StatelessWidget {
  const _ProfileInterests({required this.interests});
  final List<Interest> interests;
  @override
  Widget build(BuildContext context) {
    if (interests.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    final visibleInterests = interests.take(3).toList();
    final additionalCount = interests.length - 3;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...visibleInterests.map(
          (i) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: .45),
              ),
            ),
            child: Text(
              '#${i.name}',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        if (additionalCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: .6),
              ),
            ),
            child: Text(
              '+$additionalCount',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats({required this.profile});
  final dynamic profile;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _StatCard(
          value: NumberFormatter.formatCount(profile.friendCount),
          label: 'profile_action_friends'.tr,
          icon: Icons.people_outline_rounded,
        ),
      ),
    ],
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });
  final String value, label;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .35)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.onSurfaceVariant),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivateProfile extends StatelessWidget {
  const _PrivateProfile({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_outline_rounded, size: 34),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ProfileMenuSheet extends StatelessWidget {
  const _ProfileMenuSheet();
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withValues(alpha: .3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: _ProfileMenuRow(
                icon: Icons.flag_outlined,
                label: 'Signaler le compte',
                onTap: () {
                  Navigator.of(context).pop();
                  Get.snackbar(
                    'Signalement',
                    'Le signalement sera bientôt disponible.',
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'cancel'.tr,
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  const _ProfileMenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                color: destructive ? scheme.error : scheme.onSurfaceVariant,
                size: 22,
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  color: destructive ? scheme.error : scheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileActivitiesSection extends StatelessWidget {
  const _ProfileActivitiesSection({required this.activities});
  final List<Map<String, dynamic>> activities;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'profile_activities_title'.tr,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 85,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: activities.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final act = activities[index];
              final name = act['name']?.toString() ?? 'discover_tag_activity'.tr;
              final price = double.tryParse(act['base_price']?.toString() ?? '0') ?? 0.0;
              final currency = act['currency_code']?.toString() ?? 'XAF';

              return Container(
                width: 160,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      price <= 0
                          ? 'discover_price_free'.tr
                          : NumberFormatter.formatPrice(price, currency),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: price <= 0 ? AppColors.success : colors.primary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
