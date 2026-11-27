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
      final viewInsetsBottom = MediaQuery.viewInsetsOf(ctx).bottom;
      final viewPaddingBottom = MediaQuery.viewPaddingOf(ctx).bottom;
      final viewPaddingTop = MediaQuery.viewPaddingOf(ctx).top;
      final bottomPadding =
          math.max(viewInsetsBottom, viewPaddingBottom) + spacing.xxl;
      final nonScrollableBottomPadding =
          viewInsetsBottom > 0 ? spacing.space12 : viewPaddingBottom + spacing.xxl;
      final resolvedPadding = contentPadding ??
          EdgeInsets.fromLTRB(
            spacing.space20,
            spacing.space12,
            spacing.space20,
            isScrollable ? bottomPadding : nonScrollableBottomPadding,
          );
      final sheetRadius = BorderRadius.vertical(top: Radius.circular(radius.xl));
      final maxHeight = mediaSize.height * (heightFactor ?? maxHeightFactor);
      final availableHeight = math.max(
        240.0,
        mediaSize.height - viewInsetsBottom - viewPaddingTop,
      );
      final resolvedHeight = heightFactor != null
          ? (isScrollable
              ? mediaSize.height * heightFactor
              : math.min(mediaSize.height * heightFactor, availableHeight))
          : null;
      final resolvedMaxHeight =
          isScrollable ? maxHeight : math.min(maxHeight, availableHeight);

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

      return Padding(
        padding: EdgeInsets.only(bottom: isScrollable ? 0 : viewInsetsBottom),
        child: ResponsiveContainer(
          heightFactor: 1,
          padding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            height: resolvedHeight,
            constraints: BoxConstraints(maxHeight: resolvedMaxHeight),
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
        ),
      );
    },
  );
}
