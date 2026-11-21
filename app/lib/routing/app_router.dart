import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:personal_fitness_os/routing/app_shell.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:personal_fitness_os/features/training/presentation/screens/add_exercise_to_workout_screen.dart';
import 'package:personal_fitness_os/features/training/presentation/screens/add_workout_screen.dart';
import 'package:personal_fitness_os/features/training/presentation/screens/configure_sets_screen.dart';
import 'package:personal_fitness_os/features/training/presentation/screens/create_training_plan_screen.dart';
import 'package:personal_fitness_os/features/training/presentation/screens/training_list_screen.dart';
import 'package:personal_fitness_os/features/training/presentation/screens/training_plan_detail_screen.dart';
import 'package:personal_fitness_os/features/training/presentation/screens/workout_detail_screen.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/screens/session_summary_screen.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/screens/workout_session_screen.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/screens/create_custom_exercise_screen.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/screens/exercise_detail_screen.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/screens/exercise_list_screen.dart';
import 'package:personal_fitness_os/features/body/presentation/screens/body_measurements_screen.dart';
import 'package:personal_fitness_os/features/body/presentation/screens/body_overview_screen.dart';
import 'package:personal_fitness_os/features/body/presentation/screens/progress_photos_screen.dart';
import 'package:personal_fitness_os/features/body/presentation/screens/weight_history_screen.dart';
import 'package:personal_fitness_os/features/calendar/presentation/screens/activity_calendar_screen.dart';
import 'package:personal_fitness_os/features/nutrition/presentation/screens/nutrition_screen.dart';
import 'package:personal_fitness_os/features/goals/presentation/screens/goals_screen.dart';
import 'package:personal_fitness_os/features/goals/presentation/screens/goal_detail_screen.dart';
import 'package:personal_fitness_os/features/history/presentation/screens/history_screen.dart';
import 'package:personal_fitness_os/features/auth/presentation/screens/login_screen.dart';
import 'package:personal_fitness_os/features/auth/presentation/screens/register_screen.dart';

final authStateProvider = StateProvider<bool>((ref) => false);

final goRouterProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }
      if (isLoggedIn && isAuthRoute) {
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
                    builder: (context, state) => const CreateTrainingPlanScreen(),
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
                              final workoutId = state.pathParameters['workoutId']!;
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
                              final workoutId = state.pathParameters['workoutId']!;
                              final exerciseId = state.pathParameters['exerciseId']!;
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
        path: '/nutrition',
        builder: (context, state) => const NutritionScreen(),
        routes: [
          GoRoute(
            path: 'meal/:mealId',
            builder: (context, state) => Scaffold(
              appBar: AppBar(title: Text('Meal ${state.pathParameters['mealId']}')),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/body',
        builder: (context, state) => const BodyOverviewScreen(),
        routes: [
          GoRoute(
            path: 'weight',
            builder: (context, state) => const WeightHistoryScreen(),
          ),
          GoRoute(
            path: 'measurements',
            builder: (context, state) => const BodyMeasurementsScreen(),
          ),
          GoRoute(
            path: 'photos',
            builder: (context, state) => const ProgressPhotosScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/goals',
        builder: (context, state) => const GoalsScreen(),
        routes: [
          GoRoute(
            path: ':goalId',
            builder: (context, state) {
              final goalId = state.pathParameters['goalId']!;
              return GoalDetailScreen(goalId: goalId);
            },
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
        path: '/calendar',
        builder: (context, state) => const ActivityCalendarScreen(),
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
