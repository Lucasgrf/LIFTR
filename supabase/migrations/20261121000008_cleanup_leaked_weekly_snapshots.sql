-- Clean up any weekly_snapshots row that was accidentally populated from a
-- previous account's local SharedPreferences session cache when switching
-- accounts on the same device before user-scoped cache isolation was added.

update public.weekly_snapshots ws
set
  workouts_completed = 0,
  training_duration_seconds = 0,
  working_sets_count = 0,
  total_volume_kg = 0,
  avg_rpe = null,
  avg_execution_score = null,
  updated_at = now()
where ws.workouts_completed > 0
  and not exists (
    select 1
    from public.workout_sessions s
    where s.user_id = ws.user_id
      and s.status = 'completed'
  );
