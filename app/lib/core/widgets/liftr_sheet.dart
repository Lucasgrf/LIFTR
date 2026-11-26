import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_spacing.dart';
import 'package:personal_fitness_os/core/widgets/liftr_sheet_header.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';

/// Standard LIFTR modal bottom sheet container with keyboard/safe-area padding,
/// tablet max-width constraint via [ResponsiveContainer], and optional [LiftrSheetHeader].
Future<T?> showLiftrSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  String? eyebrow,
  String? subtitle,
  Widget? trailing,
  bool isScrollable = true,
  double? heightFactor,
  double maxHeightFactor = 0.9,
  bool isDismissible = true,
  bool enableDrag = true,
  EdgeInsetsGeometry? contentPadding,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    builder: (ctx) {
      final colors = ctx.appColors;
      final radius = ctx.appRadius;
      final spacing = ctx.appSpacing;
      final mediaSize = MediaQuery.sizeOf(ctx);
      final bottomPadding = math.max(
            MediaQuery.viewInsetsOf(ctx).bottom,
            MediaQuery.viewPaddingOf(ctx).bottom,
          ) +
          spacing.xxl;
      final resolvedPadding = contentPadding ??
          EdgeInsets.fromLTRB(
            spacing.space20,
            spacing.space12,
            spacing.space20,
            bottomPadding,
          );
      final sheetRadius = BorderRadius.vertical(top: Radius.circular(radius.xl));
      final maxHeight = mediaSize.height * (heightFactor ?? maxHeightFactor);

      final Widget innerBody = isScrollable
          ? SingleChildScrollView(
              padding: resolvedPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (title != null) ...[
                    LiftrSheetHeader(
                      title: title,
                      eyebrow: eyebrow,
                      subtitle: subtitle,
                      trailing: trailing,
                    ),
                    SizedBox(height: spacing.space12),
                  ],
                  builder(ctx),
                ],
              ),
            )
          : Padding(
              padding: resolvedPadding,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (title != null) ...[
                    LiftrSheetHeader(
                      title: title,
                      eyebrow: eyebrow,
                      subtitle: subtitle,
                      trailing: trailing,
                    ),
                    SizedBox(height: spacing.space12),
                  ],
                  Expanded(child: builder(ctx)),
                ],
              ),
            );

      return ResponsiveContainer(
        heightFactor: 1,
        padding: EdgeInsets.zero,
        child: Container(
          width: double.infinity,
          height: heightFactor != null ? mediaSize.height * heightFactor : null,
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: sheetRadius,
            border: Border(
              top: BorderSide(color: colors.border),
              left: BorderSide(color: colors.border),
              right: BorderSide(color: colors.border),
            ),
          ),
          child: ClipRRect(
            borderRadius: sheetRadius,
            child: Material(
              type: MaterialType.transparency,
              child: innerBody,
            ),
          ),
        ),
      );
    },
  );
}
