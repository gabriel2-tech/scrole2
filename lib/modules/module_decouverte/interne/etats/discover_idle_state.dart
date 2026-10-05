import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/text_styles.dart';

/// État "idle" : affiché quand l'utilisateur n'a encore rien tapé.
/// Un emoji et un texte d'invite sont placés dans la partie basse de
/// l'écran, sous la barre de recherche.
class DiscoverIdleState extends StatelessWidget {
  const DiscoverIdleState({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(flex: 3),
        Text(
          '🔎',
          style: const TextStyle(fontSize: 56),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Alors, on cherche quoi aujourd\'hui ?',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondaryDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Spacer(flex: 5),
      ],
    );
  }
}
