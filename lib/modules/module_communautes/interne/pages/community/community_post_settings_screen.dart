import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrole/app/theme/app_colors.dart';
import 'package:scrole/app/theme/text_styles.dart';

class CommunityPostSettingsScreen extends StatefulWidget {
  final bool initialCommentsEnabled;
  final bool initialSharingEnabled;

  const CommunityPostSettingsScreen({
    super.key,
    this.initialCommentsEnabled = true,
    this.initialSharingEnabled = true,
  });

  @override
  State<CommunityPostSettingsScreen> createState() => _CommunityPostSettingsScreenState();
}

class _CommunityPostSettingsScreenState extends State<CommunityPostSettingsScreen> {
  late bool _commentsEnabled;
  late bool _sharingEnabled;

  @override
  void initState() {
    super.initState();
    _commentsEnabled = widget.initialCommentsEnabled;
    _sharingEnabled = widget.initialSharingEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Paramètres de publication'),
        titleTextStyle: AppTextStyles.h5.copyWith(color: colorScheme.onSurface),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: () {
                Get.back(result: {
                  'commentsEnabled': _commentsEnabled,
                  'sharingEnabled': _sharingEnabled,
                });
              },
              child: Text(
                'Enregistrer',
                style: AppTextStyles.buttonSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: Text('Autoriser les commentaires', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text('Permettre aux membres de commenter cette publication.', style: AppTextStyles.bodySmall.copyWith(color: colorScheme.outline)),
              value: _commentsEnabled,
              onChanged: (val) => setState(() => _commentsEnabled = val),
              activeColor: AppColors.primary,
            ),
            const Divider(height: 24),
            SwitchListTile(
              title: Text('Autoriser le partage', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text('Permettre aux membres de partager cette publication.', style: AppTextStyles.bodySmall.copyWith(color: colorScheme.outline)),
              value: _sharingEnabled,
              onChanged: (val) => setState(() => _sharingEnabled = val),
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
