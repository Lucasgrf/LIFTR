import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/network/network_info.dart';

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  late MockConnectivity mockConnectivity;
  late ConnectivityNetworkInfoImpl networkInfo;

  setUp(() {
    mockConnectivity = MockConnectivity();
    networkInfo = ConnectivityNetworkInfoImpl(mockConnectivity);
  });

  group('Offline and Online Flow Integration Test', () {
    test('should reactively switch connectivity states and report accurately', () async {
      final controller = StreamController<List<ConnectivityResult>>.broadcast();
      when(() => mockConnectivity.onConnectivityChanged)
          .thenAnswer((_) => controller.stream);

      final events = <bool>[];
      final subscription = networkInfo.onConnectivityChanged.listen(events.add);

      // Simulate going offline
      controller.add([ConnectivityResult.none]);
      await Future<void>.delayed(Duration.zero);

      // Simulate reconnecting via wifi
      controller.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);

      expect(events, [false, true]);

      await subscription.cancel();
      await controller.close();
    });
  });
}
