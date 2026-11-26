import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/utils/duration_formatter.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/app_input.dart';
import 'package:personal_fitness_os/core/widgets/liftr_sheet.dart';
import 'package:personal_fitness_os/core/widgets/liftr_sheet_header.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/cardio_log.dart';
import 'package:personal_fitness_os/features/weekly_comparison/presentation/providers/weekly_comparison_providers.dart';

class LogCardioModal extends ConsumerStatefulWidget {
  const LogCardioModal({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  static Future<bool?> show(BuildContext context) {
    return showLiftrSheet<bool>(
      context: context,
      builder: (_) => const LogCardioModal(embedded: true),
    );
  }

  @override
  ConsumerState<LogCardioModal> createState() => _LogCardioModalState();
}

class _LogCardioModalState extends ConsumerState<LogCardioModal> {
  String _modality = CardioLog.modalities.first;
  int _minutes = 20;
  final TextEditingController _notesController = TextEditingController();
  bool _isSaving = false;

  static const List<int> _presets = [15, 20, 30, 45, 60];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _stepMinutes(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _minutes = (_minutes + delta).clamp(1, 300);
    });
  }

  Future<void> _editMinutesDialog() async {
    final controller = TextEditingController(text: '$_minutes');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tempo de cardio (min)'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'min'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null) {
      final parsed = int.tryParse(result.trim());
      if (parsed != null && parsed > 0) {
        setState(() => _minutes = parsed.clamp(1, 300));
      }
    }
  }

  Future<void> _submit() async {
    if (_isSaving || _minutes <= 0) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    final repo = ref.read(weeklyComparisonRepositoryProvider);
    final result = await repo.logStandaloneCardio(
      modality: _modality,
      durationSeconds: _minutes * 60,
      performedAt: DateTime.now(),
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    result.fold(
      (_) {
        ref.invalidate(currentWeekSummaryProvider);
        ref.invalidate(weeklyComparisonProvider);
        ref.invalidate(dashboardDataProvider);
        context.showSnackBar(
          'Cardio registrado (${formatCardioSeconds(_minutes * 60)}).',
        );
        Navigator.of(context).pop(true);
      },
      (failure) {
        context.showSnackBar(
          'Erro ao salvar cardio: ${failure.message}',
          isError: true,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LiftrSheetHeader(
          eyebrow: 'CARDIO AVULSO',
          title: 'Registrar cardio',
        ),
        const SizedBox(height: 16),
        Text(
          'Modalidade',
          style: context.textTheme.labelMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CardioLog.modalities.map((mod) {
            final selected = _modality == mod;
            return Semantics(
              label: mod,
              button: true,
              selected: selected,
              child: Material(
                color: selected ? colors.primaryMuted : colors.surfaceElevated,
                shape: StadiumBorder(
                  side: BorderSide(
                    color: selected ? colors.primary : colors.border,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _modality = mod);
                  },
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 48,
                      minWidth: 48,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Text(
                      mod,
                      style: context.textTheme.labelMedium?.copyWith(
                        color: selected
                            ? colors.primaryLight
                            : colors.textPrimary,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        Text(
          'Duração',
          style: context.textTheme.labelMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        AppCard(
          backgroundColor: colors.surfaceElevated,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Semantics(
                label: 'Diminuir 5 minutos',
                button: true,
                child: Material(
                  color: colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radius.medium),
                    side: BorderSide(color: colors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _stepMinutes(-5),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.remove_rounded,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Semantics(
                  label: 'Editar duração de cardio',
                  button: true,
                  child: InkWell(
                    onTap: _editMinutesDialog,
                    borderRadius: BorderRadius.circular(radius.small),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        formatCardioSeconds(_minutes * 60),
                        textAlign: TextAlign.center,
                        style: context.textTheme.displaySmall?.copyWith(
                          color: colors.primaryLight,
                          fontFeatures: AppTypography.tabularFeatures,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Semantics(
                label: 'Aumentar 5 minutos',
                button: true,
                child: Material(
                  color: colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radius.medium),
                    side: BorderSide(color: colors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _stepMinutes(5),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.add_rounded,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presets.map((preset) {
            final isSelected = _minutes == preset;
            return Semantics(
              label: '$preset minutos',
              button: true,
              selected: isSelected,
              child: Material(
                color: isSelected ? colors.primary : colors.surfaceElevated,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radius.small),
                  side: BorderSide(
                    color: isSelected ? colors.primary : colors.border,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _minutes = preset);
                  },
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 48,
                      minWidth: 52,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${preset}m',
                      style: context.textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? colors.onPrimary
                            : colors.textSecondary,
                        fontFeatures: AppTypography.tabularFeatures,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        AppInput(
          label: 'Observações (opcional)',
          hint: 'Ex: Inclinação 6%, ritmo leve pós-treino...',
          controller: _notesController,
          maxLines: 2,
        ),
        const SizedBox(height: 20),
        AppButton.primary(
          label: 'Salvar cardio',
          icon: Icons.check_rounded,
          isLoading: _isSaving,
          onPressed: _submit,
        ),
      ],
    );

    if (widget.embedded) {
      return content;
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius.xl)),
        border: Border.all(color: colors.border),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(child: content),
    );
  }
}
