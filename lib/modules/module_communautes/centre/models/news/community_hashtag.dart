class CommunityHashtag {
  final String id;
  final String name;
  final int postCount;

  const CommunityHashtag({
    required this.id,
    required this.name,
    required this.postCount,
  });

  factory CommunityHashtag.fromJson(Map<String, dynamic> json) =>
      CommunityHashtag(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        postCount: (json['post_count'] as num? ?? 0).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'post_count': postCount,
      };
}
