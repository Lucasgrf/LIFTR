import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_input.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/food.dart';
import 'package:personal_fitness_os/features/nutrition/presentation/providers/nutrition_providers.dart';

class CreateCustomFoodModal extends ConsumerStatefulWidget {
  const CreateCustomFoodModal({super.key});

  static Future<Food?> show(BuildContext context) {
    return showModalBottomSheet<Food>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateCustomFoodModal(),
    );
  }

  @override
  ConsumerState<CreateCustomFoodModal> createState() =>
      _CreateCustomFoodModalState();
}

class _CreateCustomFoodModalState
    extends ConsumerState<CreateCustomFoodModal> {
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _servingSizeController = TextEditingController(text: '100');
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _servingSizeController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final brand =
        _brandController.text.trim().isEmpty ? null : _brandController.text.trim();
    final serving = double.tryParse(_servingSizeController.text.trim());
    final calories = double.tryParse(_caloriesController.text.trim());
    final protein = double.tryParse(_proteinController.text.trim());
    final carbs = double.tryParse(_carbsController.text.trim());
    final fat = double.tryParse(_fatController.text.trim());

    if (name.isEmpty) {
      context.showSnackBar('Nome do alimento é obrigatório.', isError: true);
      return;
    }
    if (serving == null || !serving.isFinite || serving <= 0) {
      context.showSnackBar(
          'Porção base deve ser um número maior que zero.', isError: true);
      return;
    }
    if (calories == null || !calories.isFinite || calories < 0) {
      context.showSnackBar(
          'Calorias devem ser um número não-negativo.', isError: true);
      return;
    }
    if (protein == null ||
        !protein.isFinite ||
        protein < 0 ||
        carbs == null ||
        !carbs.isFinite ||
        carbs < 0 ||
        fat == null ||
        !fat.isFinite ||
        fat < 0) {
      context.showSnackBar(
          'Macronutrientes devem ser números não-negativos.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final food = Food(
      id: '',
      name: name,
      brand: brand,
      servingSize: serving,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      isCustom: true,
    );

    final useCase = ref.read(createCustomFoodUseCaseProvider);
    final result = await useCase.execute(food);

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (created) {
        ref.invalidate(foodSearchResultsProvider);
        context.showSnackBar('Alimento "${created.name}" cadastrado!');
        Navigator.of(context).pop(created);
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
              'Novo Alimento Personalizado',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            AppInput(
              label: 'NOME DO ALIMENTO',
              hint: 'Ex: Iogurte Natural',
              controller: _nameController,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppInput(
                    label: 'MARCA (OPCIONAL)',
                    hint: 'Ex: Nestlé',
                    controller: _brandController,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppInput(
                    label: 'PORÇÃO BASE (G)',
                    hint: '100',
                    controller: _servingSizeController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppInput(
              label: 'CALORIAS POR PORÇÃO (KCAL)',
              hint: 'Ex: 150',
              controller: _caloriesController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppInput(
                    label: 'PROTEÍNA (G)',
                    hint: '10',
                    controller: _proteinController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppInput(
                    label: 'CARBOIDRATO (G)',
                    hint: '15',
                    controller: _carbsController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppInput(
                    label: 'GORDURA (G)',
                    hint: '4',
                    controller: _fatController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AppButton.primary(
              label: 'Cadastrar Alimento',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
