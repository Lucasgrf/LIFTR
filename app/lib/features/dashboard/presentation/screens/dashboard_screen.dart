import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/extensions/date_extensions.dart';
import 'package:personal_fitness_os/core/providers/clock_provider.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/workout_card_palette.dart';
import 'package:personal_fitness_os/core/utils/duration_formatter.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/liftr_icon.dart';
import 'package:personal_fitness_os/core/widgets/liftr_blank_fiche.dart';
import 'package:personal_fitness_os/core/widgets/liftr_sheet.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';
import 'package:personal_fitness_os/features/dashboard/domain/entities/day_adherence.dart';
import 'package:personal_fitness_os/features/dashboard/domain/entities/weekly_stats.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/widgets/last_completed_workout_card.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/widgets/today_workout_banner.dart';
import 'package:personal_fitness_os/features/settings/presentation/providers/settings_providers.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/workout_queue_provider.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/import_plan_sheet.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/weekly_comparison_data.dart';
import 'package:personal_fitness_os/features/weekly_comparison/presentation/providers/weekly_comparison_providers.dart';
import 'package:personal_fitness_os/features/weekly_comparison/presentation/widgets/log_cardio_modal.dart';
import 'package:personal_fitness_os/features/workout_session/domain/helpers/session_exercise_builder.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isStartingWorkout = false;

  Future<void> _startWorkout(Workout? workout) async {
    setState(() => _isStartingWorkout = true);
    try {
      final useCase = ref.read(startWorkoutSessionUseCaseProvider);
      final defaultRest = ref.read(userSettingsProvider).defaultRestSeconds;
      final initialExercises = workout != null && workout.exercises.isNotEmpty
          ? buildInitialSessionExercises(
              workout,
              defaultRestSeconds: defaultRest,
            )
          : null;
      final result = await useCase.execute(
        workoutId: workout?.id,
        workoutName: workout?.name ?? 'Treino Avulso',
        initialExercises: initialExercises,
      );
      if (!mounted) return;
      result.fold(
        (session) {
          ref.invalidate(dashboardDataProvider);
          context.push('/session/${session.id}');
        },
        (failure) => context.showSnackBar(
          'Erro ao iniciar treino: ${failure.message}',
          isError: true,
        ),
      );
    } finally {
      if (mounted) setState(() => _isStartingWorkout = false);
    }
  }

  WorkoutSession? _previousSessionFor(
    WorkoutSession current,
    List<WorkoutSession> sessions,
  ) {
    final previous =
        sessions
            .where(
              (session) =>
                  session.id != current.id &&
                  session.workoutId == current.workoutId &&
                  (session.completedAt ?? session.startedAt).isBefore(
                    current.completedAt ?? current.startedAt,
                  ),
            )
            .toList()
          ..sort(
            (a, b) => (b.completedAt ?? b.startedAt).compareTo(
              a.completedAt ?? a.startedAt,
            ),
          );
    return previous.firstOrNull;
  }

  void _openSkipOrSwapSheet(
    BuildContext context,
    TrainingPlan plan,
    List<Workout> orderedWorkouts,
  ) {
    final colors = context.appColors;
    showLiftrSheet<void>(
      context: context,
      title: 'Escolher a ficha de hoje',
      trailing: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        tooltip: 'Fechar',
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        icon: LiftrIcon(LiftrIconName.close, color: colors.textPrimary),
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      builder: (sheetContext) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              button: true,
              label:
                  'Pular ${orderedWorkouts.first.name}. Ela vai para o fim do baralho',
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref
                      .read(workoutQueueProvider.notifier)
                      .skipFirstToEnd(plan.id, orderedWorkouts);
                  Navigator.pop(sheetContext);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      LiftrIcon(
                        LiftrIconName.skip,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pular ${orderedWorkouts.first.name}',
                              style: context.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Ela vai para o fim do baralho',
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _QueueSheetCards(
              workouts: orderedWorkouts,
              selectedId: orderedWorkouts.first.id,
              onSelect: (workout) {
                HapticFeedback.selectionClick();
                ref
                    .read(workoutQueueProvider.notifier)
                    .selectNext(plan.id, orderedWorkouts, workout.id);
                Navigator.pop(sheetContext);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isNightMode =
        Theme.of(context).brightness == Brightness.dark &&
        MediaQuery.sizeOf(context).width >= 390 &&
        MediaQuery.sizeOf(context).width <= 430 &&
        MediaQuery.textScalerOf(context).scale(14) < 20;
    final settings = ref.watch(userSettingsProvider);
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final weekSummaryAsync = ref.watch(currentWeekSummaryProvider);
    ref.watch(workoutQueueProvider);
    final now = ref.watch(appClockProvider)();
    final rawDate = ptBrDateFormat(
      "EEEE, d 'de' MMMM",
    ).format(now).replaceFirst('-feira', '');
    final date = '${rawDate[0].toUpperCase()}${rawDate.substring(1)}';

    Future<void> refreshDashboard() async {
      final hadData = ref.read(dashboardDataProvider).hasValue;
      Object? refreshError;
      StackTrace? refreshStack;
      await Future.wait<void>([
        ref
            .refresh(currentWeekSummaryProvider.future)
            .then<void>((_) {}, onError: (Object _, StackTrace _) {}),
        ref
            .refresh(dashboardDataProvider.future)
            .then<void>(
              (_) {},
              onError: (Object error, StackTrace stack) {
                refreshError = error;
                refreshStack = stack;
              },
            ),
      ]);
      if (refreshError != null && hadData && context.mounted) {
        final message = userFacingMessage(
          refreshError!,
          stackTrace: refreshStack,
          context: 'DashboardScreen.refreshDashboard',
        );
        context.showSnackBar('$message Mostrando dados salvos.');
      }
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: dashboardAsync.when(
        skipLoadingOnRefresh: dashboardAsync.hasValue,
        skipError: dashboardAsync.hasValue,
        loading: () => const LiftrScreenSkeleton(),
        error: (error, stack) => RefreshIndicator(
          color: colors.primary,
          onRefresh: refreshDashboard,
          child: LayoutBuilder(
            builder: (context, constraints) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: ErrorStateWidget(
                    message: userFacingMessage(
                      error,
                      stackTrace: stack,
                      context: 'DashboardScreen.build',
                    ),
                    safetyNote: offlineSafetyNoteFor(error),
                    onRetry: () => ref.invalidate(dashboardDataProvider),
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          final plan = data.activePlan;
          final orderedWorkouts = plan != null && plan.workouts.isNotEmpty
              ? ref
                    .read(workoutQueueProvider.notifier)
                    .orderedWorkouts(
                      plan.id,
                      plan.workouts,
                      lastCompletedWorkoutId:
                          data.lastCompletedSession?.workoutId,
                    )
              : const <Workout>[];
          final workout = orderedWorkouts.isNotEmpty
              ? orderedWorkouts.first
              : data.todayWorkout;
          final completedWorkout = data.activePlan?.workouts
              .where((item) => item.id == data.lastCompletedSession?.workoutId)
              .firstOrNull;
          final hasDockCta = data.activeSession != null || workout != null;

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: colors.primary,
                  onRefresh: refreshDashboard,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(0, 32, 0, 32),
                    children: [
                      ResponsiveContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _DashboardHeader(
                              date: date,
                              displayName: settings.displayName,
                              avatarUrl: settings.avatarUrl,
                              avatarStoragePath: settings.avatarStoragePath,
                              showProfile: plan != null && !isNightMode,
                            ),
                            const SizedBox(height: 16),
                            TodayWorkoutBanner(
                              activeSession: data.activeSession,
                              todayWorkout: workout,
                              activePlan: plan,
                              isLoading: _isStartingWorkout,
                              queuePosition: orderedWorkouts.isNotEmpty
                                  ? 1
                                  : null,
                              queueTotal: orderedWorkouts.isNotEmpty
                                  ? orderedWorkouts.length
                                  : null,
                              onStartWorkout: _startWorkout,
                              onSkipOrSwap: null,
                            ),
                            if (workout == null &&
                                data.activeSession == null) ...[
                              const LiftrBlankFicheDeck(),
                              const SizedBox(height: 24),
                              _EmptyTodayActions(
                                onPaste: () => ImportPlanSheet.show(context),
                              ),
                            ],
                            if (!isNightMode &&
                                data.activeSession == null &&
                                workout != null &&
                                orderedWorkouts.length > 1) ...[
                              _QueueEdges(
                                workouts: orderedWorkouts.skip(1).toList(),
                              ),
                              const SizedBox(height: 12),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final nextWorkout = Text(
                                    'Depois vem ${orderedWorkouts[1].name}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.textTheme.bodyMedium
                                        ?.copyWith(color: colors.textSecondary),
                                  );
                                  final swapButton = TextButton(
                                    onPressed: () => _openSkipOrSwapSheet(
                                      context,
                                      plan!,
                                      orderedWorkouts,
                                    ),
                                    style: TextButton.styleFrom(
                                      minimumSize: const Size(48, 48),
                                      foregroundColor: colors.textPrimary,
                                      textStyle: context.textTheme.labelMedium
                                          ?.copyWith(
                                            decoration:
                                                TextDecoration.underline,
                                            decorationThickness: 1.5,
                                          ),
                                    ),
                                    child: const Text('Trocar treino'),
                                  );

                                  if (MediaQuery.textScalerOf(
                                        context,
                                      ).scale(14) >=
                                      20) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        nextWorkout,
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: swapButton,
                                        ),
                                      ],
                                    );
                                  }

                                  return Row(
                                    children: [
                                      Expanded(child: nextWorkout),
                                      swapButton,
                                    ],
                                  );
                                },
                              ),
                            ],
                            if (isNightMode &&
                                data.activeSession == null &&
                                workout != null &&
                                orderedWorkouts.length > 1)
                              _QueueEdges(
                                workouts: orderedWorkouts.skip(1).toList(),
                                compactSpacing: true,
                              ),
                            if (!isNightMode &&
                                data.lastCompletedSession != null) ...[
                              const SizedBox(height: 48),
                              LastCompletedWorkoutCard(
                                session: data.lastCompletedSession!,
                                previousSession: _previousSessionFor(
                                  data.lastCompletedSession!,
                                  data.weeklySessions,
                                ),
                                referenceNow: now,
                                fichaColor: completedWorkout == null
                                    ? null
                                    : WorkoutCardPalette.forIndex(
                                        completedWorkout.sortOrder,
                                      ),
                              ),
                            ],
                            if (data.activePlan != null ||
                                data.activeSession != null ||
                                data.lastCompletedSession != null ||
                                data.weeklySessions.isNotEmpty) ...[
                              const SizedBox(height: 48),
                              _ThisWeekStrip(
                                stats: data.weeklyStats,
                                sessions: data.weeklySessions,
                                comparison: weekSummaryAsync.asData?.value,
                                onCompare: () =>
                                    context.push('/weekly-comparison'),
                                onLogCardio: () => LogCardioModal.show(context),
                                now: now,
                                compactHtmlNight: isNightMode,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (hasDockCta)
                _TodayStartDock(
                  workout: workout,
                  activeSession: data.activeSession,
                  isLoading: _isStartingWorkout,
                  onStart: () {
                    final activeSession = data.activeSession;
                    if (activeSession != null) {
                      context.push('/session/${activeSession.id}');
                    } else {
                      _startWorkout(workout);
                    }
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.date,
    required this.displayName,
    required this.avatarUrl,
    required this.avatarStoragePath,
    required this.showProfile,
  });

  final String date;
  final String? displayName;
  final String? avatarUrl;
  final String? avatarStoragePath;
  final bool showProfile;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Expanded(
          child: Text(
            date,
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
        if (showProfile) ...[
          Semantics(
            label: 'Abrir perfil',
            button: true,
            child: InkWell(
              onTap: () => context.push('/profile'),
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.surfaceSubtle,
                      border: Border.all(color: colors.borderSubtle),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _HeaderAvatarThumb(
                      avatarUrl: avatarUrl,
                      storagePath: avatarStoragePath,
                      displayName: displayName,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
        Semantics(
          label: 'Abrir configurações',
          button: true,
          child: InkWell(
            onTap: () => context.push('/settings'),
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: LiftrIcon(
                      LiftrIconName.settings,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderAvatarThumb extends StatelessWidget {
  const _HeaderAvatarThumb({
    required this.avatarUrl,
    required this.storagePath,
    required this.displayName,
  });

  final String? avatarUrl;
  final String? storagePath;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final name = displayName?.trim().split(RegExp(r'\s+')) ?? const <String>[];
    final initials = name.isEmpty
        ? 'LF'
        : name.length == 1
        ? name.first.characters.take(2).toString().toUpperCase()
        : '${name.first.characters.first}${name.last.characters.first}'
              .toUpperCase();
    final url = avatarUrl?.trim() ?? '';
    final cachePx = (36 * MediaQuery.devicePixelRatioOf(context)).round().clamp(
      64,
      256,
    );
    Widget fallback() => Center(
      child: Text(
        initials,
        style: context.textTheme.bodySmall?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: url,
        cacheKey: storagePath?.isNotEmpty == true ? storagePath : url,
        memCacheWidth: cachePx,
        memCacheHeight: cachePx,
        fit: BoxFit.cover,
        errorWidget: (_, _, _) => fallback(),
      );
    }
    if (url.isNotEmpty) {
      return Image.file(
        File(url),
        fit: BoxFit.cover,
        cacheWidth: cachePx,
        cacheHeight: cachePx,
        errorBuilder: (_, _, _) => fallback(),
      );
    }
    return fallback();
  }
}

class _QueueEdges extends StatelessWidget {
  const _QueueEdges({required this.workouts, this.compactSpacing = false});

  final List<Workout> workouts;
  final bool compactSpacing;

  @override
  Widget build(BuildContext context) {
    final visible = workouts.take(4).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    final step = compactSpacing ? 7.0 : 8.0;
    return SizedBox(
      height: step * (visible.length - 1) + 10,
      child: Stack(
        children: [
          for (var index = 0; index < visible.length; index++)
            Positioned(
              top: index * step,
              left: (index + 1) * 8,
              right: (index + 1) * 8,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: WorkoutCardPalette.forIndex(visible[index].sortOrder),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(6),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TodayStartDock extends StatelessWidget {
  const _TodayStartDock({
    required this.workout,
    required this.activeSession,
    required this.isLoading,
    required this.onStart,
  });

  final Workout? workout;
  final WorkoutSession? activeSession;
  final bool isLoading;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final label = activeSession != null
        ? 'Continuar ${activeSession!.workoutName}'
        : 'Começar ${workout!.name}';
    final cardColor = activeSession != null
        ? WorkoutCardPalette.forWorkout(activeSession!.workoutName)
        : WorkoutCardPalette.forIndex(workout!.sortOrder);

    return ColoredBox(
      color: colors.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Semantics(
          button: true,
          label: label,
          child: Material(
            color: colors.textPrimary,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: isLoading ? null : onStart,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 56,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLoading)
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.background,
                          ),
                        )
                      else ...[
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Flexible(
                        child: Text(
                          isLoading ? 'Iniciando treino' : label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: context.textTheme.labelLarge?.copyWith(
                            color: colors.background,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyTodayActions extends StatelessWidget {
  const _EmptyTodayActions({required this.onPaste});

  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 56,
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => context.push('/training/new'),
          icon: const LiftrIcon(LiftrIconName.plus),
          label: const Text('Montar programa'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 56),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 56,
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPaste,
          icon: const LiftrIcon(LiftrIconName.copy),
          label: const Text('Colar código de programa'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 56),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
    ],
  );
}

class _ThisWeekStrip extends StatelessWidget {
  const _ThisWeekStrip({
    required this.stats,
    required this.sessions,
    required this.comparison,
    required this.onCompare,
    required this.onLogCardio,
    required this.now,
    this.compactHtmlNight = false,
  });

  final WeeklyStats stats;
  final List<WorkoutSession> sessions;
  final WeeklyComparisonData? comparison;
  final VoidCallback onCompare;
  final VoidCallback onLogCardio;
  final DateTime now;
  final bool compactHtmlNight;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final weekdays = const ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final daysByDate = <DateTime, dynamic>{};
    for (final day in stats.days) {
      final date = day.date;
      daysByDate[DateTime(date.year, date.month, date.day)] = day;
    }
    final cardioSeconds = comparison?.currentWeek.cardioDurationSeconds ?? 0;
    final cardioDelta = comparison?.cardioDeltaSeconds;
    final cardioChange = cardioDelta == null
        ? ''
        : cardioDelta < 0
        ? ', ${formatCardioSeconds(cardioDelta.abs())} a menos que na semana passada'
        : cardioDelta > 0
        ? ', ${formatCardioSeconds(cardioDelta)} a mais que na semana passada'
        : ', igual à semana passada';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Esta semana', style: context.textTheme.titleLarge),
            ),
            if (!compactHtmlNight)
              TextButton(
                onPressed: onCompare,
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: colors.textPrimary,
                  textStyle: context.textTheme.labelMedium?.copyWith(
                    decoration: TextDecoration.underline,
                    decorationThickness: 1.5,
                  ),
                ),
                child: const Text('Comparar'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var index = 0; index < 7; index++)
              Expanded(
                child: _WeekdayStamp(
                  label: weekdays[index],
                  date: monday.add(Duration(days: index)),
                  data: daysByDate[monday.add(Duration(days: index))],
                  sessions: sessions,
                  now: today,
                ),
              ),
          ],
        ),
        if (!compactHtmlNight) const SizedBox(height: 16),
        if (!compactHtmlNight)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              Text(
                'Cardio:',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              Text(
                '${formatCardioSeconds(cardioSeconds)}$cardioChange.',
                style: context.textTheme.bodyMedium?.copyWith(
                  fontFeatures: AppTypography.tabularFeatures,
                ),
              ),
              TextButton(
                onPressed: onLogCardio,
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: colors.textPrimary,
                  textStyle: context.textTheme.labelMedium?.copyWith(
                    decoration: TextDecoration.underline,
                    decorationThickness: 1.5,
                  ),
                ),
                child: const Text('Registrar'),
              ),
            ],
          ),
      ],
    );
  }
}

class _WeekdayStamp extends StatelessWidget {
  const _WeekdayStamp({
    required this.label,
    required this.date,
    required this.data,
    required this.sessions,
    required this.now,
  });

  final String label;
  final DateTime date;
  final DayAdherence? data;
  final List<WorkoutSession> sessions;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isToday = date == now;
    final future = date.isAfter(now);
    final session = sessions.where((item) {
      final completed = item.completedAt ?? item.startedAt;
      return completed.year == date.year &&
          completed.month == date.month &&
          completed.day == date.day;
    }).firstOrNull;
    final hasWorkout = data?.hasCompletedWorkout ?? session != null;
    final initials = !hasWorkout
        ? null
        : session == null
        ? 'TR'
        : _initials(session.workoutName);
    final muted = future ? .5 : 1.0;

    return Column(
      children: [
        Text(
          isToday ? 'hoje' : label,
          style: context.textTheme.bodySmall?.copyWith(
            color: isToday ? colors.textPrimary : colors.textSecondary,
            fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 48,
          child: Center(
            child: initials != null
                ? Opacity(
                    opacity: muted,
                    child: Transform.rotate(
                      angle: _rotationFor(date),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.danger, width: 2),
                        ),
                        child: Text(
                          initials,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: colors.danger,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isToday ? colors.textPrimary : colors.divider,
                        width: isToday ? 1.5 : 1,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'TR';
    if (parts.length == 1) return parts.first.characters.take(2).toString();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  double _rotationFor(DateTime date) {
    const angles = <double>[-.105, .087, -.052, .07];
    return angles[date.day % angles.length];
  }
}

class _QueueSheetCards extends StatelessWidget {
  const _QueueSheetCards({
    required this.workouts,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Workout> workouts;
  final String selectedId;
  final ValueChanged<Workout> onSelect;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final height = (68 + (textScale - 1) * 54).clamp(68.0, 88.0).toDouble();
    final step = height - 8;
    return SizedBox(
      height: height + step * (workouts.length - 1),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var index = 0; index < workouts.length; index++)
            Positioned(
              left: 0,
              right: 0,
              top: index * step,
              height: height,
              child: _QueueSheetCard(
                order: index + 1,
                workout: workouts[index],
                selected: workouts[index].id == selectedId,
                onTap: () => onSelect(workouts[index]),
              ),
            ),
        ],
      ),
    );
  }
}

class _QueueSheetCard extends StatelessWidget {
  const _QueueSheetCard({
    required this.order,
    required this.workout,
    required this.selected,
    required this.onTap,
  });

  final int order;
  final Workout workout;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = WorkoutCardPalette.forWorkout(workout.name);
    return Semantics(
      label:
          '$order, ${workout.name}, ${workout.exercises.length} exercícios, ${workout.totalWorkingSetsCount} séries',
      button: true,
      selected: selected,
      child: Transform.translate(
        offset: Offset(0, selected ? -4 : 0),
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(6),
          elevation: selected ? 4 : 0,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '$order',
                      style: context.textTheme.displaySmall?.copyWith(
                        color: WorkoutCardPalette.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workout.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodyLarge?.copyWith(
                            color: WorkoutCardPalette.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${workout.exercises.length} exercícios, ${workout.totalWorkingSetsCount} séries',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: WorkoutCardPalette.secondaryInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    LiftrIcon(
                      LiftrIconName.check,
                      color: WorkoutCardPalette.ink,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
