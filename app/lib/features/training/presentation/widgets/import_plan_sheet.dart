import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_input.dart';
import 'package:personal_fitness_os/core/widgets/liftr_badge.dart';
import 'package:personal_fitness_os/core/widgets/liftr_sheet.dart';
import 'package:personal_fitness_os/core/widgets/liftr_sheet_header.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/providers/exercise_providers.dart';
import 'package:personal_fitness_os/features/training/domain/entities/ai_generated_plan.dart';
import 'package:personal_fitness_os/features/training/domain/services/training_plan_share_codec.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/ai_workout_providers.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';

class ImportPlanSheet extends ConsumerStatefulWidget {
  const ImportPlanSheet({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  static Future<void> show(BuildContext context) {
    return showLiftrSheet<void>(
      context: context,
      maxHeightFactor: 0.86,
      builder: (_) => const ImportPlanSheet(embedded: true),
    );
  }

  @override
  ConsumerState<ImportPlanSheet> createState() => _ImportPlanSheetState();
}

class _ImportPlanSheetState extends ConsumerState<ImportPlanSheet> {
  final TextEditingController _controller = TextEditingController();
  GeneratedTrainingPlan? _decodedPlan;
  String? _decodeError;
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onInputChanged(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _decodedPlan = null;
        _decodeError = null;
      });
      return;
    }

    try {
      final plan = TrainingPlanShareCodec.decode(trimmed);
      setState(() {
        _decodedPlan = plan;
        _decodeError = null;
      });
    } on FormatException catch (e) {
      setState(() {
        _decodedPlan = null;
        _decodeError = e.message;
      });
    } catch (_) {
      setState(() {
        _decodedPlan = null;
        _decodeError = 'Código inválido ou incompleto.';
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    HapticFeedback.selectionClick();
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      if (!mounted) return;
      context.showSnackBar(
        'Área de transferência vazia.',
        isError: true,
      );
      return;
    }
    _controller.text = text;
    _onInputChanged(text);
  }

  Future<void> _importAndActivate() async {
    final draft = _decodedPlan;
    if (draft == null || _isSaving) return;

    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    final result = await ref
        .read(planPersisterServiceProvider)
        .persistPlan(draft, activateImmediately: true);

    if (!mounted) return;
    setState(() => _isSaving = false);

    result.fold(
      (savedPlan) {
        ref.read(trainingPlansStateProvider.notifier).refresh();
        ref.read(exerciseListStateProvider.notifier).refresh();
        ref.invalidate(dashboardDataProvider);
        context.showSnackBar(
          'Programa "${savedPlan.name}" importado e ativado!',
        );
        Navigator.of(context).pop();
      },
      (failure) {
        context.showSnackBar(
          userFacingMessage(failure, context: 'ImportPlanSheet._import'),
          isError: true,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final preview = _decodedPlan;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LiftrSheetHeader(
          eyebrow: 'IMPORTAR PROGRAMA',
          title: 'Importar treino por código',
          trailing: Semantics(
            label: 'Fechar importação de treino',
            button: true,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              constraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
              icon: Icon(
                Icons.close_rounded,
                color: colors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Cole o código LIFTR-PLAN-V1:... (ou a mensagem inteira do WhatsApp) '
          'para clonar as sessões e séries na sua conta.',
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        AppInput(
          key: const Key('import_plan_code_input'),
          controller: _controller,
          onChanged: _onInputChanged,
          minLines: 2,
          maxLines: 4,
          hint: 'LIFTR-PLAN-V1:...',
          fillColor: colors.surfaceSubtle,
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.textPrimary,
            fontFeatures: AppTypography.tabularFeatures,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _pasteFromClipboard,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: colors.primaryLight,
            ),
            icon: const Icon(Icons.content_paste_rounded, size: 18),
            label: const Text('Colar da área de transferência'),
          ),
        ),
        if (_decodeError != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(radius.medium),
              border: Border.all(
                color: colors.danger.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              _decodeError!,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.danger,
              ),
            ),
          ),
        ],
        if (preview != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(radius.large),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.45),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRÉVIA DO PROGRAMA',
                  style: AppTypography.eyebrow(context),
                ),
                const SizedBox(height: 4),
                Text(
                  preview.planName,
                  style: context.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    LiftrBadge(
                      label: '${preview.totalWorkoutsCount} sessões',
                      tone: LiftrBadgeTone.brand,
                    ),
                    LiftrBadge(
                      label: '${preview.totalExercisesCount} exercícios',
                      tone: LiftrBadgeTone.neutral,
                    ),
                    LiftrBadge(
                      label: '${preview.totalWorkingSetsCount} séries',
                      tone: LiftrBadgeTone.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...preview.workouts.map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${w.name} (${w.exercises.length} exercícios)',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                        fontFeatures: AppTypography.tabularFeatures,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Exercícios personalizados que não existirem na sua conta serão criados automaticamente.',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: colors.primaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        AppButton.primary(
          label: 'Importar e ativar treino',
          icon: Icons.download_done_rounded,
          isLoading: _isSaving,
          onPressed: preview != null && !_isSaving
              ? _importAndActivate
              : null,
        ),
      ],
    );

    if (widget.embedded) {
      return content;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius.xl)),
          border: Border.all(color: colors.border),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: content,
          ),
        ),
      ),
    );
  }
}
