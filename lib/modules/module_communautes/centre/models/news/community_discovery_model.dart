class CommunityDiscoveryModel {
  final String id;
  final String name;
  final String? photoProfile;
  final String? photoCover;
  final String visibility;
  final int memberCount;
  final bool isMember;

  const CommunityDiscoveryModel({
    required this.id,
    required this.name,
    this.photoProfile,
    this.photoCover,
    required this.visibility,
    required this.memberCount,
    required this.isMember,
  });

  factory CommunityDiscoveryModel.fromJson(Map<String, dynamic> json) =>
      CommunityDiscoveryModel(
        id: json['id'] as String,
        name: json['name'] as String,
        photoProfile: json['photo_profile'] as String?,
        photoCover: json['photo_cover'] as String?,
        visibility: json['visibility'] as String? ?? 'public',
        memberCount: (json['member_count'] as num? ?? 0).toInt(),
        isMember: json['is_member'] == true || json['is_member'] == 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'photo_profile': photoProfile,
        'photo_cover': photoCover,
        'visibility': visibility,
        'member_count': memberCount,
        'is_member': isMember,
      };
}
