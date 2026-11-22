import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';

/// Canonical Otl Aicher movement kinematics categories for LIFTR exercises.
enum MovementKinematicsPattern {
  pushHorizontal(
    assetPath: 'assets/icons/exercises/push_horizontal.svg',
    label: 'Empurrar horizontal',
  ),
  pushVertical(
    assetPath: 'assets/icons/exercises/push_vertical.svg',
    label: 'Empurrar vertical',
  ),
  pullHorizontal(
    assetPath: 'assets/icons/exercises/pull_horizontal.svg',
    label: 'Puxar horizontal',
  ),
  pullVertical(
    assetPath: 'assets/icons/exercises/pull_vertical.svg',
    label: 'Puxar vertical',
  ),
  squat(
    assetPath: 'assets/icons/exercises/squat.svg',
    label: 'Padrão de agachamento',
  ),
  hinge(
    assetPath: 'assets/icons/exercises/hinge.svg',
    label: 'Dobradiça de quadril',
  ),
  coreCarry(
    assetPath: 'assets/icons/exercises/core_carry.svg',
    label: 'Estabilidade e core',
  ),
  isolation(
    assetPath: 'assets/icons/exercises/isolation.svg',
    label: 'Isolamento articular',
  );

  const MovementKinematicsPattern({
    required this.assetPath,
    required this.label,
  });

  final String assetPath;
  final String label;
}

/// Resolves an [Exercise] into one of the 8 modular vector kinematics diagrams.
MovementKinematicsPattern resolveMovementPattern(Exercise exercise) {
  final rawPattern = exercise.movementPattern?.toLowerCase().trim() ?? '';
  switch (rawPattern) {
    case 'horizontal_push':
      return MovementKinematicsPattern.pushHorizontal;
    case 'vertical_push':
      return MovementKinematicsPattern.pushVertical;
    case 'horizontal_pull':
      return MovementKinematicsPattern.pullHorizontal;
    case 'vertical_pull':
      return MovementKinematicsPattern.pullVertical;
    case 'squat':
    case 'lunge':
      return MovementKinematicsPattern.squat;
    case 'hip_hinge':
    case 'hinge':
      return MovementKinematicsPattern.hinge;
    case 'core':
    case 'rotation':
    case 'carry':
    case 'cardio':
      return MovementKinematicsPattern.coreCarry;
    case 'isolation':
      return MovementKinematicsPattern.isolation;
  }

  switch (exercise.primaryMuscleGroup.toLowerCase().trim()) {
    case 'chest':
      return MovementKinematicsPattern.pushHorizontal;
    case 'shoulders':
    case 'anterior_deltoid':
    case 'lateral_deltoid':
      return MovementKinematicsPattern.pushVertical;
    case 'back':
    case 'lats':
    case 'rhomboids':
    case 'traps':
      return MovementKinematicsPattern.pullHorizontal;
    case 'quadriceps':
    case 'legs':
      return MovementKinematicsPattern.squat;
    case 'hamstrings':
    case 'glutes':
    case 'lower_back':
      return MovementKinematicsPattern.hinge;
    case 'abs':
    case 'obliques':
    case 'core':
      return MovementKinematicsPattern.coreCarry;
    default:
      return MovementKinematicsPattern.isolation;
  }
}

class _KinematicsColorMapper extends ColorMapper {
  const _KinematicsColorMapper({
    required this.silhouette,
    required this.equipment,
    required this.accent,
    required this.vector,
  });

  final Color silhouette;
  final Color equipment;
  final Color accent;
  final Color vector;

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    return switch (color.toARGB32()) {
      0xFFF2F2F0 => silhouette,
      0xFF8E8E98 => equipment,
      0xFF72A987 => accent,
      0xFF93C4A5 => vector,
      _ => color,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _KinematicsColorMapper &&
        other.silhouette == silhouette &&
        other.equipment == equipment &&
        other.accent == accent &&
        other.vector == vector;
  }

  @override
  int get hashCode => Object.hash(silhouette, equipment, accent, vector);
}

/// Theme-aware modular biomechanical SVG diagram for exercises.
class ExerciseDiagram extends StatelessWidget {
  const ExerciseDiagram({
    super.key,
    required this.exercise,
    this.size = 56,
    this.showFrame = true,
  });

  final Exercise exercise;
  final double size;
  final bool showFrame;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final pattern = resolveMovementPattern(exercise);
    final mapper = _KinematicsColorMapper(
      silhouette: colors.textPrimary,
      equipment: colors.textSecondary,
      accent: colors.primary,
      vector: colors.primaryLight,
    );

    final svg = SvgPicture.asset(
      pattern.assetPath,
      width: size,
      height: size,
      colorMapper: mapper,
      semanticsLabel: 'Diagrama biomecânico de ${exercise.name}',
    );

    if (!showFrame) {
      return svg;
    }

    return Container(
      padding: EdgeInsets.all(size >= 96 ? 12 : 6),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(radius.medium),
        border: Border.all(color: colors.border),
      ),
      child: svg,
    );
  }
}
