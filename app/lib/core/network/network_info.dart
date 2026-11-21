import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Returns true when [error] represents a connectivity / transport failure
/// rather than a business or validation rejection.
bool isNetworkError(Object error) {
  if (error is SocketException ||
      error is TimeoutException ||
      error is HandshakeException) {
    return true;
  }
  final typeName = error.runtimeType.toString().toLowerCase();
  if (typeName.contains('clientexception') ||
      typeName.contains('authretryablefetchexception') ||
      typeName.contains('socketexception')) {
    return true;
  }
  final msg = error.toString().toLowerCase();
  return msg.contains('socketexception') ||
      msg.contains('failed host lookup') ||
      msg.contains('network is unreachable') ||
      msg.contains('connection refused') ||
      msg.contains('connection closed') ||
      msg.contains('connection reset') ||
      msg.contains('handshakeexception') ||
      msg.contains('clientexception') ||
      msg.contains('timed out');
}

abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onConnectivityChanged;
}

class ConnectivityNetworkInfoImpl implements NetworkInfo {
  ConnectivityNetworkInfoImpl(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  @override
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(_hasConnection);
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }
}
