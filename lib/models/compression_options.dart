/// Base compression options
class CompressionOptions {
  final String? outputFormat;
  final bool keepMetadata;
  final Map<String, dynamic>? customOptions;

  const CompressionOptions({
    this.outputFormat,
    this.keepMetadata = true,
    this.customOptions,
  });

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'outputFormat': outputFormat,
      'keepMetadata': keepMetadata,
      'customOptions': customOptions,
    };
  }

  /// Create a copy with updated values
  CompressionOptions copyWith({
    String? outputFormat,
    bool? keepMetadata,
    Map<String, dynamic>? customOptions,
  }) {
    return CompressionOptions(
      outputFormat: outputFormat ?? this.outputFormat,
      keepMetadata: keepMetadata ?? this.keepMetadata,
      customOptions: customOptions ?? this.customOptions,
    );
  }
}

/// Video compression options
class VideoCompressionOptions extends CompressionOptions {
  final String quality;
  final int? maxWidth;
  final int? maxHeight;
  final int? bitrate;
  final String? videoCodec;
  final String? audioCodec;
  final double? frameRate;
  final bool progressive;

  const VideoCompressionOptions({
    super.outputFormat,
    super.keepMetadata,
    super.customOptions,
    this.quality = 'medium',
    this.maxWidth,
    this.maxHeight,
    this.bitrate,
    this.videoCodec,
    this.audioCodec,
    this.frameRate,
    this.progressive = false,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'quality': quality,
      'maxWidth': maxWidth,
      'maxHeight': maxHeight,
      'bitrate': bitrate,
      'videoCodec': videoCodec,
      'audioCodec': audioCodec,
      'frameRate': frameRate,
      'progressive': progressive,
    };
  }

  @override
  VideoCompressionOptions copyWith({
    String? outputFormat,
    bool? keepMetadata,
    Map<String, dynamic>? customOptions,
    String? quality,
    int? maxWidth,
    int? maxHeight,
    int? bitrate,
    String? videoCodec,
    String? audioCodec,
    double? frameRate,
    bool? progressive,
  }) {
    return VideoCompressionOptions(
      outputFormat: outputFormat ?? this.outputFormat,
      keepMetadata: keepMetadata ?? this.keepMetadata,
      customOptions: customOptions ?? this.customOptions,
      quality: quality ?? this.quality,
      maxWidth: maxWidth ?? this.maxWidth,
      maxHeight: maxHeight ?? this.maxHeight,
      bitrate: bitrate ?? this.bitrate,
      videoCodec: videoCodec ?? this.videoCodec,
      audioCodec: audioCodec ?? this.audioCodec,
      frameRate: frameRate ?? this.frameRate,
      progressive: progressive ?? this.progressive,
    );
  }
}

/// Image compression options
class ImageCompressionOptions extends CompressionOptions {
  final int quality;
  final int? maxWidth;
  final int? maxHeight;
  final bool progressive;
  final bool stripMetadata;
  final String? format;

  const ImageCompressionOptions({
    super.outputFormat,
    super.keepMetadata,
    super.customOptions,
    this.quality = 80,
    this.maxWidth,
    this.maxHeight,
    this.progressive = false,
    this.stripMetadata = false,
    this.format,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'quality': quality,
      'maxWidth': maxWidth,
      'maxHeight': maxHeight,
      'progressive': progressive,
      'stripMetadata': stripMetadata,
      'format': format,
    };
  }

  @override
  ImageCompressionOptions copyWith({
    String? outputFormat,
    bool? keepMetadata,
    Map<String, dynamic>? customOptions,
    int? quality,
    int? maxWidth,
    int? maxHeight,
    bool? progressive,
    bool? stripMetadata,
    String? format,
  }) {
    return ImageCompressionOptions(
      outputFormat: outputFormat ?? this.outputFormat,
      keepMetadata: keepMetadata ?? this.keepMetadata,
      customOptions: customOptions ?? this.customOptions,
      quality: quality ?? this.quality,
      maxWidth: maxWidth ?? this.maxWidth,
      maxHeight: maxHeight ?? this.maxHeight,
      progressive: progressive ?? this.progressive,
      stripMetadata: stripMetadata ?? this.stripMetadata,
      format: format ?? this.format,
    );
  }
}

/// Audio compression options
class AudioCompressionOptions {
  final int quality;
  final String? outputFormat;
  final bool keepMetadata;
  final Map<String, dynamic>? customOptions;
  final int? sampleRate;
  final int? channels;
  final String? audioCodec;
  final int? bitrate;

  const AudioCompressionOptions({
    this.quality = 80,
    this.outputFormat,
    this.keepMetadata = true,
    this.customOptions,
    this.sampleRate,
    this.channels,
    this.audioCodec,
    this.bitrate,
  });

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'quality': quality,
      'outputFormat': outputFormat,
      'keepMetadata': keepMetadata,
      'customOptions': customOptions,
      'sampleRate': sampleRate,
      'channels': channels,
      'audioCodec': audioCodec,
      'bitrate': bitrate,
    };
  }

  /// Create a copy with updated values
  AudioCompressionOptions copyWith({
    int? quality,
    String? outputFormat,
    bool? keepMetadata,
    Map<String, dynamic>? customOptions,
    int? sampleRate,
    int? channels,
    String? audioCodec,
    int? bitrate,
  }) {
    return AudioCompressionOptions(
      quality: quality ?? this.quality,
      outputFormat: outputFormat ?? this.outputFormat,
      keepMetadata: keepMetadata ?? this.keepMetadata,
      customOptions: customOptions ?? this.customOptions,
      sampleRate: sampleRate ?? this.sampleRate,
      channels: channels ?? this.channels,
      audioCodec: audioCodec ?? this.audioCodec,
      bitrate: bitrate ?? this.bitrate,
    );
  }
}
