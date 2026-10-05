import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrole/app/routes/app_pages.dart';
import 'package:scrole/shared/widgets/scrole_bottom_sheet.dart';
import '../controllers/main_layout_controller.dart';

class ExpandableAddMenu extends StatelessWidget {
  final VoidCallback onCommunityTap;
  final VoidCallback onEventTap;
  final VoidCallback onActivityTap;
  final VoidCallback onPostTap;

  const ExpandableAddMenu({
    super.key,
    required this.onCommunityTap,
    required this.onEventTap,
    required this.onActivityTap,
    required this.onPostTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: GestureDetector(
        onTap: () => _showActionBottomSheet(context),
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF6B9D), Color(0xFF8B5CF6)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(0.4),
                blurRadius: 14,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  void _showActionBottomSheet(BuildContext context) {
    ScroleBottomSheet.show<void>(
      context: context,
      showCancel: true,
      child: ScroleBottomSheetGroup(
        children: [
          ScroleBottomSheetAction(
            icon: Icons.group_add_rounded,
            label: 'Communauté',
            subtitle: 'Crée une nouvelle communauté',
            onTap: () {
              Navigator.of(context).pop();
              Get.find<MainLayoutController>().onCreateCommunity();
            },
          ),
          const ScroleBottomSheetDivider(),
          ScroleBottomSheetAction(
            icon: Icons.event_rounded,
            label: 'Événement',
            subtitle: 'Organise un événement',
            onTap: () {
              Navigator.of(context).pop();
              Get.find<MainLayoutController>().onCreateEvent();
            },
          ),
          const ScroleBottomSheetDivider(),
          ScroleBottomSheetAction(
            icon: Icons.assignment_outlined,
            label: 'Activité',
            subtitle: 'Proposer une activité à la communauté',
            onTap: () {
              Navigator.of(context).pop();
              Get.toNamed(AppPages.createactivite);
            },
          ),
        ],
      ),
    );
  }
}
