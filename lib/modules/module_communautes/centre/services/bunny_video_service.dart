import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

class BunnyVideoUploadSession {
  final String videoId;
  final String libraryId;
  final String tusEndpoint;
  final String authorizationSignature;
  final int authorizationExpire;
  final int maxSizeBytes;
  final int maxDurationMs;

  const BunnyVideoUploadSession({
    required this.videoId,
    required this.libraryId,
    required this.tusEndpoint,
    required this.authorizationSignature,
    required this.authorizationExpire,
    required this.maxSizeBytes,
    required this.maxDurationMs,
  });

  factory BunnyVideoUploadSession.fromJson(Map<String, dynamic> json) {
    return BunnyVideoUploadSession(
      videoId: (json['video_id'] ?? '').toString(),
      libraryId: (json['library_id'] ?? '').toString(),
      tusEndpoint: (json['tus_endpoint'] ?? '').toString(),
      authorizationSignature: (json['authorization_signature'] ?? '').toString(),
      authorizationExpire: (json['authorization_expire'] as num?)?.toInt() ?? 0,
      maxSizeBytes: (json['max_size_bytes'] as num?)?.toInt() ?? 52428800,
      maxDurationMs: (json['max_duration_ms'] as num?)?.toInt() ?? 120000,
    );
  }
}

class BunnyVideoUploadResult {
  final String videoId;
  final String libraryId;
  final int durationMs;
  final int sizeBytes;
  final String? thumbnailUrl;

  const BunnyVideoUploadResult({
    required this.videoId,
    required this.libraryId,
    required this.durationMs,
    required this.sizeBytes,
    this.thumbnailUrl,
  });
}

class BunnyVideoService {
  final SupabaseClient _client;

  BunnyVideoService(this._client);

  Future<BunnyVideoUploadSession> requestUploadSession({
    required String communityId,
    required String postId,
    required String clientMediaId,
    required String filename,
    required String mimeType,
    required int sizeBytes,
    required int durationMs,
  }) async {
    try {
      debugPrint('[BUNNY] Requesting upload session (prepare) for $filename ($sizeBytes bytes, $durationMs ms, post=$postId, clientMedia=$clientMediaId)');
      final response = await _client.functions.invoke(
        'bunny-video-upload',
        body: {
          'action': 'prepare',
          'community_id': communityId,
          'post_id': postId,
          'client_media_id': clientMediaId,
          'filename': filename,
          'mime_type': mimeType,
          'size_bytes': sizeBytes,
          'duration_ms': durationMs,
        },
      );

      if (response.status != 200) {
        throw Exception('Edge function returned status ${response.status}');
      }

      final data = response.data;
      Map<String, dynamic> jsonMap;
      if (data is Map) {
        jsonMap = Map<String, dynamic>.from(data);
      } else if (data is String) {
        jsonMap = Map<String, dynamic>.from(jsonDecode(data));
      } else {
        throw Exception('Invalid response format from bunny-video-upload');
      }

      if (jsonMap['success'] != true) {
        throw Exception('Bunny upload session creation failed: ${jsonMap['message'] ?? 'unknown error'}');
      }

      return BunnyVideoUploadSession.fromJson(jsonMap);
    } catch (e) {
      debugPrint('[BUNNY] Error requesting session: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkVideoStatus({
    required String postId,
    required String clientMediaId,
  }) async {
    final response = await _client.functions.invoke(
      'bunny-video-upload',
      body: {
        'action': 'status',
        'post_id': postId,
        'client_media_id': clientMediaId,
      },
    );
    if (response.status != 200) {
      throw Exception('Edge function returned status ${response.status}');
    }
    final data = response.data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    } else if (data is String) {
      return Map<String, dynamic>.from(jsonDecode(data));
    }
    throw Exception('Invalid status response from bunny-video-upload');
  }

  Future<void> uploadVideoTus({
    required File file,
    required BunnyVideoUploadSession session,
    Function(double progress)? onProgress,
  }) async {
    final length = await file.length();
    final uri = Uri.parse(session.tusEndpoint);
    
    final currentUnixTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final signatureExpired = session.authorizationExpire <= currentUnixTime;

    debugPrint('[TUS] endpoint=${session.tusEndpoint}');
    debugPrint('[TUS] videoId=${session.videoId}');
    debugPrint('[TUS] libraryId=${session.libraryId}');
    debugPrint('[TUS] authorizationExpire=${session.authorizationExpire}');
    debugPrint('[TUS] signaturePresent=${session.authorizationSignature.isNotEmpty}');
    debugPrint('[TUS] signatureLength=${session.authorizationSignature.length}');
    debugPrint('[TUS] currentUnixTime=$currentUnixTime');
    debugPrint('[TUS] signatureExpired=$signatureExpired');

    if (signatureExpired) {
      throw Exception('Bunny authorization signature expired');
    }

    final filename = file.path.split('/').last;
    final filenameBase64 = base64.encode(utf8.encode(filename));
    final filetypeBase64 = base64.encode(utf8.encode('video/mp4'));
    final videoIdBase64 = base64.encode(utf8.encode(session.videoId));
    final libraryIdBase64 = base64.encode(utf8.encode(session.libraryId));
    final expirationBase64 = base64.encode(utf8.encode(session.authorizationExpire.toString()));
    final signatureBase64 = base64.encode(utf8.encode(session.authorizationSignature));

    final uploadMetadata = 'filename $filenameBase64,filetype $filetypeBase64,videoId $videoIdBase64,libraryId $libraryIdBase64,expiration $expirationBase64,signature $signatureBase64';

    final headers = {
      'Tus-Resumable': '1.0.0',
      'Upload-Length': length.toString(),
      'Upload-Metadata': uploadMetadata,
      'AuthorizationSignature': session.authorizationSignature,
      'AuthorizationExpire': session.authorizationExpire.toString(),
      'VideoId': session.videoId,
      'LibraryId': session.libraryId,
    };

    // 1. POST creation request
    final postReq = http.Request('POST', uri);
    postReq.headers.addAll(headers);
    final streamedPost = await postReq.send();
    final postResponse = await http.Response.fromStream(streamedPost);

    if (postResponse.statusCode != 201 && postResponse.statusCode != 200) {
      debugPrint('[TUS] status=${postResponse.statusCode}');
      debugPrint('[TUS] responseBody=${postResponse.body}');
      throw Exception('TUS creation failed with status ${postResponse.statusCode}: ${postResponse.body}');
    }

    final location = postResponse.headers['location'] ?? postResponse.headers['Location'];
    if (location == null || location.isEmpty) {
      throw Exception('TUS upload location header missing');
    }

    final uploadUri = Uri.parse(location.startsWith('http') ? location : '${uri.scheme}://${uri.host}$location');
    debugPrint('[BUNNY] TUS upload location obtained: $uploadUri');

    // 2. PATCH upload chunks
    final bytes = await file.readAsBytes();
    int uploadedBytes = 0;
    const chunkSize = 1024 * 1024 * 2; // 2MB chunks

    while (uploadedBytes < length) {
      final end = (uploadedBytes + chunkSize < length) ? uploadedBytes + chunkSize : length;
      final chunk = bytes.sublist(uploadedBytes, end);

      debugPrint('[TUS PATCH] location=$uploadUri');
      debugPrint('[TUS PATCH] videoId=${session.videoId}');
      debugPrint('[TUS PATCH] libraryId=${session.libraryId}');
      debugPrint('[TUS PATCH] signaturePresent=${session.authorizationSignature.isNotEmpty}');
      debugPrint('[TUS PATCH] expiration=${session.authorizationExpire}');
      debugPrint('[TUS PATCH] offset=$uploadedBytes');
      debugPrint('[TUS PATCH] chunkSize=${chunk.length}');

      final patchReq = http.Request('PATCH', uploadUri);
      patchReq.headers.addAll({
        'Tus-Resumable': '1.0.0',
        'Upload-Offset': uploadedBytes.toString(),
        'Content-Type': 'application/offset+octet-stream',
        'AuthorizationSignature': session.authorizationSignature,
        'AuthorizationExpire': session.authorizationExpire.toString(),
        'VideoId': session.videoId,
        'LibraryId': session.libraryId,
      });
      patchReq.bodyBytes = chunk;

      final streamedPatch = await patchReq.send();
      final patchResponse = await http.Response.fromStream(streamedPatch);

      if (patchResponse.statusCode != 204 && patchResponse.statusCode != 200) {
        debugPrint('[TUS] status=${patchResponse.statusCode}');
        debugPrint('[TUS] responseBody=${patchResponse.body}');
        throw Exception('TUS upload chunk failed with status ${patchResponse.statusCode}: ${patchResponse.body}');
      }

      uploadedBytes = end;
      if (onProgress != null) {
        onProgress(uploadedBytes / length);
      }
    }

    debugPrint('[BUNNY] TUS upload completed successfully');
  }
}
