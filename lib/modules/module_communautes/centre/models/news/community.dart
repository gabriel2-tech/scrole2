/// Représente l'objet `community` retourné par la RPC `create_community`.
class Community {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? avatarUrl;
  final String? bannerUrl;
  final String visibility;
  final String status;
  final int memberCount;
  final DateTime? createdAt;

  const Community({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.avatarUrl,
    this.bannerUrl,
    required this.visibility,
    required this.status,
    required this.memberCount,
    this.createdAt,
  });

  factory Community.fromJson(Map<String, dynamic> json, {int? memberCount}) => Community(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    slug: json['slug']?.toString() ?? '',
    description: json['description']?.toString(),
    avatarUrl: json['avatar_url']?.toString() ?? json['photo_profile']?.toString() ?? json['photo_url']?.toString(),
    bannerUrl: json['banner_url']?.toString() ?? json['photo_cover']?.toString() ?? json['cover_url']?.toString(),
    visibility: json['visibility']?.toString() ?? 'public',
    status: json['status']?.toString() ?? 'active',
    memberCount: memberCount ?? (json['member_count'] as num?)?.toInt() ?? 0,
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
  );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'description': description,
        'avatar_url': avatarUrl,
        'banner_url': bannerUrl,
        'visibility': visibility,
        'status': status,
        'member_count': memberCount,
        'created_at': createdAt?.toIso8601String(),
      };
}
