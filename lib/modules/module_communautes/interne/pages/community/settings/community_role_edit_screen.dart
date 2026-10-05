import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrole/app/theme/text_styles.dart';
import 'package:scrole/shared/widgets/app_cached_image.dart';
import '../../../controllers/community/settings/community_settings_controller.dart';

class CommunityRoleEditScreen extends StatefulWidget {
  const CommunityRoleEditScreen({super.key});

  @override
  State<CommunityRoleEditScreen> createState() => _CommunityRoleEditScreenState();
}

class _CommunityRoleEditScreenState extends State<CommunityRoleEditScreen> {
  late final String userId;
  late final String displayName;
  late final String currentRole;
  late final String photoUrl;
  late String selectedRole;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    userId = args['userId']?.toString() ?? '';
    displayName = args['displayName']?.toString() ?? 'Membre';
    currentRole = args['currentRole']?.toString().toLowerCase() ?? 'member';
    photoUrl = args['photoUrl']?.toString() ?? '';

    selectedRole = currentRole;
    if (selectedRole != 'admin' && selectedRole != 'moderator' && selectedRole != 'member') {
      selectedRole = 'member';
    }
  }

  Future<void> _saveRole() async {
    try {
      setState(() => isSaving = true);
      final controller = Get.find<CommunitySettingsController>();
      await controller.updateMemberRole(userId, selectedRole);
      Get.back();
      Get.snackbar('Succès', 'Rôle mis à jour avec succès.', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Erreur', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('community_edit_role_title'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // User profile card header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: photoUrl.isNotEmpty
                      ? AppCachedImage(imageUrl: photoUrl, width: 72, height: 72, fit: BoxFit.cover)
                      : Container(
                          width: 72,
                          height: 72,
                          color: colorScheme.primary.withValues(alpha: 0.15),
                          alignment: Alignment.center,
                          child: Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M',
                            style: TextStyle(color: colorScheme.primary, fontSize: 26, fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: AppTextStyles.h6.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Rôle actuel : ${currentRole.capitalizeFirst}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Sélectionnez le nouveau rôle',
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),

          // Role selection cards
          _RoleCard(
            title: 'Administrateur',
            subtitle: 'Contrôle total de la communauté, gestion des rôles, paramètres et modération avancée.',
            icon: Icons.admin_panel_settings_rounded,
            isSelected: selectedRole == 'admin',
            colorScheme: colorScheme,
            onTap: () => setState(() => selectedRole = 'admin'),
          ),
          const SizedBox(height: 12),
          _RoleCard(
            title: 'Modérateur',
            subtitle: 'Modération des publications et des membres, gestion des signalements.',
            icon: Icons.security_rounded,
            isSelected: selectedRole == 'moderator',
            colorScheme: colorScheme,
            onTap: () => setState(() => selectedRole = 'moderator'),
          ),
          const SizedBox(height: 12),
          _RoleCard(
            title: 'Membre',
            subtitle: 'Membre standard avec accès aux publications et discussions de la communauté.',
            icon: Icons.person_rounded,
            isSelected: selectedRole == 'member',
            colorScheme: colorScheme,
            onTap: () => setState(() => selectedRole = 'member'),
          ),
          const SizedBox(height: 36),

          // Save button
          ElevatedButton(
            onPressed: isSaving ? null : _saveRole,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Enregistrer les modifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? colorScheme.primary.withValues(alpha: 0.08) : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary.withValues(alpha: 0.15) : colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
