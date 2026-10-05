import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:scrole/app/utils/boot_timing.dart';

import '../../../../../app/service_global/connectivity_service.dart';
import '../../../../../shared/widgets/app_cached_image.dart';
import '../../../../../shared/widgets/glas_buton.dart';
import '../../../../../shared/widgets/shimmer.dart';
import '../../../../../shared/widgets/user_certified_badge.dart';
import '../controllers/main_layout_controller.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final MainLayoutController controller;

  const CustomAppBar({super.key, required this.controller});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    bootLog('CustomAppBar.build');
    final colorScheme = Theme.of(context).colorScheme;
    final connectivity = Get.find<ConnectivityService>();

    return SafeArea(
      child: Container(
        height: preferredSize.height,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.transparent,
        child: Row(
          children: [
            // ─── GAUCHE : Avatar + état réseau non bloquant ───
            Obx(() {
              if (controller.isLoading.value) {
                return const SkeletonShimmer(
                  width: 44,
                  height: 44,
                  borderRadius: 22,
                );
              }

              return Row(
                children: [
                  GestureDetector(
                    onTap: controller.goToProfilScreen,
                    child: Hero(
                      tag: 'user_avatar',
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.outline,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: controller.avatarUrl.isNotEmpty
                              ? AppCachedImage(
                                  imageUrl: controller.avatarUrl,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: colorScheme.surfaceContainerHigh,
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: colorScheme.onSurfaceVariant,
                                    size: 24,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            controller.displayName,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (controller.isVerified.value) ...[
                            const SizedBox(width: 4),
                            const UserCertifiedBadge(size: 16),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Obx(() {
                        final isOnline = connectivity.isConnected.value;
                        return Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isOnline
                                    ? const Color(0xFF10B981)
                                    : colorScheme.outline,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isOnline ? 'status_online'.tr : 'status_offline'.tr,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ],
              );
            }),

            const Spacer(),

            // ─── DROITE : Actions principales (Chat & Notifications en SVG) ───
            Row(
              children: [
                Obx(() => GlassmorphismButton(
                      icon: SvgPicture.asset(
                        'assets/svg_icons/chat-round-svgrepo-com.svg',
                        width: 22,
                        height: 22,
                        colorFilter: ColorFilter.mode(
                          colorScheme.onSurface,
                          BlendMode.srcIn,
                        ),
                      ),
                      badgeCount: double.tryParse(controller.messageBadge),
                      onTap: controller.openMessages,
                    )),
                const SizedBox(width: 8),
                Obx(() => GlassmorphismButton(
                      icon: SvgPicture.asset(
                        'assets/svg_icons/notification-svgrepo-com.svg',
                        width: 22,
                        height: 22,
                        colorFilter: ColorFilter.mode(
                          colorScheme.onSurface,
                          BlendMode.srcIn,
                        ),
                      ),
                      badgeCount: double.tryParse(controller.notificationBadge),
                      onTap: controller.openNotifications,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
