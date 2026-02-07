import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/logger.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();

  Stream<bool> get onConnectivityChanged => _controller.stream;
  bool _isConnected = true;

  // Singleton
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  Future<void> init() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);

    // Listen to changes
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final isConnected = results.any(
          (result) => result != ConnectivityResult.none,
    );

    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      _controller.add(isConnected);

      if (isConnected) {
        log.i('✅ Internet connection restored');
      } else {
        log.w('❌ No internet connection');
      }
    }
  }

  bool get isConnected => _isConnected;

  Future<bool> checkConnection() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  void dispose() {
    _controller.close();
  }
}

// Usage in widgets:
// StreamBuilder<bool>(
//   stream: ConnectivityService().onConnectivityChanged,
//   builder: (context, snapshot) {
//     if (snapshot.data == false) {
//       return OfflineBanner();
//     }
//     return YourContent();
//   },
// )