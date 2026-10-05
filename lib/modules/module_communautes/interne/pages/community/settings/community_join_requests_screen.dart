import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrole/shared/widgets/app_cached_image.dart';
import 'package:scrole/shared/widgets/user_certified_badge.dart';
import '../../../controllers/community/settings/community_join_requests_controller.dart';

class CommunityJoinRequestsScreenBody extends GetView<CommunityJoinRequestsController> {
  const CommunityJoinRequestsScreenBody({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.requests.isEmpty) {
        return Center(
          child: Text(
            'Aucune demande d\'adhésion',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 15),
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: controller.requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final req = controller.requests[index];

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: req.photoUrl != null && req.photoUrl!.isNotEmpty
                      ? AppCachedImage(imageUrl: req.photoUrl!, width: 48, height: 48, fit: BoxFit.cover)
                      : Container(
                          width: 48,
                          height: 48,
                          color: colorScheme.primary.withValues(alpha: 0.15),
                          alignment: Alignment.center,
                          child: Text(
                            req.displayName.isNotEmpty ? req.displayName[0].toUpperCase() : 'U',
                            style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            req.displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          if (req.isVerified) ...[
                            const SizedBox(width: 4),
                            const UserCertifiedBadge(size: 14),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${req.username}',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => controller.respondRequest(req.id, false),
                  icon: const Icon(Icons.close_rounded, color: Colors.red),
                  tooltip: 'Refuser',
                ),
                IconButton(
                  onPressed: () => controller.respondRequest(req.id, true),
                  icon: const Icon(Icons.check_rounded, color: Colors.green),
                  tooltip: 'Accepter',
                ),
              ],
            ),
          );
        },
      );
    });
  }
}

class CommunityJoinRequestsScreen extends StatelessWidget {
  const CommunityJoinRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demandes d\'adhésion'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: const CommunityJoinRequestsScreenBody(),
    );
  }
}
