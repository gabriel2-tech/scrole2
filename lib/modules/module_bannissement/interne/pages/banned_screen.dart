import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class BannedScreen extends StatelessWidget {
  final String? reason;
  final DateTime? bannedUntil;
  final String? userId;

  const BannedScreen({
    super.key,
    this.reason,
    this.bannedUntil,
    this.userId,
  });

  static const String supportEmail = 'support@scrole.fun';
  static const String helpCenterUrl = 'https://infos.scrole.fun';
  static const String discordUrl = 'https://discord.gg/lumis';
  static const String appealFormUrl = 'https://lumis-app.com/contester-ban';

  bool get isPermanent => bannedUntil == null;

  String get _formattedDate {
    if (bannedUntil == null) return '';
    final d = bannedUntil!;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} à ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar(
        'Erreur',
        'Impossible d\'ouvrir le lien',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _openSupportEmail() async {
    final subject = Uri.encodeComponent('Contestation de bannissement — Compte $userId');
    final body = Uri.encodeComponent(
      'Bonjour,\n\nJe souhaite contester le bannissement de mon compte.\n\n'
          'Identifiant : ${userId ?? "N/A"}\n'
          'Motif indiqué : ${reason ?? "Non précisé"}\n\n'
          'Explication : \n',
    );
    await _openUrl('mailto:$supportEmail?subject=$subject&body=$body');
  }

  void _copyUserId(BuildContext context) {
    if (userId == null) return;
    Clipboard.setData(ClipboardData(text: userId!));
    Get.snackbar(
      'Copié',
      'Identifiant copié dans le presse-papier',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icône
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.block_rounded,
                        color: Colors.redAccent,
                        size: 44,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Titre
                  Text(
                    'Compte suspendu',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Message principal
                  Text(
                    isPermanent
                        ? 'Votre compte a été banni définitivement de Scrole pour non-respect des règles de la communauté.'
                        : 'Votre compte a été temporairement suspendu de Scrole.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Détails du ban
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (reason != null && reason!.isNotEmpty) ...[
                          _DetailRow(
                            icon: Icons.info_outline_rounded,
                            label: 'Motif',
                            value: reason!,
                          ),
                          const SizedBox(height: 10),
                        ],
                        _DetailRow(
                          icon: Icons.timer_outlined,
                          label: 'Durée',
                          value: isPermanent ? 'Permanent' : 'Jusqu\'au $_formattedDate',
                        ),
                        if (userId != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _DetailRow(
                                  icon: Icons.badge_outlined,
                                  label: 'Identifiant',
                                  value: userId!,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 18),
                                tooltip: 'Copier l\'identifiant',
                                onPressed: () => _copyUserId(context),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  Text(
                    'Vous pensez qu\'il s\'agit d\'une erreur ?',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Boutons de contact
                  _ContactButton(
                    icon: Icons.gavel_rounded,
                    label: 'Contester ce bannissement',
                    onTap: () => _openUrl(appealFormUrl),
                    primary: true,
                  ),
                  const SizedBox(height: 10),
                  _ContactButton(
                    icon: Icons.mail_outline_rounded,
                    label: 'Contacter le support par e-mail',
                    onTap: _openSupportEmail,
                  ),
                  const SizedBox(height: 10),
                  _ContactButton(
                    icon: Icons.help_outline_rounded,
                    label: 'Centre d\'aide',
                    onTap: () => _openUrl(helpCenterUrl),
                  ),
                  const SizedBox(height: 10),
                  _ContactButton(
                    icon: Icons.forum_outlined,
                    label: 'Rejoindre le Discord communautaire',
                    onTap: () => _openUrl(discordUrl),
                  ),
                  const SizedBox(height: 28),

                  // Déconnexion
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        // Adapter à votre AuthMiddleware / AuthController
                        Get.offAllNamed('/login');
                      },
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Se déconnecter'),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (primary) {
      return SizedBox(
        height: 48,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 20),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}