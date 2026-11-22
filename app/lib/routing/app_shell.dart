import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/network/connectivity_providers.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_motion.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
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

  static const _destinations = <({String label, IconData icon, IconData activeIcon})>[
    (
      label: 'Hoje',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    (
      label: 'Treino',
      icon: Icons.fitness_center_outlined,
      activeIcon: Icons.fitness_center_rounded,
    ),
    (
      label: 'Progresso',
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
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
        ref.read(appUpdateProvider.notifier).checkSilentlyIfDue(
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
    final motion = context.appMotion;
    final radius = context.appRadius;
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.surfaceSubtle,
          border: Border(
            top: BorderSide(color: colors.border, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(_destinations.length, (index) {
                final item = _destinations[index];
                final isSelected = selectedIndex == index;
                final fg = isSelected ? colors.primaryLight : colors.textTertiary;

                return Expanded(
                  child: Semantics(
                    label: item.label,
                    selected: isSelected,
                    button: true,
                    child: InkWell(
                      onTap: () => _goBranch(index),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: motion.resolve(context, motion.fast),
                            curve: motion.curveStandard,
                            width: isSelected ? 24 : 0,
                            height: 2.5,
                            margin: const EdgeInsets.only(bottom: 7),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(radius.full),
                            ),
                          ),
                          Icon(
                            isSelected ? item.activeIcon : item.icon,
                            size: 22,
                            color: fg,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.labelSmall?.copyWith(
                              color: fg,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ],
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
