import 'package:get/get.dart';
import '../../../module_communautes/centre/models/news/community.dart';
import '../../../module_communautes/externe/repositories/community_repository.dart';
import '../../../module_creation_de_compte/externe/repositories/user_repository.dart';
import '../models/discover_models.dart';

class DiscoverService extends GetxService {
  final UserRepository _userRepo = UserRepository();
  final CommunityRepository _communityRepo = Get.find<CommunityRepository>();

  Future<List<SearchResultItem>> searchAll(String term) async {
    final response = await _userRepo.client.rpc(
      'search_all',
      params: {'p_query': term},
    );

    if (response is List) {
      final currentUserId = _userRepo.client.auth.currentUser?.id;
      return response
          .whereType<Map>()
          .map((e) => SearchResultItem.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.category != 'user' || currentUserId == null || e.id != currentUserId)
          .toList();
    }
    return [];
  }

  Future<List<AccountSuggestion>> searchUsers(String term) async {
    final raw = await _userRepo.searchUsers(term);
    final currentUserId = _userRepo.client.auth.currentUser?.id;

    return raw
        .where((e) => currentUserId == null || e['user_id']?.toString() != currentUserId)
        .map((e) => AccountSuggestion(
              id: e['user_id'] ?? '',
              username: e['username'] ?? '',
              displayName: '${e['first_name'] ?? ''} ${e['last_name'] ?? ''}'.trim(),
              avatarUrl: e['photo_url'],
              bio: e['bio'],
              isVerified: e['is_verified'] == true,
              friendCount: (e['friend_count'] as num?)?.toInt(),
            ))
        .toList();
  }

  Future<List<CommunitySuggestion>> searchCommunities(String term) async {
    final raw = await _communityRepo.searchCommunities(term);
    return raw.map((e) => CommunitySuggestion(
      id: e['id'] ?? '',
      name: e['name'] ?? '',
      imageUrl: e['avatar_url'],
      description: e['description'],
      membersCount: e['member_count'] ?? 0,
    )).toList();
  }
}
