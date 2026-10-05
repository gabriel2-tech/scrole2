import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../../../../app/theme/text_styles.dart';
import '../controllers/community/community_list_controller.dart';

class CommunityEmpty extends StatelessWidget {
  final CommunityListController controller;

  const CommunityEmpty({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final lottieHeight = screenHeight * 0.42;

    return CustomScrollView(
      slivers: [
        // --- Hero Illustration ---
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: lottieHeight,
                  child: RepaintBoundary(
                    child: Lottie.asset(
                      "assets/lotties/Community services.json",
                      repeat: true,
                      animate: true,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'community_empty_title'.tr,
                  style: AppTextStyles.h3.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'community_empty_subtitle'.tr,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: controller.navigateToCreateCommunity,
                    icon: const Icon(Icons.add),
                    label: Text(
                      'community_create_button'.tr,
                      style: AppTextStyles.button,
                    ),
                  ),
                ),                SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 24,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}