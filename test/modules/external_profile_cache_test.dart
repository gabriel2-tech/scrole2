import 'package:flutter_test/flutter_test.dart';
import 'package:scrole/modules/module_decouverte/centre/models/external_profile_model.dart';

void main() {
  group('ExternalProfileModel serialization and cache compatibility tests', () {
    test('serializes and deserializes correctly via toJson and fromJson', () {
      final model = const ExternalProfileModel(
        userId: 'usr-456',
        username: 'alice_w',
        displayName: 'Alice Walker',
        bio: 'Mobile Engineer & Scrole Explorer',
        slogan: 'Building the future',
        photoUrl: 'https://example.com/alice.png',
        coverUrl: 'https://example.com/cover.png',
        country: 'Cameroon',
        city: 'Douala',
        isPrivate: false,
        isBlocked: false,
        isConnected: true,
        connectionRequestSent: false,
        incomingConnectionRequest: false,
        isFollowing: true,
        isCertified: true,
        canMessage: true,
        friendCount: 42,
        interests: [],
        activities: [
          {'id': 'act-1', 'name': 'Running Club', 'base_price': 0.0, 'currency_code': 'XAF'}
        ],
      );

      final json = model.toJson();
      expect(json['user_id'], equals('usr-456'));
      expect(json['username'], equals('alice_w'));
      expect(json['is_certified'], equals(true));
      expect(json['friend_count'], equals(42));
      expect(json['activities'], isNotEmpty);

      final deserialized = ExternalProfileModel.fromJson(json);
      expect(deserialized.userId, equals('usr-456'));
      expect(deserialized.username, equals('alice_w'));
      expect(deserialized.displayName, equals('Alice Walker'));
      expect(deserialized.isCertified, isTrue);
      expect(deserialized.friendCount, equals(42));
      expect(deserialized.activities.length, equals(1));
      expect(deserialized.activities.first['name'], equals('Running Club'));
    });

    test('handles private profile contract flags correctly', () {
      final privateJson = {
        'user_id': 'usr-789',
        'username': 'bob_private',
        'first_name': 'Bob',
        'last_name': 'Secret',
        'is_private': true,
        'is_connected': false,
        'connection_request_sent': true,
        'can_message': false,
        'friend_count': 10,
      };

      final model = ExternalProfileModel.fromJson(privateJson);
      expect(model.userId, equals('usr-789'));
      expect(model.isPrivate, isTrue);
      expect(model.isConnected, isFalse);
      expect(model.connectionRequestSent, isTrue);
      expect(model.canMessage, isFalse);
      expect(model.friendCount, equals(10));
    });
  });
}
