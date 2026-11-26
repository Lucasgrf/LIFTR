import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/network/connectivity_providers.dart';
import 'package:personal_fitness_os/core/storage/shared_preferences_provider.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/core/widgets/app_input.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/features/auth/presentation/screens/login_screen.dart';
import 'package:personal_fitness_os/features/auth/presentation/screens/register_screen.dart';
import 'package:personal_fitness_os/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:personal_fitness_os/features/body/presentation/providers/weight_providers.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/repositories/exercise_repository.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/providers/exercise_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/providers/history_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/exercise_history_modal.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/progress_weight_view.dart';
import 'package:personal_fitness_os/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:personal_fitness_os/features/profile/presentation/providers/profile_providers.dart';
import 'package:personal_fitness_os/features/profile/presentation/screens/profile_screen.dart';
import 'package:personal_fitness_os/features/settings/presentation/providers/settings_providers.dart';
import 'package:personal_fitness_os/features/training/domain/entities/set_template.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout_exercise.dart';
import 'package:personal_fitness_os/features/training/domain/usecases/configure_set_templates.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';
import 'package:personal_fitness_os/features/training/presentation/screens/add_exercise_to_workout_screen.dart';
import 'package:personal_fitness_os/features/training/presentation/screens/ai_workout_generator_screen.dart';
import 'package:personal_fitness_os/features/training/presentation/screens/configure_sets_screen.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/import_plan_sheet.dart';
import 'package:personal_fitness_os/routing/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

    testWidgets(
        'ProgressWeightView renders ErrorStateWidget without kOfflineDataSafetyNote (remote-only)',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            weightHistoryProvider.overrideWith(
              (_) => Future.error(
                const NetworkFailure('No network'),
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const Scaffold(body: ProgressWeightView()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateWidget), findsOneWidget);
      expect(find.textContaining('Sem conexão com a internet'), findsOneWidget);
      expect(find.text(kOfflineDataSafetyNote), findsNothing);
    });
  });

  group('UX-02 Forms, preserved rest durations & PT-BR decimals', () {
    test('restDropdownValuesFor preserves custom off-list values without snapping',
        () {
      expect(
        AddExerciseToWorkoutScreen.restDropdownValuesFor(90),
        [60, 90, 120, 150, 180, 240],
      );
      expect(
        AddExerciseToWorkoutScreen.restDropdownValuesFor(100),
        [60, 90, 100, 120, 150, 180, 240],
      );
      expect(
        AddExerciseToWorkoutScreen.formatRestOptionLabel(100),
        '100s (personalizado)',
      );
      expect(
        AddExerciseToWorkoutScreen.formatRestOptionLabel(120),
        '120s (2:00)',
      );

      expect(
        ConfigureSetsScreen.restDropdownValuesFor(100),
        [0, 60, 90, 100, 120, 150, 180, 240],
      );
      expect(
        ConfigureSetsScreen.restDropdownValuesFor(120),
        [0, 60, 90, 120, 150, 180, 240],
      );
    });

    testWidgets(
        'AddExerciseToWorkoutScreen handles cardio 60s recommendation and renders dropdown',
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
        'ConfigureSetsScreen shows 100s (personalizado) and preserves 100s when saved untouched',
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
                restSeconds: 100, // custom value must be preserved when untouched
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

      // Custom off-list rest shows "(personalizado)" without mutating stored value
      expect(find.text('100s (personalizado)'), findsOneWidget);

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
      expect(saved.restSeconds, 100);
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

  group('UX-05 Auth, onboarding, AI generator and import inputs', () {
    testWidgets(
        'LoginScreen uses AutofillGroup, AppInput, next focus, and Esqueci minha senha flow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final sentEmails = <String>[];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            passwordResetSenderProvider.overrideWithValue(
              (email) async => sentEmails.add(email),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AutofillGroup), findsOneWidget);
      expect(find.byType(AppInput), findsNWidgets(2));

      final emailField = find.descendant(
        of: find.byType(AppInput).at(0),
        matching: find.byType(EditableText),
      );
      final passwordField = find.descendant(
        of: find.byType(AppInput).at(1),
        matching: find.byType(EditableText),
      );

      await tester.tap(emailField);
      await tester.enterText(emailField, 'atleta@liftr.app');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();

      final editablePassword = tester.widget<EditableText>(passwordField);
      expect(editablePassword.focusNode.hasFocus, isTrue);

      await tester.tap(find.text('Esqueci minha senha'));
      await tester.pumpAndSettle();

      expect(find.text('Redefinir senha'), findsOneWidget);
      await tester.tap(find.text('Enviar link'));
      await tester.pumpAndSettle();

      expect(sentEmails, ['atleta@liftr.app']);
      expect(
        find.text(
          'Se houver uma conta com esse e-mail, enviaremos um link para redefinir sua senha.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Fechar'));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'Esqueci minha senha disables submit while pending and shows neutral copy without leaking user existence',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final prevLogger = appErrorLogger;
      final logged = <Object>[];
      appErrorLogger = (err, {stackTrace, context}) => logged.add(err);
      addTearDown(() => appErrorLogger = prevLogger);

      final completer = Completer<void>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            passwordResetSenderProvider.overrideWithValue(
              (_) => completer.future,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Esqueci minha senha'));
      await tester.pumpAndSettle();

      final dialogEmail = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(EditableText),
      );
      await tester.enterText(dialogEmail, 'naoexiste@liftr.app');
      await tester.tap(find.text('Enviar link'));
      await tester.pump();

      final sendingBtn = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Enviando...'),
      );
      expect(sendingBtn.onPressed, isNull);

      completer.completeError(const AuthException('User not found'));
      await tester.pumpAndSettle();

      expect(logged.single, isA<AuthException>());
      expect(
        find.text(
          'Se houver uma conta com esse e-mail, enviaremos um link para redefinir sua senha.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('naoexiste@liftr.app'), findsNothing);
    });

    testWidgets(
        'ResetPasswordScreen validates mismatch, updates password, clears recovery flag, and finishes autofill',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final updatedPasswords = <String>[];
      final textInputCalls = <String>[];
      final router = GoRouter(
        initialLocation: '/reset-password',
        routes: [
          GoRoute(
            path: '/login',
            builder: (_, _) => const Scaffold(body: Text('LoginScreenMock')),
          ),
          GoRoute(
            path: '/reset-password',
            builder: (_, _) => const ResetPasswordScreen(),
          ),
        ],
      );

      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            passwordRecoveryPendingProvider.overrideWith((_) => true),
            passwordUpdaterProvider.overrideWithValue(
              (pwd) async => updatedPasswords.add(pwd),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return MaterialApp.router(
                theme: AppTheme.dark(),
                routerConfig: router,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fields = find.byType(AppInput);
      expect(fields, findsNWidgets(2));
      expect(
        tester.widget<AppInput>(fields.at(0)).autofillHints,
        contains(AutofillHints.newPassword),
      );
      expect(
        tester.widget<AppInput>(fields.at(1)).autofillHints,
        contains(AutofillHints.newPassword),
      );

      await tester.enterText(
        find.descendant(of: fields.at(0), matching: find.byType(EditableText)),
        'nova123',
      );
      await tester.enterText(
        find.descendant(of: fields.at(1), matching: find.byType(EditableText)),
        'diferente',
      );
      await tester.tap(find.text('Salvar nova senha'));
      await tester.pumpAndSettle();
      expect(find.text('As senhas não coincidem'), findsOneWidget);

      await tester.enterText(
        find.descendant(of: fields.at(1), matching: find.byType(EditableText)),
        'nova123',
      );

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.textInput,
        (call) async {
          textInputCalls.add(call.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.textInput,
          null,
        ),
      );

      await tester.tap(find.text('Salvar nova senha'));
      await tester.pumpAndSettle();

      expect(updatedPasswords, ['nova123']);
      expect(container.read(passwordRecoveryPendingProvider), isFalse);
      expect(textInputCalls, contains('TextInput.finishAutofillContext'));
      expect(find.text('LoginScreenMock'), findsOneWidget);
    });

    testWidgets(
        'LoginScreen invokes finishAutofillContext upon successful sign-in',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final textInputCalls = <String>[];
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('DashboardMock')),
          ),
          GoRoute(
            path: '/login',
            builder: (_, _) => const LoginScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            theme: AppTheme.dark(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fields = find.byType(AppInput);
      await tester.enterText(
        find.descendant(of: fields.at(0), matching: find.byType(EditableText)),
        'atleta@liftr.app',
      );
      await tester.enterText(
        find.descendant(of: fields.at(1), matching: find.byType(EditableText)),
        'senha123',
      );

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.textInput,
        (call) async {
          textInputCalls.add(call.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.textInput,
          null,
        ),
      );

      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(textInputCalls, contains('TextInput.finishAutofillContext'));
      expect(find.text('DashboardMock'), findsOneWidget);
    });

    testWidgets(
        'RegisterScreen uses AutofillGroup, newPassword hint, focus traversal, and finishes autofill on submit',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final textInputCalls = <String>[];
      final router = GoRouter(
        initialLocation: '/register',
        routes: [
          GoRoute(
            path: '/register',
            builder: (_, _) => const RegisterScreen(),
          ),
          GoRoute(
            path: '/onboarding',
            builder: (_, _) => const Scaffold(body: Text('OnboardingMock')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp.router(
            theme: AppTheme.dark(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AutofillGroup), findsOneWidget);
      expect(find.byType(AppInput), findsNWidgets(3));
      expect(
        tester.widget<AppInput>(find.byType(AppInput).at(2)).autofillHints,
        contains(AutofillHints.newPassword),
      );

      final nameField = find.descendant(
        of: find.byType(AppInput).at(0),
        matching: find.byType(EditableText),
      );
      final emailField = find.descendant(
        of: find.byType(AppInput).at(1),
        matching: find.byType(EditableText),
      );
      final passwordField = find.descendant(
        of: find.byType(AppInput).at(2),
        matching: find.byType(EditableText),
      );

      await tester.tap(nameField);
      await tester.enterText(nameField, 'Lucas');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();
      expect(tester.widget<EditableText>(emailField).focusNode.hasFocus, isTrue);

      await tester.enterText(emailField, 'lucas@liftr.app');
      await tester.enterText(passwordField, 'senha123');

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.textInput,
        (call) async {
          textInputCalls.add(call.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.textInput,
          null,
        ),
      );

      await tester.tap(find.text('Criar conta'));
      await tester.pumpAndSettle();

      expect(textInputCalls, contains('TextInput.finishAutofillContext'));
      expect(find.text('OnboardingMock'), findsOneWidget);
    });

    testWidgets(
        'OnboardingScreen shows inline Step 0 validation, handles PopScope step back, and guards double submit',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final router = GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Home')),
          ),
          GoRoute(
            path: '/login',
            builder: (_, _) => const Scaffold(body: Text('Login')),
          ),
          GoRoute(
            path: '/onboarding',
            builder: (_, _) => const OnboardingScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            profileControllerProvider
                .overrideWith((ref) => _NoopProfileRemoteController(ref)),
          ],
          child: MaterialApp.router(
            theme: AppTheme.dark(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final stepInputs = find.byType(AppInput);
      expect(stepInputs, findsNWidgets(4));

      await tester.enterText(
        find.descendant(
          of: stepInputs.at(0),
          matching: find.byType(TextFormField),
        ),
        '9',
      );
      await tester.pump();
      expect(find.text('Entre 12 e 100 anos'), findsOneWidget);

      await tester.enterText(
        find.descendant(
          of: stepInputs.at(0),
          matching: find.byType(TextFormField),
        ),
        '28',
      );
      await tester.pump();
      expect(find.text('Entre 12 e 100 anos'), findsNothing);

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Passo 2 de 6'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Passo 1 de 6'), findsOneWidget);

      for (var i = 0; i < 5; i++) {
        final nextLabel = i == 4 ? 'Confirmar plano' : 'Continuar';
        await tester.tap(find.text(nextLabel));
        await tester.pumpAndSettle();
      }
      expect(find.text('Passo 6 de 6'), findsOneWidget);

      final skipBtn = find.text('Pular e fazer depois');
      await tester.ensureVisible(skipBtn);
      await tester.tap(skipBtn);
      await tester.pump();
      await tester.tap(skipBtn, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets(
        'OnboardingScreen Step 0 back routes to /login when stack cannot pop, and _finish releases _isSubmitting on error',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Part 1: Step 0 back goes to /login when GoRouter cannot pop
      final loginRouter = GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Home')),
          ),
          GoRoute(
            path: '/login',
            builder: (_, _) => const Scaffold(body: Text('LoginTarget')),
          ),
          GoRoute(
            path: '/onboarding',
            builder: (_, _) => const OnboardingScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            profileControllerProvider
                .overrideWith((ref) => _NoopProfileRemoteController(ref)),
          ],
          child: MaterialApp.router(
            theme: AppTheme.dark(),
            routerConfig: loginRouter,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('LoginTarget'), findsOneWidget);
    });

    testWidgets(
        'OnboardingScreen releases _isSubmitting and shows error snackbar when _finish fails, allowing retry',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var shouldThrow = true;
      final retryRouter = GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('HomeAfterRetry')),
          ),
          GoRoute(
            path: '/login',
            builder: (_, _) => const Scaffold(body: Text('LoginTarget')),
          ),
          GoRoute(
            path: '/onboarding',
            builder: (_, _) => const OnboardingScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            profileControllerProvider
                .overrideWith((ref) => _NoopProfileRemoteController(ref)),
            onboardingCompleteHookProvider.overrideWithValue(
              (_) async {
                if (shouldThrow) {
                  throw const ServerFailure('503 Service Unavailable');
                }
              },
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.dark(),
            routerConfig: retryRouter,
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (var i = 0; i < 5; i++) {
        final nextLabel = i == 4 ? 'Confirmar plano' : 'Continuar';
        await tester.tap(find.text(nextLabel));
        await tester.pumpAndSettle();
      }
      expect(find.text('Passo 6 de 6'), findsOneWidget);

      final skipBtn = find.text('Pular e fazer depois');
      await tester.ensureVisible(skipBtn);
      await tester.tap(skipBtn);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('servidor está temporariamente indisponível'),
        findsOneWidget,
      );
      expect(find.text('Passo 6 de 6'), findsOneWidget);

      ScaffoldMessenger.of(
        tester.element(find.byType(OnboardingScreen)),
      ).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      // Retry succeeds because _isSubmitting was released in finally
      shouldThrow = false;
      await tester.ensureVisible(skipBtn);
      await tester.tap(skipBtn);
      await tester.pumpAndSettle();
      expect(find.text('HomeAfterRetry'), findsOneWidget);
    });

    testWidgets(
        'AiWorkoutGeneratorScreen gates offline state before wizard and uses AppInput on Step 5',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            isOfflineModeProvider.overrideWithValue(true),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const AiWorkoutGeneratorScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Você está sem conexão com a internet'),
        findsOneWidget,
      );
      expect(find.text(kOfflineDataSafetyNote), findsNothing);
      expect(find.text('Voltar'), findsOneWidget);
      expect(find.text('Continuar'), findsNothing);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            isOfflineModeProvider.overrideWithValue(false),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const AiWorkoutGeneratorScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Passo 5 de 5'), findsOneWidget);
      expect(find.byKey(const Key('ai_restrictions_input')), findsOneWidget);
      expect(
        tester.widget<AppInput>(find.byKey(const Key('ai_restrictions_input'))),
        isA<AppInput>(),
      );
    });

    testWidgets('ImportPlanSheet uses AppInput for plan code entry',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const Scaffold(body: ImportPlanSheet()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('import_plan_code_input')), findsOneWidget);
      expect(
        tester.widget<AppInput>(find.byKey(const Key('import_plan_code_input'))),
        isA<AppInput>(),
      );
    });
  });
}
