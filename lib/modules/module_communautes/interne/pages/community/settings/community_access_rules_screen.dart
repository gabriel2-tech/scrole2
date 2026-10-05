import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/community/settings/community_settings_controller.dart';

class CommunityAccessRulesScreen extends GetView<CommunitySettingsController> {
  const CommunityAccessRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('community_access_rules_title'.tr),
        actions: [
          TextButton(
            onPressed: controller.saveRules,
            child: Text('edit_profile_save'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Définissez qui peut rejoindre votre communauté. Les membres doivent respecter tous les critères activés.',
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // --- Section Âge ---
            _FilterSection(
              title: 'Restriction d\'âge',
              icon: Icons.cake_outlined,
              isActive: controller.filterAge.value,
              onToggle: controller.toggleAgeFilter,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _AgePicker(
                          label: 'Min',
                          value: controller.minAge.value,
                          onChanged: (v) => controller.minAge.value = v,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _AgePicker(
                          label: 'Max',
                          value: controller.maxAge.value,
                          onChanged: (v) => controller.maxAge.value = v,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- Section Genre ---
            _FilterSection(
              title: 'Restriction de genre',
              icon: Icons.wc_outlined,
              isActive: controller.filterGender.value,
              onToggle: controller.toggleGenderFilter,
              child: Wrap(
                spacing: 8,
                children: [
                  _GenderChip(
                    label: 'Homme',
                    isSelected: controller.allowedGenders.contains('male'),
                    onTap: () => controller.toggleGender('male'),
                  ),
                  _GenderChip(
                    label: 'Femme',
                    isSelected: controller.allowedGenders.contains('female'),
                    onTap: () => controller.toggleGender('female'),
                  ),
                  _GenderChip(
                    label: 'Autre',
                    isSelected: controller.allowedGenders.contains('other'),
                    onTap: () => controller.toggleGender('other'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- Section Pays ---
            _FilterSection(
              title: 'Restriction géographique',
              icon: Icons.public_outlined,
              isActive: controller.filterCountry.value,
              onToggle: controller.toggleCountryFilter,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Ouvrir sélecteur de pays multiple
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter des pays'),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isActive;
  final ValueChanged<bool> onToggle;
  final Widget child;

  const _FilterSection({
    required this.title,
    required this.icon,
    required this.isActive,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? colorScheme.primary.withValues(alpha: 0.5) : colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(icon, color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Switch(
              value: isActive,
              onChanged: onToggle,
              activeColor: colorScheme.primary,
            ),
          ),
          if (isActive)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
        ],
      ),
    );
  }
}

class _AgePicker extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _AgePicker({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        DropdownButtonFormField<int>(
          value: value,
          items: List.generate(82, (i) => i + 18)
              .map((age) => DropdownMenuItem(value: age, child: Text('$age ans')))
              .toList(),
          onChanged: (v) => onChanged(v!),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.primary : colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
