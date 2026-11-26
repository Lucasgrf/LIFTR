import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_spacing.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/app_input.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/providers/exercise_providers.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/widgets/exercise_card.dart';

class CreateCustomExerciseScreen extends ConsumerStatefulWidget {
  const CreateCustomExerciseScreen({super.key});

  @override
  ConsumerState<CreateCustomExerciseScreen> createState() =>
      _CreateCustomExerciseScreenState();
}

class _CreateCustomExerciseScreenState
    extends ConsumerState<CreateCustomExerciseScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _instructionsController;
  late final TextEditingController _mistakesController;
  late final TextEditingController _videoUrlController;
  late final TextEditingController _notesController;

  String? _selectedPrimaryMuscle;
  final List<String> _selectedSecondaryMuscles = [];
  String? _selectedEquipment;
  String? _selectedMovementPattern;
  bool _isLoading = false;

  static const List<Map<String, String>> primaryMuscles = [
    {'key': 'chest', 'label': 'Peito'},
    {'key': 'back', 'label': 'Costas'},
    {'key': 'quadriceps', 'label': 'Quadríceps'},
    {'key': 'hamstrings', 'label': 'Posterior de Coxa'},
    {'key': 'glutes', 'label': 'Glúteos'},
    {'key': 'calves', 'label': 'Panturrilhas'},
    {'key': 'anterior_deltoid', 'label': 'Deltóide Anterior (Ombro)'},
    {'key': 'lateral_deltoid', 'label': 'Deltóide Lateral (Ombro)'},
    {'key': 'posterior_deltoid', 'label': 'Deltóide Posterior (Ombro)'},
    {'key': 'biceps', 'label': 'Bíceps'},
    {'key': 'triceps', 'label': 'Tríceps'},
    {'key': 'forearms', 'label': 'Antebraço'},
    {'key': 'abs', 'label': 'Abdômen / Core'},
    {'key': 'obliques', 'label': 'Oblíquos'},
    {'key': 'lower_back', 'label': 'Lombar'},
    {'key': 'traps', 'label': 'Trapézio'},
  ];

  static const List<Map<String, String>> equipments = [
    {'key': 'barbell', 'label': 'Barra'},
    {'key': 'dumbbell', 'label': 'Halteres'},
    {'key': 'machine', 'label': 'Máquina'},
    {'key': 'cable', 'label': 'Cabo / Polia'},
    {'key': 'bodyweight', 'label': 'Peso Corporal'},
    {'key': 'smithMachine', 'label': 'Smith Machine'},
    {'key': 'kettlebell', 'label': 'Kettlebell'},
    {'key': 'band', 'label': 'Elástico / Band'},
  ];

  static const List<Map<String, String>> movementPatterns = [
    {'key': 'horizontal_push', 'label': 'Empurrar Horizontal (Supino)'},
    {'key': 'horizontal_pull', 'label': 'Puxar Horizontal (Remada)'},
    {'key': 'vertical_push', 'label': 'Empurrar Vertical (Desenvolvimento)'},
    {'key': 'vertical_pull', 'label': 'Puxar Vertical (Puxada/Barra)'},
    {'key': 'squat', 'label': 'Agachamento / Flexão de Joelho'},
    {'key': 'hip_hinge', 'label': 'Extensão de Quadril (Stiff/Terra)'},
    {'key': 'lunge', 'label': 'Passada / Avanço Unilateral'},
    {'key': 'isolation', 'label': 'Isolamento Articular'},
    {'key': 'rotation', 'label': 'Rotação / Anti-rotação'},
    {'key': 'carry', 'label': 'Carregamento / Transporte'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _instructionsController = TextEditingController();
    _mistakesController = TextEditingController();
    _videoUrlController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _instructionsController.dispose();
    _mistakesController.dispose();
    _videoUrlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPrimaryMuscle == null) {
      context.showSnackBar('Por favor, selecione o grupo muscular principal.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final useCase = ref.read(createCustomExerciseUseCaseProvider);
    final result = await useCase.execute(
      name: _nameController.text.trim(),
      primaryMuscleGroup: _selectedPrimaryMuscle!,
      secondaryMuscles: _selectedSecondaryMuscles.isEmpty ? null : _selectedSecondaryMuscles,
      equipment: _selectedEquipment,
      movementPattern: _selectedMovementPattern,
      instructions: _instructionsController.text.trim().isEmpty ? null : _instructionsController.text.trim(),
      commonMistakes: _mistakesController.text.trim().isEmpty ? null : _mistakesController.text.trim(),
      videoUrl: _videoUrlController.text.trim().isEmpty ? null : _videoUrlController.text.trim(),
      personalNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (created) {
        ref.read(exerciseListStateProvider.notifier).refresh();
        context.showSnackBar('Exercício "${created.name}" cadastrado com sucesso!');
        context.pop();
      },
      (failure) {
        context.showSnackBar('Erro ao salvar exercício: ${failure.message}', isError: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        title: const Text('Novo Exercício'),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 40),
            child: ResponsiveContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section: Basic Info
              Text(
                'Informações Principais',
                style: context.textTheme.titleMedium?.copyWith(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              AppInput(
                label: 'Nome do Exercício *',
                hint: 'Ex: Supino Reto com Halteres',
                controller: _nameController,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Informe o nome do exercício';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Primary Muscle Group Picker
              Text(
                'Grupo Muscular Principal *',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.appColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedPrimaryMuscle,
                    hint: Text(
                      'Selecione o músculo principal...',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.appColors.textTertiary,
                      ),
                    ),
                    dropdownColor: context.appColors.surfaceElevated,
                    items: primaryMuscles.map((m) {
                      return DropdownMenuItem<String>(
                        value: m['key'],
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: ExerciseCard.getMuscleColor(context, m['key']!),
                                shape: BoxShape.circle,
                              ),
                            ),
                            AppSpacing.horizontalGap12,
                            Text(
                              m['label']!,
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: context.appColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedPrimaryMuscle = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Secondary Muscles
              Text(
                'Músculos Secundários (Opcional)',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.appColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: primaryMuscles
                    .where((m) => m['key'] != _selectedPrimaryMuscle)
                    .map((m) {
                  final isSelected = _selectedSecondaryMuscles.contains(m['key']);
                  return FilterChip(
                    label: Text(m['label']!),
                    selected: isSelected,
                    showCheckmark: false,
                    labelStyle: context.textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? context.appColors.onPrimary
                          : context.appColors.textSecondary,
                    ),
                    backgroundColor: context.appColors.surfaceVariant,
                    selectedColor: context.appColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.appRadius.small),
                      side: BorderSide(
                        color: isSelected ? context.appColors.primary : context.appColors.border,
                      ),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSecondaryMuscles.add(m['key']!);
                        } else {
                          _selectedSecondaryMuscles.remove(m['key']);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Section: Biomechanics
              Text(
                'Biomecânica & Equipamento',
                style: context.textTheme.titleMedium?.copyWith(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              // Equipment Picker
              Text(
                'Equipamento',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.appColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedEquipment,
                    hint: Text(
                      'Selecione o equipamento (opcional)...',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.appColors.textTertiary,
                      ),
                    ),
                    dropdownColor: context.appColors.surfaceElevated,
                    items: equipments.map((e) {
                      return DropdownMenuItem<String>(
                        value: e['key'],
                        child: Text(
                          e['label']!,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.appColors.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedEquipment = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Movement Pattern Picker
              Text(
                'Padrão de Movimento',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.appColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedMovementPattern,
                    hint: Text(
                      'Selecione o padrão de movimento (opcional)...',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.appColors.textTertiary,
                      ),
                    ),
                    dropdownColor: context.appColors.surfaceElevated,
                    items: movementPatterns.map((p) {
                      return DropdownMenuItem<String>(
                        value: p['key'],
                        child: Text(
                          p['label']!,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.appColors.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedMovementPattern = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Section: Instructions & Notes
              Text(
                'Instruções & Vídeo',
                style: context.textTheme.titleMedium?.copyWith(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              AppInput(
                label: 'Instruções de Execução',
                hint: 'Passo a passo de como executar o movimento corretamente...',
                controller: _instructionsController,
                maxLines: 3,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 16),

              AppInput(
                label: 'Erros Comuns',
                hint: 'Ex: Projetar cotovelos para fora, arquear lombar...',
                controller: _mistakesController,
                maxLines: 2,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 16),

              AppInput(
                label: 'Link do Vídeo (YouTube / URL)',
                hint: 'https://youtube.com/watch?v=...',
                controller: _videoUrlController,
                keyboardType: TextInputType.url,
                prefix: Icon(Icons.link_rounded, color: context.appColors.textTertiary),
              ),
              const SizedBox(height: 16),

              AppInput(
                label: 'Minhas Anotações Iniciais',
                hint: 'Ajustes pessoais ou observações...',
                controller: _notesController,
                maxLines: 2,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 32),

              // Submit Button
              AppButton.primary(
                label: 'Salvar Exercício',
                icon: Icons.check_rounded,
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
