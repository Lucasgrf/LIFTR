import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/widgets/liftr_icon.dart';

/// Back navigation and an optional large editorial title for secondary pages.
class LiftrEditorialPageHeader extends StatelessWidget {
  const LiftrEditorialPageHeader({
    required this.onBack,
    this.title,
    this.trailing,
    this.titleStyle,
    this.backLabel = 'Voltar',
    super.key,
  });

  final VoidCallback onBack;
  final String? title;
  final Widget? trailing;
  final TextStyle? titleStyle;
  final String backLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 48,
            child: Row(
              children: [
                IconButton(
                  tooltip: backLabel,
                  onPressed: onBack,
                  constraints: const BoxConstraints.tightFor(
                    width: 48,
                    height: 48,
                  ),
                  padding: EdgeInsets.zero,
                  icon: LiftrIcon(
                    LiftrIconName.back,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          if (title != null) ...[
            const SizedBox(height: 8),
            Text(
              title!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: titleStyle ?? context.textTheme.displayMedium,
            ),
          ],
        ],
      ),
    );
  }
}
