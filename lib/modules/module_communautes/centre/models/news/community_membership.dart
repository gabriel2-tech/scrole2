/// Représente l'objet `membership` retourné par la RPC `create_community` :
/// l'adhésion du créateur (toujours Owner) à sa nouvelle communauté.
class CommunityMembership {
  final String id;
  final String userId;
  final String roleId;
  final String roleName;
  final String status;

  const CommunityMembership({
    required this.id,
    required this.userId,
    required this.roleId,
    required this.roleName,
    required this.status,
  });

  factory CommunityMembership.fromJson(Map<String, dynamic> json) =>
      CommunityMembership(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        roleId: json['role_id']?.toString() ?? '',
        roleName: json['role_name']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'role_id': roleId,
        'role_name': roleName,
        'status': status,
      };
}
