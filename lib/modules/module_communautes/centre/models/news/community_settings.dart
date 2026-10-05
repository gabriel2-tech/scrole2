/// Représente l'objet `settings` retourné par la RPC `create_community` ou `get_community_preview`.
class CommunitySettings {
  final String postPermission; // 'everyone', 'admins_and_moderators', 'nobody'
  final bool postsRequireApproval;
  final bool membersListVisible;
  final bool allowReports;
  final bool allowComments;
  final bool allowReactions;

  const CommunitySettings({
    this.postPermission = 'everyone',
    required this.postsRequireApproval,
    required this.membersListVisible,
    required this.allowReports,
    this.allowComments = true,
    this.allowReactions = true,
  });

  factory CommunitySettings.fromJson(Map<String, dynamic> json) =>
      CommunitySettings(
        postPermission: json['post_permission']?.toString() ?? (json['allow_posts'] == false ? 'nobody' : 'everyone'),
        postsRequireApproval: json['posts_require_approval'] == true || json['posts_require_approval'] == 1,
        membersListVisible: json['members_list_visible'] == true || json['members_list_visible'] == 1,
        allowReports: json['allow_reports'] == true || json['allow_reports'] == 1,
        allowComments: json['allow_comments'] == true || json['allow_comments'] == 1 || json['allow_comments'] == null,
        allowReactions: json['allow_reactions'] == true || json['allow_reactions'] == 1 || json['allow_reactions'] == null,
      );

  Map<String, dynamic> toJson() => {
        'post_permission': postPermission,
        'posts_require_approval': postsRequireApproval,
        'members_list_visible': membersListVisible,
        'allow_reports': allowReports,
        'allow_comments': allowComments,
        'allow_reactions': allowReactions,
      };
}
