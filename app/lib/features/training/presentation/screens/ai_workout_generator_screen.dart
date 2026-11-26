import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_motion.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_spacing.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/liftr_badge.dart';
import 'package:personal_fitness_os/core/widgets/liftr_progress_bar.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/providers/exercise_providers.dart';
import 'package:personal_fitness_os/features/settings/presentation/providers/settings_providers.dart';
import 'package:personal_fitness_os/features/training/data/datasources/ai_workout_remote_datasource.dart';
import 'package:personal_fitness_os/features/training/domain/constants/split_presets.dart';
import 'package:personal_fitness_os/features/training/domain/entities/ai_generated_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/ai_workout_request.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/ai_workout_providers.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';

class AiWorkoutGeneratorScreen extends ConsumerStatefulWidget {
  const AiWorkoutGeneratorScreen({super.key});

  @override
  ConsumerState<AiWorkoutGeneratorScreen> createState() =>
      _AiWorkoutGeneratorScreenState();
}

class _AiWorkoutGeneratorScreenState
    extends ConsumerState<AiWorkoutGeneratorScreen> {
  static const int _totalSteps = 5;
  static const List<String> _muscleFocusOptions = [
    'Glúteos',
    'Pernas',
    'Costas',
    'Peito',
    'Ombros',
    'Braços',
    'Core',
  ];

  int _step = 0;

  // Wizard study state
  late AiWorkoutGoal _goal;
  late AiWorkoutExperience _experience;
  AiEquipmentAccess _equipmentAccess = AiEquipmentAccess.fullGym;
  late int _daysPerWeek;
  int _sessionMinutes = 60;
  String? _preferredSplit;
  final Set<String> _focusMuscles = {};
  bool _includeCardio = true;
  int _cardioMinutes = 15;
  late String _biologicalSex;
  final TextEditingController _restrictionsController = TextEditingController();

  // Generation & persistence state
  bool _isGenerating = false;
  bool _isApplying = false;
  int _generationPercent = 0;
  Timer? _progressTimer;
  String? _errorMessage;
  GeneratedTrainingPlan? _generatedPlan;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(userSettingsProvider);
    _goal = switch (settings.goal) {
      UserGoal.bulking => AiWorkoutGoal.hypertrophy,
      UserGoal.cutting => AiWorkoutGoal.fatLoss,
      UserGoal.maintenance => AiWorkoutGoal.recomposition,
    };
    _experience = switch (settings.experience) {
      UserExperience.beginner => AiWorkoutExperience.beginner,
      UserExperience.intermediate => AiWorkoutExperience.intermediate,
      UserExperience.advanced => AiWorkoutExperience.advanced,
    };
    _daysPerWeek = settings.trainingDaysPerWeek.clamp(2, 6);
    _biologicalSex = settings.biologicalSex;
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _restrictionsController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (_isGenerating || _isApplying) return;
    HapticFeedback.lightImpact();

    if (_generatedPlan != null || _errorMessage != null) {
      setState(() {
        _generatedPlan = null;
        _errorMessage = null;
      });
      return;
    }

    if (_step > 0) {
      setState(() => _step--);
      return;
    }

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/training');
    }
  }

  void _nextStep() {
    HapticFeedback.lightImpact();
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      _generatePlan();
    }
  }

  AiWorkoutRequest _buildRequest() {
    return AiWorkoutRequest(
      goal: _goal,
      experience: _experience,
      daysPerWeek: _daysPerWeek,
      sessionMinutes: _sessionMinutes,
      preferredSplit: _preferredSplit,
      focusMuscles: _focusMuscles.toList(),
      equipmentAccess: _equipmentAccess,
      includeCardio: _includeCardio,
      cardioMinutesPerSession: _cardioMinutes,
      restrictionsNotes: _restrictionsController.text.trim(),
      biologicalSex: _biologicalSex,
    );
  }

  void _startProgressTicker() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(context.appMotion.standard, (timer) {
      if (!mounted || !_isGenerating) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_generationPercent < 30) {
          _generationPercent += 5;
        } else if (_generationPercent < 70) {
          _generationPercent += 4;
        } else if (_generationPercent < 92) {
          _generationPercent += 2;
        }
      });
    });
  }

  Future<void> _generatePlan() async {
    if (_isGenerating) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _isGenerating = true;
      _generationPercent = 6;
      _errorMessage = null;
    });
    _startProgressTicker();

    try {
      final remote = ref.read(aiWorkoutRemoteDataSourceProvider);
      final plan = await remote.generatePlan(_buildRequest());
      _progressTimer?.cancel();
      if (!mounted) return;
      final completionDelay = context.appMotion.resolve(
        context,
        context.appMotion.fast,
      );
      setState(() {
        _generationPercent = 100;
      });
      if (completionDelay > Duration.zero) {
        await Future<void>.delayed(completionDelay);
        if (!mounted) return;
      }
      setState(() {
        _generatedPlan = plan;
        _isGenerating = false;
      });
    } on AiWorkoutException catch (e) {
      _progressTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isGenerating = false;
      });
    } catch (e) {
      _progressTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Não foi possível gerar seu treino agora: $e';
        _isGenerating = false;
      });
    }
  }

  Future<void> _applyGeneratedPlan() async {
    final plan = _generatedPlan;
    if (plan == null || _isApplying) return;

    HapticFeedback.mediumImpact();
    setState(() => _isApplying = true);

    final result = await ref
        .read(planPersisterServiceProvider)
        .persistPlan(plan, activateImmediately: true);

    if (!mounted) return;
    setState(() => _isApplying = false);

    result.fold(
      (saved) {
        ref.read(trainingPlansStateProvider.notifier).refresh();
        ref.read(exerciseListStateProvider.notifier).refresh();
        ref.invalidate(dashboardDataProvider);
        context.showSnackBar(
          'Programa "${saved.name}" criado e ativado!',
        );
        context.go('/training');
      },
      (failure) {
        context.showSnackBar(
          'Erro ao salvar programa: ${failure.message}',
          isError: true,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final showWizard =
        !_isGenerating && _errorMessage == null && _generatedPlan == null;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Chrome Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 18, 8),
              child: Row(
                children: [
                  Semantics(
                    label: 'Voltar',
                    button: true,
                    child: IconButton(
                      onPressed: _handleBack,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: showWizard
                        ? LiftrProgressBar(
                            progress: (_step + 1) / _totalSteps,
                            height: 4,
                          )
                        : Text(
                            'TREINO PERSONALIZADO COM IA',
                            style: AppTypography.eyebrow(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                  if (showWizard) ...[
                    const SizedBox(width: 12),
                    Text(
                      'Passo ${_step + 1} de $_totalSteps',
                      style: context.textTheme.labelMedium?.copyWith(
                        color: colors.textSecondary,
                        fontFeatures: AppTypography.tabularFeatures,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: ResponsiveContainer(
                  child: _buildBodyContent(context),
                ),
              ),
            ),

            // Sticky Bottom CTA
            if (showWizard)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                child: ResponsiveContainer(
                  padding: EdgeInsets.zero,
                  child: AppButton.primary(
                    label: _step == _totalSteps - 1
                        ? 'Gerar treino com IA'
                        : 'Continuar',
                    icon: _step == _totalSteps - 1
                        ? Icons.auto_awesome_rounded
                        : null,
                    onPressed: _nextStep,
                  ),
                ),
              )
            else if (_generatedPlan != null)
              Container(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(top: BorderSide(color: colors.border)),
                ),
                child: ResponsiveContainer(
                  padding: EdgeInsets.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppButton.primary(
                        label: 'Aplicar este treino',
                        icon: Icons.check_rounded,
                        isLoading: _isApplying,
                        onPressed: _isApplying ? null : _applyGeneratedPlan,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          TextButton.icon(
                            onPressed: _isApplying ? null : _generatePlan,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 44),
                              foregroundColor: colors.primaryLight,
                            ),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Gerar outra opção'),
                          ),
                          TextButton.icon(
                            onPressed: _isApplying
                                ? null
                                : () => setState(() => _generatedPlan = null),
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 44),
                              foregroundColor: colors.textSecondary,
                            ),
                            icon: const Icon(Icons.tune_rounded, size: 18),
                            label: const Text('Ajustar respostas'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent(BuildContext context) {
    if (_isGenerating) {
      return _buildGeneratingState(context);
    }
    if (_errorMessage != null) {
      return _buildErrorState(context, _errorMessage!);
    }
    if (_generatedPlan != null) {
      return _buildPreviewState(context, _generatedPlan!);
    }

    switch (_step) {
      case 0:
        return _buildGoalStep(context);
      case 1:
        return _buildExperienceAndEquipmentStep(context);
      case 2:
        return _buildScheduleAndSplitStep(context);
      case 3:
        return _buildFocusAndCardioStep(context);
      default:
        return _buildRestrictionsAndSummaryStep(context);
    }
  }

  Widget _buildStepHeader(
    BuildContext context, {
    required String eyebrow,
    required String title,
    required String subtitle,
  }) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow, style: AppTypography.eyebrow(context)),
        const SizedBox(height: 6),
        Text(title, style: context.textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGoalStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          context,
          eyebrow: 'ESTUDO RÁPIDO · OBJETIVO',
          title: 'Qual é o foco principal deste treino?',
          subtitle:
              'O Gemini calibra volume de séries, faixas de repetições e intervalos para o seu objetivo.',
        ),
        ...AiWorkoutGoal.values.map(
          (g) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _StudyOptionCard(
              title: g.label,
              subtitle: g.subtitle,
              selected: _goal == g,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _goal = g);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceAndEquipmentStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          context,
          eyebrow: 'ESTUDO RÁPIDO · PERFIL TÉCNICO',
          title: 'Experiência e equipamentos',
          subtitle:
              'Adequamos a complexidade dos exercícios e o volume semanal ao que você tem disponível.',
        ),
        Text('NÍVEL DE EXPERIÊNCIA', style: AppTypography.eyebrow(context)),
        const SizedBox(height: 8),
        ...AiWorkoutExperience.values.map(
          (exp) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _StudyOptionCard(
              title: exp.label,
              subtitle: exp.subtitle,
              selected: _experience == exp,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _experience = exp);
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text('ESTRUTURA DISPONÍVEL', style: AppTypography.eyebrow(context)),
        const SizedBox(height: 8),
        ...AiEquipmentAccess.values.map(
          (eq) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _StudyOptionCard(
              title: eq.label,
              subtitle: eq.subtitle,
              selected: _equipmentAccess == eq,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _equipmentAccess = eq);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleAndSplitStep(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final splitsForDays = SplitPresets.forDays(_daysPerWeek);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          context,
          eyebrow: 'ESTUDO RÁPIDO · ROTINA SEMANAL',
          title: 'Frequência, duração e divisão',
          subtitle:
              'Escolha quantos dias você treina e se prefere alguma divisão específica (ABC, ABCD, Upper/Lower, etc.).',
        ),
        Text('DIAS POR SEMANA', style: AppTypography.eyebrow(context)),
        const SizedBox(height: 10),
        Row(
          children: [2, 3, 4, 5, 6].asMap().entries.map((entry) {
            final idx = entry.key;
            final days = entry.value;
            final isSelected = _daysPerWeek == days;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: idx == 0 ? 0 : 6),
                child: Semantics(
                  label: '$days dias por semana',
                  selected: isSelected,
                  button: true,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _daysPerWeek = days;
                        _preferredSplit = null;
                      });
                    },
                    borderRadius: BorderRadius.circular(radius.medium),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colors.primary
                            : colors.surfaceElevated,
                        borderRadius: BorderRadius.circular(radius.medium),
                        border: Border.all(
                          color: isSelected ? colors.primary : colors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '$days',
                        style: context.textTheme.titleLarge?.copyWith(
                          color: isSelected
                              ? colors.onPrimary
                              : colors.textPrimary,
                          fontFeatures: AppTypography.tabularFeatures,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text('TEMPO POR SESSÃO', style: AppTypography.eyebrow(context)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [40, 50, 60, 75, 90].map((mins) {
            final selected = _sessionMinutes == mins;
            return _SelectableChip(
              label: '$mins min',
              selected: selected,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _sessionMinutes = mins);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text('DIVISÃO DE TREINO', style: AppTypography.eyebrow(context)),
        const SizedBox(height: 10),
        _StudyOptionCard(
          title: 'Sugestão inteligente da IA',
          subtitle:
              'Deixar o Gemini escolher a melhor divisão para $_daysPerWeek dias/semana',
          selected: _preferredSplit == null,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _preferredSplit = null);
          },
        ),
        const SizedBox(height: 10),
        ...splitsForDays.map(
          (preset) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _StudyOptionCard(
              title: preset.name,
              subtitle: preset.queueDescription,
              badgeLabel: preset.focusTag,
              selected: _preferredSplit == preset.name,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _preferredSplit = preset.name);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFocusAndCardioStep(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          context,
          eyebrow: 'ESTUDO RÁPIDO · ÊNFASE & CARDIO',
          title: 'Grupos prioritários e cardio',
          subtitle:
              'Marque até 3 grupos musculares caso queira dar foco extra (opcional) e configure seu cardio.',
        ),
        Text(
          'ÊNFASE MUSCULAR (OPCIONAL)',
          style: AppTypography.eyebrow(context),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _muscleFocusOptions.map((muscle) {
            final selected = _focusMuscles.contains(muscle);
            return _SelectableChip(
              label: muscle,
              selected: selected,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (selected) {
                    _focusMuscles.remove(muscle);
                  } else if (_focusMuscles.length < 3) {
                    _focusMuscles.add(muscle);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text('CARDIO EM TEMPO', style: AppTypography.eyebrow(context)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(radius.large),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Incluir cardio nas sessões',
                          style: context.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Registrado em minutos para comparação semanal',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _includeCardio,
                    activeTrackColor: colors.primary,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      setState(() => _includeCardio = val);
                    },
                  ),
                ],
              ),
              if (_includeCardio) ...[
                const SizedBox(height: 14),
                Text(
                  'DURAÇÃO ALVO POR SESSÃO',
                  style: AppTypography.eyebrow(context),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [10, 15, 20, 30, 40].map((mins) {
                    return _SelectableChip(
                      label: '$mins min',
                      selected: _cardioMinutes == mins,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _cardioMinutes = mins);
                      },
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRestrictionsAndSummaryStep(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          context,
          eyebrow: 'ESTUDO RÁPIDO · REVISÃO FINAL',
          title: 'Alguma restrição ou preferência?',
          subtitle:
              'Informe dores articulares, exercícios que prefere evitar ou qualquer detalhe adicional.',
        ),
        TextField(
          key: const Key('ai_restrictions_input'),
          controller: _restrictionsController,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            hintText:
                'Ex: desconforto no ombro, foco em glúteos e posterior, evitar agachamento livre...',
            filled: true,
            fillColor: colors.surface,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(radius.large),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RESUMO DO SEU PERFIL',
                style: AppTypography.eyebrow(context),
              ),
              const SizedBox(height: 10),
              _SummaryRow(label: 'Objetivo', value: _goal.label),
              _SummaryRow(label: 'Experiência', value: _experience.label),
              _SummaryRow(label: 'Estrutura', value: _equipmentAccess.label),
              _SummaryRow(
                label: 'Rotina',
                value: '$_daysPerWeek dias/sem · $_sessionMinutes min',
              ),
              _SummaryRow(
                label: 'Divisão',
                value: _preferredSplit ?? 'Sugestão da IA',
              ),
              _SummaryRow(
                label: 'Ênfase',
                value: _focusMuscles.isEmpty
                    ? 'Equilibrado'
                    : _focusMuscles.join(', '),
              ),
              _SummaryRow(
                label: 'Cardio',
                value: _includeCardio
                    ? 'Sim ($_cardioMinutes min/sessão)'
                    : 'Não incluir',
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _generatingStageLabel(int percent) {
    if (percent >= 100) return 'Treino pronto!';
    if (percent > 70) return 'Calibrando séries, repetições, descanso e cardio...';
    if (percent > 30) return 'Selecionando exercícios do catálogo LIFTR...';
    return 'Analisando seu perfil, nível e divisão ideal...';
  }

  Widget _buildGeneratingState(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;
    final radius = context.appRadius;
    final percent = _generationPercent.clamp(0, 100);
    final stageLabel = _generatingStageLabel(percent);

    const stages = [
      (threshold: 30, label: 'Perfil e divisão semanal'),
      (threshold: 70, label: 'Seleção do catálogo LIFTR'),
      (threshold: 95, label: 'Séries, descanso e cardio'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(radius.xl),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    'MONTANDO TREINO COM IA',
                    style: AppTypography.eyebrow(context),
                  ),
                ),
                Text(
                  '$percent%',
                  key: const Key('ai_generating_percent_text'),
                  style: context.textTheme.displayMedium?.copyWith(
                    color: percent >= 100
                        ? fitnessColors.progressUp
                        : colors.primaryLight,
                    fontFeatures: AppTypography.tabularFeatures,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LiftrProgressBar(
              progress: percent / 100.0,
              height: 6,
              color: percent >= 100
                  ? fitnessColors.progressUp
                  : colors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              stageLabel,
              style: context.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'O Gemini está estruturando $_daysPerWeek sessões (${_goal.label}) para o seu nível.',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            for (final stage in stages) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      percent >= stage.threshold
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: percent >= stage.threshold
                          ? fitnessColors.progressUp
                          : colors.textTertiary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stage.label,
                        style: context.textTheme.labelMedium?.copyWith(
                          color: percent >= stage.threshold
                              ? colors.textPrimary
                              : colors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final colors = context.appColors;
    final radius = context.appRadius;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(radius.xl),
          border: Border.all(color: colors.warning.withValues(alpha: 0.45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: colors.warning,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Não foi possível concluir a geração',
                    style: context.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            AppButton.primary(
              label: 'Tentar novamente',
              icon: Icons.refresh_rounded,
              onPressed: _generatePlan,
            ),
            const SizedBox(height: 10),
            AppButton.secondary(
              label: 'Ajustar respostas',
              onPressed: () => setState(() => _errorMessage = null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewState(
    BuildContext context,
    GeneratedTrainingPlan plan,
  ) {
    final colors = context.appColors;
    final radius = context.appRadius;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PLANO RECOMENDADO PELO GEMINI',
          style: AppTypography.eyebrow(context),
        ),
        const SizedBox(height: 6),
        Text(plan.planName, style: context.textTheme.headlineMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            LiftrBadge(
              label: plan.splitType,
              tone: LiftrBadgeTone.brand,
            ),
            LiftrBadge(
              label: '${plan.totalWorkoutsCount} sessões',
              tone: LiftrBadgeTone.neutral,
            ),
            LiftrBadge(
              label: '${plan.totalExercisesCount} exercícios',
              tone: LiftrBadgeTone.neutral,
            ),
            LiftrBadge(
              label: '${plan.totalWorkingSetsCount} séries/sem',
              tone: LiftrBadgeTone.neutral,
            ),
          ],
        ),
        if (plan.rationale != null && plan.rationale!.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.primaryMuted,
              borderRadius: BorderRadius.circular(radius.medium),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              plan.rationale!,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        ...plan.workouts.asMap().entries.map((entry) {
          final index = entry.key;
          final workout = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              variant: index == 0
                  ? AppCardVariant.accented
                  : AppCardVariant.raised,
              accentColor: colors.primary,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          workout.name,
                          style: context.textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '~${workout.estimatedDurationMinutes} min',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: colors.textSecondary,
                          fontFeatures: AppTypography.tabularFeatures,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.verticalGap12,
                  ...workout.exercises.map((ex) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            ex.isCardio
                                ? Icons.timer_rounded
                                : Icons.fitness_center_rounded,
                            size: 16,
                            color: ex.isCardio
                                ? colors.primaryLight
                                : colors.textTertiary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ex.exerciseName,
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: LiftrBadge(
                              label: ex.prescriptionSummary,
                              tone: ex.isCardio
                                  ? LiftrBadgeTone.brand
                                  : LiftrBadgeTone.neutral,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _StudyOptionCard extends StatelessWidget {
  const _StudyOptionCard({
    required this.title,
    this.subtitle,
    this.badgeLabel,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final String? badgeLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;

    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius.large),
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? colors.primary.withValues(alpha: 0.12)
                : colors.surface,
            borderRadius: BorderRadius.circular(radius.large),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          title,
                          style: context.textTheme.titleSmall?.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        if (badgeLabel != null)
                          LiftrBadge(
                            label: badgeLabel!,
                            tone: LiftrBadgeTone.brand,
                          ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? colors.primary : Colors.transparent,
                  border: Border.all(
                    color: selected ? colors.primary : colors.border,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: colors.onPrimary,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectableChip extends StatelessWidget {
  const _SelectableChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;

    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius.medium),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 56),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? colors.primary : colors.surfaceElevated,
            borderRadius: BorderRadius.circular(radius.medium),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
            ),
          ),
          child: Text(
            label,
            style: context.textTheme.labelMedium?.copyWith(
              color: selected ? colors.onPrimary : colors.textPrimary,
              fontFeatures: AppTypography.tabularFeatures,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontFeatures: AppTypography.tabularFeatures,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
