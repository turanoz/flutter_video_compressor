import 'dart:io';

/// Media file types
enum MediaType {
  video,
  image,
  audio,
}

/// Represents a media file with metadata
class MediaFile {
  final String path;
  final String name;
  final MediaType type;
  final int size;
  final Duration? duration;
  final int? width;
  final int? height;
  final String? mimeType;
  final DateTime? creationDate;
  final Map<String, dynamic>? additionalMetadata;

  const MediaFile({
    required this.path,
    required this.name,
    required this.type,
    required this.size,
    this.duration,
    this.width,
    this.height,
    this.mimeType,
    this.creationDate,
    this.additionalMetadata,
  });

  /// Create MediaFile from file path
  static Future<MediaFile> fromPath(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File does not exist: $filePath');
    }

    final stat = await file.stat();
    final fileName = filePath.split('/').last;
    
    // Determine media type from file extension
    final extension = fileName.split('.').last.toLowerCase();
    MediaType mediaType;
    
    if (['mp4', 'avi', 'mov', 'mkv', 'wmv', 'flv', 'webm'].contains(extension)) {
      mediaType = MediaType.video;
    } else if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension)) {
      mediaType = MediaType.image;
    } else if (['mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a'].contains(extension)) {
      mediaType = MediaType.audio;
    } else {
      throw Exception('Unsupported file type: $extension');
    }

    return MediaFile(
      path: filePath,
      name: fileName,
      type: mediaType,
      size: stat.size,
      creationDate: stat.modified,
    );
  }

  /// Create MediaFile from metadata
  factory MediaFile.fromMetadata(Map<String, dynamic> metadata) {
    final typeString = metadata['type'] as String?;
    MediaType mediaType;
    
    switch (typeString) {
      case 'video':
        mediaType = MediaType.video;
        break;
      case 'image':
        mediaType = MediaType.image;
        break;
      case 'audio':
        mediaType = MediaType.audio;
        break;
      default:
        throw Exception('Invalid media type: $typeString');
    }

    return MediaFile(
      path: metadata['path'] as String,
      name: metadata['name'] as String,
      type: mediaType,
      size: metadata['size'] as int? ?? 0,
      duration: metadata['duration'] != null 
          ? Duration(milliseconds: (metadata['duration'] as num).round())
          : null,
      width: metadata['width'] as int?,
      height: metadata['height'] as int?,
      mimeType: metadata['mimeType'] as String?,
      creationDate: metadata['creationDate'] != null 
          ? DateTime.parse(metadata['creationDate'] as String)
          : null,
      additionalMetadata: metadata['additionalMetadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'name': name,
      'type': type.name,
      'size': size,
      'duration': duration?.inMilliseconds,
      'width': width,
      'height': height,
      'mimeType': mimeType,
      'creationDate': creationDate?.toIso8601String(),
      'additionalMetadata': additionalMetadata,
    };
  }

  /// Create a copy with updated values
  MediaFile copyWith({
    String? path,
    String? name,
    MediaType? type,
    int? size,
    Duration? duration,
    int? width,
    int? height,
    String? mimeType,
    DateTime? creationDate,
    Map<String, dynamic>? additionalMetadata,
  }) {
    return MediaFile(
      path: path ?? this.path,
      name: name ?? this.name,
      type: type ?? this.type,
      size: size ?? this.size,
      duration: duration ?? this.duration,
      width: width ?? this.width,
      height: height ?? this.height,
      mimeType: mimeType ?? this.mimeType,
      creationDate: creationDate ?? this.creationDate,
      additionalMetadata: additionalMetadata ?? this.additionalMetadata,
    );
  }

  @override
  String toString() {
    return 'MediaFile(path: $path, name: $name, type: $type, size: $size)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediaFile && other.path == path;
  }

  @override
  int get hashCode => path.hashCode;
}
