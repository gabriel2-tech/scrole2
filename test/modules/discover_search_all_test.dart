import 'package:flutter_test/flutter_test.dart';
import 'package:scrole/modules/module_decouverte/centre/models/discover_models.dart';

void main() {
  group('SearchResultItem parsing tests', () {
    test('parses user category result correctly with friend_count', () {
      final json = {
        'category': 'user',
        'id': 'usr-123',
        'title': 'john_doe',
        'subtitle': 'John Doe',
        'photo_url': 'https://example.com/avatar.png',
        'friend_count': 12,
      };
      final item = SearchResultItem.fromJson(json);
      expect(item.category, equals('user'));
      expect(item.id, equals('usr-123'));
      expect(item.title, equals('john_doe'));
      expect(item.subtitle, equals('John Doe'));
      expect(item.photoUrl, equals('https://example.com/avatar.png'));
      expect(item.friendCount, equals(12));
    });

    test('parses user result with zero friend_count', () {
      final json = {
        'category': 'user',
        'id': 'usr-124',
        'title': 'jane_doe',
        'subtitle': 'Jane Doe',
        'photo_url': null,
        'friend_count': 0,
      };
      final item = SearchResultItem.fromJson(json);
      expect(item.friendCount, equals(0));
    });

    test('parses user result with 1 friend_count', () {
      final json = {
        'category': 'user',
        'id': 'usr-125',
        'title': 'alex_smith',
        'subtitle': 'Alex Smith',
        'photo_url': null,
        'friend_count': 1,
      };
      final item = SearchResultItem.fromJson(json);
      expect(item.friendCount, equals(1));
    });

    test('parses event category result correctly with null friend_count', () {
      final json = {
        'category': 'event',
        'id': 'evt-456',
        'title': 'Kamer Anime Fest',
        'subtitle': '25/10/2026',
        'photo_url': 'https://example.com/cover.png',
        'friend_count': null,
      };
      final item = SearchResultItem.fromJson(json);
      expect(item.category, equals('event'));
      expect(item.id, equals('evt-456'));
      expect(item.title, equals('Kamer Anime Fest'));
      expect(item.subtitle, equals('25/10/2026'));
      expect(item.photoUrl, equals('https://example.com/cover.png'));
      expect(item.friendCount, isNull);
    });

    test('parses activity category result with null photo_url and friend_count', () {
      final json = {
        'category': 'activity',
        'id': 'act-789',
        'title': 'Atelier Manga',
        'subtitle': '1500',
        'photo_url': null,
      };
      final item = SearchResultItem.fromJson(json);
      expect(item.category, equals('activity'));
      expect(item.id, equals('act-789'));
      expect(item.title, equals('Atelier Manga'));
      expect(item.subtitle, equals('1500'));
      expect(item.photoUrl, isNull);
      expect(item.friendCount, isNull);
    });
  });
}
