import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/extensions/date_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/widgets/empty_state_widget.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/features/body/domain/entities/photo_pose.dart';
import 'package:personal_fitness_os/features/body/domain/entities/progress_photo.dart';
import 'package:personal_fitness_os/features/body/presentation/providers/photo_providers.dart';
import 'package:personal_fitness_os/features/body/presentation/widgets/photo_comparator_modal.dart';
import 'package:personal_fitness_os/features/body/presentation/widgets/upload_photo_modal.dart';

class ProgressPhotosScreen extends ConsumerStatefulWidget {
  const ProgressPhotosScreen({super.key});

  @override
  ConsumerState<ProgressPhotosScreen> createState() => _ProgressPhotosScreenState();
}

class _ProgressPhotosScreenState extends ConsumerState<ProgressPhotosScreen> {
  final Set<String> _selectedPhotoIds = {};

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedPhotoIds.contains(id)) {
        _selectedPhotoIds.remove(id);
      } else {
        if (_selectedPhotoIds.length >= 2) {
          _selectedPhotoIds.clear();
        }
        _selectedPhotoIds.add(id);
      }
    });
  }

  void _compareSelected(List<ProgressPhoto> photos) {
    if (_selectedPhotoIds.length != 2) return;

    final selected = photos.where((p) => _selectedPhotoIds.contains(p.id)).toList();
    if (selected.length == 2) {
      PhotoComparatorModal.show(
        context,
        beforePhoto: selected[0],
        afterPhoto: selected[1],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final photosAsync = ref.watch(progressPhotosProvider);
    final selectedFilter = ref.watch(selectedPhotoPoseFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fotos de Evolução'),
        actions: [
          if (_selectedPhotoIds.length == 2 && photosAsync.hasValue)
            IconButton(
              icon: const Icon(Icons.compare_arrows_rounded),
              tooltip: 'Comparar Selecionadas',
              onPressed: () => _compareSelected(photosAsync.value!),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Todas'),
                  selected: selectedFilter == null,
                  onSelected: (val) {
                    ref.read(selectedPhotoPoseFilterProvider.notifier).state = null;
                  },
                ),
                const SizedBox(width: 8),
                ...PhotoPose.values.map((pose) {
                  final isSelected = selectedFilter == pose;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(pose.label),
                      selected: isSelected,
                      onSelected: (val) {
                        ref.read(selectedPhotoPoseFilterProvider.notifier).state =
                            val ? pose : null;
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          // Photos Grid View
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(progressPhotosProvider.future),
              child: photosAsync.when(
                data: (photos) {
                  if (photos.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.photo_camera_outlined,
                      title: 'Nenhuma foto encontrada',
                      subtitle: 'Registre fotos periódicas com iluminação similar para comparar sua evolução física.',
                      actionLabel: 'Adicionar Foto',
                      onAction: () => UploadPhotoModal.show(context),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 3 / 4,
                    ),
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      final photo = photos[index];
                      final isSelected = _selectedPhotoIds.contains(photo.id);

                      return GestureDetector(
                        onTap: () => _toggleSelection(photo.id),
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(context.appRadius.medium),
                                border: isSelected
                                    ? Border.all(color: colors.primary, width: 3)
                                    : Border.all(color: colors.border),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  isSelected
                                      ? context.appRadius.medium - 2
                                      : context.appRadius.medium,
                                ),
                                child: photo.photoUrl.startsWith('http')
                                    ? CachedNetworkImage(
                                        imageUrl: photo.photoUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        placeholder: (_, __) =>
                                            const Center(child: LoadingWidget()),
                                        errorWidget: (_, __, ___) => Container(
                                          color: colors.surfaceVariant,
                                          child: const Icon(Icons.broken_image_rounded),
                                        ),
                                      )
                                    : Container(
                                        color: colors.surfaceVariant,
                                        child: const Icon(Icons.image_rounded),
                                      ),
                              ),
                            ),

                            // Overlay Date & Pose Tag
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(context.appRadius.medium),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      photo.takenAt.formatShort(),
                                      style: context.textTheme.labelSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      photo.pose.label,
                                      style: context.textTheme.labelSmall?.copyWith(
                                        color: colors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Selection Indicator
                            if (isSelected)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: colors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: LoadingWidget()),
                error: (err, _) => Center(
                  child: ErrorStateWidget(
                    message: err.toString(),
                    onRetry: () => ref.refresh(progressPhotosProvider),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => UploadPhotoModal.show(context),
        icon: const Icon(Icons.add_a_photo_rounded),
        label: const Text('Nova Foto'),
      ),
    );
  }
}
