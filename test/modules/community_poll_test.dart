import 'package:flutter_test/flutter_test.dart';
import 'package:scrole/modules/module_communautes/centre/models/community_post.dart';

void main() {
  group('Community Poll & PollDraft Tests', () {
    test('Poll creation from JSON parses correctly', () {
      final json = {
        'kind': 'single',
        'ends_at': '2026-10-05T00:00:00Z',
        'is_closed': false,
        'voters_count': 10,
        'has_voted': true,
        'my_option_ids': ['opt1'],
        'results_visible': true,
        'options': [
          {'id': 'opt1', 'label': 'Option A', 'votes': 6, 'percent': 60.0, 'is_mine': true},
          {'id': 'opt2', 'label': 'Option B', 'votes': 4, 'percent': 40.0, 'is_mine': false},
        ]
      };

      final poll = CommunityPoll.fromJson(json);
      expect(poll.kind, 'single');
      expect(poll.votersCount, 10);
      expect(poll.hasVoted, isTrue);
      expect(poll.options.length, 2);
      expect(poll.options[0].percent, 60.0);
    });

    test('Quiz poll parsing with correct option and explanation', () {
      final json = {
        'kind': 'quiz',
        'is_closed': false,
        'voters_count': 5,
        'has_voted': false,
        'results_visible': false,
        'correct_option_id': 'opt2',
        'explanation': 'Because of physics.',
        'options': [
          {'id': 'opt1', 'label': 'A', 'votes': 0, 'percent': 0.0, 'is_mine': false, 'is_correct': false},
          {'id': 'opt2', 'label': 'B', 'votes': 0, 'percent': 0.0, 'is_mine': false, 'is_correct': true},
        ]
      };

      final poll = CommunityPoll.fromJson(json);
      expect(poll.kind, 'quiz');
      expect(poll.correctOptionId, 'opt2');
      expect(poll.explanation, 'Because of physics.');
      expect(poll.options[1].isCorrect, isTrue);
    });
  });
}
