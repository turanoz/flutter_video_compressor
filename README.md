# Flutter Video Compressor

A Flutter plugin that provides video, image, and audio compression capabilities using native compression algorithms from the React Native Compressor library.

## Features

- 🎥 **Video Compression**: Compress videos with quality control and format options
- 🖼️ **Image Compression**: Compress images with size and quality settings
- 🎵 **Audio Compression**: Compress audio files with quality control
- 📱 **Native Performance**: Uses native compression algorithms for optimal performance
- 🔄 **Progress Tracking**: Real-time compression progress updates
- 📊 **Metadata Support**: Extract and preserve media metadata
- 🎬 **Thumbnail Generation**: Create video thumbnails
- 💾 **Cache Management**: Built-in cache management system

## Getting Started

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_video_compressor: ^1.0.0
```

### Import

```dart
import 'package:flutter_video_compressor/flutter_video_compressor.dart';
```

## Usage

### Basic Compression

```dart
// Compress a video file
final result = await FlutterVideoCompressor.compressMedia(
  mediaFile,
  VideoCompressionOptions(
    quality: 'medium',
    maxWidth: 1280,
    maxHeight: 720,
    outputFormat: 'mp4',
  ),
  onProgress: (progress) {
    print('Compression progress: ${progress.toStringAsFixed(1)}%');
  },
);

if (result.isSuccess) {
  print('Compression completed!');
  print('Original size: ${(result.originalFile.size / 1024 / 1024).toStringAsFixed(2)} MB');
  print('Compressed size: ${(result.compressedFile.size / 1024 / 1024).toStringAsFixed(2)} MB');
  print('Compression ratio: ${result.compressionRatio.toStringAsFixed(1)}%');
}
```

### Batch Compression

```dart
// Compress multiple files
final results = await FlutterVideoCompressor.compressBatch(
  mediaFiles,
  VideoCompressionOptions(quality: 'high'),
  onProgress: (progress) {
    print('Batch progress: ${progress.toStringAsFixed(1)}%');
  },
);
```

### Image Compression

```dart
final result = await FlutterVideoCompressor.compressMedia(
  imageFile,
  ImageCompressionOptions(
    quality: 80,
    maxWidth: 1920,
    maxHeight: 1080,
    outputFormat: 'jpg',
  ),
);
```

### Audio Compression

```dart
final result = await FlutterVideoCompressor.compressMedia(
  audioFile,
  AudioCompressionOptions(
    quality: 80,
    outputFormat: 'mp3',
  ),
);
```

### Metadata and Utilities

```dart
// Get file metadata
final metadata = await FlutterVideoCompressor.getMetadata(filePath, MediaType.video);

// Create video thumbnail
final thumbnailPath = await FlutterVideoCompressor.createVideoThumbnail(
  videoPath,
  timeUs: 0,
  maxWidth: 320,
  maxHeight: 320,
);

// Clear cache
await FlutterVideoCompressor.clearCache();
```

## API Reference

### Classes

- `MediaFile`: Represents a media file with metadata
- `CompressionOptions`: Base class for compression options
- `VideoCompressionOptions`: Video-specific compression options
- `ImageCompressionOptions`: Image-specific compression options
- `AudioCompressionOptions`: Audio-specific compression options
- `CompressionResult`: Result of a compression operation

### Methods

- `compressMedia()`: Compress a single media file
- `compressBatch()`: Compress multiple media files
- `cancelCompression()`: Cancel an ongoing compression
- `getMetadata()`: Get metadata for a media file
- `createVideoThumbnail()`: Create a video thumbnail
- `getRealPath()`: Get the real file path
- `clearCache()`: Clear compression cache

## Platform Support

- ✅ **Android**: API level 21+ (Android 5.0+)
- ✅ **iOS**: iOS 12.0+
- ❌ **Web**: Not supported (requires native code)
- ❌ **Desktop**: Not supported (requires native code)

## Requirements

### Android
- Minimum SDK: 21
- Permissions: `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`

### iOS
- Minimum iOS version: 12.0
- Permissions: Photo Library access

## Example

Check out the [example app](example/) for a complete working example.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Credits

This plugin wraps the native compression algorithms from the [React Native Compressor](https://github.com/ShivamJoker/React-Native-Compressor) library.

## Issues and Feedback

Please file issues and feature requests on the [GitHub repository](https://github.com/turanoz/flutter_video_compressor).

