import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

class CommunityVideoManager {
  static final CommunityVideoManager instance = CommunityVideoManager._();
  CommunityVideoManager._();

  final Map<String, VideoPlayerController> _activeControllers = {};
  final List<String> _activeUrlsOrder = [];
  final int maxActiveControllers = 3;

  Future<VideoPlayerController> getOrCreateController(String url) async {
    if (_activeControllers.containsKey(url)) {
      _activeUrlsOrder.remove(url);
      _activeUrlsOrder.add(url);
      debugPrint('[CommunityVideoManager] Reusing controller for URL: $url');
      return _activeControllers[url]!;
    }

    if (_activeControllers.length >= maxActiveControllers) {
      final oldestUrl = _activeUrlsOrder.removeAt(0);
      final oldController = _activeControllers.remove(oldestUrl);
      await oldController?.pause();
      await oldController?.dispose();
      debugPrint('[CommunityVideoManager] Disposed oldest controller for URL: $oldestUrl (limit reached)');
    }

    debugPrint('[CommunityVideoManager] Creating new controller for URL: $url');
    final isHttp = url.startsWith('http://') || url.startsWith('https://');
    final VideoPlayerController controller;
    if (isHttp) {
      controller = VideoPlayerController.networkUrl(Uri.parse(url));
    } else {
      final absolute = url.startsWith('file://') ? Uri.parse(url).toFilePath() : url;
      controller = VideoPlayerController.file(File(absolute));
    }

    await controller.initialize();
    controller.setLooping(true);

    _activeControllers[url] = controller;
    _activeUrlsOrder.add(url);
    debugPrint('[CommunityVideoManager] Initialized controller for URL: $url (Total active: ${_activeControllers.length})');
    return controller;
  }

  void pauseAll() {
    for (final controller in _activeControllers.values) {
      if (controller.value.isPlaying) {
        controller.pause();
      }
    }
  }

  void release(String url) {
    final controller = _activeControllers.remove(url);
    _activeUrlsOrder.remove(url);
    controller?.pause();
    controller?.dispose();
    debugPrint('[CommunityVideoManager] Released controller for URL: $url');
  }
}
