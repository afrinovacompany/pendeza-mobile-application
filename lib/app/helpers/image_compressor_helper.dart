import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/logger.dart';

class ImageCompressionHelper {
  /// Compress image before uploading to Firebase Storage
  /// 🔥 COMPLETELY REWRITTEN - NOW ACTUALLY COMPRESSES!
  static Future<File?> compressImage(
      File file, {
        int quality = 75, // 🔥 REDUCED FROM 85 - 75 is sweet spot
        int maxWidth = 1200, // 🔥 REDUCED FROM 1920
        int maxHeight = 1080,
      }) async {
    try {
      final originalSize = await file.length();

      log.d('🖼️ Compressing image: ${file.path}');
      log.d('📏 Original size: ${_formatBytes(originalSize)}');

      // 🔥 MORE AGGRESSIVE SKIP - only skip if UNDER 150KB
      if (originalSize < 150 * 1024) {
        log.i('✅ Image already small (${_formatBytes(originalSize)}), skipping compression');
        return file;
      }

      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        quality: quality, // 75 is optimal for photos
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: CompressFormat.jpeg,
        keepExif: false,
      );

      if (result == null || result.isEmpty) {
        log.e('❌ Image compression failed, using original');
        return file;
      }

      // Write compressed bytes to file
      final compressedFile = File(targetPath);
      await compressedFile.writeAsBytes(result);

      final compressedSize = await compressedFile.length();

      log.d('📦 Compressed size: ${_formatBytes(compressedSize)}');

      // 🔥 NEW: More aggressive threshold - use compressed if at least 20% smaller
      if (compressedSize < originalSize * 0.8) { // 20% reduction minimum
        final savedBytes = originalSize - compressedSize;
        final savedPercent = ((savedBytes / originalSize) * 100).toStringAsFixed(1);
        log.i('✅ Compression successful: Saved ${_formatBytes(savedBytes)} ($savedPercent%)');
        return compressedFile;
      }
      // 🔥 NEW: If compression didn't help much, try more aggressive settings
      else if (compressedSize < originalSize) {
        log.i('⚠️ Only saved ${((originalSize - compressedSize) / originalSize * 100).toStringAsFixed(1)}%, trying more aggressive...');

        // Try again with lower quality
        final result2 = await FlutterImageCompress.compressWithFile(
          file.absolute.path,
          quality: 60, // Lower quality
          minWidth: 1000, // Smaller dimensions
          minHeight: 800,
          format: CompressFormat.jpeg,
          keepExif: false,
        );

        if (result2 != null && result2.isNotEmpty) {
          final compressedFile2 = File('${dir.path}/compressed_aggressive_${DateTime.now().millisecondsSinceEpoch}.jpg');
          await compressedFile2.writeAsBytes(result2);
          final compressedSize2 = await compressedFile2.length();

          if (compressedSize2 < originalSize * 0.7) { // 30% reduction
            log.i('✅ Aggressive compression: ${_formatBytes(originalSize)} → ${_formatBytes(compressedSize2)}');
            // Delete first attempt
            if (await compressedFile.exists()) await compressedFile.delete();
            return compressedFile2;
          }

          // Delete aggressive attempt if not better
          if (await compressedFile2.exists()) await compressedFile2.delete();
        }

        // If still not great, but at least smaller
        if (compressedSize < originalSize) {
          return compressedFile;
        }
      }

      // If we get here, compression didn't help - use original
      log.i('⚠️ Compression not beneficial, using original');

      // Clean up
      try {
        if (await compressedFile.exists()) {
          await compressedFile.delete();
        }
      } catch (e) {
        // Ignore
      }

      return file;
    } catch (e, s) {
      log.e('❌ Error compressing image', error: e, stackTrace: s);
      return file;
    }
  }

  /// Compress for salon gallery - 🔥 OPTIMIZED SETTINGS
  static Future<File?> compressSalonPhoto(File file) async {
    return compressImage(
      file,
      quality: 75, // 🔥 75% is perfect - good quality, much smaller
      maxWidth: 1200, // 🔥 1200px is plenty for mobile viewing
      maxHeight: 1080,
    );
  }

  /// Compress for profile pictures - 🔥 MORE AGGRESSIVE
  static Future<File?> compressProfilePicture(File file) async {
    return compressImage(
      file,
      quality: 70, // 🔥 70% is fine for tiny profile pics
      maxWidth: 400, // 🔥 Smaller
      maxHeight: 400,
    );
  }

  /// 🔥 NEW: Ultra compression for gallery thumbnails
  static Future<File?> compressThumbnail(File file) async {
    return compressImage(
      file,
      quality: 60,
      maxWidth: 300,
      maxHeight: 300,
    );
  }

  /// Helper to format bytes
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// 🔥 NEW: Direct byte compression - MOST RELIABLE
  static Future<File?> compressDirect(File file, {int quality = 70}) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/direct_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final bytes = await file.readAsBytes();

      // Use direct byte compression
      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      final compressedFile = File(targetPath);
      await compressedFile.writeAsBytes(compressedBytes);

      final originalSize = bytes.length;
      final compressedSize = compressedBytes.length;

      log.d('📦 Direct compression: ${_formatBytes(originalSize)} → ${_formatBytes(compressedSize)}');

      if (compressedSize < originalSize) {
        return compressedFile;
      }

      await compressedFile.delete();
      return file;
    } catch (e) {
      log.e('Direct compression failed: $e');
      return file;
    }
  }
}