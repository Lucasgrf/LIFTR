import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_input.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal.dart';
import 'package:personal_fitness_os/features/goals/presentation/providers/goal_providers.dart';

class AddCheckpointModal extends ConsumerStatefulWidget {
  const AddCheckpointModal({
    super.key,
    required this.goal,
  });

  final Goal goal;

  static Future<bool?> show(
    BuildContext context, {
    required Goal goal,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddCheckpointModal(goal: goal),
    );
  }

  @override
  ConsumerState<AddCheckpointModal> createState() =>
      _AddCheckpointModalState();
}

class _AddCheckpointModalState extends ConsumerState<AddCheckpointModal> {
  late final TextEditingController _valueController;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _valueController =
        TextEditingController(text: widget.goal.currentValue.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final val = double.tryParse(_valueController.text.trim());
    if (val == null || !val.isFinite) {
      context.showSnackBar('Informe um valor numérico válido.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final useCase = ref.read(addGoalCheckpointUseCaseProvider);
    final result = await useCase.execute(
      goalId: widget.goal.id,
      value: val,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (checkpoint) {
        ref.invalidate(goalsListProvider);
        ref.invalidate(goalDetailProvider(widget.goal.id));
        context.showSnackBar('Check-in registrado com sucesso!');
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
              'Registrar Check-in',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.goal.title,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            AppInput(
              label: 'VALOR ATUAL (${widget.goal.unit.toUpperCase()})',
              hint: 'Ex: 82.5',
              controller: _valueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            AppInput(
              label: 'ANOTAÇÃO (OPCIONAL)',
              hint: 'Ex: Sensação boa, peso em jejum',
              controller: _notesController,
            ),
            const SizedBox(height: 24),
            AppButton.primary(
              label: 'Salvar Check-in',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
