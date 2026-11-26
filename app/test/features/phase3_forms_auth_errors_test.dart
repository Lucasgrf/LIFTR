import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/storage/shared_preferences_provider.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/repositories/exercise_repository.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/providers/exercise_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/providers/history_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/exercise_history_modal.dart';
import 'package:personal_fitness_os/features/profile/presentation/providers/profile_providers.dart';
import 'package:personal_fitness_os/features/profile/presentation/screens/profile_screen.dart';
import 'package:personal_fitness_os/features/settings/presentation/providers/settings_providers.dart';
import 'package:personal_fitness_os/features/training/domain/entities/set_template.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout_exercise.dart';
import 'package:personal_fitness_os/features/training/domain/usecases/configure_set_templates.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';
import 'package:personal_fitness_os/features/training/presentation/screens/add_exercise_to_workout_screen.dart';
import 'package:personal_fitness_os/features/training/presentation/screens/configure_sets_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ToggleErrorExerciseRepo implements ExerciseRepository {
  bool shouldFail = true;

  @override
  Future<Result<Exercise, Failure>> createCustomExercise({
    required String name,
    required String primaryMuscleGroup,
    List<String>? secondaryMuscles,
    String? equipment,
    String? movementPattern,
    String? instructions,
    String? commonMistakes,
    String? videoUrl,
    String? personalNotes,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Result<void, Failure>> deleteCustomExercise(String id) async =>
      const Success(null);

  @override
  Future<Result<Exercise, Failure>> getExerciseById(String id) async =>
      throw UnimplementedError();

  @override
  Future<Result<List<Exercise>, Failure>> getExercises() async {
    if (shouldFail) {
      return const Err(NetworkFailure('SocketException: offline'));
    }
    return const Success([
      Exercise(
        id: 'ex-1',
        name: 'Supino Reto',
        primaryMuscleGroup: 'chest',
        equipment: 'barbell',
      ),
    ]);
  }

  @override
  Future<Result<Exercise, Failure>> updateExerciseNotes({
    required String exerciseId,
    required String notes,
  }) async =>
      throw UnimplementedError();
}

class _RecordingConfigureSetTemplatesUseCase
    implements ConfigureSetTemplatesUseCase {
  List<SetTemplate>? savedTemplates;

  @override
  Future<Result<List<SetTemplate>, Failure>> execute({
    required String workoutExerciseId,
    required List<SetTemplate> setTemplates,
  }) async {
    savedTemplates = setTemplates;
    return Success(setTemplates);
  }
}

class _NoopProfileRemoteController extends ProfileController {
  _NoopProfileRemoteController(Ref ref) : super(ref, null);
}

void main() {
  group('UX-04 ErrorStateWidget & Tentar novamente', () {
    testWidgets('ExerciseHistoryModal renders ErrorStateWidget and retries',
        (tester) async {
      var shouldFail = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exerciseHistoryProvider('ex-1').overrideWith((ref) async {
              if (shouldFail) {
                throw TimeoutException('Timed out');
              }
              return const [];
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const Scaffold(
              body: ExerciseHistoryModal(
                exerciseId: 'ex-1',
                exerciseName: 'Agachamento Livre',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateWidget), findsOneWidget);
      expect(find.textContaining('demorou mais que o esperado'), findsOneWidget);
      expect(find.text(kOfflineDataSafetyNote), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);

      shouldFail = false;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateWidget), findsNothing);
      expect(find.text('Nenhum histórico encontrado'), findsOneWidget);
    });

    testWidgets(
        'AddExerciseToWorkoutScreen shows ErrorStateWidget and retries on failure',
        (tester) async {
      final repo = _ToggleErrorExerciseRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exerciseRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const AddExerciseToWorkoutScreen(
              planId: 'plan-1',
              workoutId: 'w-1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateWidget), findsOneWidget);
      expect(find.textContaining('Sem conexão com a internet'), findsOneWidget);
      expect(find.text(kOfflineDataSafetyNote), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);

      repo.shouldFail = false;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateWidget), findsNothing);
      expect(find.text('Supino Reto'), findsOneWidget);
    });

    testWidgets(
        'ConfigureSetsScreen shows ErrorStateWidget with Tentar novamente on error',
        (tester) async {
      var shouldFail = true;
      const sampleWorkout = Workout(
        id: 'w-1',
        trainingPlanId: 'plan-1',
        name: 'Treino A',
        dayOfWeek: 1,
        exercises: [
          WorkoutExercise(
            id: 'we-1',
            workoutId: 'w-1',
            exerciseId: 'ex-1',
            exercise: Exercise(
              id: 'ex-1',
              name: 'Agachamento Livre',
              primaryMuscleGroup: 'legs',
              equipment: 'barbell',
            ),
            setTemplates: [
              SetTemplate(
                id: 'st-1',
                workoutExerciseId: 'we-1',
                setNumber: 1,
                setType: SetType.working,
                targetRepsMin: 8,
                targetRepsMax: 12,
                restSeconds: 120,
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workoutDetailProvider((planId: 'plan-1', workoutId: 'w-1'))
                .overrideWith((ref) async {
              if (shouldFail) {
                throw Exception('503 Service Unavailable');
              }
              return sampleWorkout;
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const ConfigureSetsScreen(
              planId: 'plan-1',
              workoutId: 'w-1',
              workoutExerciseId: 'we-1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateWidget), findsOneWidget);
      expect(
        find.textContaining('servidor está temporariamente indisponível'),
        findsOneWidget,
      );
      expect(find.text(kOfflineDataSafetyNote), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);

      shouldFail = false;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateWidget), findsNothing);
      expect(find.text('Agachamento Livre'), findsOneWidget);
    });
  });

  group('UX-02 Forms, normalized rest & PT-BR decimals', () {
    test('normalizeRestSeconds snaps off-list durations to closest option', () {
      expect(AddExerciseToWorkoutScreen.normalizeRestSeconds(45), 60);
      expect(AddExerciseToWorkoutScreen.normalizeRestSeconds(100), 90);
      expect(AddExerciseToWorkoutScreen.normalizeRestSeconds(110), 120);
      expect(AddExerciseToWorkoutScreen.normalizeRestSeconds(200), 180);
      expect(AddExerciseToWorkoutScreen.normalizeRestSeconds(300), 240);

      expect(ConfigureSetsScreen.normalizeRestSeconds(15), 0);
      expect(ConfigureSetsScreen.normalizeRestSeconds(45), 60);
      expect(ConfigureSetsScreen.normalizeRestSeconds(105), 90);
      expect(ConfigureSetsScreen.normalizeRestSeconds(220), 240);
    });

    testWidgets(
        'AddExerciseToWorkoutScreen handles cardio 60s recommendation and renders normalized dropdown',
        (tester) async {
      final repo = _ToggleErrorExerciseRepo()..shouldFail = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exerciseRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const AddExerciseToWorkoutScreen(
              planId: 'plan-1',
              workoutId: 'w-1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Supino Reto'));
      await tester.pumpAndSettle();

      expect(find.text('Prescrever Séries'), findsOneWidget);
      expect(find.byType(DropdownButton<int>), findsAtLeastNWidgets(1));
    });

    testWidgets(
        'ConfigureSetsScreen renders 48dp steppers for Reps & RIR, normalizes off-list rest and saves updated values',
        (tester) async {
      final recorder = _RecordingConfigureSetTemplatesUseCase();
      const workout = Workout(
        id: 'w-1',
        trainingPlanId: 'plan-1',
        name: 'Treino A',
        dayOfWeek: 1,
        exercises: [
          WorkoutExercise(
            id: 'we-1',
            workoutId: 'w-1',
            exerciseId: 'ex-1',
            exercise: Exercise(
              id: 'ex-1',
              name: 'Supino Inclinado',
              primaryMuscleGroup: 'chest',
              equipment: 'barbell',
            ),
            setTemplates: [
              SetTemplate(
                id: 'st-1',
                workoutExerciseId: 'we-1',
                setNumber: 1,
                setType: SetType.working,
                targetRepsMin: 8,
                targetRepsMax: 10,
                targetRirMin: 1,
                targetRirMax: 2,
                restSeconds: 110, // off-list value -> normalized to 120s
              ),
            ],
          ),
        ],
      );

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, _) => Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => context.push('/configure'),
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/configure',
            builder: (_, _) => const ConfigureSetsScreen(
              planId: 'plan-1',
              workoutId: 'w-1',
              workoutExerciseId: 'we-1',
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workoutDetailProvider((planId: 'plan-1', workoutId: 'w-1'))
                .overrideWith((ref) async => workout),
            configureSetTemplatesUseCaseProvider.overrideWithValue(recorder),
          ],
          child: MaterialApp.router(
            theme: AppTheme.dark(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      // Normalized rest dropdown shows 120s instead of crashing on 110s
      expect(find.text('120s'), findsOneWidget);

      // Verify >= 48x48dp touch targets on all stepper buttons
      final incRepsMin = find.bySemanticsLabel('Aumentar Reps mín.');
      final decRepsMax = find.bySemanticsLabel('Diminuir Reps máx.');
      final incRirMin = find.bySemanticsLabel('Aumentar RIR mín.');
      final incRirMax = find.bySemanticsLabel('Aumentar RIR máx.');
      for (final f in [incRepsMin, decRepsMax, incRirMin, incRirMax]) {
        final size = tester.getSize(f);
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }

      await tester.tap(incRepsMin);
      await tester.tap(incRirMin);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salvar Configuração de Séries'));
      await tester.pumpAndSettle();

      expect(recorder.savedTemplates, hasLength(1));
      final saved = recorder.savedTemplates!.single;
      expect(saved.targetRepsMin, 9);
      expect(saved.targetRirMin, 2);
      expect(saved.restSeconds, 120);
    });

    testWidgets(
        'ProfileScreen body data sheet validates ranges inline and accepts PT-BR comma decimals',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            profileControllerProvider
                .overrideWith((ref) => _NoopProfileRemoteController(ref)),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return MaterialApp(
                theme: AppTheme.dark(),
                home: const ProfileScreen(),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dados corporais'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(4));

      // Out-of-range inputs trigger inline range errors and block closing
      await tester.enterText(fields.at(0), '10');
      await tester.enterText(fields.at(1), '50');
      await tester.enterText(fields.at(2), '5');
      await tester.enterText(fields.at(3), '80');
      await tester.pump();

      await tester.ensureVisible(find.text('Salvar'));
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Informe um peso entre 30 e 300 kg'), findsOneWidget);
      expect(find.text('Informe uma altura entre 100 e 250 cm'), findsOneWidget);
      expect(find.text('Informe uma idade entre 12 e 100 anos'), findsOneWidget);
      expect(find.text('Informe entre 3% e 60%'), findsOneWidget);

      // Valid PT-BR comma decimals save cleanly and dispose controllers safely
      await tester.enterText(fields.at(0), '82,5');
      await tester.enterText(fields.at(1), '180');
      await tester.enterText(fields.at(2), '29');
      await tester.enterText(fields.at(3), '15,4');
      await tester.pump();

      await tester.ensureVisible(find.text('Salvar'));
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      final settings = container.read(userSettingsProvider);
      expect(settings.weightKg, 82.5);
      expect(settings.heightCm, 180);
      expect(settings.age, 29);
      expect(settings.bodyFatPercent, 15.4);
      expect(find.text('82,5 kg · 180 cm · 29 anos'), findsOneWidget);
    });
  });
}
