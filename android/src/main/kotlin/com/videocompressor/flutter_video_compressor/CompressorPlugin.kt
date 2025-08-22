package com.videocompressor.flutter_video_compressor

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.media.ThumbnailUtils
import android.os.Build
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*
import java.io.File
import java.io.FileOutputStream
import java.util.*
import kotlin.collections.HashMap

/** CompressorPlugin */
class CompressorPlugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
  private lateinit var channel: MethodChannel
  private lateinit var eventChannel: EventChannel
  private lateinit var context: Context
  private var eventSink: EventChannel.EventSink? = null
  private val compressionJobs = HashMap<String, Job>()

  // Image compression options from React Native Compressor
  data class ImageCompressionOptions(
    val quality: Double = 0.8,
    val maxWidth: Int = 1280,
    val maxHeight: Int = 1280,
    val outputFormat: String = "jpg",
    val keepMetadata: Boolean = false,
    val compressionMethod: String = "auto"
  )

  // Video compression options from React Native Compressor
  data class VideoCompressionOptions(
    val quality: Double = 0.8,
    val maxWidth: Int = 640,
    val maxHeight: Int = 480,
    val outputFormat: String = "mp4",
    val keepMetadata: Boolean = false,
    val bitrate: Int? = null,
    val frameRate: Int? = null,
    val codec: String = "h264",
    val enableAudio: Boolean = true,
    val audioCodec: String = "aac",
    val compressionMethod: String = "auto"
  )

  // Audio compression options from React Native Compressor
  data class AudioCompressionOptions(
    val quality: String = "medium", // low, medium, high
    val outputFormat: String = "mp3",
    val keepMetadata: Boolean = false,
    val sampleRate: Int = 44100,
    val channels: Int = 2,
    val audioCodec: String = "aac",
    val bitrate: Int? = null
  )

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_video_compressor")
    channel.setMethodCallHandler(this)
    
    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_video_compressor/progress")
    eventChannel.setStreamHandler(this)
    
    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "compressImage" -> {
        val imagePath = call.argument<String>("imagePath") ?: ""
        val options = parseImageOptions(call.argument<Map<String, Any>>("options") ?: emptyMap())
        compressImage(imagePath, options, result)
      }
      "compressVideo" -> {
        val videoPath = call.argument<String>("videoPath") ?: ""
        val options = parseVideoOptions(call.argument<Map<String, Any>>("options") ?: emptyMap())
        val compressionId = call.argument<String>("compressionId") ?: UUID.randomUUID().toString()
        compressVideo(videoPath, options, compressionId, result)
      }
      "compressAudio" -> {
        val audioPath = call.argument<String>("audioPath") ?: ""
        val options = parseAudioOptions(call.argument<Map<String, Any>>("options") ?: emptyMap())
        compressAudio(audioPath, options, result)
      }
      "cancelCompression" -> {
        val compressionId = call.argument<String>("compressionId") ?: ""
        cancelCompression(compressionId, result)
      }
      "getImageMetadata" -> {
        val imagePath = call.argument<String>("imagePath") ?: ""
        getImageMetadata(imagePath, result)
      }
      "getVideoMetadata" -> {
        val videoPath = call.argument<String>("videoPath") ?: ""
        getVideoMetadata(videoPath, result)
      }
      "getAudioMetadata" -> {
        val audioPath = call.argument<String>("audioPath") ?: ""
        getAudioMetadata(audioPath, result)
      }
      "createVideoThumbnail" -> {
        val videoPath = call.argument<String>("videoPath") ?: ""
        val timeUs = call.argument<Int>("timeUs") ?: 0
        val maxWidth = call.argument<Int>("maxWidth") ?: 320
        val maxHeight = call.argument<Int>("maxHeight") ?: 320
        createVideoThumbnail(videoPath, timeUs.toLong(), maxWidth, maxHeight, result)
      }
      "getRealPath" -> {
        val path = call.argument<String>("path") ?: ""
        val type = call.argument<String>("type") ?: "video"
        getRealPath(path, type, result)
      }
      "generateFilePath" -> {
        val extension = call.argument<String>("extension") ?: "mp4"
        generateFilePath(extension, result)
      }
      "getFileSize" -> {
        val filePath = call.argument<String>("filePath") ?: ""
        getFileSize(filePath, result)
      }
      "isCompressionAvailable" -> {
        result.success(true)
      }
      "clearCache" -> {
        clearCache(result)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun parseImageOptions(optionsMap: Map<String, Any>): ImageCompressionOptions {
    return ImageCompressionOptions(
      quality = (optionsMap["quality"] as? Number)?.toDouble() ?: 0.8,
      maxWidth = (optionsMap["maxWidth"] as? Number)?.toInt() ?: 1280,
      maxHeight = (optionsMap["maxHeight"] as? Number)?.toInt() ?: 1280,
      outputFormat = optionsMap["outputFormat"] as? String ?: "jpg",
      keepMetadata = optionsMap["keepMetadata"] as? Boolean ?: false,
      compressionMethod = optionsMap["compressionMethod"] as? String ?: "auto"
    )
  }

  private fun parseVideoOptions(optionsMap: Map<String, Any>): VideoCompressionOptions {
    return VideoCompressionOptions(
      quality = (optionsMap["quality"] as? Number)?.toDouble() ?: 0.8,
      maxWidth = (optionsMap["maxWidth"] as? Number)?.toInt() ?: 640,
      maxHeight = (optionsMap["maxHeight"] as? Number)?.toInt() ?: 480,
      outputFormat = optionsMap["outputFormat"] as? String ?: "mp4",
      keepMetadata = optionsMap["keepMetadata"] as? Boolean ?: false,
      bitrate = (optionsMap["bitrate"] as? Number)?.toInt(),
      frameRate = (optionsMap["frameRate"] as? Number)?.toInt(),
      codec = optionsMap["codec"] as? String ?: "h264",
      enableAudio = optionsMap["enableAudio"] as? Boolean ?: true,
      audioCodec = optionsMap["audioCodec"] as? String ?: "aac",
      compressionMethod = optionsMap["compressionMethod"] as? String ?: "auto"
    )
  }

  private fun parseAudioOptions(optionsMap: Map<String, Any>): AudioCompressionOptions {
    return AudioCompressionOptions(
      quality = optionsMap["quality"] as? String ?: "medium",
      outputFormat = optionsMap["outputFormat"] as? String ?: "mp3",
      keepMetadata = optionsMap["keepMetadata"] as? Boolean ?: false,
      sampleRate = (optionsMap["sampleRate"] as? Number)?.toInt() ?: 44100,
      channels = (optionsMap["channels"] as? Number)?.toInt() ?: 2,
      audioCodec = optionsMap["audioCodec"] as? String ?: "aac",
      bitrate = (optionsMap["bitrate"] as? Number)?.toInt()
    )
  }

  private fun compressImage(imagePath: String, options: ImageCompressionOptions, result: Result) {
    CoroutineScope(Dispatchers.IO).launch {
      try {
        val inputFile = File(imagePath)
        if (!inputFile.exists()) {
          withContext(Dispatchers.Main) {
            result.error("FILE_NOT_FOUND", "Input file does not exist", null)
          }
          return@launch
        }

        // Create output file
        val outputDir = File(context.cacheDir, "compressed_images")
        if (!outputDir.exists()) outputDir.mkdirs()
        
        val outputFile = File(outputDir, "compressed_${System.currentTimeMillis()}.${options.outputFormat}")

        // WhatsApp-like compression algorithm
        val bitmap = BitmapFactory.decodeFile(imagePath)
        if (bitmap == null) {
          withContext(Dispatchers.Main) {
            result.error("DECODE_ERROR", "Failed to decode image", null)
          }
          return@launch
        }

        // Calculate new dimensions based on WhatsApp algorithm
        val (newWidth, newHeight) = if (options.compressionMethod == "auto") {
          calculateWhatsAppDimensions(bitmap.width, bitmap.height)
        } else {
          calculateManualDimensions(bitmap.width, bitmap.height, options.maxWidth, options.maxHeight)
        }

        // Scale bitmap
        val scaledBitmap = Bitmap.createScaledBitmap(bitmap, newWidth, newHeight, true)
        
        // Calculate quality based on WhatsApp algorithm
        val quality = if (options.compressionMethod == "auto") {
          calculateWhatsAppQuality(scaledBitmap.byteCount)
        } else {
          (options.quality * 100).toInt()
        }

        // Save compressed image
        val format = if (options.outputFormat == "png") Bitmap.CompressFormat.PNG else Bitmap.CompressFormat.JPEG
        FileOutputStream(outputFile).use { out ->
          scaledBitmap.compress(format, quality, out)
        }

        // Clean up
        bitmap.recycle()
        scaledBitmap.recycle()

        withContext(Dispatchers.Main) {
          result.success(outputFile.absolutePath)
        }
      } catch (e: Exception) {
        withContext(Dispatchers.Main) {
          result.error("COMPRESSION_ERROR", "Image compression failed: ${e.message}", null)
        }
      }
    }
  }

  // WhatsApp-like image dimension calculation
  private fun calculateWhatsAppDimensions(width: Int, height: Int): Pair<Int, Int> {
    val maxDimension = 1280
    val aspectRatio = width.toFloat() / height.toFloat()
    
    return if (width > height) {
      // Landscape
      val newWidth = minOf(width, maxDimension)
      val newHeight = (newWidth / aspectRatio).toInt()
      Pair(newWidth, newHeight)
    } else {
      // Portrait
      val newHeight = minOf(height, maxDimension)
      val newWidth = (newHeight * aspectRatio).toInt()
      Pair(newWidth, newHeight)
    }
  }

  // Manual dimension calculation
  private fun calculateManualDimensions(width: Int, height: Int, maxWidth: Int, maxHeight: Int): Pair<Int, Int> {
    val aspectRatio = width.toFloat() / height.toFloat()
    
    return if (width > height) {
      val newWidth = minOf(width, maxWidth)
      val newHeight = (newWidth / aspectRatio).toInt()
      Pair(newWidth, newHeight)
    } else {
      val newHeight = minOf(height, maxHeight)
      val newWidth = (newHeight * aspectRatio).toInt()
      Pair(newWidth, newHeight)
    }
  }

  // WhatsApp-like quality calculation
  private fun calculateWhatsAppQuality(byteCount: Int): Int {
    return when {
      byteCount < 500_000 -> 92  // < 500KB
      byteCount < 1_000_000 -> 85  // < 1MB
      byteCount < 2_000_000 -> 80  // < 2MB
      byteCount < 5_000_000 -> 75  // < 5MB
      else -> 70  // >= 5MB
    }
  }

  private fun compressVideo(videoPath: String, options: VideoCompressionOptions, compressionId: String, result: Result) {
    val job = CoroutineScope(Dispatchers.IO).launch {
      try {
        val inputFile = File(videoPath)
        if (!inputFile.exists()) {
          withContext(Dispatchers.Main) {
            result.error("FILE_NOT_FOUND", "Input file does not exist", null)
          }
          return@launch
        }

        // Create output file
        val outputDir = File(context.cacheDir, "compressed_videos")
        if (!outputDir.exists()) outputDir.mkdirs()
        
        val outputFile = File(outputDir, "compressed_${System.currentTimeMillis()}.${options.outputFormat}")

        // For now, we'll use MediaMetadataRetriever for basic video info
        // In a real implementation, you would use MediaCodec or FFmpeg
        // This is a simplified version - React Native Compressor uses advanced algorithms
        
        val retriever = MediaMetadataRetriever()
        retriever.setDataSource(videoPath)
        
        val width = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toIntOrNull() ?: 0
        val height = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toIntOrNull() ?: 0
        val duration = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull() ?: 0
        
        retriever.release()

        // Simulate compression progress
        for (i in 0..100 step 10) {
          if (!isActive) break // Check for cancellation
          
          withContext(Dispatchers.Main) {
            eventSink?.success(i.toDouble())
          }
          delay(100) // Simulate compression time
        }

        // For demonstration, just copy the file (in real implementation, use MediaCodec)
        inputFile.copyTo(outputFile, overwrite = true)

        withContext(Dispatchers.Main) {
          eventSink?.success(100.0)
          result.success(outputFile.absolutePath)
        }
      } catch (e: Exception) {
        withContext(Dispatchers.Main) {
          result.error("COMPRESSION_ERROR", "Video compression failed: ${e.message}", null)
        }
      } finally {
        compressionJobs.remove(compressionId)
      }
    }
    
    compressionJobs[compressionId] = job
  }

  private fun compressAudio(audioPath: String, options: AudioCompressionOptions, result: Result) {
    CoroutineScope(Dispatchers.IO).launch {
      try {
        val inputFile = File(audioPath)
        if (!inputFile.exists()) {
          withContext(Dispatchers.Main) {
            result.error("FILE_NOT_FOUND", "Input file does not exist", null)
          }
          return@launch
        }

        // Create output file
        val outputDir = File(context.cacheDir, "compressed_audio")
        if (!outputDir.exists()) outputDir.mkdirs()
        
        val outputFile = File(outputDir, "compressed_${System.currentTimeMillis()}.${options.outputFormat}")

        // For demonstration, just copy the file (in real implementation, use MediaCodec for audio compression)
        inputFile.copyTo(outputFile, overwrite = true)

        withContext(Dispatchers.Main) {
          result.success(outputFile.absolutePath)
        }
      } catch (e: Exception) {
        withContext(Dispatchers.Main) {
          result.error("COMPRESSION_ERROR", "Audio compression failed: ${e.message}", null)
        }
      }
    }
  }

  private fun cancelCompression(compressionId: String, result: Result) {
    val job = compressionJobs[compressionId]
    if (job != null) {
      job.cancel()
      compressionJobs.remove(compressionId)
      result.success(true)
    } else {
      result.success(false)
    }
  }

  private fun getImageMetadata(imagePath: String, result: Result) {
    CoroutineScope(Dispatchers.IO).launch {
      try {
        val file = File(imagePath)
        if (!file.exists()) {
          withContext(Dispatchers.Main) {
            result.error("FILE_NOT_FOUND", "File does not exist", null)
          }
          return@launch
        }

        val options = BitmapFactory.Options().apply {
          inJustDecodeBounds = true
        }
        BitmapFactory.decodeFile(imagePath, options)

        val metadata = mapOf(
          "width" to options.outWidth,
          "height" to options.outHeight,
          "size" to file.length(),
          "extension" to file.extension,
          "mimeType" to options.outMimeType
        )

        withContext(Dispatchers.Main) {
          result.success(metadata)
        }
      } catch (e: Exception) {
        withContext(Dispatchers.Main) {
          result.error("METADATA_ERROR", "Failed to get image metadata: ${e.message}", null)
        }
      }
    }
  }

  private fun getVideoMetadata(videoPath: String, result: Result) {
    CoroutineScope(Dispatchers.IO).launch {
      try {
        val file = File(videoPath)
        if (!file.exists()) {
          withContext(Dispatchers.Main) {
            result.error("FILE_NOT_FOUND", "File does not exist", null)
          }
          return@launch
        }

        val retriever = MediaMetadataRetriever()
        retriever.setDataSource(videoPath)
        
        val width = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toIntOrNull() ?: 0
        val height = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toIntOrNull() ?: 0
        val duration = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull() ?: 0
        val bitrate = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_BITRATE)?.toIntOrNull() ?: 0
        
        retriever.release()

        val metadata = mapOf(
          "width" to width,
          "height" to height,
          "duration" to duration / 1000.0, // Convert to seconds
          "size" to file.length(),
          "extension" to file.extension,
          "bitrate" to bitrate
        )

        withContext(Dispatchers.Main) {
          result.success(metadata)
        }
      } catch (e: Exception) {
        withContext(Dispatchers.Main) {
          result.error("METADATA_ERROR", "Failed to get video metadata: ${e.message}", null)
        }
      }
    }
  }

  private fun getAudioMetadata(audioPath: String, result: Result) {
    CoroutineScope(Dispatchers.IO).launch {
      try {
        val file = File(audioPath)
        if (!file.exists()) {
          withContext(Dispatchers.Main) {
            result.error("FILE_NOT_FOUND", "File does not exist", null)
          }
          return@launch
        }

        val retriever = MediaMetadataRetriever()
        retriever.setDataSource(audioPath)
        
        val duration = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull() ?: 0
        val bitrate = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_BITRATE)?.toIntOrNull() ?: 0
        val sampleRate = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_SAMPLERATE)?.toIntOrNull() ?: 0
        
        retriever.release()

        val metadata = mapOf(
          "duration" to duration / 1000.0, // Convert to seconds
          "size" to file.length(),
          "extension" to file.extension,
          "bitrate" to bitrate,
          "sampleRate" to sampleRate
        )

        withContext(Dispatchers.Main) {
          result.success(metadata)
        }
      } catch (e: Exception) {
        withContext(Dispatchers.Main) {
          result.error("METADATA_ERROR", "Failed to get audio metadata: ${e.message}", null)
        }
      }
    }
  }

  private fun createVideoThumbnail(videoPath: String, timeUs: Long, maxWidth: Int, maxHeight: Int, result: Result) {
    CoroutineScope(Dispatchers.IO).launch {
      try {
        val bitmap = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
          ThumbnailUtils.createVideoThumbnail(File(videoPath), android.util.Size(maxWidth, maxHeight), null)
        } else {
          @Suppress("DEPRECATION")
          ThumbnailUtils.createVideoThumbnail(videoPath, MediaStore.Video.Thumbnails.MINI_KIND)
        }

        if (bitmap == null) {
          withContext(Dispatchers.Main) {
            result.error("THUMBNAIL_ERROR", "Failed to create thumbnail", null)
          }
          return@launch
        }

        // Save thumbnail
        val outputDir = File(context.cacheDir, "thumbnails")
        if (!outputDir.exists()) outputDir.mkdirs()
        
        val outputFile = File(outputDir, "thumbnail_${System.currentTimeMillis()}.jpg")
        
        FileOutputStream(outputFile).use { out ->
          bitmap.compress(Bitmap.CompressFormat.JPEG, 90, out)
        }

        bitmap.recycle()

        withContext(Dispatchers.Main) {
          result.success(outputFile.absolutePath)
        }
      } catch (e: Exception) {
        withContext(Dispatchers.Main) {
          result.error("THUMBNAIL_ERROR", "Failed to create thumbnail: ${e.message}", null)
        }
      }
    }
  }

  private fun getRealPath(path: String, type: String, result: Result) {
    // For Android, content:// to file:// conversion would go here
    // This is a simplified version
    result.success(path)
  }

  private fun generateFilePath(extension: String, result: Result) {
    val outputDir = File(context.cacheDir, "temp")
    if (!outputDir.exists()) outputDir.mkdirs()
    
    val fileName = "temp_${System.currentTimeMillis()}.$extension"
    val file = File(outputDir, fileName)
    
    result.success(file.absolutePath)
  }

  private fun getFileSize(filePath: String, result: Result) {
    try {
      val file = File(filePath)
      if (file.exists()) {
        result.success(file.length())
      } else {
        result.error("FILE_NOT_FOUND", "File does not exist", null)
      }
    } catch (e: Exception) {
      result.error("FILE_SIZE_ERROR", "Failed to get file size: ${e.message}", null)
    }
  }

  private fun clearCache(result: Result) {
    try {
      val cacheDir = context.cacheDir
      val dirs = listOf("compressed_images", "compressed_videos", "compressed_audio", "thumbnails", "temp")
      
      dirs.forEach { dirName ->
        val dir = File(cacheDir, dirName)
        if (dir.exists()) {
          dir.deleteRecursively()
        }
      }
      
      result.success(null)
    } catch (e: Exception) {
      result.error("CLEAR_CACHE_ERROR", "Failed to clear cache: ${e.message}", null)
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
    
    // Cancel all ongoing compressions
    compressionJobs.values.forEach { it.cancel() }
    compressionJobs.clear()
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }
}
