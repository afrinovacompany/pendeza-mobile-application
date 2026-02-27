import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_compress/video_compress.dart';

class VideoCompressionHelper {
  static const int maxDurationSeconds = 60;
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  // 🆕 FIX: Added method for UI validation
  static Future<int?> getVideoDuration(File videoFile) async {
    try {
      final info = await VideoCompress.getMediaInfo(videoFile.path);
      if (info.duration == null) return null;
      return (info.duration! / 1000).round();
    } catch (e) {
      debugPrint('Error getting video duration: $e');
      return null;
    }
  }

  // 🆕 FIX: Added method for UI thumbnail preview
  static Future<File?> generateThumbnail(File videoFile) async {
    try {
      return await VideoCompress.getFileThumbnail(
        videoFile.path,
        quality: 75,
        position: 0,
      );
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      return null;
    }
  }

  static Future<VideoProcessingResult?> compressVideoTo720p(File videoFile) async {
    return _performCompression(videoFile, VideoQuality.DefaultQuality);
  }

  static Future<VideoProcessingResult?> compressVideoTo360p(File videoFile) async {
    return _performCompression(videoFile, VideoQuality.LowQuality);
  }

  static Future<VideoProcessingResult?> processVideo(File videoFile) async {
    return _performCompression(videoFile, VideoQuality.MediumQuality);
  }

  static Future<VideoProcessingResult?> _performCompression(File videoFile, VideoQuality quality) async {
    try {
      final info = await VideoCompress.getMediaInfo(videoFile.path);
      if (info.duration == null) return null;
      final durationSeconds = (info.duration! / 1000).round();

      if (durationSeconds > maxDurationSeconds) {
        return VideoProcessingResult(
          success: false,
          errorMessage: 'Video must be $maxDurationSeconds seconds or less.',
        );
      }

      final thumbnailFile = await generateThumbnail(videoFile);

      final compressedInfo = await VideoCompress.compressVideo(
        videoFile.path,
        quality: quality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (compressedInfo == null || compressedInfo.file == null) {
        return const VideoProcessingResult(success: false, errorMessage: 'Compression failed');
      }

      return VideoProcessingResult(
        success: true,
        compressedVideoFile: compressedInfo.file!,
        thumbnailFile: thumbnailFile,
        durationSeconds: durationSeconds,
        originalSizeBytes: videoFile.lengthSync(),
        compressedSizeBytes: compressedInfo.file!.lengthSync(),
      );
    } catch (e) {
      return VideoProcessingResult(success: false, errorMessage: e.toString());
    }
  }

  static Future<void> deleteAllCache() async {
    await VideoCompress.deleteAllCache();
  }
}

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
}