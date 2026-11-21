import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/extensions/date_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/features/nutrition/presentation/providers/nutrition_providers.dart';
import 'package:personal_fitness_os/features/nutrition/presentation/widgets/add_food_modal.dart';
import 'package:personal_fitness_os/features/nutrition/presentation/widgets/calorie_macro_target_card.dart';
import 'package:personal_fitness_os/features/nutrition/presentation/widgets/meal_card.dart';

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final selectedDate = ref.watch(selectedNutritionDateProvider);
    final dailyAsync = ref.watch(dailyNutritionProvider);

    final isToday = selectedDate.isToday;
    final dateLabel = isToday
        ? 'Hoje, ${selectedDate.formatShort()}'
        : selectedDate.formatMedium();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrição'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dailyNutritionProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // Date Selector Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(context.appRadius.medium),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    tooltip: 'Dia anterior',
                    onPressed: () {
                      ref.read(selectedNutritionDateProvider.notifier).state =
                          selectedDate.subtract(const Duration(days: 1));
                    },
                  ),
                  Text(
                    dateLabel,
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    tooltip: 'Próximo dia',
                    onPressed: () {
                      ref.read(selectedNutritionDateProvider.notifier).state =
                          selectedDate.add(const Duration(days: 1));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            dailyAsync.when(
              data: (daily) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Calorie and Macro targets summary card
                    CalorieMacroTargetCard(dailyNutrition: daily),
                    const SizedBox(height: 20),

                    Text(
                      'REFEIÇÕES',
                      style: context.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textSecondary,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Meal Cards
                    ...daily.meals.map(
                      (meal) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MealCard(
                          meal: meal,
                          onAddFood: () => AddFoodModal.show(
                            context,
                            date: selectedDate,
                            mealType: meal.mealType,
                          ),
                          onRemoveFood: (mealFoodId) async {
                            final messenger = ScaffoldMessenger.of(context);
                            final useCase =
                                ref.read(removeFoodFromMealUseCaseProvider);
                            final result = await useCase.execute(mealFoodId);

                            result.fold(
                              (_) {
                                ref.invalidate(dailyNutritionProvider);
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Alimento removido.'),
                                  ),
                                );
                              },
                              (failure) => messenger.showSnackBar(
                                SnackBar(
                                  content: Text(failure.message),
                                  backgroundColor: Colors.red,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: LoadingWidget(),
                ),
              ),
              error: (err, _) {
                final message = err is Failure ? err.message : err.toString();
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: AppErrorWidget(
                      message: message,
                      onRetry: () => ref.refresh(dailyNutritionProvider),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
