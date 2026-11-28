import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/network/connectivity_providers.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/update/app_update_providers.dart';
import 'package:personal_fitness_os/core/update/app_update_widgets.dart';
import 'package:personal_fitness_os/core/widgets/offline_banner_widget.dart';
import 'package:personal_fitness_os/core/widgets/liftr_icon.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';

class AppShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _bannerDismissed = false;

  static const _destinations =
      <({String label, LiftrIconName icon, LiftrIconName activeIcon})>[
        (
          label: 'Hoje',
          icon: LiftrIconName.today,
          activeIcon: LiftrIconName.todayFilled,
        ),
        (
          label: 'Treino',
          icon: LiftrIconName.training,
          activeIcon: LiftrIconName.trainingFilled,
        ),
        (
          label: 'Progresso',
          icon: LiftrIconName.progress,
          activeIcon: LiftrIconName.progressFilled,
        ),
      ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isOffline = ref.read(isOfflineModeProvider);
      final hasActiveSession =
          ref.read(sessionLocalDataSourceProvider)?.getActiveSession() != null;
      unawaited(
        ref
            .read(appUpdateProvider.notifier)
            .checkSilentlyIfDue(
              isOffline: isOffline,
              hasActiveSession: hasActiveSession,
            ),
      );
    });
  }

  void _goBranch(int index) {
    HapticFeedback.selectionClick();
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
    final selectedIndex = widget.navigationShell.currentIndex;

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
          color: colors.background,
          border: Border(top: BorderSide(color: colors.divider)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
            child: Row(
              children: List.generate(_destinations.length, (index) {
                final item = _destinations[index];
                final isSelected = selectedIndex == index;
                final fg = isSelected
                    ? colors.textPrimary
                    : colors.textSecondary;

                return Expanded(
                  child: Semantics(
                    label: item.label,
                    selected: isSelected,
                    button: true,
                    child: InkWell(
                      onTap: () => _goBranch(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LiftrIcon(
                              isSelected ? item.activeIcon : item.icon,
                              color: fg,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.labelSmall?.copyWith(
                                color: fg,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
