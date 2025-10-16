import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

/// A utility class to handle all permission-related requests in the app.
///
/// This centralizes the logic for checking and requesting permissions like
/// location, camera, and notifications, making it easier to manage and reuse.
class PermissionService {
  // Private constructor to prevent instantiation
  PermissionService._();

  /// Checks the status of and requests a single permission.
  ///
  /// This method first checks the status of the given [permission].
  /// If it's already granted, it returns true.
  /// If it's permanently denied, it opens app settings for the user to change it manually.
  /// Otherwise, it requests the permission and returns the new status.
  ///
  /// Returns `true` if the permission is granted, `false` otherwise.
  static Future<bool> _requestPermission(Permission permission) async {
    final status = await permission.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      // If permission is permanently denied, open app settings
      await openAppSettings();
      return false;
    }

    final newStatus = await permission.request();
    return newStatus.isGranted;
  }

  /// Requests permission to access the device's location.
  /// This is essential for features like finding nearby salons.
  static Future<bool> requestLocationPermission() async {
    return _requestPermission(Permission.locationWhenInUse);
  }

  /// Requests permission to access the device's camera.
  /// Useful for features like uploading profile pictures.
  static Future<bool> requestCameraPermission() async {
    return _requestPermission(Permission.camera);
  }

  /// Requests permission to access the photo library.
  static Future<bool> requestPhotosPermission() async {
    // Permission for photos can differ by platform/SDK version
    final permission = _getPhotosPermission();
    return _requestPermission(permission);
  }

  /// Requests permission to send notifications.
  /// Crucial for appointment reminders and promotions.
  static Future<bool> requestNotificationsPermission() async {
    return _requestPermission(Permission.notification);
  }

  /// Helper to get the correct photos permission based on platform.
  static Permission _getPhotosPermission() {
    // For modern Android versions (SDK 33+), there are granular permissions.
    // For simplicity here, we'll use `photos`. For a production app, you might
    // want to handle `videos` and `audio` separately.
    // On iOS, `photos` covers the photo library.
    return Permission.photos;
  }

  /// Shows a standardized dialog to inform the user why a permission is needed.
  static Future<void> showPermissionDialog(
      BuildContext context, {
        required String title,
        required String content,
        required VoidCallback onConfirm,
      }) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Open Settings'),
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
          ),
        ],
      ),
    );
  }
}
