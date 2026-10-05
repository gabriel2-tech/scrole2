import 'package:flutter/material.dart';
import '../../../../../app/theme/text_styles.dart';
import '../../../../../shared/widgets/app_cached_image.dart';
import '../../../centre/models/communities_model.dart';

class CommunityGridCard extends StatelessWidget {
  final CommunityModel community;
  final VoidCallback? onTap;

  const CommunityGridCard({
    super.key,
    required this.community,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ─── Image de couverture ───
              AppCachedImage(
                imageUrl: community.coverImage,
                fit: BoxFit.cover,
              ),

              // ─── Dégradé sombre en bas ───
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),

              // ─── Avatar en haut à gauche ───
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                  ),
                  child: AppCachedImage(
                    imageUrl: community.avatarImage,
                    width: 32,
                    height: 32,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              // ─── Badge notification ───
              if (community.unreadCount > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      community.unreadCount > 99
                          ? '99+'
                          : '${community.unreadCount}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

              // ─── Nom en bas ───
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    community.name,
                    style: AppTextStyles.h6.copyWith(
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),            ],
          ),
        ),
      ),
    );
  }
}