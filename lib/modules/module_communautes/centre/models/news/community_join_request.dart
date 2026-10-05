class CommunityJoinRequest {
  final String id;
  final String communityId;
  final String userId;
  final String status;
  final DateTime? createdAt;
  final DateTime? respondedAt;
  final String username;
  final String firstName;
  final String lastName;
  final String? photoUrl;
  final bool isVerified;

  const CommunityJoinRequest({
    required this.id,
    required this.communityId,
    required this.userId,
    required this.status,
    this.createdAt,
    this.respondedAt,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.photoUrl,
    required this.isVerified,
  });

  String get displayName {
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }
    return username.isNotEmpty ? username : 'Utilisateur';
  }

  factory CommunityJoinRequest.fromJson(Map<String, dynamic> json) => CommunityJoinRequest(
        id: json['id']?.toString() ?? '',
        communityId: json['community_id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        status: json['status']?.toString() ?? 'en_attente',
        createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
        respondedAt: json['responded_at'] != null ? DateTime.tryParse(json['responded_at'].toString()) : null,
        username: json['username']?.toString() ?? '',
        firstName: json['first_name']?.toString() ?? '',
        lastName: json['last_name']?.toString() ?? '',
        photoUrl: json['photo_url']?.toString(),
        isVerified: json['is_verified'] == true || json['is_verified'] == 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'community_id': communityId,
        'user_id': userId,
        'status': status,
        'created_at': createdAt?.toIso8601String(),
        'responded_at': respondedAt?.toIso8601String(),
        'username': username,
        'first_name': firstName,
        'last_name': lastName,
        'photo_url': photoUrl,
        'is_verified': isVerified,
      };
}
