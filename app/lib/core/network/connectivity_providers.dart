import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/network/network_info.dart';

final connectivityInstanceProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return ConnectivityNetworkInfoImpl(ref.watch(connectivityInstanceProvider));
});

final isOnlineStreamProvider = StreamProvider.autoDispose<bool>((ref) {
  final networkInfo = ref.watch(networkInfoProvider);
  return networkInfo.onConnectivityChanged;
});

/// Allows toggling a discrete offline preview banner in Settings without
/// affecting real connectivity detection.
final simulatedOfflineProvider = StateProvider<bool>((ref) => false);
