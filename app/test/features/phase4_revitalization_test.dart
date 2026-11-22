import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_fitness_os/core/network/connectivity_providers.dart';
import 'package:personal_fitness_os/core/storage/shared_preferences_provider.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/core/widgets/liftr_brand_mark.dart';
import 'package:personal_fitness_os/core/widgets/liftr_progress_bar.dart';
import 'package:personal_fitness_os/features/auth/presentation/screens/login_screen.dart';
import 'package:personal_fitness_os/features/auth/presentation/screens/register_screen.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/widgets/muscle_filter_chips.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/progress_segmented_control.dart';
import 'package:personal_fitness_os/features/settings/presentation/screens/settings_screen.dart';
import 'package:personal_fitness_os/features/training/domain/entities/set_template.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout_exercise.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/weekly_muscle_volume_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  group('Fase 4 — Treinos, Progresso, Identidade e Biblioteca', () {
    testWidgets(
        'WeeklyMuscleVolumeCard uses botanical >=10 sets vs titanium <10 without rainbow hues',
        (tester) async {
      const chestEx = Exercise(
        id: 'e1',
        name: 'Supino',
        primaryMuscleGroup: 'chest',
      );
      const backEx = Exercise(
        id: 'e2',
        name: 'Remada',
        primaryMuscleGroup: 'back',
      );

      final plan = TrainingPlan(
        id: 'p1',
        userId: 'u1',
        name: 'Push Pull',
        isActive: true,
        workouts: [
          Workout(
            id: 'w1',
            trainingPlanId: 'p1',
            name: 'Day 1',
            exercises: [
              WorkoutExercise(
                id: 'we1',
                workoutId: 'w1',
                exerciseId: 'e1',
                exercise: chestEx,
                setTemplates: List.generate(
                  10,
                  (i) => SetTemplate(
                    id: 'st-$i',
                    workoutExerciseId: 'we1',
                    setNumber: i + 1,
                  ),
                ),
              ),
              WorkoutExercise(
                id: 'we2',
                workoutId: 'w1',
                exerciseId: 'e2',
                exercise: backEx,
                setTemplates: List.generate(
                  4,
                  (i) => SetTemplate(
                    id: 'sb-$i',
                    workoutExerciseId: 'we2',
                    setNumber: i + 1,
                  ),
                ),
              ),
            ],
          ),
        ],
      );

      final theme = AppTheme.dark();
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(body: WeeklyMuscleVolumeCard(plan: plan)),
        ),
      );

      final bars = tester
          .widgetList<LiftrProgressBar>(find.byType(LiftrProgressBar))
          .toList();
      final appColors = theme.extension<AppColors>()!;
      expect(bars, hasLength(6));
      // Peito = 10 sets (>= 10) -> botanical primary
      expect(bars[0].color, appColors.primary);
      // Costas = 4 sets (1..9) -> titanium textSecondary
      expect(bars[1].color, appColors.textSecondary);
      // Pernas = 0 sets -> muted textTertiary
      expect(bars[2].color, appColors.textTertiary);
    });

    testWidgets(
        'ProgressSegmentedControl exposes 48dp touch height without BoxShadow',
        (tester) async {
      int selected = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => ProgressSegmentedControl(
                selectedIndex: selected,
                onChanged: (idx) => setState(() => selected = idx),
              ),
            ),
          ),
        ),
      );

      final controlInk = find.ancestor(
        of: find.text('Exercícios'),
        matching: find.byType(InkWell),
      );
      expect(tester.getSize(controlInk).height, greaterThanOrEqualTo(48));

      final containers = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .toList();
      for (final c in containers) {
        final dec = c.decoration as BoxDecoration?;
        expect(dec?.boxShadow, isNull);
      }
    });

    testWidgets('LoginScreen and RegisterScreen use LiftrWordmark',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(theme: AppTheme.dark(), home: const LoginScreen()),
        ),
      );
      expect(find.byType(LiftrWordmark), findsOneWidget);

      await tester.pumpWidget(
        ProviderScope(
          child:
              MaterialApp(theme: AppTheme.dark(), home: const RegisterScreen()),
        ),
      );
      expect(find.byType(LiftrWordmark), findsOneWidget);
    });

    testWidgets(
        'MuscleFilterChips renders 48dp strip with botanical active fill and onPrimary contrast',
        (tester) async {
      final theme = AppTheme.dark();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: theme,
            home: const Scaffold(body: MuscleFilterChips()),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(MuscleFilterChips)).height,
        greaterThanOrEqualTo(48),
      );

      final selectedChip = tester.widget<FilterChip>(
        find.ancestor(
          of: find.text('Todos'),
          matching: find.byType(FilterChip),
        ),
      );
      final appColors = theme.extension<AppColors>()!;
      expect(selectedChip.selected, isTrue);
      expect(selectedChip.selectedColor, appColors.primary);
      expect(selectedChip.labelStyle?.color, appColors.onPrimary);
    });

    testWidgets('SettingsScreen uses proper singular and plural pendência copy',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('singular-pending'),
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            isOfflineModeProvider.overrideWith((_) => true),
            pendingSyncCountProvider.overrideWith((_) => 1),
          ],
          child: MaterialApp(theme: AppTheme.dark(), home: const SettingsScreen()),
        ),
      );
      await tester.pump();
      expect(find.text('Offline · 1 pendência'), findsOneWidget);

      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('plural-pending'),
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            isOfflineModeProvider.overrideWith((_) => true),
            pendingSyncCountProvider.overrideWith((_) => 3),
          ],
          child: MaterialApp(theme: AppTheme.dark(), home: const SettingsScreen()),
        ),
      );
      await tester.pump();
      expect(find.text('Offline · 3 pendências'), findsOneWidget);
    });
  });
}
