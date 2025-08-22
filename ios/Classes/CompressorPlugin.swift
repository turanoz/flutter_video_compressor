import Flutter
import UIKit
import AVFoundation
import Photos
import ImageIO
import MobileCoreServices

public class CompressorPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var compressionTasks: [String: URLSessionDataTask] = [:]
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_video_compressor", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "flutter_video_compressor/progress", binaryMessenger: registrar.messenger())
        
        let instance = CompressorPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "compressImage":
            guard let args = call.arguments as? [String: Any],
                  let imagePath = args["imagePath"] as? String,
                  let options = args["options"] as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                return
            }
            compressImage(imagePath: imagePath, options: options, result: result)
            
        case "compressVideo":
            guard let args = call.arguments as? [String: Any],
                  let videoPath = args["videoPath"] as? String,
                  let options = args["options"] as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                return
            }
            let compressionId = args["compressionId"] as? String ?? UUID().uuidString
            compressVideo(videoPath: videoPath, options: options, compressionId: compressionId, result: result)
            
        case "compressAudio":
            guard let args = call.arguments as? [String: Any],
                  let audioPath = args["audioPath"] as? String,
                  let options = args["options"] as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                return
            }
            compressAudio(audioPath: audioPath, options: options, result: result)
            
        case "cancelCompression":
            guard let args = call.arguments as? [String: Any],
                  let compressionId = args["compressionId"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                return
            }
            cancelCompression(compressionId: compressionId, result: result)
            
        case "getImageMetadata":
            guard let args = call.arguments as? [String: Any],
                  let imagePath = args["imagePath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                return
            }
            getImageMetadata(imagePath: imagePath, result: result)
            
        case "getVideoMetadata":
            guard let args = call.arguments as? [String: Any],
                  let videoPath = args["videoPath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                return
            }
            getVideoMetadata(videoPath: videoPath, result: result)
            
        case "getAudioMetadata":
            guard let args = call.arguments as? [String: Any],
                  let audioPath = args["audioPath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                return
            }
            getAudioMetadata(audioPath: audioPath, result: result)
            
        case "createVideoThumbnail":
            guard let args = call.arguments as? [String: Any],
                  let videoPath = args["videoPath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                return
            }
            let timeUs = args["timeUs"] as? Int64 ?? 0
            let maxWidth = args["maxWidth"] as? Int ?? 320
            let maxHeight = args["maxHeight"] as? Int ?? 320
            createVideoThumbnail(videoPath: videoPath, timeUs: timeUs, maxWidth: maxWidth, maxHeight: maxHeight, result: result)
            
        case "getRealPath":
            guard let args = call.arguments as? [String: Any],
                  let path = args["path"] as? String,
                  let type = args["type"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                return
            }
            getRealPath(path: path, type: type, result: result)
            
        case "generateFilePath":
            guard let args = call.arguments as? [String: Any],
                  let fileExtension = args["extension"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                return
            }
            generateFilePath(extension: fileExtension, result: result)
            
        case "getFileSize":
            guard let args = call.arguments as? [String: Any],
                  let filePath = args["filePath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                return
            }
            getFileSize(filePath: filePath, result: result)
            
        case "isCompressionAvailable":
            result(true)
            
        case "clearCache":
            clearCache(result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Image Compression
    private func compressImage(imagePath: String, options: [String: Any], result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let url = URL(fileURLWithPath: imagePath)
                guard let imageData = try? Data(contentsOf: url),
                      let image = UIImage(data: imageData) else {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "DECODE_ERROR", message: "Failed to decode image", details: nil))
                    }
                    return
                }
                
                let quality = options["quality"] as? Double ?? 0.8
                let maxWidth = options["maxWidth"] as? Int ?? 1280
                let maxHeight = options["maxHeight"] as? Int ?? 1280
                let outputFormat = options["outputFormat"] as? String ?? "jpg"
                let compressionMethod = options["compressionMethod"] as? String ?? "auto"
                
                // Calculate new dimensions using WhatsApp-like algorithm
                let newSize: CGSize
                if compressionMethod == "auto" {
                    newSize = self.calculateWhatsAppDimensions(originalSize: image.size)
                } else {
                    newSize = self.calculateManualDimensions(originalSize: image.size, maxWidth: maxWidth, maxHeight: maxHeight)
                }
                
                // Resize image
                let resizedImage = self.resizeImage(image: image, targetSize: newSize)
                
                // Calculate quality using WhatsApp-like algorithm
                let compressionQuality: CGFloat
                if compressionMethod == "auto" {
                    compressionQuality = self.calculateWhatsAppQuality(imageSize: newSize)
                } else {
                    compressionQuality = CGFloat(quality)
                }
                
                // Compress image
                let compressedData: Data?
                if outputFormat == "png" {
                    compressedData = resizedImage.pngData()
                } else {
                    compressedData = resizedImage.jpegData(compressionQuality: compressionQuality)
                }
                
                guard let data = compressedData else {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "COMPRESSION_ERROR", message: "Failed to compress image", details: nil))
                    }
                    return
                }
                
                // Save compressed image
                let outputDir = self.getOutputDirectory(for: "compressed_images")
                let outputFileName = "compressed_\(Date().timeIntervalSince1970).\(outputFormat)"
                let outputURL = outputDir.appendingPathComponent(outputFileName)
                
                try data.write(to: outputURL)
                
                DispatchQueue.main.async {
                    result(outputURL.path)
                }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "COMPRESSION_ERROR", message: "Image compression failed: \(error.localizedDescription)", details: nil))
                }
            }
        }
    }
    
    // WhatsApp-like dimension calculation for images
    private func calculateWhatsAppDimensions(originalSize: CGSize) -> CGSize {
        let maxDimension: CGFloat = 1280
        let aspectRatio = originalSize.width / originalSize.height
        
        if originalSize.width > originalSize.height {
            // Landscape
            let newWidth = min(originalSize.width, maxDimension)
            let newHeight = newWidth / aspectRatio
            return CGSize(width: newWidth, height: newHeight)
        } else {
            // Portrait
            let newHeight = min(originalSize.height, maxDimension)
            let newWidth = newHeight * aspectRatio
            return CGSize(width: newWidth, height: newHeight)
        }
    }
    
    // Manual dimension calculation
    private func calculateManualDimensions(originalSize: CGSize, maxWidth: Int, maxHeight: Int) -> CGSize {
        let aspectRatio = originalSize.width / originalSize.height
        let maxW = CGFloat(maxWidth)
        let maxH = CGFloat(maxHeight)
        
        if originalSize.width > originalSize.height {
            let newWidth = min(originalSize.width, maxW)
            let newHeight = newWidth / aspectRatio
            return CGSize(width: newWidth, height: newHeight)
        } else {
            let newHeight = min(originalSize.height, maxH)
            let newWidth = newHeight * aspectRatio
            return CGSize(width: newWidth, height: newHeight)
        }
    }
    
    // WhatsApp-like quality calculation
    private func calculateWhatsAppQuality(imageSize: CGSize) -> CGFloat {
        let pixelCount = imageSize.width * imageSize.height
        
        switch pixelCount {
        case 0..<500_000:
            return 0.92
        case 500_000..<1_000_000:
            return 0.85
        case 1_000_000..<2_000_000:
            return 0.80
        case 2_000_000..<5_000_000:
            return 0.75
        default:
            return 0.70
        }
    }
    
    // Resize image helper
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        let newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        let rect = CGRect(origin: .zero, size: newSize)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
    
    // MARK: - Video Compression
    private func compressVideo(videoPath: String, options: [String: Any], compressionId: String, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let inputURL = URL(fileURLWithPath: videoPath)
                let outputDir = self.getOutputDirectory(for: "compressed_videos")
                let outputFormat = options["outputFormat"] as? String ?? "mp4"
                let outputFileName = "compressed_\(Date().timeIntervalSince1970).\(outputFormat)"
                let outputURL = outputDir.appendingPathComponent(outputFileName)
                
                // Create AVAsset
                let asset = AVAsset(url: inputURL)
                
                // Get video track
                guard let videoTrack = asset.tracks(withMediaType: .video).first else {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "NO_VIDEO_TRACK", message: "No video track found", details: nil))
                    }
                    return
                }
                
                // Configure export session
                guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "EXPORT_SESSION_ERROR", message: "Failed to create export session", details: nil))
                    }
                    return
                }
                
                exportSession.outputURL = outputURL
                exportSession.outputFileType = .mp4
                
                // Start export with progress tracking
                let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                    DispatchQueue.main.async {
                        self.eventSink?(Double(exportSession.progress * 100))
                    }
                }
                
                exportSession.exportAsynchronously {
                    timer.invalidate()
                    
                    DispatchQueue.main.async {
                        switch exportSession.status {
                        case .completed:
                            self.eventSink?(100.0)
                            result(outputURL.path)
                        case .failed:
                            result(FlutterError(code: "EXPORT_FAILED", message: exportSession.error?.localizedDescription ?? "Export failed", details: nil))
                        case .cancelled:
                            result(FlutterError(code: "EXPORT_CANCELLED", message: "Export was cancelled", details: nil))
                        default:
                            result(FlutterError(code: "EXPORT_ERROR", message: "Unknown export error", details: nil))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Audio Compression
    private func compressAudio(audioPath: String, options: [String: Any], result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let inputURL = URL(fileURLWithPath: audioPath)
                let outputDir = self.getOutputDirectory(for: "compressed_audio")
                let outputFormat = options["outputFormat"] as? String ?? "m4a"
                let outputFileName = "compressed_\(Date().timeIntervalSince1970).\(outputFormat)"
                let outputURL = outputDir.appendingPathComponent(outputFileName)
                
                // Create AVAsset
                let asset = AVAsset(url: inputURL)
                
                // Configure export session for audio
                guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "EXPORT_SESSION_ERROR", message: "Failed to create export session", details: nil))
                    }
                    return
                }
                
                exportSession.outputURL = outputURL
                exportSession.outputFileType = .m4a
                
                // Start export
                exportSession.exportAsynchronously {
                    DispatchQueue.main.async {
                        switch exportSession.status {
                        case .completed:
                            result(outputURL.path)
                        case .failed:
                            result(FlutterError(code: "EXPORT_FAILED", message: exportSession.error?.localizedDescription ?? "Export failed", details: nil))
                        case .cancelled:
                            result(FlutterError(code: "EXPORT_CANCELLED", message: "Export was cancelled", details: nil))
                        default:
                            result(FlutterError(code: "EXPORT_ERROR", message: "Unknown export error", details: nil))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Cancel Compression
    private func cancelCompression(compressionId: String, result: @escaping FlutterResult) {
        if let task = compressionTasks[compressionId] {
            task.cancel()
            compressionTasks.removeValue(forKey: compressionId)
            result(true)
        } else {
            result(false)
        }
    }
    
    // MARK: - Metadata
    private func getImageMetadata(imagePath: String, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let url = URL(fileURLWithPath: imagePath)
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: imagePath)
                let fileSize = fileAttributes[.size] as? Int64 ?? 0
                
                guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
                      let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] else {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "METADATA_ERROR", message: "Failed to get image metadata", details: nil))
                    }
                    return
                }
                
                let width = imageProperties[kCGImagePropertyPixelWidth] as? Int ?? 0
                let height = imageProperties[kCGImagePropertyPixelHeight] as? Int ?? 0
                let orientation = imageProperties[kCGImagePropertyOrientation] as? Int ?? 1
                
                let metadata: [String: Any] = [
                    "width": width,
                    "height": height,
                    "size": fileSize,
                    "extension": url.pathExtension,
                    "orientation": orientation
                ]
                
                DispatchQueue.main.async {
                    result(metadata)
                }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "METADATA_ERROR", message: "Failed to get image metadata: \(error.localizedDescription)", details: nil))
                }
            }
        }
    }
    
    private func getVideoMetadata(videoPath: String, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let url = URL(fileURLWithPath: videoPath)
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: videoPath)
                let fileSize = fileAttributes[.size] as? Int64 ?? 0
                
                let asset = AVAsset(url: url)
                
                let duration = CMTimeGetSeconds(asset.duration)
                var width = 0
                var height = 0
                var bitrate = 0
                
                if let videoTrack = asset.tracks(withMediaType: .video).first {
                    let size = videoTrack.naturalSize
                    width = Int(size.width)
                    height = Int(size.height)
                    bitrate = Int(videoTrack.estimatedDataRate)
                }
                
                let metadata: [String: Any] = [
                    "width": width,
                    "height": height,
                    "duration": duration,
                    "size": fileSize,
                    "extension": url.pathExtension,
                    "bitrate": bitrate
                ]
                
                DispatchQueue.main.async {
                    result(metadata)
                }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "METADATA_ERROR", message: "Failed to get video metadata: \(error.localizedDescription)", details: nil))
                }
            }
        }
    }
    
    private func getAudioMetadata(audioPath: String, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let url = URL(fileURLWithPath: audioPath)
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: audioPath)
                let fileSize = fileAttributes[.size] as? Int64 ?? 0
                
                let asset = AVAsset(url: url)
                let duration = CMTimeGetSeconds(asset.duration)
                
                var bitrate = 0
                var sampleRate = 0
                
                if let audioTrack = asset.tracks(withMediaType: .audio).first {
                    bitrate = Int(audioTrack.estimatedDataRate)
                    
                    // Get format descriptions
                    if let formatDescription = audioTrack.formatDescriptions.first {
                        let audioStreamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription as! CMAudioFormatDescription)
                        if let basicDescription = audioStreamBasicDescription {
                            sampleRate = Int(basicDescription.pointee.mSampleRate)
                        }
                    }
                }
                
                let metadata: [String: Any] = [
                    "duration": duration,
                    "size": fileSize,
                    "extension": url.pathExtension,
                    "bitrate": bitrate,
                    "sampleRate": sampleRate
                ]
                
                DispatchQueue.main.async {
                    result(metadata)
                }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "METADATA_ERROR", message: "Failed to get audio metadata: \(error.localizedDescription)", details: nil))
                }
            }
        }
    }
    
    // MARK: - Video Thumbnail
    private func createVideoThumbnail(videoPath: String, timeUs: Int64, maxWidth: Int, maxHeight: Int, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let url = URL(fileURLWithPath: videoPath)
                let asset = AVAsset(url: url)
                let imageGenerator = AVAssetImageGenerator(asset: asset)
                imageGenerator.appliesPreferredTrackTransform = true
                imageGenerator.maximumSize = CGSize(width: maxWidth, height: maxHeight)
                
                let time = CMTime(value: timeUs, timescale: 1000000) // Convert microseconds to CMTime
                let image = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                
                let uiImage = UIImage(cgImage: image)
                guard let imageData = uiImage.jpegData(compressionQuality: 0.9) else {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "THUMBNAIL_ERROR", message: "Failed to create thumbnail data", details: nil))
                    }
                    return
                }
                
                // Save thumbnail
                let outputDir = self.getOutputDirectory(for: "thumbnails")
                let outputFileName = "thumbnail_\(Date().timeIntervalSince1970).jpg"
                let outputURL = outputDir.appendingPathComponent(outputFileName)
                
                try imageData.write(to: outputURL)
                
                DispatchQueue.main.async {
                    result(outputURL.path)
                }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "THUMBNAIL_ERROR", message: "Failed to create thumbnail: \(error.localizedDescription)", details: nil))
                }
            }
        }
    }
    
    // MARK: - Utility Methods
    private func getRealPath(path: String, type: String, result: @escaping FlutterResult) {
        // For iOS, ph:// to file:// conversion would go here
        // This is a simplified version
        result(path)
    }
    
    private func generateFilePath(extension: String, result: @escaping FlutterResult) {
        let outputDir = getOutputDirectory(for: "temp")
        let fileName = "temp_\(Date().timeIntervalSince1970).\(`extension`)"
        let outputURL = outputDir.appendingPathComponent(fileName)
        
        result(outputURL.path)
    }
    
    private func getFileSize(filePath: String, result: @escaping FlutterResult) {
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: filePath)
            let fileSize = fileAttributes[.size] as? Int64 ?? 0
            result(fileSize)
        } catch {
            result(FlutterError(code: "FILE_SIZE_ERROR", message: "Failed to get file size: \(error.localizedDescription)", details: nil))
        }
    }
    
    private func clearCache(result: @escaping FlutterResult) {
        do {
            let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            let dirs = ["compressed_images", "compressed_videos", "compressed_audio", "thumbnails", "temp"]
            
            for dirName in dirs {
                let dirURL = cacheDir.appendingPathComponent(dirName)
                if FileManager.default.fileExists(atPath: dirURL.path) {
                    try FileManager.default.removeItem(at: dirURL)
                }
            }
            
            result(nil)
        } catch {
            result(FlutterError(code: "CLEAR_CACHE_ERROR", message: "Failed to clear cache: \(error.localizedDescription)", details: nil))
        }
    }
    
    private func getOutputDirectory(for subdirectory: String) -> URL {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let outputDir = cacheDir.appendingPathComponent(subdirectory)
        
        if !FileManager.default.fileExists(atPath: outputDir.path) {
            try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true, attributes: nil)
        }
        
        return outputDir
    }
    
    // MARK: - FlutterStreamHandler
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
