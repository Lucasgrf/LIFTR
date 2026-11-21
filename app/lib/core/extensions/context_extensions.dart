import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';

extension ContextExtensions on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: textTheme.bodyMedium?.copyWith(
              color: isError ? Colors.white : appColors.textPrimary,
            ),
          ),
          backgroundColor: isError ? Colors.redAccent : appColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
