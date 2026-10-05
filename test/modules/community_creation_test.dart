import 'package:flutter_test/flutter_test.dart';
import 'package:scrole/modules/module_communautes/centre/models/news/create_community_request.dart';

void main() {
  group('CreateCommunityRequest Tests', () {
    test('toParams produces exact RPC payload expected by create_community', () {
      const request = CreateCommunityRequest(
        id: 'c-uuid-123',
        name: 'Designers Afrique',
        slug: 'designers-afrique',
        description: 'Communauté des designers en Afrique',
        photoProfile: 'https://example.com/avatar.jpg',
        photoCover: 'https://example.com/banner.jpg',
        visibility: 'public',
      );

      final params = request.toParams();

      expect(params['p_id'], equals('c-uuid-123'));
      expect(params['p_name'], equals('Designers Afrique'));
      expect(params['p_slug'], equals('designers-afrique'));
      expect(params['p_description'], equals('Communauté des designers en Afrique'));
      expect(params['p_photo_profile'], equals('https://example.com/avatar.jpg'));
      expect(params['p_photo_cover'], equals('https://example.com/banner.jpg'));
      expect(params['p_visibility'], equals('public'));
      expect(params.containsKey('p_require_manual_approval'), isFalse);

      // Verify no legacy restriction parameters exist
      expect(params.containsKey('p_access_rules'), isFalse);
      expect(params.containsKey('countries_enabled'), isFalse);
      expect(params.containsKey('gender_restriction'), isFalse);
    });
  });
}
