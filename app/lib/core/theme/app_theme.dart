import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_motion.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_spacing.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';

class AppTheme {
  static ThemeData light() => _buildTheme(isDark: false);

  static ThemeData dark() => _buildTheme(isDark: true);

  static ThemeData _buildTheme({required bool isDark}) {
    final colors = isDark ? AppColors.dark : AppColors.light;
    const radius = AppRadius.defaults;
    const spacing = AppSpacing.defaults;
    const motion = AppMotion.defaults;
    final fitness = isDark ? FitnessColors.dark : FitnessColors.light;
    final textTheme = AppTypography.textTheme(isDark: isDark);

    final colorScheme =
        (isDark ? const ColorScheme.dark() : const ColorScheme.light())
            .copyWith(
              primary: colors.primary,
              onPrimary: colors.onPrimary,
              secondary: colors.textSecondary,
              onSecondary: colors.background,
              surface: colors.surface,
              onSurface: colors.textPrimary,
              surfaceContainerLowest: colors.background,
              surfaceContainerLow: colors.surfaceSubtle,
              surfaceContainer: colors.surface,
              surfaceContainerHigh: colors.surfaceElevated,
              surfaceContainerHighest: colors.surfaceVariant,
              onSurfaceVariant: colors.textSecondary,
              outline: colors.border,
              outlineVariant: colors.divider,
              error: colors.danger,
              onError: colors.onPrimary,
            );

    final borderRadius = BorderRadius.circular(radius.medium);
    final fieldBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: colors.border),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      fontFamily: AppTypography.fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      cardTheme: CardThemeData(
        color: colors.surfaceSubtle,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.small),
        ),
      ),
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[
        colors,
        radius,
        spacing,
        motion,
        fitness,
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceVariant,
        selectedColor: colors.textPrimary,
        checkmarkColor: colors.background,
        labelStyle: textTheme.labelMedium?.copyWith(color: colors.textPrimary),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: colors.background,
        ),
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
        hintStyle: textTheme.bodyMedium?.copyWith(color: colors.textTertiary),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: colors.textSecondary,
        ),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.borderFocus, width: 2),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.danger),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.danger, width: 2),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        side: BorderSide(color: colors.borderInteractive, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.textPrimary;
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(colors.background),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.xs),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.textPrimary;
          return colors.textTertiary;
        }),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.textPrimary;
          return colors.surfaceVariant;
        }),
        thumbColor: WidgetStatePropertyAll(colors.background),
        trackOutlineColor: WidgetStatePropertyAll(colors.border),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 56),
          backgroundColor: colors.textPrimary,
          foregroundColor: colors.background,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          textStyle: textTheme.labelLarge,
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 56),
          backgroundColor: colors.textPrimary,
          foregroundColor: colors.background,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          textStyle: textTheme.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 56),
          foregroundColor: colors.textPrimary,
          side: BorderSide(color: colors.textPrimary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: colors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius.small),
          ),
          textStyle: textTheme.labelMedium,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.xl),
          side: BorderSide(color: colors.border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius.xl)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surfaceElevated,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.textPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.medium),
          side: BorderSide(color: colors.border),
        ),
      ),
    );
  }
}
