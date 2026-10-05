import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrole/app/utils/boot_timing.dart';
import '../../../module_communautes/interne/pages/community/community_list_screen.dart';
import '../../../module_decouverte/interne/pages/discover_screen.dart';
import '../../../module_evenement/interne/pages/event_screen.dart';
import '../controllers/main_layout_controller.dart';
import '../widgets/buton_nav.dart';
import '../widgets/main_app_bar.dart';

class MainLayoutPage extends GetView<MainLayoutController> {
  const MainLayoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    bootLog('MainNavigationScreen.build');
    if (!Get.isRegistered<MainLayoutController>()) {
      Get.put(MainLayoutController());
    }

    final controller = Get.find<MainLayoutController>();

    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(controller: controller),
      body: Obx(() {
        return LazyIndexedStack(
          index: controller.currentTab.value,
          children: const [
            EventScreen(),
            SearchScreen(),
            CommunityListScreen(),
          ],
        );
      }),
      bottomNavigationBar: CustomBottomNav(controller: controller),
    );
  }
}

/// IndexedStack paresseux qui ne construit la page d'un onglet qu'à sa première visite.
class LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late final List<bool> _activated;

  @override
  void initState() {
    super.initState();
    bootLog('LazyIndexedStack.initState');
    _activated = List<bool>.generate(
      widget.children.length,
      (i) => i == widget.index,
    );
  }

  @override
  void didUpdateWidget(LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index >= 0 && widget.index < _activated.length) {
      if (!_activated[widget.index]) {
        _activated[widget.index] = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bootLog('LazyIndexedStack.build');
    return IndexedStack(
      index: widget.index,
      children: List<Widget>.generate(widget.children.length, (i) {
        if (_activated[i]) {
          return widget.children[i];
        }
        return const SizedBox.shrink();
      }),
    );
  }
}
