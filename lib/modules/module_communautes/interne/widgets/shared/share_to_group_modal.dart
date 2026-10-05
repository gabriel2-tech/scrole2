import 'package:flutter/material.dart';
import '../../../centre/models/community_post.dart';
import '../../../centre/models/community_room.dart';
import 'entity_avatar.dart';

class ShareToGroupModal extends StatefulWidget {
  final CommunityPost post;
  final List<CommunityGroup> groups;
  final void Function(CommunityGroup group, String? message) onGroupSelected;

  const ShareToGroupModal({
    super.key,
    required this.post,
    required this.groups,
    required this.onGroupSelected,
  });

  @override
  State<ShareToGroupModal> createState() => _ShareToGroupModalState();
}

class _ShareToGroupModalState extends State<ShareToGroupModal> {
  CommunityGroup? _selected;
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'En discuter dans...',
                style: textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Choisis un groupe pour partager cette publication',
                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              if (widget.groups.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.groups_3_outlined, size: 48, color: colorScheme.outline),
                      const SizedBox(height: 12),
                      Text(
                        'Tu ne fais partie d\'aucun groupe',
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                Container(
                  constraints: const BoxConstraints(maxHeight: 250),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: widget.groups.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final group = widget.groups[index];
                      final isSelected = _selected?.id == group.id;

                      return Material(
                        color: isSelected ? colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(() => _selected = group),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            child: Row(
                              children: [
                                EntityAvatar(initials: group.initials, color: group.color, size: 40),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    group.name,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (_selected != null) ...[
                const SizedBox(height: 24),
                TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Ajouter un message (optionnel)',
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: () => widget.onGroupSelected(_selected!, _messageController.text),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Partager maintenant', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
