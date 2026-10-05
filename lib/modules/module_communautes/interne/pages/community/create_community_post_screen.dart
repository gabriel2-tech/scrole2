import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';
import 'package:scrole/app/theme/app_colors.dart';
import 'package:scrole/app/theme/text_styles.dart';
import 'package:scrole/app_controller.dart';
import 'package:scrole/shared/widgets/app_cached_image.dart';
import 'package:scrole/shared/widgets/media_gallery_sheet.dart';
import 'package:scrole/shared/widgets/video_trim_screen.dart';
import 'package:scrole/shared/widgets/video_full_screen_viewer.dart';
import '../../controllers/community/community_feed_controller.dart';
import '../../../centre/services/community_service.dart';
import '../../../centre/models/news/community_hashtag.dart';
import 'community_poll_composer_screen.dart';
import 'community_post_hashtag_selection_screen.dart';
import 'community_post_settings_screen.dart';
import 'community_post_mentions_screen.dart';

class CreateCommunityPostScreen extends StatefulWidget {
  final String communityName;
  final String? communityId;
  final String? prefilledText;
  final String? prefilledMediaUrl;

  const CreateCommunityPostScreen({
    super.key,
    required this.communityName,
    this.communityId,
    this.prefilledText,
    this.prefilledMediaUrl,
  });

  @override
  State<CreateCommunityPostScreen> createState() => _CreateCommunityPostScreenState();
}

class _CreateCommunityPostScreenState extends State<CreateCommunityPostScreen> {
  late final TextEditingController _textController;
  final List<File> _selectedFiles = [];
  String? _prefilledUrl;
  Map<String, dynamic>? _pollData;
  bool _isPublishing = false;

  bool _commentsEnabled = true;
  bool _sharingEnabled = true;
  final List<CommunityHashtag> _selectedHashtags = [];
  List<Map<String, dynamic>> _selectedMentions = [];
  List<String> _selectedMentionIds = [];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.prefilledText ?? '');
    _prefilledUrl = widget.prefilledMediaUrl;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  bool get _canPublish =>
      _textController.text.trim().isNotEmpty ||
      _selectedFiles.isNotEmpty ||
      (_prefilledUrl != null && _prefilledUrl!.isNotEmpty) ||
      _pollData != null;

  Future<void> _openMentions() async {
    final cId = widget.communityId ?? Get.parameters['id'] ?? '';
    if (cId.isEmpty) return;
    final result = await Get.to<List<Map<String, dynamic>>>(
      () => const CommunityPostMentionsScreen(),
      arguments: {'communityId': cId, 'initialSelected': _selectedMentionIds},
    );
    if (result != null) {
      setState(() {
        _selectedMentions = result;
        _selectedMentionIds = result.map((m) => (m['user_id'] ?? m['id'] ?? '').toString()).toList();
      });
    }
  }

  Future<void> _openPollCreator() async {
    if (_selectedFiles.isNotEmpty || (_prefilledUrl != null && _prefilledUrl!.isNotEmpty)) {
      Get.snackbar('Attention', 'Un sondage ne peut pas contenir de photos ni de vidéos.', backgroundColor: Colors.black87, colorText: Colors.white);
      return;
    }
    final pollMap = await Get.to<Map<String, dynamic>>(() => const CommunityPollComposerScreen(), transition: Transition.rightToLeft);
    if (pollMap != null) {
      setState(() {
        _pollData = pollMap;
      });
    }
  }

  void _publish() {
    if (!_canPublish) return;

    List<File> filesToPublish = List.from(_selectedFiles);
    if (filesToPublish.isEmpty && _prefilledUrl != null && _prefilledUrl!.isNotEmpty && !_prefilledUrl!.startsWith('http')) {
      filesToPublish.add(File(_prefilledUrl!));
    }

    final content = _textController.text.trim();

    if (content.isEmpty && filesToPublish.isEmpty && _pollData == null) {
      Get.snackbar('Publication vide', 'Une publication doit contenir du texte, un média ou un sondage.', backgroundColor: Colors.black87, colorText: Colors.white);
      return;
    }

    if (filesToPublish.length > 15) {
      Get.snackbar('Limite dépassée', 'Maximum 15 fichiers autorisés.', backgroundColor: Colors.black87, colorText: Colors.white);
      return;
    }

    Get.back();

    CommunityFeedController? feedController;
    try {
      if (widget.communityId != null && widget.communityId!.isNotEmpty) {
        feedController = Get.find<CommunityFeedController>(tag: widget.communityId);
      } else {
        feedController = Get.find<CommunityFeedController>();
      }
    } catch (_) {
      try {
        feedController = Get.find<CommunityFeedController>();
      } catch (_) {}
    }

    final postContent = content.isNotEmpty ? content : null;
    final hashtagsList = _selectedHashtags.map((h) => h.name).toList();
    final mentionsList = _selectedMentionIds;

    if (feedController != null) {
      unawaited(feedController.createPost(
        content: postContent,
        imageFiles: filesToPublish,
        commentsEnabled: _commentsEnabled,
        sharingEnabled: _sharingEnabled,
        hashtags: hashtagsList,
        mentions: mentionsList,
        poll: _pollData,
      ));
    } else {
      final service = Get.isRegistered<CommunityService>() ? Get.find<CommunityService>() : Get.put(CommunityService(Get.find(), Get.find()));
      final cId = widget.communityId ?? Get.parameters['id'] ?? '';
      if (cId.isNotEmpty) {
        unawaited(service.createCommunityPost(
          communityId: cId,
          content: postContent,
          imageFiles: filesToPublish,
          commentsEnabled: _commentsEnabled,
          sharingEnabled: _sharingEnabled,
          hashtags: hashtagsList,
          mentions: mentionsList,
          poll: _pollData,
        ));
      }
    }
  }

  Future<void> _openGallery() async {
    if (_pollData != null) {
      Get.snackbar('Attention', 'Un sondage ne peut pas contenir de photos ni de vidéos.', backgroundColor: Colors.black87, colorText: Colors.white);
      return;
    }

    final maxAllowed = 15 - _selectedFiles.length;
    if (maxAllowed <= 0) {
      Get.snackbar(
        'Limite atteinte',
        'Vous ne pouvez pas ajouter plus de 15 éléments.',
        backgroundColor: Colors.black87,
        colorText: Colors.white,
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MediaGallerySheet(
        maxSelection: maxAllowed,
        onSelected: (files) {
          if (files.isNotEmpty) {
            setState(() {
              _selectedFiles.addAll(files.map((f) => File(f.path)));
              _prefilledUrl = null;
            });
          }
        },
      ),
    );
  }

  bool _isVideo(File file) {
    final ext = file.path.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'].contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appController = Get.find<AppController>();
    final profileRaw = appController.profile.value ?? {};
    final profile = (profileRaw['profile'] is Map)
        ? Map<String, dynamic>.from(profileRaw['profile'] as Map)
        : profileRaw;
    final firstName = profile['first_name']?.toString() ?? profile['prenom']?.toString() ?? '';
    final lastName = profile['last_name']?.toString() ?? profile['nom']?.toString() ?? '';
    final fullName = "$firstName $lastName".trim();
    final username = profile['username']?.toString() ?? '';
    final displayName = fullName.isEmpty ? (username.isEmpty ? 'profile_default_username'.tr : username) : fullName;
    final avatarUrl = profile['photo_url']?.toString() ?? '';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Créer une publication'),
        titleTextStyle: AppTextStyles.h5.copyWith(color: colorScheme.onSurface),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.close_rounded, size: 28),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _canPublish && !_isPublishing ? _publish : null,
              style: TextButton.styleFrom(
                foregroundColor: _canPublish ? colorScheme.primary : colorScheme.outline,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: _isPublishing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      'Publier',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _canPublish ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.6),
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profil + Badge Communauté
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: colorScheme.surfaceContainerHighest),
                            child: ClipOval(
                              child: avatarUrl.isNotEmpty
                                  ? AppCachedImage(imageUrl: avatarUrl, width: 44, height: 44, fit: BoxFit.cover)
                                  : Icon(Icons.person, color: colorScheme.onSurfaceVariant),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(displayName, style: AppTextStyles.h6.copyWith(fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Dans r/${widget.communityName}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Champ de texte
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _textController,
                        autofocus: true,
                        maxLines: null,
                        style: AppTextStyles.bodyXL.copyWith(fontSize: 18, height: 1.4, color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: _pollData != null ? 'Posez votre question pour le sondage...' : 'Quoi de neuf ?',
                          hintStyle: AppTextStyles.bodyXL.copyWith(fontSize: 18, color: colorScheme.outline.withValues(alpha: 0.5)),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          filled: false,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),

                    if (_selectedHashtags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: _selectedHashtags.map((h) => Chip(
                            label: Text('#${h.name}'),
                            onDeleted: () => setState(() => _selectedHashtags.removeWhere((item) => item.name.toLowerCase() == h.name.toLowerCase())),
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            labelStyle: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                          )).toList(),
                        ),
                      ),

                    if (_selectedMentions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: _selectedMentions.map((m) {
                            final username = m['username'] ?? m['user_profiles']?['username'] ?? 'membre';
                            return Chip(
                              label: Text('@$username'),
                              onDeleted: () => setState(() {
                                final uId = (m['user_id'] ?? m['id'] ?? '').toString();
                                _selectedMentions.removeWhere((item) => (item['user_id'] ?? item['id']).toString() == uId);
                                _selectedMentionIds.remove(uId);
                              }),
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              labelStyle: TextStyle(color: colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.bold),
                            );
                          }).toList(),
                        ),
                      ),

                    // Poll Preview Card
                    if (_pollData != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.poll_rounded, color: colorScheme.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Sondage (${_pollData!['kind']})', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                                    Text('${(_pollData!['options'] as List).length} options', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => setState(() => _pollData = null),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Media Preview Grid
                    if (_selectedFiles.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _selectedFiles.length == 1 ? 1 : 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: _selectedFiles.length == 1 ? 1.6 : 1.2,
                          ),
                          itemCount: _selectedFiles.length > 4 ? 4 : _selectedFiles.length,
                          itemBuilder: (context, index) {
                            final file = _selectedFiles[index];
                            final isLastVisible = (index == 3 && _selectedFiles.length > 4);
                            final remainingCount = _selectedFiles.length - 4;
                            final isVid = _isVideo(file);

                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: _MediaThumbnailPreview(file: file),
                                ),
                                if (isLastVisible)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '+$remainingCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedFiles.removeAt(index)),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                                if (isVid)
                                  Positioned(
                                    top: 6,
                                    left: 6,
                                    child: Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () => Get.to(() => VideoFullScreenViewer(videoFile: file)),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 16),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () async {
                                            final trimmed = await Get.to<File>(() => VideoTrimScreen(videoFile: file));
                                            if (trimmed != null && mounted) {
                                              setState(() {
                                                _selectedFiles[index] = trimmed;
                                              });
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.content_cut_rounded, color: Colors.white, size: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      )
                    else if (_prefilledUrl != null && _prefilledUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _prefilledUrl!.startsWith('http')
                                  ? AppCachedImage(imageUrl: _prefilledUrl!, width: double.infinity, height: 280, fit: BoxFit.cover)
                                  : Image.file(File(_prefilledUrl!), width: double.infinity, height: 280, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton.filled(
                                onPressed: () => setState(() => _prefilledUrl = null),
                                icon: const Icon(Icons.close),
                                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom action bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    onPressed: _openGallery,
                    icon: Icon(Icons.camera_alt_rounded, color: colorScheme.onSurface, size: 24),
                    tooltip: 'Média',
                  ),
                  IconButton(
                    onPressed: _openPollCreator,
                    icon: Icon(Icons.poll_rounded, color: _pollData != null ? colorScheme.primary : colorScheme.onSurface, size: 24),
                    tooltip: 'Sondage',
                  ),
                  IconButton(
                    onPressed: () async {
                      final result = await Get.to<List<CommunityHashtag>>(() => CommunityPostHashtagSelectionScreen(
                        initialSelected: _selectedHashtags,
                      ));
                      if (result != null) {
                        setState(() {
                          _selectedHashtags.clear();
                          _selectedHashtags.addAll(result);
                        });
                      }
                    },
                    icon: Icon(Icons.tag_rounded, color: _selectedHashtags.isNotEmpty ? colorScheme.primary : colorScheme.onSurface, size: 24),
                    tooltip: 'Hashtags',
                  ),
                  IconButton(
                    onPressed: _openMentions,
                    icon: Icon(Icons.alternate_email_rounded, color: _selectedMentions.isNotEmpty ? colorScheme.primary : colorScheme.onSurface, size: 24),
                    tooltip: 'Mentions',
                  ),
                  IconButton(
                    onPressed: () async {
                      final result = await Get.to<Map<String, dynamic>>(() => CommunityPostSettingsScreen(
                        initialCommentsEnabled: _commentsEnabled,
                        initialSharingEnabled: _sharingEnabled,
                      ));
                      if (result != null) {
                        setState(() {
                          _commentsEnabled = result['commentsEnabled'] ?? true;
                          _sharingEnabled = result['sharingEnabled'] ?? true;
                        });
                      }
                    },
                    icon: Icon(Icons.settings_outlined, color: colorScheme.onSurface, size: 24),
                    tooltip: 'Paramètres',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaThumbnailPreview extends StatefulWidget {
  final File file;
  const _MediaThumbnailPreview({required this.file});

  @override
  State<_MediaThumbnailPreview> createState() => _MediaThumbnailPreviewState();
}

class _MediaThumbnailPreviewState extends State<_MediaThumbnailPreview> {
  File? _thumbFile;
  bool _isLoading = false;
  VideoPlayerController? _videoController;
  bool _isPlaying = false;
  bool _isVideoInitialized = false;

  bool get _isVideo {
    final ext = widget.file.path.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'].contains(ext);
  }

  @override
  void initState() {
    super.initState();
    if (_isVideo) {
      _loadThumb();
    }
  }

  Future<void> _loadThumb() async {
    setState(() => _isLoading = true);
    try {
      final thumb = await VideoCompress.getFileThumbnail(
        widget.file.path,
        quality: 50,
        position: -1,
      );
      if (mounted) {
        setState(() {
          _thumbFile = thumb;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _initVideoPlayer() async {
    if (_videoController != null) return;
    try {
      _videoController = VideoPlayerController.file(widget.file);
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      if (mounted) {
        setState(() => _isVideoInitialized = true);
        _videoController!.play();
        _isPlaying = true;
      }
    } catch (e) {
      debugPrint('[MediaThumbnailPreview] video init error: $e');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (!_isVideoInitialized) {
      _initVideoPlayer();
      return;
    }
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isPlaying = false;
      } else {
        _videoController!.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideo) {
      if (_isVideoInitialized && _videoController != null) {
        return GestureDetector(
          onTap: _togglePlay,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
              if (!_isPlaying)
                const Center(
                  child: Icon(Icons.play_circle_fill_rounded, color: Colors.white70, size: 48),
                ),
            ],
          ),
        );
      }

      return GestureDetector(
        onTap: _togglePlay,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _thumbFile != null
                ? Image.file(_thumbFile!, width: double.infinity, height: double.infinity, fit: BoxFit.cover)
                : Container(color: Colors.black12),
            const Center(
              child: Icon(Icons.play_circle_fill_rounded, color: Colors.white70, size: 48),
            ),
            if (_isLoading)
              const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
          ],
        ),
      );
    }
    return Image.file(widget.file, width: double.infinity, height: double.infinity, fit: BoxFit.cover);
  }
}
