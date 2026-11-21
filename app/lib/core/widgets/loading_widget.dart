import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';

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
