import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/extensions/date_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_input.dart';
import 'package:personal_fitness_os/features/body/presentation/providers/weight_providers.dart';

class LogWeightModal extends ConsumerStatefulWidget {
  const LogWeightModal({
    super.key,
    this.initialWeightKg,
  });

  final double? initialWeightKg;

  static Future<bool?> show(BuildContext context, {double? initialWeightKg}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LogWeightModal(initialWeightKg: initialWeightKg),
    );
  }

  @override
  ConsumerState<LogWeightModal> createState() => _LogWeightModalState();
}

class _LogWeightModalState extends ConsumerState<LogWeightModal> {
  late double _weightKg;
  late DateTime _selectedDate;
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _weightKg = widget.initialWeightKg ?? 75.0;
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    final useCase = ref.read(logWeightEntryUseCaseProvider);
    final result = await useCase.execute(
      weightKg: _weightKg,
      measuredAt: _selectedDate,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (entry) {
        ref.invalidate(weightStatsProvider);
        ref.invalidate(weightHistoryProvider);
        context.showSnackBar('Peso de ${_weightKg.toStringAsFixed(1)} kg registrado!');
        Navigator.of(context).pop(true);
      },
      (failure) {
        context.showSnackBar(failure.message, isError: true);
      },
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
              'Registrar Peso',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Date picker button
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(context.appRadius.small),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(context.appRadius.small),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 18, color: colors.primary),
                    const SizedBox(width: 10),
                    Text(
                      _selectedDate.formatMedium(),
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Alterar',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Numeric weight input
            AppNumericInput(
              label: 'PESO (KG)',
              value: _weightKg,
              step: 0.1,
              min: 20.0,
              max: 300.0,
              unit: 'kg',
              onChanged: (val) => setState(() => _weightKg = (val * 10).round() / 10),
            ),
            const SizedBox(height: 16),

            // Notes input
            AppInput(
              label: 'OBSERVAÇÕES (OPCIONAL)',
              hint: 'Ex: Jejum, após treino, etc.',
              controller: _notesController,
            ),
            const SizedBox(height: 24),

            // Save button
            AppButton.primary(
              label: 'Salvar Pesagem',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
