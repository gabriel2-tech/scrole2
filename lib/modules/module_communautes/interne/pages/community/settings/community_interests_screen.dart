import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scrole/app/repository_global/centre_interets_repository.dart';
import 'package:scrole/app/theme/text_styles.dart';
import 'package:scrole/shared/models/interest_model.dart';
import 'package:scrole/modules/module_profil/interne/pages/interest_selection_screen.dart';
import 'package:scrole/modules/module_communautes/centre/services/community_service.dart';

class CommunityInterestsScreen extends StatefulWidget {
  const CommunityInterestsScreen({super.key});

  @override
  State<CommunityInterestsScreen> createState() => _CommunityInterestsScreenState();
}

class _CommunityInterestsScreenState extends State<CommunityInterestsScreen> {
  late final String communityId;
  List<Interest> _allInterests = [];
  List<Interest> _selectedInterests = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    communityId = Get.arguments?.toString() ?? Get.parameters['id'] ?? '';
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final interestRepo = InterestRepository(Supabase.instance.client);
      final communityService = Get.find<CommunityService>();

      final all = await interestRepo.getInterests();
      final selected = await communityService.getCommunityInterests(communityId);

      if (mounted) {
        setState(() {
          _allInterests = all;
          _selectedInterests = selected;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[CommunityInterestsScreen] error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openInterestSelection() async {
    final selectedIds = _selectedInterests.map((e) => e.id).toList();

    final result = await Get.to<List<String>>(
      () => InterestSelectionScreen(),
      arguments: {
        'allInterests': _allInterests,
        'selectedIds': selectedIds,
        'maxSelection': 0,
      },
    );

    if (result != null) {
      _saveInterests(result);
    }
  }

  Future<void> _saveInterests(List<String> newSelectedIds) async {
    setState(() => _isSaving = true);
    try {
      final service = Get.find<CommunityService>();
      await service.updateCommunityInterests(communityId: communityId, interestIds: newSelectedIds);

      final updatedSelected = _allInterests.where((i) => newSelectedIds.contains(i.id)).toList();

      if (mounted) {
        setState(() {
          _selectedInterests = updatedSelected;
          _isSaving = false;
        });
      }
      Get.snackbar('Succès', 'Centres d\'intérêt mis à jour.', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Erreur', e.toString(), snackPosition: SnackPosition.BOTTOM);
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Centres d\'intérêt', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _openInterestSelection,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Ajouter des CI', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedInterests.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.interests_outlined, size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun centre d\'intérêt associé à cette communauté.',
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 15),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : _openInterestSelection,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Ajouter des CI'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Centres d\'intérêt actuels (${_selectedInterests.length})',
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedInterests.map((interest) {
                        return Chip(
                          avatar: interest.iconUrl != null && interest.iconUrl!.isNotEmpty
                              ? CircleAvatar(backgroundImage: NetworkImage(interest.iconUrl!))
                              : null,
                          label: Text(interest.name),
                          backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.6),
                          labelStyle: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.w600),
                        );
                      }).toList(),
                    ),
                  ],
                ),
    );
  }
}
