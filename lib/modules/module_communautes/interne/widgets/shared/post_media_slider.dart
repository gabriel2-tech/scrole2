import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../../../../shared/widgets/app_cached_image.dart';
import '../../../../../shared/widgets/video_full_screen_viewer.dart';
import '../../../centre/models/community_post.dart';
import '../../pages/shared/media_full_screen_page.dart';

class PostMediaSlider extends StatefulWidget {
  final List<PostMedia> media;
  final double height;

  const PostMediaSlider({
    super.key,
    required this.media,
    this.height = 340,
  });

  @override
  State<PostMediaSlider> createState() => _PostMediaSliderState();
}

class _PostMediaSliderState extends State<PostMediaSlider> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openFullScreen(int index) {
    Get.to(
      () => MediaFullScreenPage(
        media: widget.media,
        initialIndex: index,
      ),
      transition: Transition.fadeIn,
      fullscreenDialog: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.media.length;

    if (count == 0) return const SizedBox.shrink();

    // Un seul média : pas besoin de slider ni de dots.
    if (count == 1) {
      return GestureDetector(
        onTap: () => _openFullScreen(0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: _MediaTile(media: widget.media.first, height: widget.height),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: count,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => _openFullScreen(index),
                child: _MediaTile(
                  key: ValueKey('media_${widget.media[index].url}_$index'),
                  media: widget.media[index],
                  height: widget.height,
                ),
              ),
            ),

            // --- Compteur "2/15" en haut à droite ---
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_currentPage + 1}/$count',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            // --- Dots en bas, façon Instagram / Twitter ---
            if (count <= 10)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(count, (index) {
                    final isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: isActive ? 6 : 5,
                      height: isActive ? 6 : 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  final PostMedia media;
  final double height;

  const _MediaTile({super.key, required this.media, required this.height});

  @override
  Widget build(BuildContext context) {
    if (media.url != null && media.url!.isNotEmpty) {
      final url = media.url!;
      if (media.isVideo || url.toLowerCase().endsWith('.mp4') || url.toLowerCase().endsWith('.mov') || url.toLowerCase().endsWith('.avi')) {
        return _VideoTile(
          key: ValueKey('video_$url'),
          url: url,
          thumbnailUrl: media.thumbnailUrl,
          height: height,
        );
      }
      final isHttp = url.startsWith('http://') || url.startsWith('https://');
      final absolute = url.startsWith('file://') ? Uri.parse(url).toFilePath() : url;
      final isLocalFile = !isHttp && absolute.startsWith('/') && File(absolute).existsSync();
      return SizedBox(
        width: double.infinity,
        height: height,
        child: isLocalFile
            ? Image.file(File(absolute), fit: BoxFit.cover)
            : AppCachedImage(imageUrl: url, fit: BoxFit.cover),
      );
    }

    return Container(
      width: double.infinity,
      height: height,
      color: media.color,
    );
  }
}

class _VideoTile extends StatefulWidget {
  final String url;
  final String? thumbnailUrl;
  final double height;

  const _VideoTile({
    super.key,
    required this.url,
    this.thumbnailUrl,
    required this.height,
  });

  @override
  State<_VideoTile> createState() => _VideoTileState();
}

class _VideoTileState extends State<_VideoTile> {
  bool _isActivated = false;
  bool _isLoading = false;
  bool _hasError = false;
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _wasPlayingBeforeScroll = false;

  ScrollPosition? _scrollPosition;

  @override
  void initState() {
    super.initState();
    debugPrint('[VIDEO_UI] thumbnail displayed: ${widget.thumbnailUrl ?? widget.url}');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollPosition?.removeListener(_checkVisibility);
    _scrollPosition = Scrollable.maybeOf(context)?.position;
    _scrollPosition?.addListener(_checkVisibility);
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_checkVisibility);
    _scrollPosition = null;
    _disposeController();
    super.dispose();
  }

  void _disposeController() {
    if (_controller != null) {
      _controller?.pause();
      _controller?.dispose();
      _controller = null;
      debugPrint('[VIDEO_UI] controller disposed');
    }
  }

  double _calculateVisibleFraction() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return 0.0;
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);

    final screenHeight = MediaQuery.of(context).size.height;
    final widgetTop = position.dy;
    final widgetBottom = position.dy + size.height;

    if (widgetBottom <= 0 || widgetTop >= screenHeight) return 0.0;

    final visibleTop = widgetTop < 0 ? 0.0 : widgetTop;
    final visibleBottom = widgetBottom > screenHeight ? screenHeight : widgetBottom;
    final visibleHeight = visibleBottom - visibleTop;

    return (visibleHeight / size.height).clamp(0.0, 1.0);
  }

  void _checkVisibility() {
    if (!mounted || !_isActivated || _controller == null) return;
    final fraction = _calculateVisibleFraction();
    if (fraction < 0.5) {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        if (_isPlaying) {
          setState(() => _isPlaying = false);
          debugPrint('[VIDEO_UI] paused: visibility < 50%');
        }
      }
    } else {
      if (!_controller!.value.isPlaying && _wasPlayingBeforeScroll) {
        _controller!.play();
        if (!_isPlaying) {
          setState(() => _isPlaying = true);
          debugPrint('[VIDEO_UI] playing (resumed by visibility >= 50%)');
        }
      }
    }
  }

  Future<void> _activateVideo() async {
    if (_isLoading || _isActivated) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    debugPrint('[VIDEO_UI] video url: ${widget.url}');
    debugPrint('[VIDEO_UI] thumbnail url: ${widget.thumbnailUrl}');
    debugPrint('[VIDEO_UI] creating controller');
    debugPrint('[VIDEO_UI] initializing controller');

    try {
      final isHttp = widget.url.startsWith('http://') || widget.url.startsWith('https://');
      if (isHttp) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      } else {
        final absolute = widget.url.startsWith('file://') ? Uri.parse(widget.url).toFilePath() : widget.url;
        _controller = VideoPlayerController.file(File(absolute));
      }

      await _controller!.initialize();
      _controller!.setLooping(true);
      debugPrint('[VIDEO_UI] controller initialized');
      debugPrint('[VIDEO_UI] duration: ${_controller!.value.duration}');
      debugPrint('[VIDEO_UI] playback started');

      if (mounted) {
        setState(() {
          _isActivated = true;
          _isLoading = false;
          _isPlaying = true;
          _wasPlayingBeforeScroll = true;
        });
        _controller!.play();
      }
    } catch (e) {
      debugPrint('[VIDEO_UI] initialization error: $e');
      _disposeController();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _isActivated = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isActivated && _controller != null && _controller!.value.isInitialized) {
      return GestureDetector(
        onTap: () {
          setState(() {
            if (_controller!.value.isPlaying) {
              _controller!.pause();
              _isPlaying = false;
              _wasPlayingBeforeScroll = false;
              debugPrint('[VIDEO_UI] paused by user tap');
            } else {
              _controller!.play();
              _isPlaying = true;
              _wasPlayingBeforeScroll = true;
              debugPrint('[VIDEO_UI] playing by user tap');
            }
          });
        },
        child: Container(
          height: widget.height,
          width: double.infinity,
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              ),
              if (!_isPlaying)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
                ),
              Positioned(
                bottom: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () {
                    Get.to(() => VideoFullScreenViewer(videoUrl: widget.url));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Thumbnail-First State
    return GestureDetector(
      onTap: _activateVideo,
      child: Container(
        height: widget.height,
        width: double.infinity,
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            if (widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty)
              AppCachedImage(imageUrl: widget.thumbnailUrl!, fit: BoxFit.cover)
            else
              AppCachedImage(imageUrl: widget.url, fit: BoxFit.cover),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            else if (_hasError)
              Container(
                color: Colors.black54,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.white70, size: 36),
                    const SizedBox(height: 8),
                    const Text('Impossible de lire la vidéo', style: TextStyle(color: Colors.white, fontSize: 12)),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: _activateVideo,
                      child: const Text('Réessayer', style: TextStyle(color: Colors.blueAccent)),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
              ),
            Positioned(
              bottom: 12,
              right: 12,
              child: GestureDetector(
                onTap: () {
                  Get.to(() => VideoFullScreenViewer(videoUrl: widget.url));
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
