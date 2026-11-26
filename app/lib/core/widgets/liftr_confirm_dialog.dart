import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_spacing.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';

/// Unified confirmation dialog for destructive and guarded actions.
/// Returns `true` only when the user explicitly confirms; returns `false` on cancel or dismiss.
Future<bool> showLiftrConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancelar',
  IconData? icon,
  bool isDestructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final colors = ctx.appColors;
      final radius = ctx.appRadius;
      final spacing = ctx.appSpacing;
      final toneColor = isDestructive ? colors.danger : colors.primaryLight;
      final toneBackground = isDestructive
          ? colors.danger.withValues(alpha: 0.12)
          : colors.primaryMuted;

      return AlertDialog(
        contentPadding: EdgeInsets.fromLTRB(
          spacing.space20,
          spacing.space24,
          spacing.space20,
          spacing.space16,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: toneBackground,
                    borderRadius: BorderRadius.circular(radius.medium),
                  ),
                  child: Icon(icon, color: toneColor),
                ),
                SizedBox(height: spacing.space12),
              ],
              Text(
                title,
                style: ctx.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacing.space8),
              Text(
                message,
                style: ctx.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacing.space20),
              if (isDestructive)
                AppButton.destructive(
                  label: confirmLabel,
                  onPressed: () => Navigator.of(ctx).pop(true),
                )
              else
                AppButton.primary(
                  label: confirmLabel,
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
              SizedBox(height: spacing.space8),
              AppButton.text(
                label: cancelLabel,
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}
