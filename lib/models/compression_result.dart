import 'media_file.dart';

/// Result of a compression operation
class CompressionResult {
  final MediaFile originalFile;
  final MediaFile compressedFile;
  final double compressionRatio;
  final Duration compressionTime;
  final bool isSuccess;
  final String? errorMessage;

  const CompressionResult({
    required this.originalFile,
    required this.compressedFile,
    required this.compressionRatio,
    required this.compressionTime,
    required this.isSuccess,
    this.errorMessage,
  });

  /// Create a copy with updated values
  CompressionResult copyWith({
    MediaFile? originalFile,
    MediaFile? compressedFile,
    double? compressionRatio,
    Duration? compressionTime,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return CompressionResult(
      originalFile: originalFile ?? this.originalFile,
      compressedFile: compressedFile ?? this.compressedFile,
      compressionRatio: compressionRatio ?? this.compressionRatio,
      compressionTime: compressionTime ?? this.compressionTime,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'originalFile': originalFile.toMap(),
      'compressedFile': compressedFile.toMap(),
      'compressionRatio': compressionRatio,
      'compressionTime': compressionTime.inMilliseconds,
      'isSuccess': isSuccess,
      'errorMessage': errorMessage,
    };
  }

  /// Create from Map
  factory CompressionResult.fromMap(Map<String, dynamic> map) {
    return CompressionResult(
      originalFile: MediaFile.fromMetadata(map['originalFile']),
      compressedFile: MediaFile.fromMetadata(map['compressedFile']),
      compressionRatio: (map['compressionRatio'] as num).toDouble(),
      compressionTime: Duration(milliseconds: map['compressionTime'] as int),
      isSuccess: map['isSuccess'] as bool,
      errorMessage: map['errorMessage'] as String?,
    );
  }

  @override
  String toString() {
    return 'CompressionResult('
        'originalFile: $originalFile, '
        'compressedFile: $compressedFile, '
        'compressionRatio: ${compressionRatio.toStringAsFixed(2)}%, '
        'compressionTime: ${compressionTime.inMilliseconds}ms, '
        'isSuccess: $isSuccess'
        '${errorMessage != null ? ', errorMessage: $errorMessage' : ''}'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CompressionResult &&
        other.originalFile == originalFile &&
        other.compressedFile == compressedFile &&
        other.compressionRatio == compressionRatio &&
        other.compressionTime == compressionTime &&
        other.isSuccess == isSuccess &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return Object.hash(
      originalFile,
      compressedFile,
      compressionRatio,
      compressionTime,
      isSuccess,
      errorMessage,
    );
  }
}
