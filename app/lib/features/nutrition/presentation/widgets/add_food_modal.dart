import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_input.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/food.dart';
import 'package:personal_fitness_os/features/nutrition/presentation/providers/nutrition_providers.dart';
import 'package:personal_fitness_os/features/nutrition/presentation/widgets/create_custom_food_modal.dart';

class AddFoodModal extends ConsumerStatefulWidget {
  const AddFoodModal({
    super.key,
    required this.date,
    required this.mealType,
  });

  final DateTime date;
  final String mealType;

  static Future<bool?> show(
    BuildContext context, {
    required DateTime date,
    required String mealType,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddFoodModal(date: date, mealType: mealType),
    );
  }

  @override
  ConsumerState<AddFoodModal> createState() => _AddFoodModalState();
}

class _AddFoodModalState extends ConsumerState<AddFoodModal> {
  final _searchController = TextEditingController();
  Food? _selectedFood;
  double _quantityGrams = 100.0;
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedFood == null) {
      context.showSnackBar('Selecione um alimento.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final useCase = ref.read(addFoodToMealUseCaseProvider);
    final result = await useCase.execute(
      date: widget.date,
      mealType: widget.mealType,
      foodId: _selectedFood!.id,
      quantityGrams: _quantityGrams,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (mealFood) {
        ref.invalidate(dailyNutritionProvider);
        context.showSnackBar('Alimento adicionado à refeição!');
        Navigator.of(context).pop(true);
      },
      (failure) => context.showSnackBar(failure.message, isError: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final searchResultsAsync = ref.watch(foodSearchResultsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + bottomInset,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.appRadius.large),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Adicionar Alimento',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  final newFood = await CreateCustomFoodModal.show(context);
                  if (newFood != null) {
                    setState(() => _selectedFood = newFood);
                  }
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Criar Novo'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field
          AppInput(
            hint: 'Buscar alimento (ex: frango, arroz, ovo...)',
            prefix: Icon(Icons.search, color: colors.textTertiary),
            controller: _searchController,
            onChanged: (val) {
              ref.read(foodSearchQueryProvider.notifier).state = val;
            },
          ),
          const SizedBox(height: 12),

          // Selected Food / Quantity configuration
          if (_selectedFood != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(context.appRadius.medium),
                border: Border.all(color: colors.primary.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _selectedFood!.displayName,
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(() => _selectedFood = null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AppNumericInput(
                    label: 'QUANTIDADE (G)',
                    value: _quantityGrams,
                    step: 10.0,
                    min: 1.0,
                    max: 2000.0,
                    unit: 'g',
                    onChanged: (val) => setState(() => _quantityGrams = val),
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final ratio = _quantityGrams /
                          (_selectedFood!.servingSize > 0
                              ? _selectedFood!.servingSize
                              : 100.0);
                      final cal = _selectedFood!.calories * ratio;
                      final pro = _selectedFood!.protein * ratio;
                      final carb = _selectedFood!.carbs * ratio;
                      final fat = _selectedFood!.fat * ratio;

                      return Text(
                        'Total: ${cal.toStringAsFixed(0)} kcal • ${pro.toStringAsFixed(0)}g P • ${carb.toStringAsFixed(0)}g C • ${fat.toStringAsFixed(0)}g G',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Search results
          Expanded(
            child: searchResultsAsync.when(
              data: (foods) {
                if (foods.isEmpty) {
                  return Center(
                    child: Text(
                      'Nenhum alimento encontrado.\nClique em "Criar Novo" para cadastrar.',
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: foods.length,
                  itemBuilder: (context, index) {
                    final food = foods[index];
                    final isSelected = _selectedFood?.id == food.id;

                    return ListTile(
                      dense: true,
                      selected: isSelected,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        food.displayName,
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '${food.servingSize.toStringAsFixed(0)}g • ${food.calories.toStringAsFixed(0)} kcal (${food.protein.toStringAsFixed(0)}P / ${food.carbs.toStringAsFixed(0)}C / ${food.fat.toStringAsFixed(0)}G)',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: colors.primary)
                          : const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        setState(() {
                          _selectedFood = food;
                          _quantityGrams = food.servingSize;
                        });
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Erro: $err')),
            ),
          ),

          if (_selectedFood != null) ...[
            const SizedBox(height: 12),
            AppButton.primary(
              label: 'Adicionar à Refeição',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ],
        ],
      ),
    );
  }
}
