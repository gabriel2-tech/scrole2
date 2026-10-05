import 'package:flutter_test/flutter_test.dart';
import 'package:scrole/modules/module_decouverte/centre/models/discover_models.dart';

void main() {
  group('SearchResultItem isCertified Tests', () {
    test('parses certified user correctly', () {
      final json = {
        'category': 'user',
        'id': 'uuid-123',
        'title': 'tsunade',
        'subtitle': 'Gabriel stan',
        'photo_url': 'https://example.com/avatar.jpg',
        'friend_count': 3,
        'is_certified': true,
      };

      final item = SearchResultItem.fromJson(json);
      expect(item.category, equals('user'));
      expect(item.id, equals('uuid-123'));
      expect(item.title, equals('tsunade'));
      expect(item.subtitle, equals('Gabriel stan'));
      expect(item.friendCount, equals(3));
      expect(item.isCertified, isTrue);
    });

    test('parses uncertified user correctly', () {
      final json = {
        'category': 'user',
        'id': 'uuid-456',
        'title': 'naruto',
        'subtitle': 'Hokage',
        'is_certified': false,
      };

      final item = SearchResultItem.fromJson(json);
      expect(item.isCertified, isFalse);
    });

    test('defaults isCertified to false if missing or null in JSON', () {
      final jsonMissing = {
        'category': 'user',
        'id': 'uuid-789',
        'title': 'kakashi',
      };

      final jsonNull = {
        'category': 'user',
        'id': 'uuid-789',
        'title': 'kakashi',
        'is_certified': null,
      };

      final item1 = SearchResultItem.fromJson(jsonMissing);
      final item2 = SearchResultItem.fromJson(jsonNull);

      expect(item1.isCertified, isFalse);
      expect(item2.isCertified, isFalse);
    });

    test('isCertified is false for community, event, and activity categories', () {
      final communityJson = {
        'category': 'community',
        'id': 'c-1',
        'title': 'Otaku Club',
        'is_certified': true,
      };

      final eventJson = {
        'category': 'event',
        'id': 'e-1',
        'title': 'Concert Fest',
      };

      final activityJson = {
        'category': 'activity',
        'id': 'a-1',
        'title': 'Paint Workshop',
      };

      final cItem = SearchResultItem.fromJson(communityJson);
      final eItem = SearchResultItem.fromJson(eventJson);
      final aItem = SearchResultItem.fromJson(activityJson);

      expect(cItem.category, equals('community'));
      expect(eItem.category, equals('event'));
      expect(aItem.category, equals('activity'));
      expect(eItem.isCertified, isFalse);
      expect(aItem.isCertified, isFalse);
    });
  });
}
