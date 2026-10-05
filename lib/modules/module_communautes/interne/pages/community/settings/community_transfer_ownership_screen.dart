import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../app/theme/app_colors.dart';
import '../../../../../../app/theme/text_styles.dart';
import '../../../../../../shared/widgets/scrole_bottom_sheet.dart';
import '../../../../centre/services/community_service.dart';

class CommunityTransferOwnershipController extends GetxController {
  final CommunityService _service = Get.find<CommunityService>();
  final String communityId = Get.parameters['id'] ?? '';
  
  final members = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadMembers();
  }

  Future<void> loadMembers() async {
    isLoading.value = true;
    try {
      final res = await _service.getCommunityMembers(communityId);
      members.value = res;
    } catch (e) {
      debugPrint('[CommunityTransfer] Error loading members: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> transferOwnership(String targetUserId, String targetName) async {
    try {
      await _service.updateCommunityMemberRole(communityId, targetUserId, 'Owner');
      Get.snackbar('Succès', 'Propriété transférée à $targetName avec succès.', snackPosition: SnackPosition.BOTTOM);
      Get.back();
    } catch (e) {
      Get.snackbar('Erreur', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }
}

class CommunityTransferOwnershipScreen extends StatelessWidget {
  const CommunityTransferOwnershipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CommunityTransferOwnershipController());
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Transférer la propriété', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.members.isEmpty) {
          return Center(child: Text('Aucun membre éligible.', style: AppTextStyles.body));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.members.length,
          itemBuilder: (context, index) {
            final m = controller.members[index];
            final userName = m['username'] ?? m['user_profiles']?['username'] ?? 'Membre';
            final userId = m['user_id']?.toString() ?? '';
            final role = m['role_name'] ?? m['status'] ?? 'Membre';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : 'M'),
                ),
                title: Text(userName, style: AppTextStyles.bodyLarge),
                subtitle: Text('Rôle actuel: $role', style: AppTextStyles.bodySmall),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: colors.error),
                  onPressed: () {
                    ScroleBottomSheet.show(
                      context: context,
                      showCancel: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Transférer la communauté ?', style: AppTextStyles.h4),
                          const SizedBox(height: 8),
                          Text('Vous allez céder la propriété de cette communauté à $userName. Cette action est irréversible.', style: AppTextStyles.bodySmall),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: colors.error),
                            onPressed: () {
                              Get.back();
                              controller.transferOwnership(userId, userName);
                            },
                            child: const Text('Confirmer le transfert'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Transférer'),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
