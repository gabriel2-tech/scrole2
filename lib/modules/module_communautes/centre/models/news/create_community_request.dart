/// Payload envoyé à la RPC `create_community`.
///
/// Contient UNIQUEMENT ce que le client a le droit d'envoyer. Tout le reste
/// (creator_id, role_id, member_id, community_id, flags internes...) est
/// déterminé côté PostgreSQL via `auth.uid()` et les valeurs par défaut de
/// la RPC.
class CreateCommunityRequest {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? photoProfile;
  final String? photoCover;
  final String visibility; // 'public' | 'prive'

  const CreateCommunityRequest({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.photoProfile,
    this.photoCover,
    this.visibility = 'public',
  });

  /// Paramètres au format attendu par `client.rpc('create_community', params: ...)`.
  Map<String, dynamic> toParams() => {
        'p_id': id,
        'p_name': name,
        'p_slug': slug,
        'p_description': description,
        'p_photo_profile': photoProfile,
        'p_photo_cover': photoCover,
        'p_visibility': visibility,
      };
}
