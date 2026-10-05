import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrole/modules/module_communautes/centre/models/community_post.dart';
import 'package:scrole/modules/module_communautes/centre/services/community_outbox_processor.dart';
import 'package:scrole/modules/module_communautes/interne/controllers/community/community_feed_controller.dart';

class PollCardWidget extends StatefulWidget {
  final CommunityPoll poll;
  final String postId;
  final CommunityFeedController controller;

  const PollCardWidget({
    super.key,
    required this.poll,
    required this.postId,
    required this.controller,
  });

  @override
  State<PollCardWidget> createState() => _PollCardWidgetState();
}

class _PollCardWidgetState extends State<PollCardWidget> {
  late List<String> _selectedOptionIds;

  @override
  void initState() {
    super.initState();
    _selectedOptionIds = List.from(widget.poll.myOptionIds);
  }

  @override
  void didUpdateWidget(covariant PollCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.poll.myOptionIds != oldWidget.poll.myOptionIds) {
      _selectedOptionIds = List.from(widget.poll.myOptionIds);
    }
  }

  void _onOptionTap(PollOption option) {
    if (widget.poll.isClosed) return;
    if (widget.poll.kind == 'quiz' && widget.poll.hasVoted) return; // quiz is definitive

    setState(() {
      if (widget.poll.kind == 'single' || widget.poll.kind == 'this_or_that' || widget.poll.kind == 'quiz') {
        _selectedOptionIds = [option.id];
      } else {
        if (_selectedOptionIds.contains(option.id)) {
          _selectedOptionIds.remove(option.id);
        } else {
          _selectedOptionIds.add(option.id);
        }
      }
    });

    try {
      final outboxProcessor = Get.find<CommunityOutboxProcessor>();
      outboxProcessor.enqueuePollVoteWithCoalescing(
        postId: widget.postId,
        optionIds: _selectedOptionIds,
      );
    } catch (e) {
      debugPrint('[PollCardWidget] Outbox error: $e');
      widget.controller.votePoll(widget.postId, _selectedOptionIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final poll = widget.poll;
    final showResults = poll.resultsVisible || poll.hasVoted || poll.isClosed;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.poll_rounded, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    poll.kind == 'quiz' ? 'Quiz' : 'Sondage',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.primary),
                  ),
                ],
              ),
              Text(
                '${poll.votersCount} votant${poll.votersCount > 1 ? 's' : ''} • ${poll.isClosed ? 'Terminé' : 'En cours'}',
                style: TextStyle(fontSize: 11.5, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...poll.options.map((option) {
            final isSelected = _selectedOptionIds.contains(option.id);
            final isCorrectQuiz = poll.kind == 'quiz' && poll.hasVoted && option.isCorrect == true;
            final isWrongQuiz = poll.kind == 'quiz' && poll.hasVoted && isSelected && option.isCorrect == false;

            Color borderColor = colorScheme.outlineVariant.withValues(alpha: 0.5);
            Color bgColor = Colors.transparent;

            if (isSelected) {
              borderColor = colorScheme.primary;
              bgColor = colorScheme.primary.withValues(alpha: 0.08);
            }
            if (isCorrectQuiz) {
              borderColor = Colors.green;
              bgColor = Colors.green.withValues(alpha: 0.1);
            } else if (isWrongQuiz) {
              borderColor = Colors.red;
              bgColor = Colors.red.withValues(alpha: 0.1);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => _onOptionTap(option),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
                  ),
                  child: Row(
                    children: [
                      if (poll.kind == 'multiple')
                        Checkbox(
                          value: isSelected,
                          onChanged: poll.isClosed ? null : (_) => _onOptionTap(option),
                          visualDensity: VisualDensity.compact,
                        )
                      else
                        Radio<bool>(
                          value: true,
                          groupValue: isSelected ? true : null,
                          onChanged: poll.isClosed || (poll.kind == 'quiz' && poll.hasVoted) ? null : (_) => _onOptionTap(option),
                          visualDensity: VisualDensity.compact,
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          option.label,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (showResults) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${option.percent.toStringAsFixed(0)}% (${option.votes})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isCorrectQuiz ? Colors.green : (isWrongQuiz ? Colors.red : colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
          if (poll.kind == 'quiz' && poll.hasVoted && poll.explanation != null && poll.explanation!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '💡 Explication : ${poll.explanation}',
                style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
