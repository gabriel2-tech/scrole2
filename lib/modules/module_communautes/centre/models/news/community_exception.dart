/// Codes d'erreur métier reconnus, indépendants du message technique
/// PostgreSQL/Supabase brut. Le service s'appuie sur ce code pour produire
/// un message propre destiné à l'utilisateur (voir CommunityService).
enum CommunityErrorCode {
  unauthenticated,
  duplicateSlug,
  invalidName,
  invalidSlug,
  invalidVisibility,
  network,
  unknown,
}

/// Exception typée levée par [CommunityRepository]. Le [rawMessage] est
/// conservé pour les logs techniques ; il ne doit jamais être affiché tel
/// quel à l'utilisateur — voir CommunityService pour la traduction.
class CommunityException implements Exception {
  final CommunityErrorCode code;
  final String rawMessage;

  const CommunityException(this.code, this.rawMessage);

  @override
  String toString() => 'CommunityException(${code.name}): $rawMessage';
}
