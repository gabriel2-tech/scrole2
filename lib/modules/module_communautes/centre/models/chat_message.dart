import 'package:flutter/material.dart';

class VoiceMessage {
  final String fileName;
  final String sizeLabel;
  final String durationLabel;
  final String? url; // Chemin local ou URL distante

  const VoiceMessage({
    required this.fileName,
    required this.sizeLabel,
    required this.durationLabel,
    this.url,
  });
}

class ChatMessage {
  final String id;
  final String authorName;
  final Color authorColor;
  final String time;
  final String? text;
  final bool isEdited;
  final List<String>? mediaUrls; // Nouveau : support pour plusieurs images/vidéos
  final VoiceMessage? voiceMessage;
  final ChatMessage? repliedTo;

  const ChatMessage({
    required this.id,
    required this.authorName,
    required this.authorColor,
    required this.time,
    this.text,
    this.isEdited = false,
    this.mediaUrls,
    this.voiceMessage,
    this.repliedTo,
  });
}
