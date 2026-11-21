import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/extensions/date_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/features/body/domain/entities/progress_photo.dart';

class PhotoComparatorModal extends StatelessWidget {
  const PhotoComparatorModal({
    super.key,
    required this.beforePhoto,
    required this.afterPhoto,
  });

  final ProgressPhoto beforePhoto;
  final ProgressPhoto afterPhoto;

  static Future<void> show(
    BuildContext context, {
    required ProgressPhoto beforePhoto,
    required ProgressPhoto afterPhoto,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.appRadius.large),
        ),
      ),
      builder: (_) => PhotoComparatorModal(
        beforePhoto: beforePhoto,
        afterPhoto: afterPhoto,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    // Ensure before is chronologically first
    final first = beforePhoto.takenAt.isBefore(afterPhoto.takenAt) ? beforePhoto : afterPhoto;
    final second = first == beforePhoto ? afterPhoto : beforePhoto;

    final daysDiff = second.takenAt.difference(first.takenAt).inDays.abs();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comparação Antes & Depois',
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    'Diferença de $daysDiff dias',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPhotoColumn(
                  context,
                  title: 'ANTES',
                  photo: first,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPhotoColumn(
                  context,
                  title: 'DEPOIS',
                  photo: second,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

  Widget _buildPhotoColumn(
    BuildContext context, {
    required String title,
    required ProgressPhoto photo,
  }) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(context.appRadius.small),
          ),
          child: Text(
            title,
            style: context.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.primary,
              letterSpacing: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          photo.takenAt.formatMedium(),
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(context.appRadius.medium),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: photo.photoUrl.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: photo.photoUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(child: LoadingWidget()),
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
      ],
    );
  }
}
