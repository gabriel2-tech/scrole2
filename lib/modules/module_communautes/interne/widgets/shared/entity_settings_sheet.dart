import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrole/shared/widgets/app_cached_image.dart';

/// Feuille façon Discord, réutilisée pour la communauté (nom + membres +
/// description) et pour un salon/groupe (nom + en ligne + description).
/// Le bouton "Paramètres" mène vers la page de paramètres complète.
class EntitySettingsSheet extends StatelessWidget {
  final String title;
  final String badgeLabel;
  final Widget avatar;
  final Color coverColor;
  final String? coverUrl;
  final String? description;
  final int? onlineCount;
  final int? memberCount;
  final bool notificationsEnabled;
  final ValueChanged<bool> onNotificationsChanged;
  final VoidCallback onMarkAsRead;
  final VoidCallback onSettingsTap;
  final VoidCallback onInvite;
  final VoidCallback onReport;
  final VoidCallback onLeave;
  final String leaveLabel;
  final bool canManage;

  const EntitySettingsSheet({
    super.key,
    required this.title,
    required this.badgeLabel,
    required this.avatar,
    required this.coverColor,
    this.coverUrl,
    this.description,
    this.onlineCount,
    this.memberCount,
    required this.notificationsEnabled,
    required this.onNotificationsChanged,
    required this.onMarkAsRead,
    required this.onSettingsTap,
    required this.onInvite,
    required this.onReport,
    required this.onLeave,
    required this.leaveLabel,
    this.canManage = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              // --- Header with Gradient Cover ---
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      height: 120,
                      child: (coverUrl != null && coverUrl!.isNotEmpty)
                          ? AppCachedImage(
                              imageUrl: coverUrl!,
                              width: double.infinity,
                              height: 120,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    coverColor,
                                    coverColor.withValues(alpha: 0.8),
                                  ],
                                ),
                              ),
                            ),
                    ),
                    Positioned(
                      top: 12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      bottom: -35,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 38,
                          backgroundColor: Colors.transparent,
                          child: avatar,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- Content ---
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 45, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      title,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // --- Badges Row ---
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badgeLabel.toUpperCase(),
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (onlineCount != null)
                          _buildStatBadge(Icons.circle, '${onlineCount!} en ligne', Colors.green),
                        if (memberCount != null)
                          _buildStatBadge(Icons.people_alt_rounded, '${memberCount!} membres', colorScheme.onSurfaceVariant),
                      ],
                    ),

                    if (description != null && description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        description!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // --- Primary Actions ---
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.settings_rounded,
                            label: 'Paramètres',
                            onTap: onSettingsTap,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.person_add_rounded,
                            label: 'Inviter',
                            onTap: onInvite,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    
                    // --- Options List ---
                    _SectionTitle('OPTIONS'),
                    const SizedBox(height: 8),
                    _SheetGroup(
                      children: [
                        _SheetRow(
                          icon: Icons.done_all_rounded,
                          title: 'Marquer comme lu',
                          onTap: onMarkAsRead,
                        ),
                        _SheetToggleRow(
                          icon: Icons.notifications_active_outlined,
                          title: 'Notifications',
                          value: notificationsEnabled,
                          onChanged: onNotificationsChanged,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    
                    // --- Danger Zone ---
                    _SectionTitle('SÉCURITÉ'),
                    const SizedBox(height: 8),
                    _SheetGroup(
                      children: [
                        _SheetRow(
                          icon: Icons.report_gmailerrorred_rounded,
                          title: 'Signaler $badgeLabel',
                          onTap: onReport,
                        ),
                        _SheetRow(
                          icon: Icons.logout_rounded,
                          title: leaveLabel,
                          onTap: onLeave,
                          titleColor: colorScheme.error,
                        ),
                      ],
                    ),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatBadge(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: color.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        color: Colors.grey,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, size: 24, color: colorScheme.onSurface),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetGroup extends StatelessWidget {
  final List<Widget> children;
  const _SheetGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) 
              Divider(height: 1, indent: 50, color: colorScheme.outline.withValues(alpha: 0.1)),
          ],
        ],
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? titleColor;

  const _SheetRow({required this.icon, required this.title, required this.onTap, this.titleColor});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: titleColor ?? colorScheme.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: titleColor ?? colorScheme.onSurface,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _SheetToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SheetToggleRow({required this.icon, required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 22, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          Switch(
            value: value, 
            onChanged: onChanged,
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
