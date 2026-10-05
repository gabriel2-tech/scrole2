import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/text_styles.dart';


class DiscoverSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool showClearButton;

  const DiscoverSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.showClearButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.black1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2D34)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(Icons.search_rounded, color: AppColors.textSecondaryDark, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              autofocus: false,
              style: AppTextStyles.input.copyWith(color: AppColors.white),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: 'Rechercher des comptes, événements, communautés…',
                hintStyle: AppTextStyles.inputHint
                    .copyWith(color: AppColors.textSecondaryDark),
              ),
            ),
          ),
          if (showClearButton)
            GestureDetector(
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.close_rounded,
                    color: AppColors.textSecondaryDark, size: 20),
              ),
            )
          else
            const SizedBox(width: 14),
        ],
      ),
    );
  }
}
