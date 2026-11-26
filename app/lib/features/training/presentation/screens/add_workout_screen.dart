import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/app_input.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';

class AddWorkoutScreen extends ConsumerStatefulWidget {
  const AddWorkoutScreen({
    required this.planId,
    super.key,
  });

  final String planId;

  @override
  ConsumerState<AddWorkoutScreen> createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends ConsumerState<AddWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _durationController;
  late final TextEditingController _notesController;

  int? _selectedDayOfWeek = 1; // Default Monday
  bool _isLoading = false;

  static const List<Map<String, dynamic>> daysOfWeek = [
    {'day': 1, 'label': 'Segunda-feira'},
    {'day': 2, 'label': 'Terça-feira'},
    {'day': 3, 'label': 'Quarta-feira'},
    {'day': 4, 'label': 'Quinta-feira'},
    {'day': 5, 'label': 'Sexta-feira'},
    {'day': 6, 'label': 'Sábado'},
    {'day': 0, 'label': 'Domingo'},
    {'day': null, 'label': 'Dia Flexível / Sem dia fixo'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _durationController = TextEditingController(text: '60');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final duration = int.tryParse(_durationController.text.trim());
    final useCase = ref.read(addWorkoutToPlanUseCaseProvider);
    final result = await useCase.execute(
      trainingPlanId: widget.planId,
      name: _nameController.text.trim(),
      dayOfWeek: _selectedDayOfWeek,
      estimatedDurationMinutes: duration,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (created) {
        ref.invalidate(trainingPlanDetailProvider(widget.planId));
        ref.read(trainingPlansStateProvider.notifier).refresh();
        context.showSnackBar('Treino "${created.name}" adicionado!');
        context.pop();
      },
      (failure) {
        context.showSnackBar('Erro ao adicionar treino: ${failure.message}', isError: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        title: const Text('Adicionar Treino ao Plano'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 40),
          children: [
            ResponsiveContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            AppInput(
              label: 'Nome do Treino *',
              hint: 'Ex: Treino A - Superior (Peito/Costas)',
              controller: _nameController,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Informe o nome do treino';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            Text(
              'Dia da Semana',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.appColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  isExpanded: true,
                  value: _selectedDayOfWeek,
                  dropdownColor: context.appColors.surfaceElevated,
                  items: daysOfWeek.map((d) {
                    return DropdownMenuItem<int?>(
                      value: d['day'] as int?,
                      child: Text(
                        d['label'] as String,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.appColors.textPrimary,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedDayOfWeek = val),
                ),
              ),
            ),
            const SizedBox(height: 16),

            AppInput(
              label: 'Duração Estimada (minutos)',
              hint: '60',
              controller: _durationController,
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val != null && val.trim().isNotEmpty) {
                  final num = int.tryParse(val.trim());
                  if (num == null || num <= 0) {
                    return 'Informe uma duração válida em minutos';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            AppInput(
              label: 'Orientações Gerais (Opcional)',
              hint: 'Ex: Foco em cadência controlada na fase excêntrica...',
              controller: _notesController,
              maxLines: 2,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 32),

            AppButton.primary(
              label: 'Adicionar Treino',
              icon: Icons.check_rounded,
              isLoading: _isLoading,
              onPressed: _submit,
            ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
