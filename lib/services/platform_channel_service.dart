import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../models/compression_options.dart';
import '../models/compression_result.dart';
import '../models/media_file.dart';

/// Service for communicating with native compression code via platform channels
class PlatformChannelService {
  static const MethodChannel _channel =
      MethodChannel('flutter_video_compressor');
  static const EventChannel _eventChannel =
      EventChannel('flutter_video_compressor/progress');

  /// Compress a media file
  static Future<CompressionResult> compressMedia(
    MediaFile file,
    CompressionOptions options, {
    ProgressCallback? onProgress,
    String? compressionId,
  }) async {
    final stopwatch = Stopwatch()..start();
    String compressedPath;
    MediaFile compressedFile;

    try {
      // Set up progress listener if callback provided
      if (onProgress != null) {
        _eventChannel.receiveBroadcastStream().listen(
          (dynamic event) {
            if (event is Map<String, dynamic> &&
                event['compressionId'] == compressionId) {
              final progress = (event['progress'] as num).toDouble();
              onProgress(progress);
            }
          },
        );
      }

      switch (file.type) {
        case MediaType.video:
          final videoOptions = options is VideoCompressionOptions
              ? options
              : VideoCompressionOptions(
                  outputFormat: options.outputFormat,
                  keepMetadata: options.keepMetadata,
                  customOptions: options.customOptions,
                );

          compressedPath = await compressVideo(
            videoPath: file.path,
            options: videoOptions,
            compressionId: compressionId,
          );
          compressedFile =
              await _createMediaFileFromPath(compressedPath, MediaType.video);
          break;

        case MediaType.image:
          final imageOptions = options is ImageCompressionOptions
              ? options
              : ImageCompressionOptions(
                  outputFormat: options.outputFormat,
                  keepMetadata: options.keepMetadata,
                  customOptions: options.customOptions,
                );

          compressedPath = await compressImage(
            imagePath: file.path,
            options: imageOptions,
          );
          compressedFile =
              await _createMediaFileFromPath(compressedPath, MediaType.image);
          break;

        case MediaType.audio:
          final audioOptions = options is AudioCompressionOptions
              ? options
              : AudioCompressionOptions(
                  quality: 80, // Default medium quality
                  outputFormat: options.outputFormat ?? 'mp3',
                  keepMetadata: options.keepMetadata,
                  customOptions: options.customOptions,
                );

          compressedPath = await compressAudio(
            audioPath: file.path,
            options: audioOptions as AudioCompressionOptions,
          );
          compressedFile =
              await _createMediaFileFromPath(compressedPath, MediaType.audio);
          break;
      }

      stopwatch.stop();

      // Calculate compression result
      final originalSize = file.size;
      final compressedSize = compressedFile.size;
      final compressionRatio =
          ((originalSize - compressedSize) / originalSize) * 100;

      return CompressionResult(
        originalFile: file,
        compressedFile: compressedFile,
        compressionRatio: compressionRatio,
        compressionTime: stopwatch.elapsed,
        isSuccess: true,
      );
    } catch (e) {
      stopwatch.stop();

      return CompressionResult(
        originalFile: file,
        compressedFile: file, // Use original file on error
        compressionRatio: 0,
        compressionTime: stopwatch.elapsed,
        isSuccess: false,
        errorMessage: e.toString(),
      );
    } finally {
      // Clean up progress subscription
      // Note: In a real implementation, you'd want to store and manage these subscriptions
    }
  }

  /// Compress video
  static Future<String> compressVideo({
    required String videoPath,
    required VideoCompressionOptions options,
    String? compressionId,
  }) async {
    final result = await _channel.invokeMethod('compressVideo', {
      'videoPath': videoPath,
      'options': options.toMap(),
      'compressionId': compressionId,
    });

    if (result is String) {
      return result;
    } else {
      throw Exception('Invalid response from native code: $result');
    }
  }

  /// Compress image
  static Future<String> compressImage({
    required String imagePath,
    required ImageCompressionOptions options,
  }) async {
    final result = await _channel.invokeMethod('compressImage', {
      'imagePath': imagePath,
      'options': options.toMap(),
    });

    if (result is String) {
      return result;
    } else {
      throw Exception('Invalid response from native code: $result');
    }
  }

  /// Compress audio
  static Future<String> compressAudio({
    required String audioPath,
    required AudioCompressionOptions options,
  }) async {
    final result = await _channel.invokeMethod('compressAudio', {
      'audioPath': audioPath,
      'options': options.toMap(),
    });

    if (result is String) {
      return result;
    } else {
      throw Exception('Invalid response from native code: $result');
    }
  }

  /// Cancel compression
  static Future<bool> cancelCompression(String compressionId) async {
    final result = await _channel.invokeMethod('cancelCompression', {
      'compressionId': compressionId,
    });

    return result is bool ? result : false;
  }

  /// Get metadata for a media file
  static Future<MediaFile?> getMetadata(String filePath, MediaType type) async {
    try {
      final result = await _channel.invokeMethod('getMetadata', {
        'filePath': filePath,
        'type': type.name,
      });

      if (result is Map<String, dynamic>) {
        return MediaFile.fromMetadata(result);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Create video thumbnail
  static Future<String?> createVideoThumbnail(
    String videoPath, {
    int timeUs = 0,
    int maxWidth = 320,
    int maxHeight = 320,
  }) async {
    try {
      final result = await _channel.invokeMethod('createVideoThumbnail', {
        'videoPath': videoPath,
        'timeUs': timeUs,
        'maxWidth': maxWidth,
        'maxHeight': maxHeight,
      });

      return result is String ? result : null;
    } catch (e) {
      return null;
    }
  }

  /// Get real file path from content URI
  static Future<String?> getRealPath(String path, String type) async {
    try {
      final result = await _channel.invokeMethod('getRealPath', {
        'path': path,
        'type': type,
      });

      return result is String ? result : null;
    } catch (e) {
      return null;
    }
  }

  /// Clear compression cache
  static Future<bool> clearCache() async {
    try {
      final result = await _channel.invokeMethod('clearCache');
      return result is bool ? result : false;
    } catch (e) {
      return false;
    }
  }

  /// Create MediaFile from compressed file path
  static Future<MediaFile> _createMediaFileFromPath(
      String filePath, MediaType type) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Compressed file not found: $filePath');
    }

    final stat = await file.stat();
    final fileName = filePath.split('/').last;

    return MediaFile(
      path: filePath,
      name: fileName,
      type: type,
      size: stat.size,
      creationDate: stat.modified,
    );
  }
}

/// Progress callback type
typedef ProgressCallback = void Function(double progress);
