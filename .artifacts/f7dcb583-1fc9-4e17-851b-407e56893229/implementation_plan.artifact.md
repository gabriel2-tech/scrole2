# Implementation Plan - Community Addendum (Moderation Center, Polls & Fixes)

This plan outlines the implementation strategy for completing the community module features including visibility adjustments, moderation center integration, poll creation & voting with outbox support, and robust unit testing.

## User Review Required

> [!IMPORTANT]
> - **Visibility enum**: Transitioned from `'private'` to `'prive'` across models and UI to match backend constraints.
> - **Polls & Media**: Mutual exclusivity enforced between polls and media (photos/videos).

## Proposed Changes

### [Models & Repositories]
#### [MODIFY] [community_post.dart](file:///home/gabriel/travail/scrole/scrole/lib/modules/module_communautes/centre/models/community_post.dart)
- Add `PollOption`, `CommunityPoll`, and `PollDraft` classes with strict validation matching server rules.
- Add `poll` field to `CommunityPost`.

#### [MODIFY] [community_repository.dart](file:///home/gabriel/travail/scrole/scrole/lib/modules/module_communautes/externe/repositories/community_repository.dart)
- Add moderation center RPC methods (`getCommunityModerationCounts`, `getCommunityPendingPosts`, `getCommunityJoinRequests`, `respondCommunityJoinRequest`, `getCommunitySpamQueue`, `getCommunityReports`, `resolveCommunityReport`, `getCommunityAlerts`, `updateCommunityFeatures`).
- Update `createCommunityPost` and `voteCommunityPoll`.

### [Widgets & Screens]
#### [MODIFY] [create_community_post_screen.dart](file:///home/gabriel/travail/scrole/scrole/lib/modules/module_communautes/interne/pages/community/create_community_post_screen.dart)
- Integrate `CreatePollSheet`, mutual exclusivity check against photos/videos, and poll preview card.

#### [MODIFY] [poll_card_widget.dart](file:///home/gabriel/travail/scrole/scrole/lib/modules/module_communautes/interne/widgets/community/poll_card_widget.dart)
- Handle confidentiality rules (hide results before voting), quiz finality, multiple-choice percentage calculations, and voting.

### [Testing]
#### [NEW] [community_poll_test.dart](file:///home/gabriel/travail/scrole/scrole/test/modules/community_poll_test.dart)
- Unit tests for `PollDraft` validation, poll card state machine, outbox poll vote, and percentage calculation.

## Verification Plan

### Automated Tests
- Run `flutter test` and `flutter analyze` to ensure zero errors and green tests.
