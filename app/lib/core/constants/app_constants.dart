class AppConstants {
  static const int defaultRestSeconds = 90;
  static const String defaultRirRange = '1-2';
  
  static const double barbellIncrement = 2.5;
  static const double dumbbellIncrement = 2.0;
  static const double machineIncrement = 5.0;
}

enum MuscleGroup {
  chest,
  back,
  legs,
  shoulders,
  arms,
  core,
  fullBody,
}

enum Equipment {
  barbell,
  dumbbell,
  machine,
  cable,
  bodyweight,
  kettlebell,
  band,
  smithMachine,
}

enum MovementPattern {
  horizontalPush,
  horizontalPull,
  verticalPush,
  verticalPull,
  squat,
  hinge,
  lunge,
  isolation,
  carry,
}

enum SetType {
  mobility,
  warmup,
  rampUp,
  working,
  dropSet,
  myoRep,
}

enum MealType {
  breakfast,
  lunch,
  dinner,
  snack,
  preWorkout,
  postWorkout,
}

enum GoalCategory {
  hypertrophy,
  strength,
  endurance,
  weightLoss,
  maintenance,
}

enum GoalStatus {
  active,
  completed,
  abandoned,
}

enum ExecutionQuality {
  poor,
  fair,
  good,
  excellent,
}

enum Mood {
  awful,
  bad,
  neutral,
  good,
  excellent,
}
