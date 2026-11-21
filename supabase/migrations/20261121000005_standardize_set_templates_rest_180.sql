-- Standardize existing non-Cardio set_templates to the 3-minute (180s) rest default.
update public.set_templates st
set rest_seconds = 180,
    updated_at = now()
from public.workout_exercises we
join public.exercises e on e.id = we.exercise_id
where st.workout_exercise_id = we.id
  and st.rest_seconds <> 180
  and coalesce(lower(e.movement_pattern), '') <> 'cardio'
  and coalesce(lower(e.primary_muscle_group), '') <> 'cardio'
  and lower(e.name) <> 'cardio';
