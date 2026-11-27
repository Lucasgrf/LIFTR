import 'package:personal_fitness_os/core/utils/pt_br_copy_utils.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_entry.dart';
import 'package:personal_fitness_os/features/insights/domain/entities/fitness_insight.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/nutrition_goal.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';

class DeterministicInsightsEngine {
  const DeterministicInsightsEngine();

  List<FitnessInsight> evaluate({
    required List<WorkoutSession> sessions,
    required List<WeightEntry> weightHistory,
    NutritionGoal? nutritionGoal,
    required DateTime now,
  }) {
    final insights = <FitnessInsight>[];

    // Rule 1: Weekly Volume Spike (>25% increase)
    final volumeInsight = _checkVolumeSpike(sessions, now);
    if (volumeInsight != null) insights.add(volumeInsight);

    // Rule 2: High Perceived Exertion / Fatigue Alert (RPE avg >= 8.8 in recent sessions)
    final fatigueInsight = _checkHighFatigue(sessions);
    if (fatigueInsight != null) insights.add(fatigueInsight);

    // Rule 3: Weight vs Nutrition Goal Alignment
    final nutritionInsight = _checkWeightNutritionAlignment(weightHistory, nutritionGoal, now);
    if (nutritionInsight != null) insights.add(nutritionInsight);

    // Rule 4: Consistency Celebration (>= 4 workouts in last 7 days)
    final consistencyInsight = _checkConsistency(sessions, now);
    if (consistencyInsight != null) insights.add(consistencyInsight);

    return insights;
  }

  FitnessInsight? _checkVolumeSpike(List<WorkoutSession> sessions, DateTime now) {
    final currentWeekStart = now.subtract(const Duration(days: 7));
    final prevWeekStart = now.subtract(const Duration(days: 14));

    final currentWeekSessions = sessions.where((s) {
      final date = s.completedAt ?? s.startedAt;
      return date.isAfter(currentWeekStart) && date.isBefore(now.add(const Duration(seconds: 1)));
    }).toList();

    final prevWeekSessions = sessions.where((s) {
      final date = s.completedAt ?? s.startedAt;
      return date.isAfter(prevWeekStart) && date.isBefore(currentWeekStart);
    }).toList();

    final currentVol = currentWeekSessions.fold(0.0, (sum, s) => sum + s.totalVolumeKg);
    final prevVol = prevWeekSessions.fold(0.0, (sum, s) => sum + s.totalVolumeKg);

    if (prevVol > 0 && currentVol > prevVol * 1.25) {
      final percent = (((currentVol - prevVol) / prevVol) * 100).round();
      return FitnessInsight(
        id: 'insight-volume-spike',
        title: 'Aumento expressivo de volume',
        description: 'Seu volume semanal aumentou em $percent% comparado à semana anterior. Monitore a recuperação e dores articulares para evitar overreaching.',
        category: InsightCategory.volume,
        severity: InsightSeverity.warning,
        createdAt: now,
      );
    }
    return null;
  }

  FitnessInsight? _checkHighFatigue(List<WorkoutSession> sessions) {
    if (sessions.length < 3) return null;

    final last3Sessions = sessions.take(3).where((s) => s.perceivedExertion != null).toList();
    if (last3Sessions.length >= 3) {
      final avgRpe = last3Sessions.fold(0.0, (sum, s) => sum + s.perceivedExertion!) / 3.0;
      if (avgRpe >= 8.8) {
        return FitnessInsight(
          id: 'insight-fatigue-alert',
          title: 'Fadiga acumulada elevada',
          description: 'A percepção média de esforço (RPE) nos seus últimos 3 treinos foi de ${avgRpe.toStringAsFixed(1)}/10. Considere um dia extra de descanso ou uma sessão regenerativa.',
          category: InsightCategory.fatigue,
          severity: InsightSeverity.alert,
          createdAt: DateTime.now(),
        );
      }
    }
    return null;
  }

  FitnessInsight? _checkWeightNutritionAlignment(
    List<WeightEntry> weightHistory,
    NutritionGoal? goal,
    DateTime now,
  ) {
    if (goal == null || weightHistory.length < 4) return null;

    final recent7d = weightHistory.where((w) => w.measuredAt.isAfter(now.subtract(const Duration(days: 7)))).toList();
    final prev14d = weightHistory.where((w) =>
        w.measuredAt.isAfter(now.subtract(const Duration(days: 14))) &&
        w.measuredAt.isBefore(now.subtract(const Duration(days: 7)))).toList();

    if (recent7d.isEmpty || prev14d.isEmpty) return null;

    final avgRecent = recent7d.fold(0.0, (sum, w) => sum + w.weightKg) / recent7d.length;
    final avgPrev = prev14d.fold(0.0, (sum, w) => sum + w.weightKg) / prev14d.length;
    final diff = avgRecent - avgPrev;

    // If goal is cutting (e.g. < 2100 kcal) and weight is rising by > 0.5kg
    if (goal.calories < 2200 && diff > 0.5) {
      return FitnessInsight(
        id: 'insight-weight-cut-divergence',
        title: 'Tendência de peso em alta com meta de déficit',
        description: 'Sua média de peso subiu +${formatWeightKgPtBr(diff)} na última semana. Verifique a precisão das pesagens de alimentos ou retenção hídrica.',
        category: InsightCategory.nutrition,
        severity: InsightSeverity.warning,
        createdAt: now,
      );
    }

    return null;
  }

  FitnessInsight? _checkConsistency(List<WorkoutSession> sessions, DateTime now) {
    final last7d = sessions.where((s) {
      final date = s.completedAt ?? s.startedAt;
      return date.isAfter(now.subtract(const Duration(days: 7))) && s.isCompleted;
    }).toList();

    if (last7d.length >= 4) {
      return FitnessInsight(
        id: 'insight-consistency-streak',
        title: 'Excelente consistência!',
        description: 'Você completou ${pluralize(last7d.length, 'treino', 'treinos')} nos últimos 7 dias. O estímulo muscular e a disciplina estão ótimos.',
        category: InsightCategory.consistency,
        severity: InsightSeverity.success,
        createdAt: now,
      );
    }

    return null;
  }
}
