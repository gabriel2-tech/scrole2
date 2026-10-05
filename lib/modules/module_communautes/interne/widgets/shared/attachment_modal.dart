import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AttachmentModal extends StatelessWidget {
  final Function(String question, List<String> options)? onPollCreated;
  final VoidCallback? onMediaTap;

  const AttachmentModal({super.key, this.onPollCreated, this.onMediaTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(color: colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, -5))]),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)))),
        Text('Ajouter au message', style: textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        const SizedBox(height: 16),
        _AttachmentTile(icon: Icons.perm_media_outlined, title: 'Média ou fichier', subtitle: 'Photo, vidéo, PDF, document, archive…', onTap: () { Get.back(); onMediaTap?.call(); }),
      ]),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _AttachmentTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16), border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1))), child: Row(children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: colorScheme.primary, size: 24)),
      const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), const SizedBox(height: 2), Text(subtitle, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12))])),
      Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
    ])));
  }
}
