import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:scrole/app/utils/boot_timing.dart';
import 'dart:ui';

import '../controllers/main_layout_controller.dart';
import 'boutton_expand.dart';

class CustomBottomNav extends StatelessWidget {
  final MainLayoutController controller;

  const CustomBottomNav({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    bootLog('CustomBottomNav.build');
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 12;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Barre de navigation
        Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: bottomPadding,
            top: 8,
          ),
          child: Row(
            children: [
              // Partie 1 - 4 icônes glassmorphism
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withValues(alpha: .5)
                            : Colors.white.withValues(alpha: .7),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: .1)
                              : Colors.black.withValues(alpha: .05),
                          width: 1.5,
                        ),
                      ),
                      child: Obx(
                        () => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _NavIconButton(
                              svgPath: 'assets/svg_icons/event-promotion-sale-svgrepo-com.svg',
                              label: 'Événements',
                              isSelected: controller.selectedNavIndex == 0,
                              onTap: () => controller.changeTab(0),
                            ),
                            _NavIconButton(
                              icon: Icons.explore_rounded,
                              label: 'Découvrir',
                              isSelected: controller.selectedNavIndex == 1,
                              onTap: () => controller.changeTab(1),
                            ),
                            _NavIconButton(
                              icon: Icons.groups_rounded,
                              label: 'Groupes',
                              isSelected: controller.selectedNavIndex == 2,
                              onTap: () => controller.changeTab(2),
                            ),
                            _NavIconButton(
                              icon: Icons.person_rounded,
                              label: 'Profil',
                              isSelected: false,
                              onTap: controller.goToProfilScreen,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Partie 2 - Bouton "+" expandable
              ExpandableAddMenu(
                onCommunityTap: controller.onCreateCommunity,
                onEventTap: controller.onCreateEvent,
                onActivityTap: controller.onCreateActivity,
                onPostTap: controller.onCreatePost,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavIconButton extends StatelessWidget {
  final IconData? icon;
  final String? svgPath;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavIconButton({
    this.icon,
    this.svgPath,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final iconColor = isSelected ? primaryColor : colorScheme.onSurfaceVariant;

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: .15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: svgPath != null
              ? SvgPicture.asset(
                  svgPath!,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                )
              : Icon(
                  icon,
                  color: iconColor,
                  size: 26,
                ),
        ),
      ),
    );
  }
}
