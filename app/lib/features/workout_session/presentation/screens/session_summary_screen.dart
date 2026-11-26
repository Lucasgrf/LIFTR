import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/network/connectivity_providers.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_motion.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_spacing.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/utils/duration_formatter.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/liftr_badge.dart';
import 'package:personal_fitness_os/core/widgets/liftr_brand_mark.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/core/widgets/offline_banner_widget.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';
import 'package:personal_fitness_os/features/progression/domain/entities/exercise_performance_history.dart';
import 'package:personal_fitness_os/features/progression/domain/repositories/progression_repository.dart';
import 'package:personal_fitness_os/features/progression/domain/services/progression_engine.dart';
import 'package:personal_fitness_os/features/progression/presentation/providers/progression_providers.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/workout_mood_icon.dart';

class _PromotedExercise {
  const _PromotedExercise({
    required this.name,
    required this.nextWeightKg,
    required this.deltaKg,
    required this.currentWeightKg,
  });

  final String name;
  final double nextWeightKg;
  final double deltaKg;
  final double currentWeightKg;
}

class _SessionProgressionSummary {
  const _SessionProgressionSummary({
    this.promoted = const [],
    this.consolidating = const [],
  });

  final List<_PromotedExercise> promoted;
  final List<_PromotedExercise> consolidating;
}

final _sessionProgressionSummaryProvider = FutureProvider.autoDispose
    .family<_SessionProgressionSummary, String>((ref, sessionId) async {
  final session = await ref.watch(liveSessionDetailProvider(sessionId).future);
  final sessionDate = session.completedAt ?? session.startedAt;

  ProgressionRepository? repo;
  try {
    repo = ref.watch(progressionRepositoryProvider);
  } catch (_) {
    repo = null;
  }

  final promoted = <_PromotedExercise>[];
  final consolidating = <_PromotedExercise>[];

  for (final SessionExercise se in session.exercises) {
    if (se.isCardio) continue;
    final workingSets = se.sets.where((s) => s.isWorkingSet).toList();
    if (workingSets.isEmpty) continue;

    final currentPerf = ExercisePerformanceHistory(
      exerciseId: se.exerciseId,
      workoutSessionId: session.id,
      workoutName: session.workoutName,
      date: sessionDate,
      loggedSets: workingSets,
    );

    if (!ProgressionEngine.didSessionHitCeiling(
      currentPerf,
      targetRepsMax: se.targetRepsMax,
      targetRir: se.targetRir,
    )) {
      continue;
    }

    final maxWeight = currentPerf.maxWeightKg;
    if (maxWeight <= 0) continue;

    final delta =
        ProgressionEngine.defaultWeightIncrement(se.exercise?.equipment);
    final candidate = _PromotedExercise(
      name: se.exercise?.name ?? 'Exercício',
      nextWeightKg: maxWeight + delta,
      deltaKg: delta,
      currentWeightKg: maxWeight,
    );

    var hitCount = 1;
    if (repo != null) {
      try {
        final res = await repo.getRecentExercisePerformances(
          se.exerciseId,
          limit: ProgressionEngine.requiredCeilingHitsForIncrease + 2,
        );
        final histories = res.fold(
          (list) => list,
          (_) => const <ExercisePerformanceHistory>[],
        );
        for (final prev in histories) {
          if (prev.workoutSessionId == session.id) continue;
          if (prev.date.isAfter(sessionDate)) continue;
          if (prev.workingSets.isNotEmpty &&
              prev.maxWeightKg >= maxWeight - 0.01 &&
              ProgressionEngine.didSessionHitCeiling(
                prev,
                targetRepsMax: se.targetRepsMax,
                targetRir: se.targetRir,
              )) {
            hitCount++;
            if (hitCount >= ProgressionEngine.requiredCeilingHitsForIncrease) {
              break;
            }
          } else {
            break;
          }
        }
      } catch (_) {
        // Offline or uninitialized remote in isolated widget tests -> 1/2
      }
    }

    if (hitCount >= ProgressionEngine.requiredCeilingHitsForIncrease) {
      promoted.add(candidate);
    } else {
      consolidating.add(candidate);
    }
  }

  return _SessionProgressionSummary(
    promoted: promoted,
    consolidating: consolidating,
  );
});

class SessionSummaryScreen extends ConsumerWidget {
  const SessionSummaryScreen({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  List<_PromotedExercise> _detectCeilingCandidates(WorkoutSession session) {
    final candidates = <_PromotedExercise>[];
    for (final SessionExercise se in session.exercises) {
      if (se.isCardio) continue;
      final workingSets = se.sets.where((s) => s.isWorkingSet).toList();
      if (workingSets.isEmpty) continue;
      final hitMaxOnAll = ProgressionEngine.didSessionHitCeiling(
        ExercisePerformanceHistory(
          exerciseId: se.exerciseId,
          workoutSessionId: session.id,
          workoutName: session.workoutName,
          date: session.completedAt ?? session.startedAt,
          loggedSets: workingSets,
        ),
        targetRepsMax: se.targetRepsMax,
        targetRir: se.targetRir,
      );
      if (!hitMaxOnAll) continue;

      final maxWeight = workingSets.fold<double>(
        0.0,
        (maxVal, s) => s.weightKg > maxVal ? s.weightKg : maxVal,
      );
      if (maxWeight <= 0) continue;

      final delta =
          ProgressionEngine.defaultWeightIncrement(se.exercise?.equipment);
      candidates.add(
        _PromotedExercise(
          name: se.exercise?.name ?? 'Exercício',
          nextWeightKg: maxWeight + delta,
          deltaKg: delta,
          currentWeightKg: maxWeight,
        ),
      );
    }
    return candidates;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final fitnessColors = context.fitnessColors;
    final sessionAsync = ref.watch(liveSessionDetailProvider(sessionId));
    final progressionSummaryAsync =
        ref.watch(_sessionProgressionSummaryProvider(sessionId));
    final isOffline = ref.watch(isOfflineModeProvider);
    final isOnline = !isOffline;
    final pendingCount = ref.watch(pendingSyncCountProvider);
    final canPop = GoRouter.maybeOf(context)?.canPop() ?? false;

    return Scaffold(
      backgroundColor: colors.background,
      body: sessionAsync.when(
        loading: () => const SafeArea(child: LiftrScreenSkeleton()),
        error: (err, st) => ErrorStateWidget(
          message: userFacingMessage(
            err,
            stackTrace: st,
            context: 'SessionSummaryScreen.build',
          ),
          safetyNote: kOfflineDataSafetyNote,
          onRetry: () => ref.invalidate(liveSessionDetailProvider(sessionId)),
        ),
        data: (session) {
          final minutes = math.max(1, session.durationSeconds ~/ 60);
          final targetSets = session.exercises
              .where((e) => !e.isCardio)
              .fold<int>(0, (sum, e) => sum + e.targetSetsCount);
          final setsLabel = targetSets > 0
              ? '${session.totalWorkingSetsCount}/$targetSets'
              : '${session.totalWorkingSetsCount}';
          final volumeFormatted = NumberFormat('#,##0', 'pt_BR').format(
            session.totalVolumeKg.round(),
          );
          final cardioSeconds = session.totalCardioDurationSeconds;
          final hasSecondaryStrip = session.perceivedExertion != null ||
              session.executionScore != null ||
              cardioSeconds > 0;
          final dateObj = session.completedAt ?? session.startedAt;
          final dateLabel =
              DateFormat('EEEE, d MMM', 'pt_BR').format(dateObj);
          final capitalizedDate =
              dateLabel[0].toUpperCase() + dateLabel.substring(1);
          final summary = progressionSummaryAsync.asData?.value ??
              _SessionProgressionSummary(
                consolidating: _detectCeilingCandidates(session),
              );
          final promoted = summary.promoted;
          final consolidating = summary.consolidating;

          final motion = context.appMotion;
          return SafeArea(
            child: Column(
              children: [
                if (isOffline)
                  OfflineBannerWidget(pendingChangesCount: pendingCount),
                if (canPop)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
                    child: Row(
                      children: [
                        Semantics(
                          label: 'Voltar',
                          button: true,
                          child: IconButton(
                            onPressed: () => context.pop(),
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'REGISTRO DO TREINO',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.eyebrow(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(0, canPop ? 12 : 28, 0, 24),
                    children: [
                      ResponsiveContainer(
                        child: Column(
                          children: [
                            if (!canPop) ...[
                              const LiftrBrandMark(size: 18),
                              const SizedBox(height: 14),
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: colors.primaryMuted,
                                  borderRadius:
                                      BorderRadius.circular(radius.large),
                                  border: Border.all(
                                    color: fitnessColors.progressUp,
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 28,
                                  color: fitnessColors.progressUp,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'SESSÃO FINALIZADA',
                                style: AppTypography.eyebrow(context),
                              ),
                              const SizedBox(height: 6),
                            ],
                            Text(
                              canPop ? session.workoutName : 'Treino concluído',
                              style: context.textTheme.displayMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              canPop
                                  ? capitalizedDate
                                  : '${session.workoutName} · $capitalizedDate',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (session.mood != null) ...[
                              const SizedBox(height: 10),
                              WorkoutMoodChip(mood: session.mood!),
                            ],
                            const SizedBox(height: 22),

                            // Trio of objective metrics
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 18,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius:
                                    BorderRadius.circular(radius.large),
                                border: Border.all(color: colors.border),
                              ),
                              child: IntrinsicHeight(
                                child: Row(
                                  children: [
                                    _SummaryMetricCol(
                                      value: '$minutes',
                                      unit: 'min',
                                      label: 'Duração',
                                    ),
                                    VerticalDivider(
                                      width: 1,
                                      color: colors.divider,
                                    ),
                                    _SummaryMetricCol(
                                      value: setsLabel,
                                      label: 'Séries',
                                    ),
                                    VerticalDivider(
                                      width: 1,
                                      color: colors.divider,
                                    ),
                                    _SummaryMetricCol(
                                      value: volumeFormatted,
                                      unit: 'kg',
                                      label: 'Volume',
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            if (hasSecondaryStrip) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surfaceSubtle,
                                  borderRadius:
                                      BorderRadius.circular(radius.large),
                                  border: Border.all(color: colors.border),
                                ),
                                child: IntrinsicHeight(
                                  child: Row(
                                    children: [
                                      if (session.perceivedExertion !=
                                          null) ...[
                                        _SummaryMetricCol(
                                          value: session.perceivedExertion!
                                              .toStringAsFixed(1)
                                              .replaceAll('.', ','),
                                          label: 'RPE auto',
                                        ),
                                      ],
                                      if (session.perceivedExertion != null &&
                                          (session.executionScore != null ||
                                              cardioSeconds > 0))
                                        VerticalDivider(
                                          width: 1,
                                          color: colors.divider,
                                        ),
                                      if (session.executionScore != null)
                                        _SummaryMetricCol(
                                          value: '${session.executionScore}%',
                                          label: 'Execução',
                                        ),
                                      if (session.executionScore != null &&
                                          cardioSeconds > 0)
                                        VerticalDivider(
                                          width: 1,
                                          color: colors.divider,
                                        ),
                                      if (cardioSeconds > 0)
                                        _SummaryMetricCol(
                                          value: formatCardioSeconds(
                                            cardioSeconds,
                                          ),
                                          label: 'Cardio',
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            if (session.notes != null &&
                                session.notes!.trim().isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: colors.surfaceSubtle,
                                  borderRadius:
                                      BorderRadius.circular(radius.large),
                                  border: Border.all(color: colors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'NOTAS DA SESSÃO',
                                      style: AppTypography.eyebrow(context),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      session.notes!.trim(),
                                      style: context.textTheme.bodySmall?.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Unlocked load progressions (SUBIR)
                            if (promoted.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  6,
                                ),
                                decoration: BoxDecoration(
                                  color: fitnessColors.progressUp
                                      .withValues(alpha: 0.08),
                                  borderRadius:
                                      BorderRadius.circular(radius.large),
                                  border: Border.all(
                                    color: fitnessColors.progressUp
                                        .withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: fitnessColors.progressUp
                                                .withValues(alpha: 0.14),
                                            borderRadius:
                                                BorderRadius.circular(
                                              radius.small,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.north_east_rounded,
                                            size: 20,
                                            color: fitnessColors.progressUp,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'SUBIR CARGA',
                                                style: context
                                                    .textTheme.labelSmall
                                                    ?.copyWith(
                                                  color:
                                                      fitnessColors.progressUp,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 1.1,
                                                ),
                                              ),
                                              Text(
                                                'Subidas de carga desbloqueadas',
                                                style: context
                                                    .textTheme.titleSmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ...promoted.asMap().entries.map((entry) {
                                      final idx = entry.key;
                                      final item = entry.value;
                                      return TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        duration: motion.resolve(
                                          context,
                                          Duration(
                                            milliseconds: (motion
                                                        .standard
                                                        .inMilliseconds +
                                                    idx * 35)
                                                .clamp(0, 260),
                                          ),
                                        ),
                                        curve: motion.curveStandard,
                                        builder: (ctx, val, child) {
                                          return Opacity(
                                            opacity: val,
                                            child: Transform.translate(
                                              offset:
                                                  Offset(0, (1 - val) * 12),
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: Container(
                                          constraints: const BoxConstraints(
                                            minHeight: 60,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              top: BorderSide(
                                                color: fitnessColors.progressUp
                                                    .withValues(alpha: 0.16),
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.name,
                                                      style: context
                                                          .textTheme.titleSmall,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Nova meta: ${_formatKg(item.nextWeightKg)} kg',
                                                      style: context
                                                          .textTheme.bodySmall
                                                          ?.copyWith(
                                                        color: colors
                                                            .textSecondary,
                                                        fontFeatures:
                                                            AppTypography
                                                                .tabularFeatures,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              LiftrBadge(
                                                label:
                                                    '+${_formatKg(item.deltaKg)} kg',
                                                tone: LiftrBadgeTone.success,
                                                icon: Icons.north_east_rounded,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],

                            // Consolidation 1/2 ceiling block (waiting 2nd session)
                            if (consolidating.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  14,
                                  16,
                                  8,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.primaryMuted
                                      .withValues(alpha: 0.45),
                                  borderRadius:
                                      BorderRadius.circular(radius.large),
                                  border: Border.all(
                                    color:
                                        colors.primary.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: colors.primary
                                                .withValues(alpha: 0.14),
                                            borderRadius: BorderRadius.circular(
                                              radius.small,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.looks_one_rounded,
                                            size: 20,
                                            color: colors.primaryLight,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'CONSOLIDAÇÃO 1/2',
                                                style: context
                                                    .textTheme.labelSmall
                                                    ?.copyWith(
                                                  color: colors.primaryLight,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 1.1,
                                                ),
                                              ),
                                              Text(
                                                'Teto atingido · falta 1 confirmação',
                                                style: context
                                                    .textTheme.titleSmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    for (final item in consolidating)
                                      Container(
                                        constraints:
                                            const BoxConstraints(minHeight: 56),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            top: BorderSide(
                                              color: colors.borderSubtle,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.name,
                                                    style: context
                                                        .textTheme.titleSmall,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Repita o teto com ${_formatKg(item.currentWeightKg)} kg na próxima sessão para liberar +${_formatKg(item.deltaKg)} kg',
                                                    style: context
                                                        .textTheme.bodySmall
                                                        ?.copyWith(
                                                      color:
                                                          colors.textSecondary,
                                                      fontFeatures: AppTypography
                                                          .tabularFeatures,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const LiftrBadge(
                                              label: '1/2',
                                              tone: LiftrBadgeTone.brand,
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],

                            // Full workout exercises & sets log
                            if (session.exercises.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'EXERCÍCIOS REALIZADOS',
                                  style: AppTypography.eyebrow(context),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  borderRadius:
                                      BorderRadius.circular(radius.large),
                                  border: Border.all(color: colors.border),
                                ),
                                child: Column(
                                  children: [
                                    for (var i = 0;
                                        i < session.exercises.length;
                                        i++) ...[
                                      if (i > 0)
                                        Divider(
                                          height: 1,
                                          thickness: 1,
                                          color: colors.borderSubtle,
                                        ),
                                      _LoggedExerciseDetailTile(
                                        sessionExercise: session.exercises[i],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 18),

                            // WhatsApp sync pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surfaceSubtle,
                                borderRadius:
                                    BorderRadius.circular(radius.full),
                                border: Border.all(color: colors.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isOnline
                                        ? Icons.check_circle_outline_rounded
                                        : Icons.chat_bubble_outline_rounded,
                                    size: 15,
                                    color: isOnline
                                        ? fitnessColors.progressUp
                                        : colors.textTertiary,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      isOnline
                                          ? 'Sincronizado com o WhatsApp'
                                          : 'Resumo enviado para o WhatsApp quando sincronizado',
                                      style: context.textTheme.labelSmall
                                          ?.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Fixed bottom CTA
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                  child: ResponsiveContainer(
                    padding: EdgeInsets.zero,
                    child: AppButton.primary(
                      label: canPop ? 'Voltar' : 'Voltar para Hoje',
                      onPressed: () {
                        if (canPop) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatKg(double weight) {
    if (weight == weight.toInt()) return weight.toInt().toString();
    return weight.toStringAsFixed(1).replaceAll('.', ',');
  }
}

class _LoggedExerciseDetailTile extends StatelessWidget {
  const _LoggedExerciseDetailTile({required this.sessionExercise});

  final SessionExercise sessionExercise;

  String _formatKg(double w) {
    if (w == w.toInt()) return w.toInt().toString();
    return w.toStringAsFixed(1).replaceAll('.', ',');
  }

  String _setTag(LoggedSet set) {
    if (sessionExercise.isCardio) return 'Cardio';
    switch (set.setType) {
      case SetType.warmup:
        return 'AQ';
      case SetType.dropSet:
        return 'DROP';
      case SetType.mobility:
        return 'MOB';
      case SetType.rampUp:
        return 'REC';
      case SetType.myoRep:
        return 'MYO';
      case SetType.working:
        return '${set.setNumber}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;
    final radius = context.appRadius;
    final name = sessionExercise.exercise?.name ?? 'Exercício';
    final isCardio = sessionExercise.isCardio;

    final summaryText = isCardio
        ? formatCardioSeconds(sessionExercise.totalCardioDurationSeconds)
        : '${sessionExercise.completedWorkingSetsCount} séries · ${_formatKg(sessionExercise.totalVolumeKg)} kg';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: context.textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                summaryText,
                style: context.textTheme.labelSmall?.copyWith(
                  color: colors.textSecondary,
                  fontFeatures: AppTypography.tabularFeatures,
                ),
              ),
            ],
          ),
          if (sessionExercise.sets.isEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Nenhuma série registrada',
              style: context.textTheme.labelSmall?.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            for (final s in sessionExercise.sets) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          constraints: const BoxConstraints(minWidth: 32),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: s.setType == SetType.dropSet
                                ? fitnessColors.dropSetTag
                                    .withValues(alpha: 0.16)
                                : s.setType == SetType.warmup
                                    ? fitnessColors.warmupTag
                                        .withValues(alpha: 0.16)
                                    : colors.surfaceElevated,
                            borderRadius: BorderRadius.circular(radius.xs),
                          ),
                          child: Text(
                            _setTag(s),
                            style: context.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: s.setType == SetType.dropSet
                                  ? fitnessColors.dropSetTag
                                  : s.setType == SetType.warmup
                                      ? fitnessColors.warmupTag
                                      : colors.textSecondary,
                              fontFeatures: AppTypography.tabularFeatures,
                            ),
                          ),
                        ),
                        SizedBox(width: context.appSpacing.space12),
                        Expanded(
                          child: Text(
                            isCardio
                                ? '${math.max(1, s.durationMinutes)} min'
                                : '${_formatKg(s.weightKg)} kg × ${s.repsCompleted} reps',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontFeatures: AppTypography.tabularFeatures,
                            ),
                          ),
                        ),
                        if (!isCardio && s.rirActual != null)
                          Text(
                            'RIR ${s.rirActual}',
                            style: context.textTheme.labelSmall?.copyWith(
                              color: colors.textTertiary,
                              fontFeatures: AppTypography.tabularFeatures,
                            ),
                          ),
                      ],
                    ),
                    if (s.dropSets.isNotEmpty)
                      for (var dIdx = 0; dIdx < s.dropSets.length; dIdx++)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 38),
                          child: Row(
                            children: [
                              Icon(
                                Icons.subdirectory_arrow_right_rounded,
                                size: 13,
                                color: fitnessColors.dropSetTag,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Drop ${dIdx + 1}: ${_formatKg(s.dropSets[dIdx].weightKg)} kg × ${s.dropSets[dIdx].repsCompleted} reps',
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: fitnessColors.dropSetTag,
                                  fontFeatures: AppTypography.tabularFeatures,
                                ),
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SummaryMetricCol extends StatelessWidget {
  const _SummaryMetricCol({
    required this.value,
    required this.label,
    this.unit,
  });

  final String value;
  final String label;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Expanded(
      child: Column(
        children: [
          Text.rich(
            TextSpan(
              text: value,
              style: context.textTheme.headlineMedium?.copyWith(
                fontFeatures: AppTypography.tabularFeatures,
              ),
              children: [
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: context.textTheme.labelMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
