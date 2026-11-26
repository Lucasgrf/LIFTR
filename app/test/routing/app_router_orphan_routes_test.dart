import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:personal_fitness_os/features/insights/presentation/providers/insight_providers.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/weekly_comparison_data.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/weekly_snapshot.dart';
import 'package:personal_fitness_os/features/weekly_comparison/presentation/providers/weekly_comparison_providers.dart';
import 'package:personal_fitness_os/routing/app_router.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

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

    testWidgets(
      'unknown or removed routes redirect to home when logged in',
      (tester) async {
        final now = DateTime(2026, 8, 22);
        final emptyWeek = WeeklySnapshot(
          weekStart: now,
          weekEnd: now,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith((_) => true),
              dashboardDataProvider.overrideWith(
                (_) async => const DashboardData(),
              ),
              fitnessInsightsProvider.overrideWith((_) async => const []),
              currentWeekSummaryProvider.overrideWith(
                (_) async => WeeklyComparisonData(
                  currentWeek: emptyWeek,
                ),
              ),
            ],
            child: Consumer(
              builder: (context, ref, _) {
                final router = ref.watch(goRouterProvider);
                return MaterialApp.router(
                  theme: AppTheme.dark(),
                  routerConfig: router,
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final container = ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp)),
        );
        final router = container.read(goRouterProvider);

        for (final path in ['/nutrition', '/body/photos', '/rota-inexistente']) {
          router.go(path);
          await tester.pumpAndSettle();
          expect(
            router.routeInformationProvider.value.uri.path,
            '/',
            reason: '$path deve redirecionar para / via onException',
          );
        }
      },
    );

    testWidgets(
      'unknown or removed routes redirect to /login when logged out',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith((_) => false),
            ],
            child: Consumer(
              builder: (context, ref, _) {
                final router = ref.watch(goRouterProvider);
                return MaterialApp.router(
                  theme: AppTheme.dark(),
                  routerConfig: router,
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final container = ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp)),
        );
        final router = container.read(goRouterProvider);

        router.go('/calendar');
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/login');
      },
    );
  });
}
