import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/network/connectivity_providers.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/update/app_update_providers.dart';
import 'package:personal_fitness_os/core/update/app_update_widgets.dart';
import 'package:personal_fitness_os/core/widgets/offline_banner_widget.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';

class AppShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _bannerDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isOffline = ref.read(isOfflineModeProvider);
      final hasActiveSession =
          ref.read(sessionLocalDataSourceProvider)?.getActiveSession() != null;
      unawaited(
        ref.read(appUpdateProvider.notifier).checkSilentlyIfDue(
              isOffline: isOffline,
              hasActiveSession: hasActiveSession,
            ),
      );
    });
  }

  void _goBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    ref.watch(sessionAutoSyncProvider);
    final isOfflineMode = ref.watch(isOfflineModeProvider);
    final pendingCount = ref.watch(pendingSyncCountProvider);
    final updateState = ref.watch(appUpdateProvider);

    ref.listen<bool>(isOfflineModeProvider, (previous, next) {
      if (next && previous != next && _bannerDismissed) {
        setState(() => _bannerDismissed = false);
      }
    });

    final showOfflineBanner = isOfflineMode && !_bannerDismissed;
    final showUpdateBanner = !isOfflineMode && updateState.shouldShowBanner;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (showOfflineBanner)
              OfflineBannerWidget(
                pendingChangesCount: pendingCount,
                onDismiss: () => setState(() => _bannerDismissed = true),
              ),
            if (showUpdateBanner)
              AppUpdateBanner(
                updateInfo: updateState.availableUpdate!,
                onUpdateTap: () => showAppUpdateSheet(context),
                onDismiss: () =>
                    ref.read(appUpdateProvider.notifier).dismissBanner(),
              ),
            Expanded(child: widget.navigationShell),
          ],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceSubtle,
          border: Border(
            top: BorderSide(color: colors.border, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: _goBranch,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Hoje',
            ),
            NavigationDestination(
              icon: Icon(Icons.fitness_center_outlined),
              selectedIcon: Icon(Icons.fitness_center_rounded),
              label: 'Treino',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: 'Progresso',
            ),
          ],
        ),
      ),
    );
  }
}
