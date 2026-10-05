import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/text_styles.dart';


class DiscoverLoadingState extends StatelessWidget {
  const DiscoverLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Recherche en cours…',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondaryDark),
        ),
      ],
    );
  }
}
