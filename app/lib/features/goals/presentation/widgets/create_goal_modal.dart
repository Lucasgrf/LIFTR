import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/extensions/date_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_input.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_category.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_status.dart';
import 'package:personal_fitness_os/features/goals/presentation/providers/goal_providers.dart';

class CreateGoalModal extends ConsumerStatefulWidget {
  const CreateGoalModal({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateGoalModal(),
    );
  }

  @override
  ConsumerState<CreateGoalModal> createState() => _CreateGoalModalState();
}

class _CreateGoalModalState extends ConsumerState<CreateGoalModal> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _initialValueController = TextEditingController();
  final _targetValueController = TextEditingController();
  final _unitController = TextEditingController();

  GoalCategory _selectedCategory = GoalCategory.weight;
  DateTime? _deadline;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _unitController.text = _selectedCategory.defaultUnit;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _initialValueController.dispose();
    _targetValueController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();
    final initial = double.tryParse(_initialValueController.text.trim());
    final target = double.tryParse(_targetValueController.text.trim());
    final unit = _unitController.text.trim();

    if (title.isEmpty) {
      context.showSnackBar('Título da meta é obrigatório.', isError: true);
      return;
    }
    if (initial == null || !initial.isFinite || target == null || !target.isFinite) {
      context.showSnackBar(
          'Valores inicial e alvo devem ser números válidos.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final goal = Goal(
      id: '',
      title: title,
      description: description,
      category: _selectedCategory,
      initialValue: initial,
      targetValue: target,
      currentValue: initial,
      unit: unit,
      startedAt: DateTime.now(),
      deadline: _deadline,
      status: GoalStatus.active,
    );

    final useCase = ref.read(createGoalUseCaseProvider);
    final result = await useCase.execute(goal);

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (created) {
        ref.invalidate(goalsListProvider);
        context.showSnackBar('Meta "${created.title}" criada com sucesso!');
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
              'Nova Meta',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Category Dropdown
            DropdownButtonFormField<GoalCategory>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'CATEGORIA',
                labelStyle: context.textTheme.labelSmall?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
                filled: true,
                fillColor: colors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.appRadius.medium),
                  borderSide: BorderSide(color: colors.border),
                ),
              ),
              items: GoalCategory.values.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat.label),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedCategory = val;
                    if (_unitController.text.isEmpty ||
                        GoalCategory.values
                            .any((c) => c.defaultUnit == _unitController.text)) {
                      _unitController.text = val.defaultUnit;
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 12),

            AppInput(
              label: 'TÍTULO DA META',
              hint: 'Ex: Chegar a 80kg ou Supino 100kg',
              controller: _titleController,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: AppInput(
                    label: 'VALOR INICIAL',
                    hint: '86',
                    controller: _initialValueController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppInput(
                    label: 'VALOR ALVO',
                    hint: '80',
                    controller: _targetValueController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppInput(
                    label: 'UNIDADE',
                    hint: 'kg',
                    controller: _unitController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Deadline selection button
            InkWell(
              onTap: _pickDeadline,
              borderRadius: BorderRadius.circular(context.appRadius.medium),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(context.appRadius.medium),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_rounded,
                        size: 20, color: colors.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _deadline == null
                            ? 'Definir Prazo (Opcional)'
                            : 'Prazo: ${_deadline!.formatFull()}',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: _deadline == null
                              ? colors.textSecondary
                              : colors.textPrimary,
                        ),
                      ),
                    ),
                    if (_deadline != null)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        onPressed: () => setState(() => _deadline = null),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            AppInput(
              label: 'DESCRIÇÃO / MOTIVAÇÃO (OPCIONAL)',
              hint: 'Ex: Foco no cutting para o verão',
              controller: _descriptionController,
            ),
            const SizedBox(height: 24),

            AppButton.primary(
              label: 'Criar Meta',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
