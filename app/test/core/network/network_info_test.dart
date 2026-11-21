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

  group('ConnectivityNetworkInfoImpl', () {
    test('isConnected should return true when wifi is available', () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);

      final result = await networkInfo.isConnected;
      expect(result, isTrue);
    });

    test('isConnected should return false when connectivity is none', () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);

      final result = await networkInfo.isConnected;
      expect(result, isFalse);
    });

    test('onConnectivityChanged should stream boolean presence of internet', () async {
      final controller = StreamController<List<ConnectivityResult>>();
      when(() => mockConnectivity.onConnectivityChanged)
          .thenAnswer((_) => controller.stream);

      expectLater(
        networkInfo.onConnectivityChanged,
        emitsInOrder([true, false, true]),
      );

      controller.add([ConnectivityResult.mobile]);
      controller.add([ConnectivityResult.none]);
      controller.add([ConnectivityResult.wifi]);

      await controller.close();
    });
  });
}
