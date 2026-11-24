import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/core/storage/shared_preferences_provider.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/repositories/exercise_repository.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/providers/exercise_providers.dart';
import 'package:personal_fitness_os/features/training/data/datasources/ai_workout_remote_datasource.dart';
import 'package:personal_fitness_os/features/training/domain/entities/ai_generated_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/ai_workout_request.dart';
import 'package:personal_fitness_os/features/training/domain/entities/set_template.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout_exercise.dart';
import 'package:personal_fitness_os/features/training/domain/repositories/training_repository.dart';
import 'package:personal_fitness_os/features/training/domain/services/training_plan_share_codec.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/ai_workout_providers.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';
import 'package:personal_fitness_os/features/training/presentation/screens/ai_workout_generator_screen.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/export_plan_sheet.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/import_plan_sheet.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/switch_program_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubAiWorkoutRemoteDataSource implements AiWorkoutRemoteDataSource {
  _StubAiWorkoutRemoteDataSource({
    this.planToReturn,
    this.errorToThrow,
    this.completer,
  });

  final GeneratedTrainingPlan? planToReturn;
  final AiWorkoutException? errorToThrow;
  final Completer<GeneratedTrainingPlan>? completer;
  AiWorkoutRequest? lastRequest;

  @override
  Future<GeneratedTrainingPlan> generatePlan(AiWorkoutRequest request) async {
    lastRequest = request;
    if (completer != null) return completer!.future;
    if (errorToThrow != null) throw errorToThrow!;
    return planToReturn!;
  }
}

class _StubExerciseRepository implements ExerciseRepository {
  @override
  Future<Result<List<Exercise>, Failure>> getExercises() async => const Success([
        Exercise(
          id: 'ex-1',
          name: 'Elevação pélvica com barra',
          primaryMuscleGroup: 'legs',
        ),
        Exercise(
          id: 'ex-cardio',
          name: 'Esteira / Cardio',
          primaryMuscleGroup: 'cardio',
          movementPattern: 'cardio',
        ),
      ]);

  @override
  Future<Result<Exercise, Failure>> getExerciseById(String id) async =>
      const Err(ServerFailure('Not found'));

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
      Success(
        Exercise(
          id: 'custom-new',
          name: name,
          primaryMuscleGroup: primaryMuscleGroup,
          isCustom: true,
        ),
      );

  @override
  Future<Result<Exercise, Failure>> updateExerciseNotes({
    required String exerciseId,
    required String notes,
  }) async =>
      const Err(ServerFailure('Unsupported'));

  @override
  Future<Result<void, Failure>> deleteCustomExercise(String id) async =>
      const Success(null);
}

class _StubTrainingRepository implements TrainingRepository {
  final List<TrainingPlan> savedPlans = [];

  @override
  Future<Result<List<TrainingPlan>, Failure>> getTrainingPlans() async =>
      Success(savedPlans);

  @override
  Future<Result<TrainingPlan?, Failure>> getActiveTrainingPlan() async =>
      Success(savedPlans.where((p) => p.isActive).firstOrNull);

  @override
  Future<Result<TrainingPlan, Failure>> getTrainingPlanById(String id) async =>
      Success(
        savedPlans.where((p) => p.id == id).firstOrNull ??
            TrainingPlan(id: id, userId: 'u1', name: 'Plano Salvo'),
      );

  @override
  Future<Result<TrainingPlan, Failure>> createTrainingPlan({
    required String name,
    String? description,
    bool isActive = false,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final plan = TrainingPlan(
      id: 'plan-${savedPlans.length + 1}',
      userId: 'u1',
      name: name,
      description: description,
      isActive: isActive,
    );
    savedPlans.add(plan);
    return Success(plan);
  }

  @override
  Future<Result<TrainingPlan, Failure>> setActiveTrainingPlan(
    String planId,
  ) async =>
      Success(
        TrainingPlan(id: planId, userId: 'u1', name: 'Plano Ativo', isActive: true),
      );

  @override
  Future<Result<Workout, Failure>> addWorkoutToPlan({
    required String trainingPlanId,
    required String name,
    int? dayOfWeek,
    int sortOrder = 0,
    String? notes,
    int? estimatedDurationMinutes,
  }) async =>
      Success(
        Workout(
          id: 'w-$sortOrder',
          trainingPlanId: trainingPlanId,
          name: name,
        ),
      );

  @override
  Future<Result<WorkoutExercise, Failure>> addExerciseToWorkout({
    required String workoutId,
    required String exerciseId,
    int sortOrder = 0,
    String? notes,
    List<SetTemplate>? initialSetTemplates,
  }) async =>
      Success(
        WorkoutExercise(
          id: 'we-$sortOrder',
          workoutId: workoutId,
          exerciseId: exerciseId,
          setTemplates: initialSetTemplates ?? const [],
        ),
      );

  @override
  Future<Result<List<SetTemplate>, Failure>> configureSetTemplates({
    required String workoutExerciseId,
    required List<SetTemplate> setTemplates,
  }) async =>
      Success(setTemplates);

  @override
  Future<Result<void, Failure>> reorderWorkoutExercises({
    required String workoutId,
    required List<String> orderedWorkoutExerciseIds,
  }) async =>
      const Success(null);

  @override
  Future<Result<void, Failure>> reorderPlanWorkouts({
    required String trainingPlanId,
    required List<String> orderedWorkoutIds,
  }) async =>
      const Success(null);

  @override
  Future<Result<void, Failure>> deleteTrainingPlan(String planId) async =>
      const Success(null);

  @override
  Future<Result<void, Failure>> deleteWorkout(String workoutId) async =>
      const Success(null);

  @override
  Future<Result<void, Failure>> deleteWorkoutExercise(
    String workoutExerciseId,
  ) async =>
      const Success(null);
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  const tGeneratedPlan = GeneratedTrainingPlan(
    planName: 'ABCD Foco Inferiores & Glúteos',
    splitType: 'ABCD · Inferiores & Glúteos',
    description: '2 sessões inferiores e 2 superiores',
    rationale: 'Volume distribuído para hipertrofia de inferiores com cardio.',
    workouts: [
      GeneratedWorkoutSpec(
        name: 'Treino A — Quadríceps e Glúteos',
        estimatedDurationMinutes: 55,
        exercises: [
          GeneratedExerciseSpec(
            exerciseId: 'ex-1',
            exerciseName: 'Elevação pélvica com barra',
            setsCount: 4,
            targetRepsMin: 8,
            targetRepsMax: 12,
            restSeconds: 150,
          ),
          GeneratedExerciseSpec(
            exerciseId: 'ex-cardio',
            exerciseName: 'Esteira / Cardio',
            isCardio: true,
            targetDurationMinutes: 20,
            restSeconds: 0,
          ),
        ],
      ),
    ],
  );

  group('AiWorkoutGeneratorScreen', () {
    testWidgets(
        'completes 5-step study, previews Gemini plan, and renders overflow-free at 320x640@1.3x in Dark and Light',
        (tester) async {
      final stubAi = _StubAiWorkoutRemoteDataSource(
        planToReturn: tGeneratedPlan,
      );
      final stubTraining = _StubTrainingRepository();
      final stubExercises = _StubExerciseRepository();

      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final semanticsHandle = tester.ensureSemantics();
      try {
        for (final entry in [
          ('dark', AppTheme.dark()),
          ('light', AppTheme.light()),
        ]) {
          await tester.pumpWidget(
            ProviderScope(
              key: ValueKey('ai-gen-${entry.$1}'),
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                aiWorkoutRemoteDataSourceProvider.overrideWithValue(stubAi),
                trainingRepositoryProvider.overrideWithValue(stubTraining),
                exerciseRepositoryProvider.overrideWithValue(stubExercises),
              ],
              child: MaterialApp(
                theme: entry.$2,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.3),
                  ),
                  child: child!,
                ),
                home: const AiWorkoutGeneratorScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Step 1
          expect(find.text('Passo 1 de 5'), findsOneWidget);
          expect(find.text('Hipertrofia'), findsOneWidget);
          await tester.tap(find.text('Continuar'));
          await tester.pumpAndSettle();

          // Step 2
          expect(find.text('Passo 2 de 5'), findsOneWidget);
          await tester.tap(find.text('Continuar'));
          await tester.pumpAndSettle();

          // Step 3 (shows ABCD and ABCD · Inferiores & Glúteos for 4 days)
          expect(find.text('Passo 3 de 5'), findsOneWidget);
          expect(find.text('ABCD'), findsOneWidget);
          expect(find.text('ABCD · Inferiores & Glúteos'), findsOneWidget);
          await tester.tap(find.text('Continuar'));
          await tester.pumpAndSettle();

          // Step 4
          expect(find.text('Passo 4 de 5'), findsOneWidget);
          expect(find.text('Glúteos'), findsOneWidget);
          await tester.tap(find.text('Continuar'));
          await tester.pumpAndSettle();

          // Step 5 -> Generate
          expect(find.text('Passo 5 de 5'), findsOneWidget);
          await tester.tap(find.text('Gerar treino com IA'));
          await tester.pumpAndSettle();

          // Preview state
          expect(
            find.text('ABCD Foco Inferiores & Glúteos'),
            findsOneWidget,
          );
          expect(find.text('Elevação pélvica com barra'), findsOneWidget);
          expect(find.text('20 min · Cardio'), findsOneWidget);
          expect(find.text('Aplicar este treino'), findsOneWidget);
        }
      } finally {
        semanticsHandle.dispose();
      }
    });

    testWidgets(
        'displays actionable message when GEMINI_API_KEY is not configured yet (503)',
        (tester) async {
      final stubAi = _StubAiWorkoutRemoteDataSource(
        errorToThrow: const AiWorkoutException(
          code: AiWorkoutErrorCode.keyNotConfigured,
          message:
              'A chave GEMINI_API_KEY ainda não foi configurada no Supabase.',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            aiWorkoutRemoteDataSourceProvider.overrideWithValue(stubAi),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const AiWorkoutGeneratorScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (int i = 0; i < 4; i++) {
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Gerar treino com IA'));
      await tester.pumpAndSettle();

      expect(
        find.text('Não foi possível concluir a geração'),
        findsOneWidget,
      );
      expect(
        find.textContaining('GEMINI_API_KEY'),
        findsOneWidget,
      );
      expect(find.text('Tentar novamente'), findsOneWidget);
    });

    testWidgets(
        'displays progressive percentage bar (0% -> 100%) and contextual stage while generating (Issue #28)',
        (tester) async {
      final completer = Completer<GeneratedTrainingPlan>();
      final stubAi = _StubAiWorkoutRemoteDataSource(completer: completer);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            aiWorkoutRemoteDataSourceProvider.overrideWithValue(stubAi),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: const AiWorkoutGeneratorScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (int i = 0; i < 4; i++) {
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Gerar treino com IA'));
      await tester.pump();

      expect(find.byKey(const Key('ai_generating_percent_text')), findsOneWidget);
      expect(find.text('6%'), findsOneWidget);
      expect(
        find.text('Analisando seu perfil, nível e divisão ideal...'),
        findsOneWidget,
      );

      // Advance timers to verify percentage climbs smoothly across stages
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.textContaining('%'), findsWidgets);
      expect(
        find.text('Selecionando exercícios do catálogo LIFTR...'),
        findsOneWidget,
      );

      completer.complete(tGeneratedPlan);
      await tester.pumpAndSettle();

      expect(find.text('ABCD Foco Inferiores & Glúteos'), findsOneWidget);
    });
  });

  group('ExportPlanSheet, ImportPlanSheet & SwitchProgramSheet', () {
    final tSamplePlan = TrainingPlan(
      id: 'p-share',
      userId: 'u-1',
      name: 'Treino ABC Irmãos',
      isActive: true,
      workouts: const [
        Workout(
          id: 'w-a',
          trainingPlanId: 'p-share',
          name: 'Treino A — Peito e Tríceps',
          exercises: [
            WorkoutExercise(
              id: 'we-a1',
              workoutId: 'w-a',
              exerciseId: 'ex-1',
              exercise: Exercise(
                id: 'ex-1',
                name: 'Supino reto com barra',
                primaryMuscleGroup: 'chest',
              ),
              setTemplates: [
                SetTemplate(
                  id: 's1',
                  workoutExerciseId: 'we-a1',
                  setNumber: 1,
                  targetRepsMin: 8,
                  targetRepsMax: 12,
                ),
              ],
            ),
          ],
        ),
      ],
    );

    testWidgets(
        'ExportPlanSheet & ImportPlanSheet encode, preview, and import without overflow at 320x640@1.3x',
        (tester) async {
      final stubTraining = _StubTrainingRepository();
      final stubExercises = _StubExerciseRepository();
      final code = TrainingPlanShareCodec.encode(tSamplePlan);

      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            trainingRepositoryProvider.overrideWithValue(stubTraining),
            exerciseRepositoryProvider.overrideWithValue(stubExercises),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.3),
              ),
              child: child!,
            ),
            home: Scaffold(
              body: ExportPlanSheet(plan: tSamplePlan),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Treino ABC Irmãos'), findsOneWidget);
      expect(find.byKey(const Key('export_plan_code_text')), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Now test ImportPlanSheet
      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('import-scope'),
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            trainingRepositoryProvider.overrideWithValue(stubTraining),
            exerciseRepositoryProvider.overrideWithValue(stubExercises),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.3),
              ),
              child: child!,
            ),
            home: const Scaffold(
              body: ImportPlanSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('import_plan_code_input')),
        code,
      );
      await tester.pumpAndSettle();

      expect(find.text('PRÉVIA DO PROGRAMA'), findsOneWidget);
      expect(find.text('Treino ABC Irmãos'), findsOneWidget);

      await tester.ensureVisible(find.text('Importar e ativar treino'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Importar e ativar treino'));
      await tester.pumpAndSettle();

      expect(stubTraining.savedPlans, hasLength(1));
      expect(stubTraining.savedPlans.first.name, 'Treino ABC Irmãos');
    });

    testWidgets(
        'SwitchProgramSheet displays full split catalog (AB, ABC, ABCD, ABCDE) plus AI & Import actions',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: Scaffold(
              body: SwitchProgramSheet(plans: [tSamplePlan]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Montar treino com IA'), findsOneWidget);
      expect(find.text('Importar treino por código'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('AB (Superior / Inferior)'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('AB (Superior / Inferior)'), findsOneWidget);
      expect(find.text('ABC'), findsOneWidget);
    });
  });
}
