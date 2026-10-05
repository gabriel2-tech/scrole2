/// Représente l'objet `roles` retourné par la RPC `create_community` :
/// les ids des 4 rôles système créés automatiquement.
class CommunityRoles {
  final String ownerId;
  final String adminId;
  final String moderatorId;
  final String memberId;

  const CommunityRoles({
    required this.ownerId,
    required this.adminId,
    required this.moderatorId,
    required this.memberId,
  });

  factory CommunityRoles.fromJson(Map<String, dynamic> json) =>
      CommunityRoles(
        ownerId: json['owner_id']?.toString() ?? '',
        adminId: json['admin_id']?.toString() ?? '',
        moderatorId: json['moderator_id']?.toString() ?? '',
        memberId: json['member_id']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'owner_id': ownerId,
        'admin_id': adminId,
        'moderator_id': moderatorId,
        'member_id': memberId,
      };
}
