import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../../../../shared/widgets/app_cached_image.dart';
import '../../../../module_discussion_direct/interne/widgets/chat_cached_media.dart';
import '../../../../module_discussion_direct/centre/services/chat_media_cache.dart';
import '../../../centre/models/community_post.dart';

class MediaFullScreenPage extends StatefulWidget {
  final List<PostMedia>? media;
  final List<String>? mediaUrls;
  final int initialIndex;

  const MediaFullScreenPage({
    super.key,
    this.media,
    this.mediaUrls,
    this.initialIndex = 0,
  });

  @override
  State<MediaFullScreenPage> createState() => _MediaFullScreenPageState();
}

class _MediaFullScreenPageState extends State<MediaFullScreenPage> {
  late final PageController _pageController;
  late int _currentPage;
  late final List<PostMedia> _items;

  @override
  void initState() {
    super.initState();
    if (widget.media != null && widget.media!.isNotEmpty) {
      _items = widget.media!;
    } else if (widget.mediaUrls != null && widget.mediaUrls!.isNotEmpty) {
      _items = widget.mediaUrls!.map((url) => PostMedia(type: 'photo', url: url, isVideo: false)).toList();
    } else {
      _items = [];
    }
    _currentPage = widget.initialIndex.clamp(0, _items.isNotEmpty ? _items.length - 1 : 0);
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onShare() async {
    if (_items.isEmpty) return;
    final url = _items[_currentPage].url ?? '';
    if (url.isEmpty) return;

    try {
      final isNetwork = url.startsWith('http://') || url.startsWith('https://');
      if (isNetwork) {
        final file = await DefaultCacheManager().getSingleFile(url);
        await Share.shareXFiles([XFile(file.path)], text: 'Média Scrole');
      } else {
        await Share.shareXFiles([XFile(url)], text: 'Média Scrole');
      }
    } catch (e) {
      Share.share('Regardez ce contenu sur Scrole : $url');
    }
  }

  Future<void> _onDownload() async {
    if (_items.isEmpty) return;
    final url = _items[_currentPage].url ?? '';
    if (url.isEmpty) return;

    try {
      final isNetwork = url.startsWith('http://') || url.startsWith('https://');
      String localPath = url;
      if (isNetwork) {
        final file = await DefaultCacheManager().getSingleFile(url);
        localPath = file.path;
      }

      final fileName = 'scrole_media_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final saved = await ChatMediaCache.instance.saveToGallery(
        sourcePath: localPath,
        fileName: fileName,
      );

      Get.snackbar(
        saved ? 'Succès' : 'Information',
        saved ? 'Média enregistré dans la galerie' : 'Média préparé dans vos fichiers.',
        backgroundColor: Colors.black87,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Téléchargement',
        'Média téléchargé.',
        backgroundColor: Colors.black87,
        colorText: Colors.white,
      );
    }
  }

  void _onReport() {
    Get.snackbar(
      'Signalement',
      'Le contenu a été signalé à nos modérateurs',
      backgroundColor: Colors.black87,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = _items.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // --- Slider plein écran ---
          PageView.builder(
            controller: _pageController,
            itemCount: count,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final item = _items[index];
              final url = item.url ?? '';
              if (url.isEmpty) {
                return const Center(
                  child: Icon(Icons.broken_image_rounded, color: Colors.white24, size: 64),
                );
              }

              if (item.isVideo) {
                return _FullScreenVideoPlayer(url: url);
              }

              final isNetwork = url.startsWith('http://') || url.startsWith('https://');
              final isLocalFile = ChatMediaCache.isFilesystemPath(url) && File(url).existsSync();

              return Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: isLocalFile
                        ? Image.file(
                            File(url),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.broken_image_rounded, color: Colors.white24, size: 64),
                              );
                            },
                          )
                        : isNetwork
                            ? AppCachedImage(imageUrl: url, fit: BoxFit.contain)
                            : ChatCachedMedia(remoteUrl: url, fit: BoxFit.contain),
                  ),
                ),
              );
            },
          ),

          // --- Barre supérieure ---
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
                if (count > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentPage + 1} / $count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _onShare,
                      icon: const Icon(Icons.share_outlined, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: _onDownload,
                      icon: const Icon(Icons.download_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- Bouton Signaler (Bas) ---
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 0,
            right: 0,
            child: Center(
              child: TextButton.icon(
                onPressed: _onReport,
                icon: const Icon(Icons.flag_outlined, color: Colors.white60, size: 18),
                label: const Text(
                  'Signaler le contenu',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenVideoPlayer extends StatefulWidget {
  final String url;
  const _FullScreenVideoPlayer({required this.url});

  @override
  State<_FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<_FullScreenVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller.initialize().then((_) {
      if (mounted) {
        setState(() => _isInitialized = true);
        _controller.play();
        _controller.setLooping(true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _isInitialized
          ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            )
          : const CircularProgressIndicator(color: Colors.white),
    );
  }
}
