import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/network/network_info.dart';

final connectivityInstanceProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return ConnectivityNetworkInfoImpl(ref.watch(connectivityInstanceProvider));
});

/// Streams real connectivity status, emitting the initial check immediately
/// followed by OS connectivity change events.
final isOnlineStreamProvider = StreamProvider<bool>((ref) async* {
  final networkInfo = ref.watch(networkInfoProvider);
  var lastValue = true;
  try {
    lastValue = await networkInfo.isConnected;
  } catch (_) {
    lastValue = true;
  }
  yield lastValue;

  await for (final next in networkInfo.onConnectivityChanged) {
    if (next != lastValue) {
      lastValue = next;
      yield next;
    }
  }
});

/// Exposes the developer offline-simulation toggle only in non-release builds
/// unless explicitly opted in via
/// `--dart-define=ENABLE_OFFLINE_SIMULATION=true`.
final offlineSimulationEnabledProvider = Provider<bool>(
  (ref) =>
      !kReleaseMode ||
      const bool.fromEnvironment('ENABLE_OFFLINE_SIMULATION'),
);

/// Allows toggling a discrete offline preview banner in Settings without
/// affecting real connectivity detection.
final simulatedOfflineProvider = StateProvider<bool>((ref) => false);

/// Set to true immediately if an active network request fails due to lost
/// connectivity before the OS connectivity stream emits.
final runtimeOfflineDetectedProvider = StateProvider<bool>((ref) => false);

/// Combined offline state used by UI banners and offline-first repositories.
final isOfflineModeProvider = Provider<bool>((ref) {
  final isOnline = ref.watch(isOnlineStreamProvider).asData?.value ?? true;
  final simulationEnabled = ref.watch(offlineSimulationEnabledProvider);
  final simulated =
      simulationEnabled && ref.watch(simulatedOfflineProvider);
  final runtimeOffline = ref.watch(runtimeOfflineDetectedProvider);
  return !isOnline || simulated || runtimeOffline;
});

/// Number of locally queued workout operations waiting for cloud sync.
final pendingSyncCountProvider = StateProvider<int>((ref) => 0);
