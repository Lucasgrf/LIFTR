import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_input.dart';
import 'package:personal_fitness_os/core/widgets/liftr_list_group.dart';
import 'package:personal_fitness_os/core/widgets/liftr_editorial_page_header.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';

class CreateTrainingPlanScreen extends ConsumerStatefulWidget {
  const CreateTrainingPlanScreen({super.key});

  @override
  ConsumerState<CreateTrainingPlanScreen> createState() =>
      _CreateTrainingPlanScreenState();
}

class _CreateTrainingPlanScreenState
    extends ConsumerState<CreateTrainingPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final useCase = ref.read(createTrainingPlanUseCaseProvider);
    final result = await useCase.execute(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      isActive: _isActive,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (created) {
        ref.read(trainingPlansStateProvider.notifier).refresh();
        context.showSnackBar('Programa "${created.name}" criado com sucesso!');
        context.pop();
      },
      (failure) {
        context.showSnackBar(
          'Erro ao criar programa: ${failure.message}',
          isError: true,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 40),
            children: [
              ResponsiveContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LiftrEditorialPageHeader(
                      title: 'Novo programa',
                      onBack: () => context.pop(),
                    ),
                    AppInput(
                      label: 'Nome do Programa *',
                      hint: 'Ex: Hipertrofia ABCD, Upper/Lower, PPL...',
                      controller: _nameController,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Informe o nome do programa';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    AppInput(
                      label: 'Descrição / Objetivo (Opcional)',
                      hint:
                          'Ex: Foco em peitoral e deltóide lateral, 4x por semana...',
                      controller: _descriptionController,
                      maxLines: 3,
                      keyboardType: TextInputType.multiline,
                    ),
                    const SizedBox(height: 20),

                    LiftrListGroup(
                      children: [
                        LiftrListRow.toggle(
                          label: 'Definir como programa ativo',
                          subtitle:
                              'Este programa se tornará o treino principal do seu dia a dia.',
                          value: _isActive,
                          onChanged: (val) => setState(() => _isActive = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    AppButton.primary(
                      label: 'Salvar Programa',
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
      ),
    );
  }
}
