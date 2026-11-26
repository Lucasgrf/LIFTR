import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/constants/supabase_config.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/features/auth/presentation/screens/login_screen.dart';
import 'package:personal_fitness_os/features/auth/presentation/screens/register_screen.dart';
import 'package:personal_fitness_os/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/screens/create_custom_exercise_screen.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/screens/exercise_detail_screen.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/screens/exercise_list_screen.dart';
import 'package:personal_fitness_os/features/history/presentation/screens/history_screen.dart';
import 'package:personal_fitness_os/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:personal_fitness_os/features/profile/presentation/screens/profile_screen.dart';
import 'package:personal_fitness_os/features/settings/presentation/screens/settings_screen.dart';
import 'package:personal_fitness_os/features/training/presentation/screens/add_exercise_to_workout_screen.dart';
import 'package:personal_fitness_os/features/training/presentation/screens/add_workout_screen.dart';
import 'package:personal_fitness_os/features/training/presentation/screens/ai_workout_generator_screen.dart';
import 'package:personal_fitness_os/features/training/presentation/screens/configure_sets_screen.dart';
import 'package:personal_fitness_os/features/training/presentation/screens/create_training_plan_screen.dart';
import 'package:personal_fitness_os/features/training/presentation/screens/training_list_screen.dart';
import 'package:personal_fitness_os/features/training/presentation/screens/training_plan_detail_screen.dart';
import 'package:personal_fitness_os/features/training/presentation/screens/workout_detail_screen.dart';
import 'package:personal_fitness_os/features/weekly_comparison/presentation/screens/weekly_comparison_screen.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/screens/session_summary_screen.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/screens/workout_session_screen.dart';
import 'package:personal_fitness_os/routing/app_shell.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authStateProvider = StateProvider<bool>((ref) {
  if (!SupabaseConfig.isConfigured) return false;
  try {
    return Supabase.instance.client.auth.currentSession != null;
  } catch (_) {
    return false;
  }
});

final passwordRecoveryPendingProvider = StateProvider<bool>((ref) => false);
final passwordRecoveryErrorProvider = StateProvider<String?>((ref) => null);

/// Tracks the currently authenticated Supabase user ID so all user-specific
/// caches (`SharedPreferences`) and in-memory Riverpod providers automatically
/// isolate and reset whenever the user logs out or switches accounts.
final activeUserIdProvider = StateProvider<String?>((ref) {
  if (!SupabaseConfig.isConfigured) return null;
  try {
    final auth = Supabase.instance.client.auth;
    final sub = auth.onAuthStateChange.listen(
      (data) {
        final newUserId = data.session?.user.id;
        ref.controller.state = newUserId;
        ref.read(authStateProvider.notifier).state = data.session != null;
        if (data.event == AuthChangeEvent.passwordRecovery) {
          ref.read(passwordRecoveryErrorProvider.notifier).state = null;
          ref.read(passwordRecoveryPendingProvider.notifier).state = true;
        } else if (data.event == AuthChangeEvent.signedIn) {
          ref.read(passwordRecoveryErrorProvider.notifier).state = null;
        } else if (data.event == AuthChangeEvent.signedOut) {
          ref.read(passwordRecoveryPendingProvider.notifier).state = false;
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        appErrorLogger(
          error,
          stackTrace: stackTrace,
          context: 'AuthStateChange.authLink',
        );
        ref.read(passwordRecoveryPendingProvider.notifier).state = false;
        ref.read(passwordRecoveryErrorProvider.notifier).state =
            userFacingMessage(
          error,
          stackTrace: stackTrace,
          context: 'AuthStateChange.authLink',
          logError: false,
        );
      },
    );
    ref.onDispose(sub.cancel);
    return auth.currentUser?.id;
  } catch (_) {
    return null;
  }
});

/// Synchronizes [activeUserIdProvider] and [authStateProvider] after explicit
/// login, sign-up, onboarding completion, or sign-out.
void syncActiveAuthSession(
  WidgetRef ref, {
  required bool isLoggedIn,
  String? overrideUserId,
}) {
  String? resolvedUserId = overrideUserId;
  if (resolvedUserId == null && isLoggedIn && SupabaseConfig.isConfigured) {
    try {
      resolvedUserId = Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      resolvedUserId = null;
    }
  }
  ref.read(activeUserIdProvider.notifier).state =
      isLoggedIn ? resolvedUserId : null;
  ref.read(authStateProvider.notifier).state = isLoggedIn;
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = ref.watch(authStateProvider);
  final isPasswordRecovery = ref.watch(passwordRecoveryPendingProvider);

  return GoRouter(
    initialLocation: '/',
    onException: (_, state, router) => router.go('/'),
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (isPasswordRecovery && location != '/reset-password') {
        return '/reset-password';
      }
      final isAuthRoute =
          location == '/login' ||
          location == '/register' ||
          location == '/onboarding' ||
          location == '/reset-password';
      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }
      if (isLoggedIn &&
          !isPasswordRecovery &&
          (location == '/login' || location == '/register')) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/training',
                builder: (context, state) => const TrainingListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) =>
                        const CreateTrainingPlanScreen(),
                  ),
                  GoRoute(
                    path: 'ai-generator',
                    builder: (context, state) =>
                        const AiWorkoutGeneratorScreen(),
                  ),
                  GoRoute(
                    path: ':planId',
                    builder: (context, state) {
                      final planId = state.pathParameters['planId']!;
                      return TrainingPlanDetailScreen(planId: planId);
                    },
                    routes: [
                      GoRoute(
                        path: 'add-workout',
                        builder: (context, state) {
                          final planId = state.pathParameters['planId']!;
                          return AddWorkoutScreen(planId: planId);
                        },
                      ),
                      GoRoute(
                        path: 'workout/:workoutId',
                        builder: (context, state) {
                          final planId = state.pathParameters['planId']!;
                          final workoutId = state.pathParameters['workoutId']!;
                          return WorkoutDetailScreen(
                            planId: planId,
                            workoutId: workoutId,
                          );
                        },
                        routes: [
                          GoRoute(
                            path: 'add-exercise',
                            builder: (context, state) {
                              final planId = state.pathParameters['planId']!;
                              final workoutId =
                                  state.pathParameters['workoutId']!;
                              return AddExerciseToWorkoutScreen(
                                planId: planId,
                                workoutId: workoutId,
                              );
                            },
                          ),
                          GoRoute(
                            path: 'exercise/:exerciseId/configure-sets',
                            builder: (context, state) {
                              final planId = state.pathParameters['planId']!;
                              final workoutId =
                                  state.pathParameters['workoutId']!;
                              final exerciseId =
                                  state.pathParameters['exerciseId']!;
                              return ConfigureSetsScreen(
                                planId: planId,
                                workoutId: workoutId,
                                workoutExerciseId: exerciseId,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/session/:sessionId',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return WorkoutSessionScreen(sessionId: sessionId);
        },
        routes: [
          GoRoute(
            path: 'summary',
            builder: (context, state) {
              final sessionId = state.pathParameters['sessionId']!;
              return SessionSummaryScreen(sessionId: sessionId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/weekly-comparison',
        builder: (context, state) => const WeeklyComparisonScreen(),
      ),
      GoRoute(
        path: '/exercises',
        builder: (context, state) => const ExerciseListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const CreateCustomExerciseScreen(),
          ),
          GoRoute(
            path: ':exerciseId',
            builder: (context, state) {
              final exerciseId = state.pathParameters['exerciseId']!;
              return ExerciseDetailScreen(exerciseId: exerciseId);
            },
          ),
        ],
      ),
    ],
  );
});
