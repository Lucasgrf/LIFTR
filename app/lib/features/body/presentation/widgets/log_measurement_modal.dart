import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_input.dart';
import 'package:personal_fitness_os/features/body/domain/entities/body_measurement.dart';
import 'package:personal_fitness_os/features/body/presentation/providers/measurement_providers.dart';

class LogMeasurementModal extends ConsumerStatefulWidget {
  const LogMeasurementModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.appRadius.large),
        ),
      ),
      builder: (_) => const LogMeasurementModal(),
    );
  }

  @override
  ConsumerState<LogMeasurementModal> createState() => _LogMeasurementModalState();
}

class _LogMeasurementModalState extends ConsumerState<LogMeasurementModal> {
  final _waistController = TextEditingController();
  final _chestController = TextEditingController();
  final _armRightController = TextEditingController();
  final _armLeftController = TextEditingController();
  final _thighRightController = TextEditingController();
  final _thighLeftController = TextEditingController();
  final _hipController = TextEditingController();
  final _shoulderController = TextEditingController();
  final _calfRightController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _waistController.dispose();
    _chestController.dispose();
    _armRightController.dispose();
    _armLeftController.dispose();
    _thighRightController.dispose();
    _thighLeftController.dispose();
    _hipController.dispose();
    _shoulderController.dispose();
    _calfRightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double? _parseVal(String text) {
    if (text.trim().isEmpty) return null;
    return double.tryParse(text.replaceAll(',', '.'));
  }

  Future<void> _submit() async {
    final waist = _parseVal(_waistController.text);
    final chest = _parseVal(_chestController.text);
    final armR = _parseVal(_armRightController.text);
    final armL = _parseVal(_armLeftController.text);
    final thighR = _parseVal(_thighRightController.text);
    final thighL = _parseVal(_thighLeftController.text);
    final hip = _parseVal(_hipController.text);
    final shoulder = _parseVal(_shoulderController.text);
    final calfR = _parseVal(_calfRightController.text);
    final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

    if (waist == null &&
        chest == null &&
        armR == null &&
        armL == null &&
        thighR == null &&
        thighL == null &&
        hip == null &&
        shoulder == null &&
        calfR == null) {
      context.showSnackBar('Preencha pelo menos uma medida corporal.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final measurement = BodyMeasurement(
        id: '',
        measuredAt: DateTime.now(),
        waist: waist,
        chest: chest,
        armRight: armR,
        armLeft: armL,
        thighRight: thighR,
        thighLeft: thighL,
        hip: hip,
        shoulder: shoulder,
        calfRight: calfR,
        notes: notes,
      );

      final useCase = ref.read(logMeasurementUseCaseProvider);
      final result = await useCase.execute(measurement);

      if (!mounted) return;

      result.fold(
        (_) {
          ref.invalidate(measurementsListProvider);
          ref.invalidate(latestMeasurementProvider);
          Navigator.of(context).pop();
          context.showSnackBar('Medidas registradas com sucesso!');
        },
        (failure) {
          context.showSnackBar(failure.message, isError: true);
        },
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Registrar Medidas',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Form Fields Grid
            Row(
              children: [
                Expanded(
                  child: AppInput(
                    label: 'Cintura (cm)',
                    hint: '80.0',
                    controller: _waistController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppInput(
                    label: 'Peitoral (cm)',
                    hint: '102.0',
                    controller: _chestController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: AppInput(
                    label: 'Braço Dir. (cm)',
                    hint: '38.0',
                    controller: _armRightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppInput(
                    label: 'Braço Esq. (cm)',
                    hint: '38.0',
                    controller: _armLeftController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: AppInput(
                    label: 'Coxa Dir. (cm)',
                    hint: '58.0',
                    controller: _thighRightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppInput(
                    label: 'Quadril (cm)',
                    hint: '98.0',
                    controller: _hipController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: AppInput(
                    label: 'Ombros (cm)',
                    hint: '115.0',
                    controller: _shoulderController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppInput(
                    label: 'Panturrilha (cm)',
                    hint: '37.0',
                    controller: _calfRightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            AppInput(
              label: 'Observações (opcional)',
              hint: 'Em jejum, pós-treino, etc.',
              controller: _notesController,
            ),
            const SizedBox(height: 20),

            AppButton.primary(
              label: 'Salvar Medidas',
              isLoading: _isSaving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
