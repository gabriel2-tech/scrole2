import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../../app/theme/text_styles.dart';
import 'video_trim_screen.dart';

class MediaGallerySheet extends StatefulWidget {
  const MediaGallerySheet({
    super.key,
    required this.onSelected,
    this.maxSelection = 15,
    this.allowVideos = true,
  });

  final Function(List<XFile>) onSelected;
  final int maxSelection;
  final bool allowVideos;

  @override
  State<MediaGallerySheet> createState() => _MediaGallerySheetState();
}

class _MediaGallerySheetState extends State<MediaGallerySheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<AssetEntity> _allAssets = [];
  final List<AssetEntity> _selectedAssets = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 60;
  
  bool _isOpeningMedia = false;
  AssetPathEntity? _currentPath;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.allowVideos ? 3 : 1, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _requestAssets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _requestAssets() async {
    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (ps.isAuth || ps == PermissionState.limited) {
        final paths = await PhotoManager.getAssetPathList(
          type: widget.allowVideos ? RequestType.common : RequestType.image,
          onlyAll: true,
          filterOption: FilterOptionGroup(
            containsLivePhotos: false,
            orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
          ),
        );

        if (paths.isNotEmpty) {
          _currentPath = paths.first;
          _currentPage = 0;
          final entities = await _currentPath!.getAssetListPaged(page: _currentPage, size: _pageSize);
          
          if (mounted) {
            setState(() {
              _allAssets.clear();
              _allAssets.addAll(entities);
              _hasMore = entities.length == _pageSize;
              _isLoading = false;
            });
          }
        } else if (mounted) {
          setState(() => _isLoading = false);
        }
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Erreur Galerie: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreAssets() async {
    if (_isLoadingMore || !_hasMore || _currentPath == null) return;

    setState(() => _isLoadingMore = true);
    try {
      _currentPage++;
      final entities = await _currentPath!.getAssetListPaged(page: _currentPage, size: _pageSize);
      
      if (mounted) {
        setState(() {
          _allAssets.addAll(entities);
          _hasMore = entities.length == _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement suite galerie: $e');
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  List<AssetEntity> get _filteredAssets {
    if (!widget.allowVideos || _tabController.index == 0) {
      return _allAssets;
    } else if (_tabController.index == 1) {
      return _allAssets.where((a) => a.type == AssetType.image).toList();
    } else {
      return _allAssets.where((a) => a.type == AssetType.video).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filtered = _filteredAssets;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 1.0,
      expand: false,
      builder: (context, scrollController) {
        return NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
              _loadMoreAssets();
            }
            return false;
          },
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Galerie (${_selectedAssets.length}/${widget.maxSelection})', style: AppTextStyles.h5),
                      if (_selectedAssets.isNotEmpty)
                        TextButton(
                          onPressed: _isOpeningMedia ? null : _confirmSelection,
                          child: Text(
                            'Confirmer (${_selectedAssets.length})',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        )
                      else
                        IconButton(
                          onPressed: _isOpeningMedia ? null : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                    ],
                  ),
                ),
                if (widget.allowVideos) ...[
                  TabBar(
                    controller: _tabController,
                    labelColor: colorScheme.primary,
                    unselectedLabelColor: colorScheme.onSurfaceVariant,
                    indicatorColor: colorScheme.primary,
                    tabs: const [
                      Tab(text: 'TOUT'),
                      Tab(text: 'PHOTOS'),
                      Tab(text: 'VIDÉOS'),
                    ],
                  ),
                  const Divider(height: 1),
                ],
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('gallery_empty'.tr),
                                  const SizedBox(height: 16),
                                  OutlinedButton(
                                    onPressed: _requestAssets,
                                    child: Text('gallery_refresh'.tr),
                                  ),
                                  TextButton(
                                    onPressed: PhotoManager.openSetting,
                                    child: Text('gallery_permissions'.tr),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.all(1),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 2,
                                mainAxisSpacing: 2,
                              ),
                              itemCount: filtered.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index >= filtered.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  );
                                }

                                final asset = filtered[index];
                                final isSelected = _selectedAssets.contains(asset);
                                final selectionIndex = _selectedAssets.indexOf(asset);

                                return _AssetItem(
                                  asset: asset,
                                  isSelected: isSelected,
                                  selectionIndex: selectionIndex,
                                  onTap: () => _toggleSelection(asset),
                                  onLongPress: () async {
                                    if (asset.type == AssetType.video) {
                                      final file = await asset.file;
                                      if (file != null) {
                                        await Get.to<File>(() => VideoTrimScreen(videoFile: file));
                                      }
                                    }
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleSelection(AssetEntity asset) async {
    // 2 minutes max limit enforcement (120 seconds)
    if (asset.type == AssetType.video && asset.duration > 120) {
      final file = await asset.file;
      if (file != null) {
        Get.snackbar(
          'Vidéo longue (> 2 min)',
          'Veuillez rogner la vidéo pour ne garder que 2 minutes maximum.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black87,
          colorText: Colors.white,
        );
        final trimmedFile = await Get.to<File>(() => VideoTrimScreen(videoFile: file));
        if (trimmedFile != null && mounted) {
          widget.onSelected([XFile(trimmedFile.path)]);
          Navigator.of(context).pop();
        }
      }
      return;
    }

    setState(() {
      if (_selectedAssets.contains(asset)) {
        _selectedAssets.remove(asset);
      } else {
        if (_selectedAssets.length < widget.maxSelection) {
          _selectedAssets.add(asset);
        } else {
          Get.snackbar(
            'Limite atteinte',
            'Vous ne pouvez sélectionner que ${widget.maxSelection} éléments.',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    });
  }

  Future<void> _confirmSelection() async {
    if (_selectedAssets.isEmpty) return;
    setState(() => _isOpeningMedia = true);

    try {
      final List<XFile> xFiles = [];
      for (final asset in _selectedAssets) {
        final file = await asset.file;
        if (file != null) {
          xFiles.add(XFile(file.path));
        }
      }
      widget.onSelected(xFiles);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _isOpeningMedia = false);
    }
  }
}

class _AssetItem extends StatelessWidget {
  const _AssetItem({
    required this.asset,
    required this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.selectionIndex = -1,
  });

  final AssetEntity asset;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final int selectionIndex;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isVideo = asset.type == AssetType.video;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          isVideo
              ? FutureBuilder<Uint8List?>(
                  future: asset.thumbnailDataWithSize(const ThumbnailSize.square(200)),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                      return Image.memory(snapshot.data!, fit: BoxFit.cover);
                    }
                    return Container(
                      color: Colors.black12,
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                      ),
                    );
                  },
                )
              : AssetEntityImage(
                  asset,
                  isOriginal: false,
                  thumbnailSize: const ThumbnailSize.square(200),
                  fit: BoxFit.cover,
                ),
          if (isVideo)
            Positioned(
              bottom: 4,
              left: 4,
              right: 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.videocam_rounded, color: Colors.white, size: 16),
                  Text(
                    _formatDuration(Duration(seconds: asset.duration)),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          if (isSelected)
            Container(
              color: Colors.black26,
              child: Center(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '${selectionIndex + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
