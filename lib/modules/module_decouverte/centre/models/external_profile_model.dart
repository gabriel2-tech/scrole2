import 'package:scrole/shared/models/interest_model.dart';

class ExternalProfileModel {
  final String userId;
  final String username;
  final String displayName;
  final DateTime? birthDate;
  final String? bio;
  final String? slogan;
  final String? photoUrl;
  final String? coverUrl;
  final String? country;
  final String? city;
  final bool isPrivate;
  final bool isBlocked;
  final bool isConnected;
  final bool connectionRequestSent;
  final bool incomingConnectionRequest;
  final bool isFollowing;
  final bool isCertified;
  final bool canMessage;
  final int friendCount;
  final List<Interest> interests;
  final List<Map<String, dynamic>> activities;

  const ExternalProfileModel({
    required this.userId,
    required this.username,
    required this.displayName,
    this.birthDate,
    this.bio,
    this.slogan,
    this.photoUrl,
    this.coverUrl,
    this.country,
    this.city,
    this.isPrivate = false,
    this.isBlocked = false,
    this.isConnected = false,
    this.connectionRequestSent = false,
    this.incomingConnectionRequest = false,
    this.isFollowing = false,
    this.isCertified = false,
    this.canMessage = false,
    this.friendCount = 0,
    this.interests = const <Interest>[],
    this.activities = const <Map<String, dynamic>>[],
  });

  ExternalProfileModel copyWith({
    bool? isConnected,
    bool? connectionRequestSent,
    bool? isFollowing,
    int? friendCount,
    List<Map<String, dynamic>>? activities,
  }) {
    return ExternalProfileModel(
      userId: userId,
      username: username,
      displayName: displayName,
      birthDate: birthDate,
      bio: bio,
      slogan: slogan,
      photoUrl: photoUrl,
      coverUrl: coverUrl,
      country: country,
      city: city,
      isPrivate: isPrivate,
      isBlocked: isBlocked,
      isConnected: isConnected ?? this.isConnected,
      connectionRequestSent: connectionRequestSent ?? this.connectionRequestSent,
      incomingConnectionRequest: incomingConnectionRequest,
      isFollowing: isFollowing ?? this.isFollowing,
      isCertified: isCertified,
      canMessage: canMessage,
      friendCount: friendCount ?? this.friendCount,
      interests: interests,
      activities: activities ?? this.activities,
    );
  }

  factory ExternalProfileModel.fromJson(Map<String, dynamic> json) {
    final first = (json['first_name'] as String? ?? '').trim();
    final last = (json['last_name'] as String? ?? '').trim();
    final display = '$first $last'.trim();
    final rawInterests = json['interests'];
    final interests = rawInterests is List
        ? rawInterests
            .whereType<Map>()
            .map((e) => Interest.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : const <Interest>[];

    final rawActivities = json['activities'];
    final activities = rawActivities is List
        ? rawActivities.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : const <Map<String, dynamic>>[];

    return ExternalProfileModel(
      userId: json['user_id'] as String,
      username: json['username'] as String? ?? '',
      displayName: display.isEmpty ? (json['username'] as String? ?? '') : display,
      birthDate: json['birth_date'] == null ? null : DateTime.tryParse(json['birth_date'].toString()),
      bio: json['bio'] as String?,
      slogan: json['slogan'] as String?,
      photoUrl: json['photo_url'] as String?,
      coverUrl: json['cover_url'] as String?,
      country: json['country'] as String?,
      city: json['city'] as String?,
      isPrivate: json['is_private'] == true,
      isBlocked: json['is_blocked'] == true,
      isConnected: json['is_connected'] == true,
      connectionRequestSent: json['connection_request_sent'] == true,
      incomingConnectionRequest: json['incoming_connection_request'] == true,
      isFollowing: json['is_following'] == true,
      isCertified: json['is_certified'] == true || json['is_verified'] == true,
      canMessage: json['can_message'] == true,
      friendCount: (json['friend_count'] as num?)?.toInt() ?? 0,
      interests: interests,
      activities: activities,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'first_name': displayName,
      'last_name': '',
      'birth_date': birthDate?.toIso8601String(),
      'bio': bio,
      'slogan': slogan,
      'photo_url': photoUrl,
      'cover_url': coverUrl,
      'country': country,
      'city': city,
      'is_private': isPrivate,
      'is_blocked': isBlocked,
      'is_connected': isConnected,
      'connection_request_sent': connectionRequestSent,
      'incoming_connection_request': incomingConnectionRequest,
      'is_following': isFollowing,
      'is_certified': isCertified,
      'can_message': canMessage,
      'friend_count': friendCount,
      'interests': interests.map((i) => i.toJson()).toList(),
      'activities': activities,
    };
  }

  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    var value = now.year - birthDate!.year;
    if (now.month < birthDate!.month || (now.month == birthDate!.month && now.day < birthDate!.day)) value--;
    return value;
  }
}
