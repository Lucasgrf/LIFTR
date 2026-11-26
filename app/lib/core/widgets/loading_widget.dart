import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_spacing.dart';
import 'package:shimmer/shimmer.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: context.appColors.primary,
      ),
    );
  }
}

class LiftrShimmerBox extends StatelessWidget {
  const LiftrShimmerBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius,
  });

  final double width;
  final double height;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = borderRadius ?? context.appRadius.large;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    final box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colors.borderSubtle),
      ),
    );

    if (disableAnimations) {
      return box;
    }

    return Shimmer.fromColors(
      baseColor: colors.surfaceSubtle,
      highlightColor: colors.surfaceElevated,
      child: box,
    );
  }
}

class LiftrScreenSkeleton extends StatelessWidget {
  const LiftrScreenSkeleton({
    super.key,
    this.itemCount = 4,
    this.showHero = true,
  });

  final int itemCount;
  final bool showHero;

  @override
  Widget build(BuildContext context) {
    final radius = context.appRadius;
    final spacing = context.appSpacing;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        spacing.space16,
        spacing.space12,
        spacing.space16,
        spacing.space32,
      ),
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHero) ...[
            LiftrShimmerBox(height: 200, borderRadius: radius.large),
            AppSpacing.verticalGap24,
            LiftrShimmerBox(width: 140, height: 18, borderRadius: radius.xs),
            AppSpacing.verticalGap12,
          ],
          ...List.generate(
            itemCount,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: spacing.space12),
              child: LiftrShimmerBox(height: 80, borderRadius: radius.medium),
            ),
          ),
        ],
      ),
    );
  }
}
