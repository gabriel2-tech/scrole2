class CommunityModel {
  final String id;
  final String name;
  final String? description;
  final String coverImage;
  final String avatarImage;
  final int memberCount;
  final List<String> tags;
  final bool isJoined;
  final bool isTrending;
  final DateTime createdAt;
  final int unreadCount;

  CommunityModel({
    required this.id,
    required this.name,
    this.description,
    required this.coverImage,
    required this.avatarImage,
    required this.memberCount,
    required this.tags,
    this.isJoined = false,
    this.isTrending = false,
    required this.createdAt,
    this.unreadCount = 0,
  });

  CommunityModel copyWith({
    String? id,
    String? name,
    String? description,
    String? coverImage,
    String? avatarImage,
    int? memberCount,
    List<String>? tags,
    bool? isJoined,
    bool? isTrending,
    DateTime? createdAt,
    int? unreadCount,
  }) {
    return CommunityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImage: coverImage ?? this.coverImage,
      avatarImage: avatarImage ?? this.avatarImage,
      memberCount: memberCount ?? this.memberCount,
      tags: tags ?? this.tags,
      isJoined: isJoined ?? this.isJoined,
      isTrending: isTrending ?? this.isTrending,
      createdAt: createdAt ?? this.createdAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}