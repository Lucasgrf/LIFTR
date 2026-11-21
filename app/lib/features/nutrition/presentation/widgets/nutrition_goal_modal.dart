import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_input.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/nutrition_goal.dart';
import 'package:personal_fitness_os/features/nutrition/presentation/providers/nutrition_providers.dart';

class NutritionGoalModal extends ConsumerStatefulWidget {
  const NutritionGoalModal({
    super.key,
    this.currentGoal,
  });

  final NutritionGoal? currentGoal;

  static Future<bool?> show(
    BuildContext context, {
    NutritionGoal? currentGoal,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NutritionGoalModal(currentGoal: currentGoal),
    );
  }

  @override
  ConsumerState<NutritionGoalModal> createState() => _NutritionGoalModalState();
}

class _NutritionGoalModalState extends ConsumerState<NutritionGoalModal> {
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final g = widget.currentGoal;
    _caloriesController = TextEditingController(text: g?.calories.toString() ?? '2200');
    _proteinController = TextEditingController(text: g?.proteinGrams.toString() ?? '160');
    _carbsController = TextEditingController(text: g?.carbsGrams.toString() ?? '240');
    _fatController = TextEditingController(text: g?.fatGrams.toString() ?? '65');
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _saveGoal() async {
    final cal = int.tryParse(_caloriesController.text.trim());
    final pro = int.tryParse(_proteinController.text.trim());
    final carb = int.tryParse(_carbsController.text.trim());
    final fat = int.tryParse(_fatController.text.trim());

    if (cal == null || pro == null || carb == null || fat == null) {
      context.showSnackBar('Preencha todos os campos corretamente.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final useCase = ref.read(saveNutritionGoalUseCaseProvider);
    final result = await useCase.execute(
      calories: cal,
      proteinGrams: pro,
      carbsGrams: carb,
      fatGrams: fat,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (goal) {
        ref.invalidate(dailyNutritionProvider);
        ref.invalidate(activeNutritionGoalProvider);
        context.showSnackBar('Meta nutricional salva com sucesso!');
        Navigator.of(context).pop(true);
      },
      (failure) => context.showSnackBar(failure.message, isError: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Text(
              'Meta Nutricional Diária',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            AppInput(
              label: 'CALORIAS TOTAIS (KCAL)',
              hint: 'Ex: 2200',
              controller: _caloriesController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppInput(
                    label: 'PROTEÍNA (G)',
                    hint: '160',
                    controller: _proteinController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppInput(
                    label: 'CARBOIDRATOS (G)',
                    hint: '240',
                    controller: _carbsController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppInput(
                    label: 'GORDURAS (G)',
                    hint: '65',
                    controller: _fatController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AppButton.primary(
              label: 'Salvar Meta',
              isLoading: _isLoading,
              onPressed: _saveGoal,
            ),
          ],
        ),
      ),
    );
  }
}
