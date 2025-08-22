import 'dart:async';
import 'package:flutter/foundation.dart';

import 'models/compression_options.dart';
import 'models/compression_result.dart';
import 'models/media_file.dart';
import 'services/platform_channel_service.dart';

export 'models/compression_options.dart';
export 'models/compression_result.dart';
export 'models/media_file.dart';
export 'services/platform_channel_service.dart';

/// Flutter Video Compressor Plugin
///
/// A Flutter plugin that provides video, image, and audio compression capabilities
/// using native compression algorithms from the React Native Compressor library.
class FlutterVideoCompressor {
  /// Compress a single media file
  static Future<CompressionResult> compressMedia(
    MediaFile file,
    CompressionOptions options, {
    ProgressCallback? onProgress,
    String? compressionId,
  }) async {
    try {
      final result = await PlatformChannelService.compressMedia(
        file,
        options,
        onProgress: onProgress,
        compressionId: compressionId,
      );
      return result;
    } catch (e) {
      return CompressionResult(
        originalFile: file,
        compressedFile: file,
        compressionRatio: 0,
        compressionTime: Duration.zero,
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Compress multiple media files in batch
  static Future<List<CompressionResult>> compressBatch(
    List<MediaFile> files,
    CompressionOptions options, {
    ProgressCallback? onProgress,
  }) async {
    final results = <CompressionResult>[];
    final totalFiles = files.length;

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final fileProgress = (i / totalFiles) * 100;

      final result = await compressMedia(
        file,
        options,
        onProgress: onProgress != null
            ? (progress) => onProgress(fileProgress + (progress / totalFiles))
            : null,
        compressionId: '${DateTime.now().millisecondsSinceEpoch}_$i',
      );

      results.add(result);

      if (kDebugMode) {
        print('Failed to compress ${file.name}: ${result.errorMessage}');
      }
    }

    return results;
  }

  /// Cancel an ongoing compression
  static Future<bool> cancelCompression(String compressionId) async {
    try {
      return await PlatformChannelService.cancelCompression(compressionId);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to cancel compression: $e');
      }
      return false;
    }
  }

  /// Get metadata for a media file
  static Future<MediaFile?> getMetadata(String filePath, MediaType type) async {
    try {
      return await PlatformChannelService.getMetadata(filePath, type);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get metadata: $e');
      }
      return null;
    }
  }

  /// Create a video thumbnail
  static Future<String?> createVideoThumbnail(
    String videoPath, {
    int timeUs = 0,
    int maxWidth = 320,
    int maxHeight = 320,
  }) async {
    try {
      return await PlatformChannelService.createVideoThumbnail(
        videoPath,
        timeUs: timeUs,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to create thumbnail: $e');
      }
      return null;
    }
  }

  /// Get the real file path from a content URI
  static Future<String?> getRealPath(String path, String type) async {
    try {
      return await PlatformChannelService.getRealPath(path, type);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get real path: $e');
      }
      return null;
    }
  }

  /// Clear compression cache
  static Future<bool> clearCache() async {
    try {
      return await PlatformChannelService.clearCache();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to clear cache: $e');
      }
      return false;
    }
  }
}

/// Progress callback type
typedef ProgressCallback = void Function(double progress);
