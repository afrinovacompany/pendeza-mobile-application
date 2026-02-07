import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Helper class for video compression and thumbnail generation
/// 
/// Features:
/// - Compresses videos for faster upload/playback
/// - Auto-generates thumbnail from first frame
/// - Validates duration (max 60 seconds)
/// - Returns compressed video + thumbnail paths
class VideoCompressionHelper {
  /// Maximum allowed video duration in seconds
  static const int maxDurationSeconds = 60;
  
  /// Maximum file size after compression (10MB)
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  /// Result of video processing
  static Future<VideoProcessingResult?> processVideo(File videoFile) async {
    try {
      // 1. Get video info first
      final info = await VideoCompress.getMediaInfo(videoFile.path);
      
      if (info.duration == null) {
        debugPrint('VideoCompressionHelper: Could not get video duration');
        return null;
      }

      final durationSeconds = (info.duration! / 1000).round();
      debugPrint('VideoCompressionHelper: Video duration = $durationSeconds seconds');

      // 2. Validate duration
      if (durationSeconds > maxDurationSeconds) {
        debugPrint('VideoCompressionHelper: Video too long ($durationSeconds > $maxDurationSeconds)');
        return VideoProcessingResult(
          success: false,
          errorMessage: 'Video must be 60 seconds or less. Your video is $durationSeconds seconds.',
        );
      }

      // 3. Generate thumbnail from first frame
      debugPrint('VideoCompressionHelper: Generating thumbnail...');
      final thumbnailFile = await VideoCompress.getFileThumbnail(
        videoFile.path,
        quality: 75,
        position: 0, // First frame
      );

      if (thumbnailFile == null) {
        debugPrint('VideoCompressionHelper: Failed to generate thumbnail');
        return VideoProcessingResult(
          success: false,
          errorMessage: 'Failed to generate video thumbnail',
        );
      }

      debugPrint('VideoCompressionHelper: Thumbnail generated at ${thumbnailFile.path}');

      // 4. Compress video
      debugPrint('VideoCompressionHelper: Compressing video...');
      final compressedInfo = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (compressedInfo == null || compressedInfo.file == null) {
        debugPrint('VideoCompressionHelper: Compression failed');
        return VideoProcessingResult(
          success: false,
          errorMessage: 'Failed to compress video',
        );
      }

      final compressedFile = compressedInfo.file!;
      final originalSize = videoFile.lengthSync();
      final compressedSize = compressedFile.lengthSync();
      final compressionRatio = ((1 - compressedSize / originalSize) * 100).toStringAsFixed(1);

      debugPrint('VideoCompressionHelper: Compression complete');
      debugPrint('  Original: ${_formatBytes(originalSize)}');
      debugPrint('  Compressed: ${_formatBytes(compressedSize)}');
      debugPrint('  Reduction: $compressionRatio%');

      // 5. Check if still too large
      if (compressedSize > maxFileSizeBytes) {
        debugPrint('VideoCompressionHelper: Compressed file still too large');
        return VideoProcessingResult(
          success: false,
          errorMessage: 'Video file is too large. Please use a shorter video.',
        );
      }

      return VideoProcessingResult(
        success: true,
        compressedVideoFile: compressedFile,
        thumbnailFile: thumbnailFile,
        durationSeconds: durationSeconds,
        originalSizeBytes: originalSize,
        compressedSizeBytes: compressedSize,
      );

    } catch (e, stackTrace) {
      debugPrint('VideoCompressionHelper: Error processing video: $e');
      debugPrint('Stack trace: $stackTrace');
      return VideoProcessingResult(
        success: false,
        errorMessage: 'Error processing video: ${e.toString()}',
      );
    }
  }

  /// Get video duration without full processing
  static Future<int?> getVideoDuration(File videoFile) async {
    try {
      final info = await VideoCompress.getMediaInfo(videoFile.path);
      if (info.duration == null) return null;
      return (info.duration! / 1000).round();
    } catch (e) {
      debugPrint('VideoCompressionHelper: Error getting duration: $e');
      return null;
    }
  }

  /// Generate thumbnail only (for preview before upload)
  static Future<File?> generateThumbnail(File videoFile, {int position = 0}) async {
    try {
      return await VideoCompress.getFileThumbnail(
        videoFile.path,
        quality: 75,
        position: position,
      );
    } catch (e) {
      debugPrint('VideoCompressionHelper: Error generating thumbnail: $e');
      return null;
    }
  }

  /// Cancel ongoing compression
  static Future<void> cancelCompression() async {
    await VideoCompress.cancelCompression();
  }

  /// Delete all temporary files created during compression
  static Future<void> deleteAllCache() async {
    await VideoCompress.deleteAllCache();
  }

  /// Format bytes to human readable string
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

/// Result of video processing operation
class VideoProcessingResult {
  final bool success;
  final File? compressedVideoFile;
  final File? thumbnailFile;
  final int? durationSeconds;
  final int? originalSizeBytes;
  final int? compressedSizeBytes;
  final String? errorMessage;

  const VideoProcessingResult({
    required this.success,
    this.compressedVideoFile,
    this.thumbnailFile,
    this.durationSeconds,
    this.originalSizeBytes,
    this.compressedSizeBytes,
    this.errorMessage,
  });

  /// Get compression ratio as percentage
  double? get compressionRatio {
    if (originalSizeBytes == null || compressedSizeBytes == null) return null;
    return (1 - compressedSizeBytes! / originalSizeBytes!) * 100;
  }

  /// Get formatted original size
  String get formattedOriginalSize {
    if (originalSizeBytes == null) return 'Unknown';
    return _formatBytes(originalSizeBytes!);
  }

  /// Get formatted compressed size
  String get formattedCompressedSize {
    if (compressedSizeBytes == null) return 'Unknown';
    return _formatBytes(compressedSizeBytes!);
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
