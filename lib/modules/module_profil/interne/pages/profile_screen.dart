import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:image_picker/image_picker.dart';
import 'package:scrole/app/routes/app_pages.dart';
import 'package:scrole/app/theme/app_colors.dart';
import 'package:scrole/app/theme/text_styles.dart';
import 'package:scrole/shared/widgets/app_cached_image.dart';
import 'package:scrole/shared/widgets/image_source_sheet.dart';
import 'package:scrole/shared/widgets/user_certified_badge.dart';
import 'package:scrole/modules/module_profil/interne/controllers/profile_controller.dart';
import 'package:scrole/modules/module_profil/interne/widgets/circle_button_widget.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: controller.refreshProfile,
              color: colorScheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, colorScheme),
                    const SizedBox(height: 10),
                    _buildNameAndUsername(colorScheme),
                    const SizedBox(height: 12),
                    _buildBio(colorScheme),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            
            // Chargement plein écran discret
            Obx(() => controller.isLoading.value
                ? Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: Center(
                      child: CircularProgressIndicator(color: colorScheme.primary),
                    ),
                  )
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  // ============================================
  // HEADER
  // ============================================
  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return SizedBox(
      height: 185, // 140 (cover) + 45 (avatar overlap)
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            height: 140,
            width: double.infinity,
            child: Obx(() {
              final coverUrl = controller.coverImageUrl.value;
              if (coverUrl.isEmpty) {
                return Container(color: AppColors.secondary.withValues(alpha: 0.25));
              }
              return Stack(
                fit: StackFit.expand,
                children: [
                  AppCachedImage(
                    imageUrl: coverUrl,
                    fit: BoxFit.cover,
                    errorWidget: Container(color: AppColors.secondary.withValues(alpha: 0.25)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.black.withValues(alpha: 0.05),
                          colorScheme.surface.withValues(alpha: 0.55),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),

          Positioned(
            bottom: 8,
            right: 12,
            child: GestureDetector(
              onTap: () => showImageSourceSheet(
                context,
                onCamera: () => controller.pickCoverImage(ImageSource.camera),
                onGallery: () => controller.pickCoverImage(ImageSource.gallery),
              ),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: Obx(
                  () => controller.isUploadingCover.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                ),
              ),
            ),
          ),

          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleButtonWidget(
                  icon: Icons.arrow_back_ios_rounded,
                  onTap: () => Get.back(),
                ),
                Row(
                  children: [
                    CircleButtonWidget(
                      icon: Icons.people_outline_rounded,
                      onTap: () => Get.toNamed(AppPages.myContacts),
                    ),
                    const SizedBox(width: 8),
                    CircleButtonWidget(
                      icon: Icons.mail_outline_rounded,
                      onTap: () => Get.toNamed(AppPages.eventInvitations),
                    ),
                    const SizedBox(width: 8),
                    CircleButtonWidget(
                      icon: Icons.calendar_today_outlined,
                      onTap: () => Get.toNamed(AppPages.userAgenda),
                    ),
                    const SizedBox(width: 8),
                    CircleButtonWidget(
                      icon: Icons.qr_code_rounded,
                      onTap: () => Get.toNamed(AppPages.userQrCode),
                    ),
                    const SizedBox(width: 8),
                    CircleButtonWidget(
                      icon: Icons.settings_rounded,
                      onTap: () => Get.toNamed(AppPages.setting),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 0,
            left: 20,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Obx(() {
                  final avatarUrl = controller.profileImageUrl.value;
                  return Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.surface, width: 5),
                      color: colorScheme.primary,
                    ),
                    child: avatarUrl.isEmpty
                        ? Center(
                            child: Text(
                              controller.initials,
                              style: AppTextStyles.h3.copyWith(color: Colors.white),
                            ),
                          )
                        : AppCachedImage(
                            imageUrl: avatarUrl,
                            width: 90,
                            height: 90,
                            borderRadius: BorderRadius.circular(45),
                            fit: BoxFit.cover,
                          ),
                  );
                }),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () => showImageSourceSheet(
                      context,
                      onCamera: () => controller.pickProfileImage(ImageSource.camera),
                      onGallery: () => controller.pickProfileImage(ImageSource.gallery),
                    ),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary,
                        border: Border.all(color: colorScheme.surface, width: 3),
                      ),
                      child: Obx(
                        () => controller.isUploadingProfileImage.value
                            ? const Padding(
                                padding: EdgeInsets.all(5),
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // NAME & USERNAME + bouton d'édition
  // ============================================
  Widget _buildNameAndUsername(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Obx(
                        () => Text(
                          controller.displayName,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.h4.copyWith(color: colorScheme.onSurface),
                        ),
                      ),
                    ),
                    Obx(() {
                      if (!controller.isVerified.value) return const SizedBox.shrink();
                      return const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: UserCertifiedBadge(size: 20),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 4),
                Obx(
                  () => Text(
                    '@${controller.username.value}',
                    style: AppTextStyles.body.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () => Get.toNamed(AppPages.editmyprofil),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: Text('profile_edit_button'.tr, style: AppTextStyles.buttonSmall),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // BIO
  // ============================================
  Widget _buildBio(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Obx(
        () => Text(
          controller.displayBio,
          style: AppTextStyles.body.copyWith(
            color: controller.bio.value.isEmpty
                ? colorScheme.onSurfaceVariant
                : colorScheme.onSurface.withValues(alpha: 0.85),
            fontStyle: controller.bio.value.isEmpty ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    );
  }
}
