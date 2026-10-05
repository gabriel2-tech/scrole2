import 'package:flutter_test/flutter_test.dart';
import 'package:scrole/modules/module_communautes/centre/models/news/community.dart';
import 'package:scrole/modules/module_communautes/centre/models/news/community_preview_data.dart';
import 'package:scrole/modules/module_communautes/centre/models/news/community_settings.dart';

void main() {
  group('CommunityPreview Action UI State Tests', () {
    const dummyCommunity = Community(
      id: 'c-1',
      name: 'Tsunade',
      slug: 'tsunade',
      visibility: 'public',
      status: 'active',
      memberCount: 10,
    );

    const dummySettings = CommunitySettings(
      postPermission: 'everyone',
      postsRequireApproval: false,
      membersListVisible: true,
      allowReports: true,
      allowComments: true,
      allowReactions: true,
    );

    test('State notMemberNotEligible when showJoinButton is false or isEligible is false (e.g. tsunade)', () {
      final dataIneligible = CommunityPreviewData(
        community: dummyCommunity,
        settings: dummySettings,
        memberStatus: 'none',
        isEligible: false,
        showJoinButton: false,
      );

      expect(dataIneligible.isMember, isFalse);
      expect(dataIneligible.isEligible, isFalse);
      expect(dataIneligible.showJoinButton, isFalse);
    });

    test('State notMemberEligible when non-member, eligible and showJoinButton is true', () {
      final dataEligible = CommunityPreviewData(
        community: dummyCommunity,
        settings: dummySettings,
        memberStatus: 'none',
        isEligible: true,
        showJoinButton: true,
      );

      expect(dataEligible.isMember, isFalse);
      expect(dataEligible.isEligible, isTrue);
      expect(dataEligible.showJoinButton, isTrue);
    });

    test('State pendingRequest when memberStatus is pending (e.g. communaute-a-validation)', () {
      final dataPending = CommunityPreviewData(
        community: const Community(
          id: 'c-1',
          name: 'Tsunade',
          slug: 'tsunade',
          visibility: 'prive',
          status: 'active',
          memberCount: 10,
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
        isEligible: true,
        showJoinButton: true,
      );

      expect(dataPending.isPending, isTrue);
      expect(dataPending.isMember, isFalse);
    });

    test('State memberWithProfile when memberStatus is active', () {
      final dataMember = CommunityPreviewData(
        community: dummyCommunity,
        settings: dummySettings,
        memberStatus: 'active',
        isEligible: true,
        showJoinButton: true,
      );

      expect(dataMember.isMember, isTrue);
    });
  });
}
