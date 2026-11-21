import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/extensions/date_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_input.dart';
import 'package:personal_fitness_os/features/body/domain/entities/photo_pose.dart';
import 'package:personal_fitness_os/features/body/presentation/providers/photo_providers.dart';

class UploadPhotoModal extends ConsumerStatefulWidget {
  const UploadPhotoModal({super.key});

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
      builder: (_) => const UploadPhotoModal(),
    );
  }

  @override
  ConsumerState<UploadPhotoModal> createState() => _UploadPhotoModalState();
}

class _UploadPhotoModalState extends ConsumerState<UploadPhotoModal> {
  final _picker = ImagePicker();
  String? _selectedFilePath;
  PhotoPose _selectedPose = PhotoPose.front;
  DateTime _selectedDate = DateTime.now();
  final _notesController = TextEditingController();
  bool _isUploading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() => _selectedFilePath = picked.path);
    }
  }

  Future<void> _submit() async {
    if (_selectedFilePath == null) {
      context.showSnackBar('Tire uma foto ou selecione uma imagem da galeria.', isError: true);
      return;
    }

    setState(() => _isUploading = true);

    try {
      final useCase = ref.read(uploadProgressPhotoUseCaseProvider);
      final result = await useCase.execute(
        filePath: _selectedFilePath!,
        pose: _selectedPose,
        takenAt: _selectedDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (!mounted) return;

      result.fold(
        (_) {
          ref.invalidate(progressPhotosProvider);
          Navigator.of(context).pop();
          context.showSnackBar('Foto salva com sucesso!');
        },
        (failure) {
          context.showSnackBar(failure.message, isError: true);
        },
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
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
                  'Adicionar Foto de Físico',
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

            // Image Source Choice Buttons
            if (_selectedFilePath == null) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Câmera'),
                      onPressed: () => _pickImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('Galeria'),
                      onPressed: () => _pickImage(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Imagem selecionada!',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    child: const Text('Trocar'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // Pose selector
            Text(
              'Pose',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: PhotoPose.values.map((pose) {
                final isSelected = _selectedPose == pose;
                return ChoiceChip(
                  label: Text(pose.label),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedPose = pose);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Date picker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Data: ${_selectedDate.formatMedium()}',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  child: const Text('Alterar Data'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            AppInput(
              label: 'Anotações (opcional)',
              hint: 'Ex: Iluminação natural, pump pós treino de dorsal',
              controller: _notesController,
            ),
            const SizedBox(height: 20),

            AppButton.primary(
              label: 'Salvar Foto',
              isLoading: _isUploading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
