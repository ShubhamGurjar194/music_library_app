import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Service to check internet connectivity. Used for offline handling.
class ConnectivityService {
  ConnectivityService() : _connectivity = Connectivity();

  final Connectivity _connectivity;

  /// Returns true if there is a non-none connectivity (wifi, mobile, etc.).
  Future<bool> get hasConnection async {
    final result = await _connectivity.checkConnectivity();
    return result.isNotEmpty &&
        result.any((r) => r != ConnectivityResult.none);
  }

  /// Stream of connectivity changes (optional for reactive UI).
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}
