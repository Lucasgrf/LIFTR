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
    final pendingWord = pendingChangesCount == 1 ? 'alteração salva' : 'alterações salvas';
    final text = pendingChangesCount > 0
        ? 'Modo Offline • $pendingChangesCount $pendingWord localmente'
        : 'Modo Offline • Alterações salvas localmente';

    return Semantics(
      liveRegion: true,
      explicitChildNodes: true,
      label: text,
      child: Material(
        color: colors.surfaceSubtle,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colors.warning.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
          ),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 48),
            padding: EdgeInsets.only(
              left: 12,
              right: onDismiss != null ? 0 : 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onDismiss != null) const SizedBox(width: 48),
                Icon(
                  Icons.wifi_off_rounded,
                  size: 16,
                  color: colors.warning,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.warning,
                      fontWeight: FontWeight.w600,
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
                          color: colors.warning,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
