import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/text_styles.dart';
import '../../../../../shared/widgets/cover_avatar_picker.dart';
import '../../../../../shared/widgets/selectable_filel.dart';
import '../../../../../shared/widgets/text_input_field.dart';
import '../../controllers/community/community_creation_controller.dart';

class CommunityCreationScreen extends GetView<CommunityCreationController> {
  const CommunityCreationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('create_community_title'.tr),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Obx(() {
                final loading = controller.isLoading;
                return TextButton(
                  onPressed: loading ? null : controller.createCommunity,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    disabledForegroundColor: AppColors.primary.withValues(alpha: .4),
                  ),
                  child: loading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary.withValues(alpha: .6),
                          ),
                        )
                      : Text(
                          'community_create_action'.tr,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                );
              }),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => CoverAvatarPicker(
                      bannerImage: controller.bannerImage.value,
                      avatarImage: controller.avatarImage.value,
                      onBannerCamera: () => controller.pickBanner(ImageSource.camera),
                      onBannerGallery: () => controller.pickBanner(ImageSource.gallery),
                      onBannerRemove: controller.removeBanner,
                      onAvatarCamera: () => controller.pickAvatar(ImageSource.camera),
                      onAvatarGallery: () => controller.pickAvatar(ImageSource.gallery),
                      onAvatarRemove: controller.removeAvatar,
                    )),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'community_photos_optional_hint'.tr,
                    style: AppTextStyles.caption.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 16),
                TextInputField(
                  controller: controller.nameController,
                  imputTitle: 'community_name_label'.tr,
                  impuHintText: 'community_name_hint'.tr,
                  imputIcon: const Icon(Icons.groups_outlined),
                  func: controller.validateName,
                ),
                const SizedBox(height: 16),
                TextInputField(
                  controller: controller.slugController,
                  imputTitle: 'community_slug_label'.tr,
                  impuHintText: 'community_slug_hint'.tr,
                  imputIcon: const Icon(Icons.link),
                  func: controller.validateSlug,
                ),
                const SizedBox(height: 16),
                TextInputField(
                  controller: controller.descriptionController,
                  imputTitle: 'community_description_label'.tr,
                  impuHintText: 'community_description_hint'.tr,
                  imputIcon: const Icon(Icons.description_outlined),
                  func: controller.validateDescription,
                ),
                const SizedBox(height: 16),
                Obx(() {
                  final options = [
                    SheetOption(
                      value: 'public',
                      label: 'community_visibility_public'.tr,
                      icon: Icons.public,
                      subtitle: 'community_visibility_public_hint'.tr,
                    ),
                    SheetOption(
                      value: 'private',
                      label: 'community_visibility_private'.tr,
                      icon: Icons.lock_outline,
                      subtitle: 'community_visibility_private_hint'.tr,
                    ),
                  ];
                  final selected = options.firstWhere(
                    (o) => o.value == controller.visibility.value,
                  );
                  return SelectableField<String>(
                    label: 'community_visibility_label'.tr,
                    selected: selected,
                    options: options,
                    onChanged: (v) => controller.visibility.value = v,
                  );
                }),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: Obx(() {
                    final loading = controller.isLoading;
                    return ElevatedButton(
                      onPressed: loading ? null : controller.createCommunity,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'community_create_action'.tr,
                              style: AppTextStyles.button,
                            ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
