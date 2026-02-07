import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/logger.dart';

class ImageCompressionHelper {
  /// Compress image before uploading to Firebase Storage
  /// Returns compressed file path
  ///
  /// 🔥 FIXED: Now intelligently decides whether to compress
  static Future<File?> compressImage(
      File file, {
        int quality = 85,
        int maxWidth = 1920,
        int maxHeight = 1080,
      }) async {
    try {
      final originalSize = await file.length();

      log.d('🖼️ Compressing image: ${file.path}');
      log.d('📏 Original size: ${_formatBytes(originalSize)}');

      // 🔥 SKIP COMPRESSION IF FILE IS ALREADY SMALL (< 200KB)
      if (originalSize < 200 * 1024) {
        log.i('✅ Image already small (${_formatBytes(originalSize)}), skipping compression');
        return file;
      }

      // 🔥 CREATE TEMP FILE
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // 🔥 COMPRESS WITH OPTIMIZED SETTINGS
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: CompressFormat.jpeg,
        keepExif: false, // 🔥 REMOVE METADATA TO SAVE SPACE
      );

      if (result == null) {
        log.e('❌ Image compression failed, using original');
        return file;
      }

      final compressedFile = File(result.path);
      final compressedSize = await compressedFile.length();

      log.d('📦 Compressed size: ${_formatBytes(compressedSize)}');

      // 🔥 ONLY USE COMPRESSED VERSION IF IT'S ACTUALLY SMALLER
      if (compressedSize < originalSize) {
        final savedBytes = originalSize - compressedSize;
        final savedPercent = ((savedBytes / originalSize) * 100).toStringAsFixed(1);
        log.i('✅ Compression successful: Saved ${_formatBytes(savedBytes)} ($savedPercent%)');
        return compressedFile;
      } else {
        log.i('⚠️ Compressed size ($compressedSize bytes) >= original ($originalSize bytes), using original');

        // 🔥 DELETE THE COMPRESSED FILE TO FREE SPACE
        try {
          await compressedFile.delete();
        } catch (e) {
          log.w('Could not delete temporary compressed file: $e');
        }

        return file;
      }
    } catch (e, s) {
      log.e('❌ Error compressing image', error: e, stackTrace: s);
      return file; // 🔥 RETURN ORIGINAL ON ERROR
    }
  }

  /// Compress for profile pictures (smaller size needed)
  /// 🔥 OPTIMIZED SETTINGS
  static Future<File?> compressProfilePicture(File file) async {
    return compressImage(
      file,
      quality: 80, // 🔥 REDUCED FROM 80
      maxWidth: 500,
      maxHeight: 500,
    );
  }

  /// Compress for salon gallery (higher quality)
  /// 🔥 OPTIMIZED SETTINGS
  static Future<File?> compressSalonPhoto(File file) async {
    return compressImage(
      file,
      quality: 85,
      maxWidth: 1920,
      maxHeight: 1080,
    );
  }

  /// 🔥 NEW: Compress for promotions (balance of quality and size)
  static Future<File?> compressPromotionImage(File file) async {
    return compressImage(
      file,
      quality: 85,
      maxWidth: 1200,
      maxHeight: 800,
    );
  }

  /// 🔥 NEW: Helper to format bytes into human-readable format
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// 🔥 NEW: Aggressive compression for very large images
  static Future<File?> compressAggressively(File file) async {
    try {
      final originalSize = await file.length();

      log.d('🖼️ Aggressive compression for: ${file.path}');
      log.d('📏 Original size: ${_formatBytes(originalSize)}');

      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/compressed_aggressive_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // 🔥 MULTIPLE PASS COMPRESSION FOR LARGE FILES
      File currentFile = file;
      int currentQuality = 85;
      int attempts = 0;
      const maxAttempts = 3;
      const targetSize = 500 * 1024; // 500KB target

      while (attempts < maxAttempts && await currentFile.length() > targetSize) {
        final result = await FlutterImageCompress.compressAndGetFile(
          currentFile.absolute.path,
          '${targetPath}_$attempts.jpg',
          quality: currentQuality,
          minWidth: 1200,
          minHeight: 800,
          format: CompressFormat.jpeg,
          keepExif: false,
        );

        if (result == null) break;

        final newFile = File(result.path);
        final newSize = await newFile.length();

        log.d('🔄 Attempt ${attempts + 1}: ${_formatBytes(newSize)} (quality: $currentQuality)');

        // 🔥 DELETE PREVIOUS ATTEMPT IF NOT THE ORIGINAL
        if (currentFile != file && await currentFile.exists()) {
          await currentFile.delete();
        }

        currentFile = newFile;
        currentQuality = (currentQuality * 0.85).round(); // Reduce quality by 15%
        attempts++;
      }

      final finalSize = await currentFile.length();

      if (finalSize < originalSize) {
        log.i('✅ Aggressive compression: ${_formatBytes(originalSize)} → ${_formatBytes(finalSize)}');
        return currentFile;
      } else {
        // Clean up
        if (currentFile != file && await currentFile.exists()) {
          await currentFile.delete();
        }
        return file;
      }
    } catch (e, s) {
      log.e('❌ Error in aggressive compression', error: e, stackTrace: s);
      return file;
    }
  }
}