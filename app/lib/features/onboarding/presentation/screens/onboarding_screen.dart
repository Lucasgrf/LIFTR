import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/constants/supabase_config.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/providers/clock_provider.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_motion.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/utils/pt_br_number_utils.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/app_input.dart';
import 'package:personal_fitness_os/core/widgets/liftr_badge.dart';
import 'package:personal_fitness_os/core/widgets/liftr_progress_bar.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';
import 'package:personal_fitness_os/features/body/presentation/providers/weight_providers.dart';
import 'package:personal_fitness_os/features/profile/presentation/providers/profile_providers.dart';
import 'package:personal_fitness_os/features/settings/presentation/providers/settings_providers.dart';
import 'package:personal_fitness_os/features/training/domain/constants/split_presets.dart';
import 'package:personal_fitness_os/routing/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef OnboardingCompleteHook = Future<void> Function(WidgetRef ref);

final onboardingCompleteHookProvider =
    Provider<OnboardingCompleteHook?>((ref) => null);

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const int _totalSteps = 6;

  int _step = 0;
  int _direction = 1;
  bool _isSubmitting = false;

  // Step 1
  String _sex = 'M';
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _bodyFatController;

  // Step 2
  UserGoal _goal = UserGoal.bulking;

  // Step 3
  UserExperience _experience = UserExperience.intermediate;

  // Step 4
  ActivityLevel _activityLevel = ActivityLevel.moderatelyActive;

  // Step 5
  int _daysPerWeek = 4;
  int _splitOptionIndex = 0;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(userSettingsProvider);
    _sex = initial.biologicalSex;
    _ageController = TextEditingController(text: initial.age.toString());
    _heightController =
        TextEditingController(text: initial.heightCm.toString());
    _weightController = TextEditingController(
      text: formatPtBrDecimal(initial.weightKg, decimalDigits: 1),
    );
    _bodyFatController = TextEditingController(
      text: initial.bodyFatPercent != null
          ? formatPtBrDecimal(initial.bodyFatPercent!, decimalDigits: 1)
          : '',
    );
    _goal = initial.goal;
    _experience = initial.experience;
    _activityLevel = initial.activityLevel;
    _daysPerWeek = initial.trainingDaysPerWeek.clamp(2, 6);
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _bodyFatController.dispose();
    super.dispose();
  }

  List<SplitPreset> get _currentSplitOptions =>
      SplitPresets.forDays(_daysPerWeek);

  SplitPreset get _selectedSplit =>
      _currentSplitOptions[_splitOptionIndex % _currentSplitOptions.length];

  String? get _ageError {
    final text = _ageController.text.trim();
    if (text.isEmpty) return 'Entre 12 e 100';
    final age = int.tryParse(text);
    if (age == null || age < 12 || age > 100) return 'Entre 12 e 100 anos';
    return null;
  }

  String? get _heightError {
    final text = _heightController.text.trim();
    if (text.isEmpty) return 'Entre 100 e 250';
    final height = int.tryParse(text);
    if (height == null || height < 100 || height > 250) {
      return 'Entre 100 e 250 cm';
    }
    return null;
  }

  String? get _weightError {
    final text = _weightController.text.trim();
    if (text.isEmpty) return 'Entre 20 e 400';
    final weight = parsePtBrDouble(text);
    if (weight == null || weight < 20 || weight > 400) {
      return 'Entre 20 e 400 kg';
    }
    return null;
  }

  String? get _bodyFatError {
    final text = _bodyFatController.text.trim();
    if (text.isEmpty) return null;
    final bodyFat = parsePtBrDouble(text);
    if (bodyFat == null || bodyFat < 3 || bodyFat > 60) {
      return 'Entre 3% e 60%';
    }
    return null;
  }

  bool get _isCurrentStepValid {
    if (_step == 0) {
      return _ageError == null &&
          _heightError == null &&
          _weightError == null &&
          _bodyFatError == null;
    }
    return true;
  }

  void _goBack() {
    if (_isSubmitting) return;
    if (_step > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        _direction = -1;
        _step--;
      });
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/login');
    }
  }

  void _nextStep() {
    if (!_isCurrentStepValid) return;
    HapticFeedback.lightImpact();
    if (_step < _totalSteps - 1) {
      setState(() {
        _direction = 1;
        _step++;
      });
    }
  }

  Future<void> _finish({
    required bool whatsappConnected,
    bool openAiGenerator = false,
  }) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();
    try {
      final notifier = ref.read(userSettingsProvider.notifier);
      final age = int.tryParse(_ageController.text.trim()) ?? 27;
      final height = int.tryParse(_heightController.text.trim()) ?? 178;
      final weight = parsePtBrDouble(_weightController.text) ?? 78.4;
      final bodyFat = parsePtBrDouble(_bodyFatController.text);

      notifier.updateBodyData(
        biologicalSex: _sex,
        age: age,
        heightCm: height,
        weightKg: weight,
        bodyFatPercent: bodyFat,
        clearBodyFat: bodyFat == null,
      );
      notifier.setGoal(_goal);
      notifier.setExperience(_experience);
      notifier.setActivityLevel(_activityLevel);
      notifier.setSchedule(
        daysPerWeek: _daysPerWeek,
        splitName: _selectedSplit.name,
      );
      notifier.completeOnboarding(whatsappConnected: whatsappConnected);

      final upsertWeight = ref.read(upsertDailyWeightUseCaseProvider);
      if (upsertWeight != null) {
        final weightResult = await upsertWeight.execute(
          weightKg: weight,
          measuredAt: ref.read(appClockProvider)(),
        );
        weightResult.fold(
          (_) {},
          (failure) => appErrorLogger(
            failure,
            stackTrace: failure.stackTrace,
            context: 'OnboardingScreen._finish.upsertDailyWeight',
          ),
        );
        ref.invalidate(weightHistoryProvider);
        ref.invalidate(weightStatsProvider);
      }

      final targetRoute = openAiGenerator ? '/training/ai-generator' : '/';

      final completeHook = ref.read(onboardingCompleteHookProvider);
      if (completeHook != null) {
        await completeHook(ref);
      }

      if (!SupabaseConfig.isConfigured) {
        if (!mounted) return;
        syncActiveAuthSession(ref, isLoggedIn: true);
        context.go(targetRoute);
        return;
      }

      User? user;
      try {
        user = Supabase.instance.client.auth.currentUser;
      } catch (_) {
        user = null;
      }

      if (user != null) {
        final settings = ref.read(userSettingsProvider);
        try {
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(data: settings.toJson()),
          );
        } catch (_) {
          // Best-effort metadata sync; local settings remain persisted.
        }
        unawaited(
          ref.read(profileControllerProvider.notifier).syncSettingsToRemote(),
        );
        if (!mounted) return;
        syncActiveAuthSession(
          ref,
          isLoggedIn: true,
          overrideUserId: user.id,
        );
        context.go(targetRoute);
        return;
      }

      if (!mounted) return;
      context.showSnackBar('Perfil salvo! Entre na sua conta para sincronizar.');
      context.go('/login');
    } catch (e, st) {
      if (mounted) {
        context.showSnackBar(
          userFacingMessage(
            e,
            stackTrace: st,
            context: 'OnboardingScreen._finish',
          ),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Chrome top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 18, 8),
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) => Row(
                      children: [
                        Semantics(
                          label: 'Voltar',
                          button: true,
                          child: IconButton(
                            tooltip: 'Voltar',
                            onPressed: _goBack,
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
                          child: LiftrProgressBar(
                            progress: (_step + 1) / _totalSteps,
                            height: 4,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth * 0.42,
                          ),
                          child: Text(
                            'Passo ${_step + 1} de $_totalSteps',
                            maxLines: 2,
                            style: context.textTheme.labelMedium?.copyWith(
                              color: colors.textSecondary,
                              fontFeatures: AppTypography.tabularFeatures,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Step content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ResponsiveContainer(
                  child: AnimatedSwitcher(
                    duration: context.appMotion.resolve(
                      context,
                      context.appMotion.standard,
                    ),
                    switchInCurve: context.appMotion.curveStandard,
                    switchOutCurve: context.appMotion.curveExit,
                    transitionBuilder: (child, animation) {
                      if (disableAnimations) return child;
                      final offsetAnimation = Tween<Offset>(
                        begin: Offset(0.05 * _direction, 0),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: _buildStepBody(context),
                    ),
                  ),
                ),
              ),
            ),

            // Fixed Bottom CTA
            if (_step < _totalSteps - 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                child: ResponsiveContainer(
                  padding: EdgeInsets.zero,
                  child: AppButton.primary(
                    label: _step == 4 ? 'Confirmar plano' : 'Continuar',
                    onPressed: _isCurrentStepValid ? _nextStep : null,
                  ),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildStepBody(BuildContext context) {
    switch (_step) {
      case 0:
        return _buildBodyDataStep(context);
      case 1:
        return _buildGoalStep(context);
      case 2:
        return _buildExperienceStep(context);
      case 3:
        return _buildActivityStep(context);
      case 4:
        return _buildScheduleStep(context);
      default:
        return _buildWhatsappStep(context);
    }
  }

  Widget _buildStepHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPair(
    BuildContext context, {
    required bool isNarrow,
    required Widget first,
    required Widget second,
    CrossAxisAlignment rowCrossAxisAlignment = CrossAxisAlignment.start,
  }) {
    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          first,
          const SizedBox(height: 12),
          second,
        ],
      );
    }
    return Row(
      crossAxisAlignment: rowCrossAxisAlignment,
      children: [
        Expanded(child: first),
        const SizedBox(width: 12),
        Expanded(child: second),
      ],
    );
  }

  Widget _buildBodyDataStep(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 320;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              context,
              title: 'Seus dados corporais',
              subtitle:
                  'Usamos isso apenas para calcular suas metas iniciais de carga e gasto calórico.',
            ),
            _buildPair(
              context,
              isNarrow: isNarrow,
              rowCrossAxisAlignment: CrossAxisAlignment.center,
              first: _SelectableOptionCard(
                title: 'Masculino',
                selected: _sex == 'M',
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _sex = 'M');
                },
              ),
              second: _SelectableOptionCard(
                title: 'Feminino',
                selected: _sex == 'F',
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _sex = 'F');
                },
              ),
            ),
            const SizedBox(height: 18),
            _buildPair(
              context,
              isNarrow: isNarrow,
              first: _NumericStepInput(
                label: 'Idade',
                controller: _ageController,
                suffix: 'anos',
                decimal: false,
                errorText: _ageError,
                onChanged: (_) => setState(() {}),
              ),
              second: _NumericStepInput(
                label: 'Altura',
                controller: _heightController,
                suffix: 'cm',
                decimal: false,
                errorText: _heightError,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 12),
            _buildPair(
              context,
              isNarrow: isNarrow,
              first: _NumericStepInput(
                label: 'Peso atual',
                controller: _weightController,
                suffix: 'kg',
                decimal: true,
                errorText: _weightError,
                onChanged: (_) => setState(() {}),
              ),
              second: _NumericStepInput(
                label: '% Gordura (opc.)',
                controller: _bodyFatController,
                suffix: '%',
                decimal: true,
                errorText: _bodyFatError,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGoalStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          context,
          title: 'Qual é o seu objetivo?',
          subtitle:
              'Define o ritmo de ganho ou perda de peso nas tendências e relatórios semanais.',
        ),
        ...UserGoal.values.map(
          (goal) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SelectableOptionCard(
              title: goal.label,
              subtitle: goal.subtitle,
              selected: _goal == goal,
              minHeight: 84,
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _goal = goal);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          context,
          title: 'Sua experiência na academia',
          subtitle:
              'Ajusta o ritmo de progressão inicial sugerido pelo motor de treino.',
        ),
        ...UserExperience.values.map(
          (exp) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SelectableOptionCard(
              title: exp.label,
              subtitle: exp.subtitle,
              selected: _experience == exp,
              minHeight: 88,
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _experience = exp);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          context,
          title: 'Atividade fora da academia',
          subtitle: 'Considera sua movimentação diária no trabalho e rotina.',
        ),
        ...ActivityLevel.values.map(
          (level) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SelectableOptionCard(
              title: level.label,
              subtitle: level.subtitle,
              selected: _activityLevel == level,
              minHeight: 72,
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _activityLevel = level);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleStep(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final split = _selectedSplit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          context,
          title: 'Quantos dias por semana quer treinar?',
          subtitle:
              'Sua divisão funciona como fila rotativa — sem punição se pular um dia.',
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [2, 3, 4, 5, 6].map((days) {
            final isSelected = _daysPerWeek == days;
            return Semantics(
              label: '$days dias por semana',
              selected: isSelected,
              button: true,
              child: Material(
                color: isSelected ? colors.primary : colors.surfaceElevated,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radius.medium),
                  side: BorderSide(
                    color: isSelected ? colors.primary : colors.border,
                    width: 1.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _daysPerWeek = days;
                      _splitOptionIndex = 0;
                    });
                  },
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: Center(
                      child: Text(
                        '$days',
                        style: context.textTheme.titleLarge?.copyWith(
                          color:
                              isSelected ? colors.onPrimary : colors.textPrimary,
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
        const SizedBox(height: 24),
        AppCard(
          borderRadius: radius.xl,
          borderColor: colors.primary.withValues(alpha: 0.45),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    const LiftrBadge(
                      label: 'Sugestão automática',
                      tone: LiftrBadgeTone.brand,
                    ),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() => _splitOptionIndex++);
                      },
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      child: const Text('Alternar'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$_daysPerWeek dias → ${split.name}',
                style: context.textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                split.queueDescription,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: split.sessions.map((sessionName) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(radius.small),
                      border: Border.all(color: colors.border),
                    ),
                    child: Text(
                      sessionName,
                      style: context.textTheme.labelMedium?.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'DIVISÕES DISPONÍVEIS PARA $_daysPerWeek DIAS',
                style: AppTypography.eyebrow(context),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_currentSplitOptions.length, (idx) {
                  final option = _currentSplitOptions[idx];
                  final isSelected =
                      (_splitOptionIndex % _currentSplitOptions.length) == idx;
                  return Semantics(
                    label: 'Divisão ${option.name}',
                    selected: isSelected,
                    button: true,
                    child: Material(
                      color: isSelected
                          ? colors.primary
                          : colors.surfaceElevated,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(radius.medium),
                        side: BorderSide(
                          color: isSelected ? colors.primary : colors.border,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _splitOptionIndex = idx);
                        },
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 48),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(
                            option.shortLabel,
                            style: context.textTheme.labelMedium?.copyWith(
                              color: isSelected
                                  ? colors.onPrimary
                                  : colors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWhatsappStep(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final fitnessColors = context.fitnessColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: fitnessColors.progressUp.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(radius.xl),
              border: Border.all(
                color: fitnessColors.progressUp.withValues(alpha: 0.35),
              ),
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 34,
              color: fitnessColors.progressUp,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Conecte seu WhatsApp',
          style: context.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'O app foca 100% no treino. Dieta, peso e relatórios acontecem pelo WhatsApp.',
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        const AppCard(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _BulletRow(
                icon: Icons.restaurant_rounded,
                text: 'Registre refeições por áudio ou texto em segundos',
              ),
              SizedBox(height: 14),
              _BulletRow(
                icon: Icons.monitor_weight_rounded,
                text: 'Envie seu peso pela manhã para atualizar a tendência EMA',
              ),
              SizedBox(height: 14),
              _BulletRow(
                icon: Icons.summarize_rounded,
                text: 'Receba resumo pós-treino e relatório semanal todo domingo',
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        AppButton.primary(
          label: 'Conectar WhatsApp',
          icon: Icons.link_rounded,
          isLoading: _isSubmitting,
          onPressed: _isSubmitting
              ? null
              : () => _finish(whatsappConnected: true),
        ),
        const SizedBox(height: 10),
        AppButton.secondary(
          label: 'Montar meu treino com IA',
          icon: Icons.auto_awesome_rounded,
          onPressed: _isSubmitting
              ? null
              : () => _finish(
                    whatsappConnected: false,
                    openAiGenerator: true,
                  ),
        ),
        const SizedBox(height: 10),
        AppButton.text(
          label: 'Pular e fazer depois',
          onPressed: _isSubmitting
              ? null
              : () => _finish(whatsappConnected: false),
        ),
      ],
    );
  }
}

class _SelectableOptionCard extends StatelessWidget {
  const _SelectableOptionCard({
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
    this.minHeight = 58,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Semantics(
      selected: selected,
      button: true,
      child: AppCard(
        onTap: onTap,
        backgroundColor: selected
            ? colors.primary.withValues(alpha: 0.12)
            : colors.surface,
        borderColor: selected ? colors.primary : colors.border,
        borderWidth: selected ? 1.5 : 1,
        constraints: BoxConstraints(minHeight: minHeight),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.titleMedium?.copyWith(
                        color: colors.textPrimary,
                      ),
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
    );
  }
}

class _NumericStepInput extends StatelessWidget {
  const _NumericStepInput({
    required this.label,
    required this.controller,
    required this.suffix,
    required this.decimal,
    required this.onChanged,
    this.errorText,
  });

  final String label;
  final TextEditingController controller;
  final String suffix;
  final bool decimal;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return AppInput(
      label: label,
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        if (decimal)
          PtBrDecimalInputFormatter(maxDecimalDigits: 1)
        else
          FilteringTextInputFormatter.digitsOnly,
      ],
      suffixText: suffix,
      errorText: errorText,
      style: context.textTheme.titleLarge?.copyWith(
        fontFeatures: AppTypography.tabularFeatures,
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: fitnessColors.progressUp.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(context.appRadius.small),
          ),
          child: Icon(icon, size: 18, color: fitnessColors.progressUp),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
