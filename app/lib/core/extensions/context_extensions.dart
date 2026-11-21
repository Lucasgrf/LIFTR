import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';

extension ContextExtensions on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  void showSnackBar(String message, {bool isError = false}) {
    final colors = appColors;
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: textTheme.bodyMedium?.copyWith(
              color: isError ? colors.onPrimary : colors.textPrimary,
            ),
          ),
          backgroundColor: isError ? colors.danger : colors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
