import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Manages image caching and optimization for receipt photos
class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._internal();
  factory ImageCacheManager() => _instance;
  ImageCacheManager._internal();

  final Map<String, Uint8List> _memoryCache = {};
  static const int _maxMemoryCacheSize = 50 * 1024 * 1024; // 50MB
  int _currentMemoryCacheSize = 0;

  /// Gets the cache directory
  Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/image_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Generates a cache key from image ID
  String _getCacheKey(String imageId) {
    final bytes = utf8.encode(imageId);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Gets cached image file path
  Future<File> _getCacheFile(String imageId) async {
    final cacheDir = await _getCacheDirectory();
    final cacheKey = _getCacheKey(imageId);
    return File('${cacheDir.path}/$cacheKey.jpg');
  }

  /// Loads image from cache (memory or disk)
  Future<Uint8List?> loadImage(String imageId) async {
    // Check memory cache first
    if (_memoryCache.containsKey(imageId)) {
      return _memoryCache[imageId];
    }

    // Check disk cache
    final cacheFile = await _getCacheFile(imageId);
    if (await cacheFile.exists()) {
      final bytes = await cacheFile.readAsBytes();
      _addToMemoryCache(imageId, bytes);
      return bytes;
    }

    return null;
  }

  /// Saves image to cache
  Future<void> saveImage(String imageId, Uint8List imageData) async {
    // Save to disk cache
    final cacheFile = await _getCacheFile(imageId);
    await cacheFile.writeAsBytes(imageData);

    // Add to memory cache
    _addToMemoryCache(imageId, imageData);
  }

  /// Adds image to memory cache with size management
  void _addToMemoryCache(String imageId, Uint8List imageData) {
    final imageSize = imageData.length;

    // Remove old entries if cache is full
    while (_currentMemoryCacheSize + imageSize > _maxMemoryCacheSize &&
        _memoryCache.isNotEmpty) {
      final firstKey = _memoryCache.keys.first;
      final removedSize = _memoryCache[firstKey]!.length;
      _memoryCache.remove(firstKey);
      _currentMemoryCacheSize -= removedSize;
    }

    // Add new entry
    _memoryCache[imageId] = imageData;
    _currentMemoryCacheSize += imageSize;
  }

  /// Removes image from cache
  Future<void> removeImage(String imageId) async {
    // Remove from memory cache
    if (_memoryCache.containsKey(imageId)) {
      _currentMemoryCacheSize -= _memoryCache[imageId]!.length;
      _memoryCache.remove(imageId);
    }

    // Remove from disk cache
    final cacheFile = await _getCacheFile(imageId);
    if (await cacheFile.exists()) {
      await cacheFile.delete();
    }
  }

  /// Clears all cached images
  Future<void> clearCache() async {
    // Clear memory cache
    _memoryCache.clear();
    _currentMemoryCacheSize = 0;

    // Clear disk cache
    final cacheDir = await _getCacheDirectory();
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
    }
  }

  /// Gets total cache size in bytes
  Future<int> getCacheSize() async {
    int totalSize = 0;
    final cacheDir = await _getCacheDirectory();
    
    if (await cacheDir.exists()) {
      await for (final entity in cacheDir.list()) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    }
    
    return totalSize;
  }

  /// Compresses image to reduce size
  static Future<Uint8List> compressImage(
    Uint8List imageData, {
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 85,
  }) async {
    // Note: In a real implementation, you would use image compression library
    // like flutter_image_compress. For now, return original data.
    // This is a placeholder for the compression logic.
    return imageData;
  }
}

/// Cached image widget with optimized loading
class CachedReceiptImage extends StatefulWidget {
  final String imageId;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedReceiptImage({
    super.key,
    required this.imageId,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<CachedReceiptImage> createState() => _CachedReceiptImageState();
}

class _CachedReceiptImageState extends State<CachedReceiptImage> {
  Uint8List? _imageData;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final imageData = await ImageCacheManager().loadImage(widget.imageId);
      
      if (mounted) {
        setState(() {
          _imageData = imageData;
          _isLoading = false;
          _hasError = imageData == null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ??
          SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
    }

    if (_hasError || _imageData == null) {
      return widget.errorWidget ??
          SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(
              child: Icon(Icons.error_outline, color: Colors.red),
            ),
          );
    }

    return Image.memory(
      _imageData!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }
}
