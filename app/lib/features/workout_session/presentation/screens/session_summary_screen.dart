import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/network/connectivity_providers.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/core/widgets/offline_banner_widget.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';
import 'package:personal_fitness_os/features/progression/domain/services/progression_engine.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';

class _PromotedExercise {
  const _PromotedExercise({
    required this.name,
    required this.nextWeightKg,
    required this.deltaKg,
  });

  final String name;
  final double nextWeightKg;
  final double deltaKg;
}

class SessionSummaryScreen extends ConsumerWidget {
  const SessionSummaryScreen({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  List<_PromotedExercise> _detectPromotions(WorkoutSession session) {
    final promoted = <_PromotedExercise>[];
    for (final SessionExercise se in session.exercises) {
      final workingSets = se.sets.where((s) => s.isWorkingSet).toList();
      if (workingSets.isEmpty) continue;
      final hitMaxOnAll =
          workingSets.every((s) => s.repsCompleted >= se.targetRepsMax);
      if (!hitMaxOnAll) continue;

      final maxWeight = workingSets.fold<double>(
        0.0,
        (maxVal, s) => s.weightKg > maxVal ? s.weightKg : maxVal,
      );
      if (maxWeight <= 0) continue;

      final delta =
          ProgressionEngine.defaultWeightIncrement(se.exercise?.equipment);
      promoted.add(
        _PromotedExercise(
          name: se.exercise?.name ?? 'Exercício',
          nextWeightKg: maxWeight + delta,
          deltaKg: delta,
        ),
      );
    }
    return promoted;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final fitnessColors = context.fitnessColors;
    final sessionAsync = ref.watch(liveSessionDetailProvider(sessionId));
    final isOffline = ref.watch(isOfflineModeProvider);
    final isOnline = !isOffline;
    final pendingCount = ref.watch(pendingSyncCountProvider);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: sessionAsync.when(
        loading: () => const SafeArea(child: LiftrScreenSkeleton()),
        error: (err, _) => ErrorStateWidget(
          message: err.toString(),
          onRetry: () => ref.invalidate(liveSessionDetailProvider(sessionId)),
        ),
        data: (session) {
          final minutes = math.max(1, session.durationSeconds ~/ 60);
          final targetSets = session.exercises.fold<int>(
            0,
            (sum, e) => sum + e.targetSetsCount,
          );
          final setsLabel = targetSets > 0
              ? '${session.totalWorkingSetsCount}/$targetSets'
              : '${session.totalWorkingSetsCount}';
          final volumeFormatted = NumberFormat('#,##0', 'pt_BR').format(
            session.totalVolumeKg.round(),
          );
          final dateObj = session.completedAt ?? session.startedAt;
          final dateLabel =
              DateFormat('EEEE, d MMM', 'pt_BR').format(dateObj);
          final capitalizedDate =
              dateLabel[0].toUpperCase() + dateLabel.substring(1);
          final promoted = _detectPromotions(session);

          return Stack(
            children: [
              // Emerald radial top glow
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -1.0),
                        radius: 0.9,
                        colors: [
                          fitnessColors.progressUp.withValues(alpha: 0.12),
                          colors.background.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    if (isOffline)
                      OfflineBannerWidget(pendingChangesCount: pendingCount),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(0, 28, 0, 24),
                        children: [
                          ResponsiveContainer(
                            child: Column(
                              children: [
                                // Celebration Halo
                                Transform.rotate(
                                  angle: -3 * math.pi / 180,
                                  child: Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: fitnessColors.progressUp,
                                      borderRadius: BorderRadius.circular(
                                        radius.xl,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: fitnessColors.progressUp
                                              .withValues(alpha: 0.22),
                                          blurRadius: 30,
                                          spreadRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.check_rounded,
                                      size: 36,
                                      color: fitnessColors.onSuccess,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'SESSÃO FINALIZADA',
                                  style: AppTypography.eyebrow(context),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Treino concluído!',
                                  style: context.textTheme.displayMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${session.workoutName} · $capitalizedDate',
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 26),

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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                      color: fitnessColors
                                                          .progressUp,
                                                      fontWeight:
                                                          FontWeight.w700,
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
                                            tween:
                                                Tween(begin: 0.0, end: 1.0),
                                            duration: disableAnimations
                                                ? Duration.zero
                                                : Duration(
                                                    milliseconds:
                                                        280 + (idx * 60),
                                                  ),
                                            curve: Curves.easeOutQuart,
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 10,
                                              ),
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  top: BorderSide(
                                                    color: fitnessColors
                                                        .progressUp
                                                        .withValues(
                                                      alpha: 0.16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          item.name,
                                                          style: context
                                                              .textTheme
                                                              .titleSmall,
                                                        ),
                                                        const SizedBox(
                                                          height: 2,
                                                        ),
                                                        Text(
                                                          'Nova meta: ${_formatKg(item.nextWeightKg)} kg',
                                                          style: context
                                                              .textTheme
                                                              .bodySmall
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
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: fitnessColors
                                                          .progressUp
                                                          .withValues(
                                                        alpha: 0.14,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        radius.full,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      '+${_formatKg(item.deltaKg)} kg',
                                                      style: context
                                                          .textTheme.labelMedium
                                                          ?.copyWith(
                                                        color: fitnessColors
                                                            .progressUp,
                                                        fontFeatures:
                                                            AppTypography
                                                                .tabularFeatures,
                                                      ),
                                                    ),
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
                                        Icons.chat_bubble_outline_rounded,
                                        size: 15,
                                        color: isOnline
                                            ? fitnessColors.progressUp
                                            : colors.textTertiary,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          isOnline
                                              ? 'Sincronizado com o WhatsApp ✓'
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
                          label: 'Voltar para Hoje',
                          onPressed: () => context.go('/'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
