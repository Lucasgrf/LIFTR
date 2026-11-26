import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fitness_os/routing/app_router.dart';

void main() {
  group('AppRouter Fase 0 orphan route cleanup', () {
    test('orphan and stub routes do not match in GoRouter configuration', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(goRouterProvider);

      const removedPaths = [
        '/nutrition',
        '/nutrition/meal/1',
        '/body',
        '/body/weight',
        '/body/measurements',
        '/body/photos',
        '/goals',
        '/goals/1',
        '/calendar',
      ];

      for (final path in removedPaths) {
        final matchList = router.configuration.findMatch(Uri.parse(path));
        expect(
          matchList.isEmpty,
          isTrue,
          reason: 'Rota removida $path ainda faz match no GoRouter',
        );
      }
    });

    test('active routes continue matching validly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(goRouterProvider);

      const activePaths = [
        '/',
        '/login',
        '/register',
        '/onboarding',
        '/training',
        '/history',
        '/profile',
        '/settings',
        '/weekly-comparison',
        '/exercises',
        '/session/s1',
        '/session/s1/summary',
      ];

      for (final path in activePaths) {
        final matchList = router.configuration.findMatch(Uri.parse(path));
        expect(
          matchList.isNotEmpty,
          isTrue,
          reason: 'Rota ativa $path deveria fazer match no GoRouter',
        );
      }
    });
  });
}
