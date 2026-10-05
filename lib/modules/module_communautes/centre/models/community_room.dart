import 'package:flutter/material.dart';

enum GroupVisibility { public, private }

/// Qui peut rejoindre un salon privé.
enum GroupJoinPolicy { open, requestToJoin, inviteOnly }

class CommunityGroup {
  final String id;
  final String initials;
  final Color color;
  final String name;
  final String? description;
  final int onlineCount;
  final bool slowModeEnabled;
  final GroupVisibility visibility;
  final GroupJoinPolicy joinPolicy;

  /// true si l'utilisateur courant fait déjà partie de ce salon.
  final bool isMember;

  const CommunityGroup({
    required this.id,
    required this.initials,
    required this.color,
    required this.name,
    this.description,
    required this.onlineCount,
    this.slowModeEnabled = false,
    this.visibility = GroupVisibility.public,
    this.joinPolicy = GroupJoinPolicy.open,
    this.isMember = true,
  });

  CommunityGroup copyWith({
    bool? isMember,
    GroupVisibility? visibility,
    GroupJoinPolicy? joinPolicy,
  }) {
    return CommunityGroup(
      id: id,
      initials: initials,
      color: color,
      name: name,
      description: description,
      onlineCount: onlineCount,
      slowModeEnabled: slowModeEnabled,
      visibility: visibility ?? this.visibility,
      joinPolicy: joinPolicy ?? this.joinPolicy,
      isMember: isMember ?? this.isMember,
    );
  }
}
