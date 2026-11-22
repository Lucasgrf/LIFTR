import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';

typedef AppErrorWidget = ErrorStateWidget;

class ErrorStateWidget extends StatelessWidget {
  const ErrorStateWidget({
    super.key,
    required this.message,
    this.title = 'Não foi possível carregar',
    this.safetyNote,
    this.onRetry,
  });

  final String message;
  final String title;
  final String? safetyNote;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: AppCard(
            variant: AppCardVariant.accented,
            accentColor: colors.danger,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(radius.small),
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 24,
                    color: colors.danger,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                if (safetyNote != null && safetyNote!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    safetyNote!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textTertiary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (onRetry != null) ...[
                  const SizedBox(height: 20),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: AppButton.secondary(
                      label: 'Tentar novamente',
                      onPressed: onRetry,
                      icon: Icons.refresh_rounded,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
