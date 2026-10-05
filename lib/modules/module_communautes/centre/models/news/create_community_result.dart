import 'community.dart';
import 'community_membership.dart';
import 'community_settings.dart';
import 'community_roles.dart';

/// Résultat complet retourné par la RPC `create_community`.
class CreateCommunityResult {
  final bool success;
  final Community community;
  final CommunityMembership membership;
  final CommunitySettings settings;
  final CommunityRoles roles;
  final int permissionsAssigned;

  const CreateCommunityResult({
    required this.success,
    required this.community,
    required this.membership,
    required this.settings,
    required this.roles,
    required this.permissionsAssigned,
  });

  factory CreateCommunityResult.fromJson(Map<String, dynamic> json) {
    final isNested = json.containsKey('community');

    if (isNested) {
      return CreateCommunityResult(
        success: json['success'] == true,
        community: Community.fromJson(Map<String, dynamic>.from(json['community'] ?? {})),
        membership: CommunityMembership.fromJson(Map<String, dynamic>.from(json['membership'] ?? {})),
        settings: CommunitySettings.fromJson(Map<String, dynamic>.from(json['settings'] ?? {})),
        roles: CommunityRoles.fromJson(Map<String, dynamic>.from(json['roles'] ?? {})),
        permissionsAssigned: (json['permissions_assigned'] as num? ?? 0).toInt(),
      );
    } else {
      final community = Community.fromJson(json);
      return CreateCommunityResult(
        success: true,
        community: community,
        membership: CommunityMembership.fromJson(json),
        settings: const CommunitySettings(
          postPermission: 'everyone',
          postsRequireApproval: false,
          membersListVisible: false,
          allowReports: true,
          allowComments: true,
          allowReactions: true,
        ),
        roles: const CommunityRoles(ownerId: '', adminId: '', moderatorId: '', memberId: ''),
        permissionsAssigned: 0,
      );
    }
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'community': community.toJson(),
        'membership': membership.toJson(),
        'settings': settings.toJson(),
        'roles': roles.toJson(),
        'permissions_assigned': permissionsAssigned,
      };
}
