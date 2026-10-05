import 'access_rule.dart';
import 'community.dart';
import 'community_settings.dart';

class CommunityPreviewData {
  final Community community;
  final CommunitySettings settings;
  final AccessRule? accessRules;
  final List<String> goldRules; // Les règles de vie (textes)
  final List<String> friendAvatars; // Avatars des amis déjà présents
  final String memberStatus; // 'active', 'pending', 'refused', 'none'
  final bool isEligible;
  final bool showJoinButton;
  final bool requiresApproval;
  final bool canJoin;
  final String? requestId;
  final String? requestStatus;

  CommunityPreviewData({
    required this.community,
    required this.settings,
    this.accessRules,
    this.goldRules = const [],
    this.friendAvatars = const [],
    required this.memberStatus,
    this.isEligible = true,
    this.showJoinButton = true,
    this.requiresApproval = false,
    this.canJoin = true,
    this.requestId,
    this.requestStatus,
  });

  bool get isMember => memberStatus == 'active';
  bool get isPending => memberStatus == 'pending' || requestStatus == 'en_attente';
  bool get isRefused => memberStatus == 'refused' || requestStatus == 'refusee';
  bool get canJoinDirectly => canJoin && !requiresApproval;
}
