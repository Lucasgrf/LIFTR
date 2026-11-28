import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';

class OfflineBannerWidget extends StatelessWidget {
  const OfflineBannerWidget({
    super.key,
    this.onDismiss,
    this.pendingChangesCount = 0,
  });

  final VoidCallback? onDismiss;
  final int pendingChangesCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final pendingWord = pendingChangesCount == 1
        ? 'alteração salva'
        : 'alterações salvas';
    final text = pendingChangesCount > 0
        ? 'Modo Offline • $pendingChangesCount $pendingWord localmente'
        : 'Modo Offline • Alterações salvas localmente';

    return Semantics(
      liveRegion: true,
      explicitChildNodes: true,
      label: text,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 48),
        padding: EdgeInsets.only(left: 20, right: onDismiss != null ? 0 : 20),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                  fontFeatures: AppTypography.tabularFeatures,
                ),
              ),
            ),
            if (onDismiss != null)
              Semantics(
                label: 'Ocultar aviso offline',
                button: true,
                child: InkWell(
                  onTap: onDismiss,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
