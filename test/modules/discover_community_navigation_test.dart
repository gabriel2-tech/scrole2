import 'package:flutter_test/flutter_test.dart';
import 'package:scrole/modules/module_communautes/centre/models/news/community.dart';
import 'package:scrole/modules/module_communautes/centre/models/news/community_preview_data.dart';
import 'package:scrole/modules/module_communautes/centre/models/news/community_settings.dart';

void main() {
  group('Discover Community Navigation Tests', () {
    test('isMember is true when memberStatus is active', () {
      final previewData = CommunityPreviewData(
        community: const Community(
          id: 'comm-1',
          name: 'Otaku CM',
          slug: 'otaku-cm',
          visibility: 'public',
          status: 'active',
          memberCount: 150,
        ),
        settings: const CommunitySettings(
          postPermission: 'everyone',
          postsRequireApproval: false,
          membersListVisible: true,
          allowReports: true,
          allowComments: true,
          allowReactions: true,
        ),
        memberStatus: 'active',
      );

      expect(previewData.isMember, isTrue);
    });

    test('isMember is false when memberStatus is none or pending', () {
      final previewDataNone = CommunityPreviewData(
        community: const Community(
          id: 'comm-2',
          name: 'Gamer CM',
          slug: 'gamer-cm',
          visibility: 'public',
          status: 'active',
          memberCount: 50,
        ),
        settings: const CommunitySettings(
          postPermission: 'everyone',
          postsRequireApproval: false,
          membersListVisible: true,
          allowReports: true,
          allowComments: true,
          allowReactions: true,
        ),
        memberStatus: 'none',
      );

      final previewDataPending = CommunityPreviewData(
        community: const Community(
          id: 'comm-3',
          name: 'Design CM',
          slug: 'design-cm',
          visibility: 'private',
          status: 'active',
          memberCount: 20,
        ),
        settings: const CommunitySettings(
          postPermission: 'everyone',
          postsRequireApproval: false,
          membersListVisible: true,
          allowReports: true,
          allowComments: true,
          allowReactions: true,
        ),
        memberStatus: 'pending',
      );

      expect(previewDataNone.isMember, isFalse);
      expect(previewDataPending.isMember, isFalse);
    });
  });
}
