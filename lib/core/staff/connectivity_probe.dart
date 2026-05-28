import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper around [Connectivity] so tests can inject a fake.
class ConnectivityProbe {
  ConnectivityProbe({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }
}
