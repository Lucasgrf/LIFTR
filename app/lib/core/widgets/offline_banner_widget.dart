import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';

class OfflineBannerWidget extends StatelessWidget {
  const OfflineBannerWidget({
    super.key,
    this.onDismiss,
  });

  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 30),
      padding: EdgeInsets.only(
        left: 12,
        right: onDismiss != null ? 4 : 12,
        top: 4,
        bottom: 4,
      ),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(
            color: colors.warning.withValues(alpha: 0.24),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (onDismiss != null) const SizedBox(width: 28),
          Icon(
            Icons.wifi_off_rounded,
            size: 15,
            color: colors.warning,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              'Modo Offline • Alterações salvas localmente',
              style: context.textTheme.labelSmall?.copyWith(
                color: colors.warning,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 4),
            Semantics(
              label: 'Ocultar aviso offline',
              button: true,
              child: InkWell(
                onTap: onDismiss,
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: Icon(
                    Icons.close_rounded,
                    size: 15,
                    color: colors.warning,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
