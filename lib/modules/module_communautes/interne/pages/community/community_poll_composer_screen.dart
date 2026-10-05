import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrole/app/theme/app_colors.dart';
import 'package:scrole/app/theme/text_styles.dart';

class CommunityPollComposerScreen extends StatefulWidget {
  const CommunityPollComposerScreen({super.key});

  @override
  State<CommunityPollComposerScreen> createState() => _CommunityPollComposerScreenState();
}

class _CommunityPollComposerScreenState extends State<CommunityPollComposerScreen> {
  String _kind = 'single'; // single, multiple, quiz, this_or_that
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  int _correctQuizIndex = 0; // for quiz
  int _durationHours = 24;
  final TextEditingController _explanationController = TextEditingController();

  @override
  void dispose() {
    for (final c in _optionControllers) {
      c.dispose();
    }
    _explanationController.dispose();
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length < 6 && _kind != 'this_or_that') {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
        if (_correctQuizIndex >= _optionControllers.length) {
          _correctQuizIndex = _optionControllers.length - 1;
        }
      });
    }
  }

  void _onKindChanged(String? newKind) {
    if (newKind == null) return;
    setState(() {
      _kind = newKind;
      if (_kind == 'this_or_that') {
        while (_optionControllers.length > 2) {
          _optionControllers.removeLast().dispose();
        }
        while (_optionControllers.length < 2) {
          _optionControllers.add(TextEditingController());
        }
      }
    });
  }

  void _submit() {
    final texts = _optionControllers.map((c) => c.text.trim()).toList();
    if (texts.any((t) => t.isEmpty || t.length > 80)) {
      Get.snackbar('Erreur', 'Chaque option doit contenir entre 1 et 80 caractères.');
      return;
    }
    if (texts.toSet().length != texts.length) {
      Get.snackbar('Erreur', 'Toutes les options doivent être différentes.');
      return;
    }

    dynamic formattedOptions;
    if (_kind == 'quiz') {
      formattedOptions = texts.asMap().entries.map((e) => {
        'label': e.value,
        'is_correct': e.key == _correctQuizIndex,
      }).toList();
    } else {
      formattedOptions = texts.map((t) => {'label': t}).toList();
    }

    final pollMap = <String, dynamic>{
      'kind': _kind,
      'options': formattedOptions,
      'duration_hours': _durationHours,
      if (_kind == 'quiz' && _explanationController.text.trim().isNotEmpty)
        'explanation': _explanationController.text.trim(),
    };

    Get.back(result: pollMap);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Créer un sondage'),
        titleTextStyle: AppTextStyles.h5.copyWith(color: colorScheme.onSurface),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.close_rounded, size: 28),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _submit,
              child: const Text(
                'Terminer',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _kind,
                decoration: InputDecoration(
                  labelText: 'Type de sondage',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(value: 'single', child: Text('Choix unique')),
                  DropdownMenuItem(value: 'multiple', child: Text('Choix multiple')),
                  DropdownMenuItem(value: 'quiz', child: Text('Quiz (avec bonne réponse)')),
                  DropdownMenuItem(value: 'this_or_that', child: Text('Ce ou Ça (2 choix)')),
                ],
                onChanged: _onKindChanged,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Options (${_optionControllers.length}/6)', style: AppTextStyles.h6.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              ..._optionControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;
                final isCorrect = _kind == 'quiz' && _correctQuizIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCorrect ? Colors.green.withValues(alpha: 0.1) : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCorrect ? Colors.green : colorScheme.outlineVariant.withValues(alpha: 0.5),
                        width: isCorrect ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (_kind == 'quiz')
                          IconButton(
                            onPressed: () => setState(() => _correctQuizIndex = index),
                            icon: Icon(
                              isCorrect ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              color: isCorrect ? Colors.green : colorScheme.outline,
                              size: 24,
                            ),
                            tooltip: isCorrect ? 'Bonne réponse' : 'Marquer comme bonne réponse',
                          ),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            maxLength: 80,
                            decoration: InputDecoration(
                              hintText: 'Option ${index + 1}',
                              counterText: '',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                        if (_kind != 'this_or_that' && _optionControllers.length > 2)
                          IconButton(
                            onPressed: () => _removeOption(index),
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          ),
                      ],
                    ),
                  ),
                );
              }),
              if (_kind != 'this_or_that' && _optionControllers.length < 6)
                TextButton.icon(
                  onPressed: _addOption,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Ajouter une option'),
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _durationHours,
                decoration: InputDecoration(
                  labelText: 'Durée du sondage',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 heure')),
                  DropdownMenuItem(value: 6, child: Text('6 heures')),
                  DropdownMenuItem(value: 24, child: Text('24 heures (1 jour)')),
                  DropdownMenuItem(value: 48, child: Text('48 heures (2 jours)')),
                  DropdownMenuItem(value: 168, child: Text('168 heures (7 jours)')),
                ],
                onChanged: (val) => setState(() => _durationHours = val ?? 24),
              ),
              if (_kind == 'quiz') ...[
                const SizedBox(height: 20),
                TextField(
                  controller: _explanationController,
                  maxLength: 280,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Explication (facultative)',
                    hintText: 'Expliquez pourquoi c\'est la bonne réponse...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _submit,
                  child: const Text('Créer le sondage', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
