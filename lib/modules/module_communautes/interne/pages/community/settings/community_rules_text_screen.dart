import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/community/community_management_controller.dart';

class CommunityRulesTextScreen extends GetView<CommunityManagementController> {
  const CommunityRulesTextScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController ruleController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: Text('community_settings_rules'.tr)),
      body: Column(
        children: [
          Expanded(
            child: Obx(() => ListView.builder(
              itemCount: controller.rules.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(controller.rules[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => controller.removeRule(index),
                  ),
                );
              },
            )),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ruleController,
                    decoration: InputDecoration(
                      hintText: 'community_settings_rules_subtitle'.tr,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    if (ruleController.text.isNotEmpty) {
                      controller.addRule(ruleController.text);
                      ruleController.clear();
                    }
                  },
                  icon: const Icon(Icons.add_circle, color: Colors.blue, size: 40),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
