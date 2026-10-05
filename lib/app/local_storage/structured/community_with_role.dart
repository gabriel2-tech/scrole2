import '../../../modules/module_communautes/centre/models/news/community.dart';

/// Modèle représentant une communauté avec le rôle de l'utilisateur.
class CommunityWithRole {
  final Community community;
  final String roleName;
  final String membershipStatus;

  const CommunityWithRole({
    required this.community,
    required this.roleName,
    required this.membershipStatus,
  });
}
