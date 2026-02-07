import 'package:package_info_plus/package_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

class VersionCheckerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Check if app needs update
  /// Store required version in Firestore: config/app_version
  Future<AppVersionStatus> checkVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Get required version from Firestore
      final doc = await _db.collection('config').doc('app_version').get();

      if (!doc.exists) {
        log.w('App version config not found in Firestore');
        return AppVersionStatus.upToDate;
      }

      final data = doc.data()!;
      final minRequiredVersion = data['minRequiredVersion'] as String;
      final latestVersion = data['latestVersion'] as String;

      if (_compareVersions(currentVersion, minRequiredVersion) < 0) {
        return AppVersionStatus.updateRequired;
      } else if (_compareVersions(currentVersion, latestVersion) < 0) {
        return AppVersionStatus.updateAvailable;
      }

      return AppVersionStatus.upToDate;
    } catch (e, s) {
      log.e('Error checking app version', error: e, stackTrace: s);
      return AppVersionStatus.upToDate; // Don't block user on error
    }
  }

  /// Compare version strings (e.g., "1.2.3" vs "1.2.4")
  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.parse).toList();
    final parts2 = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;

      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }

    return 0;
  }
}

enum AppVersionStatus {
  upToDate,
  updateAvailable, // Show banner
  updateRequired,  // Block app
}

// Firestore structure:
// config/app_version:
// {
//   "latestVersion": "1.2.0",
//   "minRequiredVersion": "1.1.0",
//   "releaseNotes": "Bug fixes and improvements"
// }