-- Flutter App Schema Migration (aligned with Flutter models & remote datasources).
-- Coexists alongside 20261103000001_schema_inicial.sql without table name collisions.

-- ---------------------------------------------------------------------------
-- 1. Exercise Library (global rows have user_id IS NULL)
-- ---------------------------------------------------------------------------

create table if not exists exercises (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  name text not null,
  primary_muscle_group text not null,
  secondary_muscles text[] not null default '{}',
  equipment text,
  movement_pattern text,
  instructions text,
  common_mistakes text,
  video_url text,
  personal_notes text,
  is_custom boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index if not exists idx_exercises_user on exercises(user_id);
create index if not exists idx_exercises_muscle on exercises(primary_muscle_group);

-- ---------------------------------------------------------------------------
-- 2. Training Plans, Workouts, Workout Exercises & Set Templates
-- ---------------------------------------------------------------------------

create table if not exists training_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  description text,
  is_active boolean not null default false,
  start_date date,
  end_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index if not exists idx_training_plans_user on training_plans(user_id);
create index if not exists idx_training_plans_active
  on training_plans(user_id, is_active) where deleted_at is null;

create table if not exists workouts (
  id uuid primary key default gen_random_uuid(),
  training_plan_id uuid not null references training_plans(id) on delete cascade,
  name text not null,
  day_of_week integer check (day_of_week between 0 and 6),
  sort_order integer not null default 0,
  notes text,
  estimated_duration_minutes integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_workouts_plan on workouts(training_plan_id, sort_order);

create table if not exists workout_exercises (
  id uuid primary key default gen_random_uuid(),
  workout_id uuid not null references workouts(id) on delete cascade,
  exercise_id uuid not null references exercises(id),
  sort_order integer not null default 0,
  notes text,
  replaced_exercise_id uuid references exercises(id) on delete set null,
  replaced_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_workout_exercises_workout
  on workout_exercises(workout_id, sort_order);

create table if not exists set_templates (
  id uuid primary key default gen_random_uuid(),
  workout_exercise_id uuid not null references workout_exercises(id) on delete cascade,
  set_number integer not null,
  set_type text not null default 'working'
    check (set_type in ('mobility', 'warmup', 'ramp_up', 'working', 'drop_set', 'myo_rep')),
  target_reps_min integer,
  target_reps_max integer,
  target_rir_min integer,
  target_rir_max integer,
  target_weight numeric(6,2),
  rest_seconds integer not null default 120,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_set_templates_exercise
  on set_templates(workout_exercise_id, set_number);

-- ---------------------------------------------------------------------------
-- 3. Workout Sessions, Session Exercises & Logged Sets
-- ---------------------------------------------------------------------------

create table if not exists workout_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  workout_id uuid references workouts(id) on delete set null,
  workout_name text,
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  duration_seconds integer not null default 0,
  status text not null default 'in_progress'
    check (status in ('in_progress', 'completed', 'abandoned')),
  perceived_exertion numeric(4,1),
  mood text check (mood in ('awful', 'terrible', 'bad', 'neutral', 'good', 'excellent')),
  notes text,
  readiness_score integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_workout_sessions_user_started
  on workout_sessions(user_id, started_at desc);
create index if not exists idx_workout_sessions_user_status
  on workout_sessions(user_id, status, completed_at desc);

create table if not exists workout_session_exercises (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references workout_sessions(id) on delete cascade,
  exercise_id uuid not null references exercises(id),
  sort_order integer not null default 0,
  notes text,
  replaced_exercise_id uuid references exercises(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_session_exercises_session
  on workout_session_exercises(session_id, sort_order);
create index if not exists idx_session_exercises_exercise
  on workout_session_exercises(exercise_id);

create table if not exists logged_sets (
  id uuid primary key default gen_random_uuid(),
  session_exercise_id uuid not null references workout_session_exercises(id) on delete cascade,
  set_number integer not null,
  set_type text not null default 'working'
    check (set_type in ('mobility', 'warmup', 'ramp_up', 'working', 'drop_set', 'myo_rep')),
  weight_kg numeric(6,2) not null default 0,
  reps_completed integer not null default 0,
  rir_actual integer,
  rpe_actual numeric(4,1),
  rest_seconds_actual integer,
  execution_quality text
    check (execution_quality in ('poor', 'fair', 'acceptable', 'good', 'excellent', 'perfect')),
  is_warmup boolean not null default false,
  notes text,
  completed_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists idx_logged_sets_session_exercise
  on logged_sets(session_exercise_id, set_number);

-- ---------------------------------------------------------------------------
-- 4. Body Tracking (Weight, Measurements, Progress Photos)
-- ---------------------------------------------------------------------------

create table if not exists weight_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  weight numeric(5,2) not null,
  measured_at timestamptz not null default now(),
  notes text,
  created_at timestamptz not null default now()
);

create index if not exists idx_weight_entries_user_date
  on weight_entries(user_id, measured_at desc);

create table if not exists body_measurements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  measured_at timestamptz not null default now(),
  waist numeric(5,1),
  chest numeric(5,1),
  arm_left numeric(5,1),
  arm_right numeric(5,1),
  thigh_left numeric(5,1),
  thigh_right numeric(5,1),
  calf_left numeric(5,1),
  calf_right numeric(5,1),
  hip numeric(5,1),
  shoulder numeric(5,1),
  neck numeric(5,1),
  forearm_left numeric(5,1),
  forearm_right numeric(5,1),
  notes text,
  created_at timestamptz not null default now()
);

create index if not exists idx_body_measurements_user_date
  on body_measurements(user_id, measured_at desc);

create table if not exists progress_photos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  photo_url text not null,
  storage_path text not null,
  taken_at timestamptz not null default now(),
  pose text not null default 'other',
  notes text,
  created_at timestamptz not null default now()
);

create index if not exists idx_progress_photos_user_date
  on progress_photos(user_id, taken_at desc);

-- ---------------------------------------------------------------------------
-- 5. Nutrition & Goals
-- ---------------------------------------------------------------------------

create table if not exists nutrition_goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  calories integer not null,
  protein_grams integer not null,
  carbs_grams integer not null,
  fat_grams integer not null,
  effective_from date not null default current_date,
  effective_until date,
  notes text,
  created_at timestamptz not null default now()
);

create index if not exists idx_nutrition_goals_user_effective
  on nutrition_goals(user_id, effective_from desc);

create table if not exists foods (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  name text not null,
  brand text,
  serving_size numeric(7,2) not null default 100,
  serving_unit text not null default 'g',
  calories numeric(7,2) not null default 0,
  protein numeric(6,2) not null default 0,
  carbs numeric(6,2) not null default 0,
  fat numeric(6,2) not null default 0,
  fiber numeric(6,2) not null default 0,
  barcode text,
  is_custom boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_foods_user_name on foods(user_id, name);

create table if not exists daily_nutrition (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  date date not null,
  total_calories numeric(7,2) not null default 0,
  total_protein numeric(6,2) not null default 0,
  total_carbs numeric(6,2) not null default 0,
  total_fat numeric(6,2) not null default 0,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, date)
);

create index if not exists idx_daily_nutrition_user_date
  on daily_nutrition(user_id, date desc);

create table if not exists meals (
  id uuid primary key default gen_random_uuid(),
  daily_nutrition_id uuid not null references daily_nutrition(id) on delete cascade,
  name text not null,
  meal_type text not null,
  eaten_at timestamptz,
  notes text,
  created_at timestamptz not null default now()
);

create index if not exists idx_meals_daily on meals(daily_nutrition_id);

create table if not exists meal_foods (
  id uuid primary key default gen_random_uuid(),
  meal_id uuid not null references meals(id) on delete cascade,
  food_id uuid not null references foods(id),
  quantity numeric(7,2) not null,
  calories numeric(7,2) not null default 0,
  protein numeric(6,2) not null default 0,
  carbs numeric(6,2) not null default 0,
  fat numeric(6,2) not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists idx_meal_foods_meal on meal_foods(meal_id);

create table if not exists goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null,
  description text,
  category text not null,
  reference_exercise_id uuid references exercises(id) on delete set null,
  reference_measurement_type text,
  initial_value numeric(8,2) not null,
  target_value numeric(8,2) not null,
  current_value numeric(8,2),
  unit text not null default '',
  started_at date not null default current_date,
  deadline date,
  completed_at timestamptz,
  status text not null default 'active'
    check (status in ('active', 'completed', 'paused', 'abandoned')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_goals_user_status on goals(user_id, status);

create table if not exists goal_checkpoints (
  id uuid primary key default gen_random_uuid(),
  goal_id uuid not null references goals(id) on delete cascade,
  value numeric(8,2) not null,
  recorded_at timestamptz not null default now(),
  notes text
);

create index if not exists idx_goal_checkpoints_goal
  on goal_checkpoints(goal_id, recorded_at desc);

-- ---------------------------------------------------------------------------
-- 6. Row Level Security (RLS)
-- ---------------------------------------------------------------------------

alter table exercises enable row level security;
alter table training_plans enable row level security;
alter table workouts enable row level security;
alter table workout_exercises enable row level security;
alter table set_templates enable row level security;
alter table workout_sessions enable row level security;
alter table workout_session_exercises enable row level security;
alter table logged_sets enable row level security;
alter table weight_entries enable row level security;
alter table body_measurements enable row level security;
alter table progress_photos enable row level security;
alter table nutrition_goals enable row level security;
alter table foods enable row level security;
alter table daily_nutrition enable row level security;
alter table meals enable row level security;
alter table meal_foods enable row level security;
alter table goals enable row level security;
alter table goal_checkpoints enable row level security;

-- Catalogs: global rows (user_id IS NULL) are readable by authenticated users;
-- personal rows are mutable only by their owner.
drop policy if exists "exercises_select_global_or_own" on exercises;
create policy "exercises_select_global_or_own" on exercises
  for select using (user_id is null or auth.uid() = user_id);

drop policy if exists "exercises_insert_own" on exercises;
create policy "exercises_insert_own" on exercises
  for insert with check (auth.uid() = user_id);

drop policy if exists "exercises_update_own" on exercises;
create policy "exercises_update_own" on exercises
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "exercises_delete_own" on exercises;
create policy "exercises_delete_own" on exercises
  for delete using (auth.uid() = user_id);

drop policy if exists "foods_select_global_or_own" on foods;
create policy "foods_select_global_or_own" on foods
  for select using (user_id is null or auth.uid() = user_id);

drop policy if exists "foods_insert_own" on foods;
create policy "foods_insert_own" on foods
  for insert with check (auth.uid() = user_id);

drop policy if exists "foods_update_own" on foods;
create policy "foods_update_own" on foods
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "foods_delete_own" on foods;
create policy "foods_delete_own" on foods
  for delete using (auth.uid() = user_id);

-- Direct user-owned tables
drop policy if exists "training_plans_own_all" on training_plans;
create policy "training_plans_own_all" on training_plans
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "workout_sessions_own_all" on workout_sessions;
create policy "workout_sessions_own_all" on workout_sessions
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "weight_entries_own_all" on weight_entries;
create policy "weight_entries_own_all" on weight_entries
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "body_measurements_own_all" on body_measurements;
create policy "body_measurements_own_all" on body_measurements
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "progress_photos_own_all" on progress_photos;
create policy "progress_photos_own_all" on progress_photos
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "nutrition_goals_own_all" on nutrition_goals;
create policy "nutrition_goals_own_all" on nutrition_goals
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "daily_nutrition_own_all" on daily_nutrition;
create policy "daily_nutrition_own_all" on daily_nutrition
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "goals_own_all" on goals;
create policy "goals_own_all" on goals
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Child tables inheriting ownership via parent FK
drop policy if exists "workouts_own_all" on workouts;
create policy "workouts_own_all" on workouts
  for all
  using (
    exists (
      select 1 from training_plans tp
      where tp.id = workouts.training_plan_id and tp.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from training_plans tp
      where tp.id = workouts.training_plan_id and tp.user_id = auth.uid()
    )
  );

drop policy if exists "workout_exercises_own_all" on workout_exercises;
create policy "workout_exercises_own_all" on workout_exercises
  for all
  using (
    exists (
      select 1
      from workouts w
      join training_plans tp on tp.id = w.training_plan_id
      where w.id = workout_exercises.workout_id and tp.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from workouts w
      join training_plans tp on tp.id = w.training_plan_id
      where w.id = workout_exercises.workout_id and tp.user_id = auth.uid()
    )
  );

drop policy if exists "set_templates_own_all" on set_templates;
create policy "set_templates_own_all" on set_templates
  for all
  using (
    exists (
      select 1
      from workout_exercises we
      join workouts w on w.id = we.workout_id
      join training_plans tp on tp.id = w.training_plan_id
      where we.id = set_templates.workout_exercise_id and tp.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from workout_exercises we
      join workouts w on w.id = we.workout_id
      join training_plans tp on tp.id = w.training_plan_id
      where we.id = set_templates.workout_exercise_id and tp.user_id = auth.uid()
    )
  );

drop policy if exists "workout_session_exercises_own_all" on workout_session_exercises;
create policy "workout_session_exercises_own_all" on workout_session_exercises
  for all
  using (
    exists (
      select 1 from workout_sessions ws
      where ws.id = workout_session_exercises.session_id and ws.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from workout_sessions ws
      where ws.id = workout_session_exercises.session_id and ws.user_id = auth.uid()
    )
  );

drop policy if exists "logged_sets_own_all" on logged_sets;
create policy "logged_sets_own_all" on logged_sets
  for all
  using (
    exists (
      select 1
      from workout_session_exercises wse
      join workout_sessions ws on ws.id = wse.session_id
      where wse.id = logged_sets.session_exercise_id and ws.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from workout_session_exercises wse
      join workout_sessions ws on ws.id = wse.session_id
      where wse.id = logged_sets.session_exercise_id and ws.user_id = auth.uid()
    )
  );

drop policy if exists "meals_own_all" on meals;
create policy "meals_own_all" on meals
  for all
  using (
    exists (
      select 1 from daily_nutrition dn
      where dn.id = meals.daily_nutrition_id and dn.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from daily_nutrition dn
      where dn.id = meals.daily_nutrition_id and dn.user_id = auth.uid()
    )
  );

drop policy if exists "meal_foods_own_all" on meal_foods;
create policy "meal_foods_own_all" on meal_foods
  for all
  using (
    exists (
      select 1
      from meals m
      join daily_nutrition dn on dn.id = m.daily_nutrition_id
      where m.id = meal_foods.meal_id and dn.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from meals m
      join daily_nutrition dn on dn.id = m.daily_nutrition_id
      where m.id = meal_foods.meal_id and dn.user_id = auth.uid()
    )
  );

drop policy if exists "goal_checkpoints_own_all" on goal_checkpoints;
create policy "goal_checkpoints_own_all" on goal_checkpoints
  for all
  using (
    exists (
      select 1 from goals g
      where g.id = goal_checkpoints.goal_id and g.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from goals g
      where g.id = goal_checkpoints.goal_id and g.user_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------------
-- 7. Supabase Storage Bucket & Policies ('progress-photos')
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public)
values ('progress-photos', 'progress-photos', true)
on conflict (id) do nothing;

drop policy if exists "progress_photos_bucket_read" on storage.objects;
create policy "progress_photos_bucket_read" on storage.objects
  for select
  using (bucket_id = 'progress-photos');

drop policy if exists "progress_photos_bucket_insert_own" on storage.objects;
create policy "progress_photos_bucket_insert_own" on storage.objects
  for insert
  with check (
    bucket_id = 'progress-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "progress_photos_bucket_update_own" on storage.objects;
create policy "progress_photos_bucket_update_own" on storage.objects
  for update
  using (
    bucket_id = 'progress-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "progress_photos_bucket_delete_own" on storage.objects;
create policy "progress_photos_bucket_delete_own" on storage.objects
  for delete
  using (
    bucket_id = 'progress-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );
