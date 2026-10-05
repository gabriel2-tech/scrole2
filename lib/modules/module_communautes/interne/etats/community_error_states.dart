import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:lottie/lottie.dart';
import '../../../../app/theme/text_styles.dart';
import '../controllers/community/community_list_controller.dart';

class CommunityError extends StatelessWidget {
  final CommunityListController controller;
  const CommunityError({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final lottieHeight = screenHeight * 0.42;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: double.infinity,
              height: lottieHeight,
              child: RepaintBoundary(
                child: Lottie.asset(
                  "assets/lotties/Internal server error.json",
                  repeat: true,
                  animate: true,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'community_error_title'.tr,
              style: AppTextStyles.h3.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'community_error_subtitle'.tr,
              style: AppTextStyles.bodyLarge.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            TextButton.icon(
              onPressed: controller.refreshData,
              icon: const Icon(Icons.refresh),
              label: Text(
                'connection_error_retry'.tr,
                style: AppTextStyles.button,
              ),
            ),
          ],
        ),
      ),
    );
  }
}