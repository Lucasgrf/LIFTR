-- Migration: Reconcile production schema drift from 20240115000000_initial_schema.
-- Safely idempotent: runs cleanly both on a database initialized from scratch
-- via supabase/migrations/ and on the live production database without altering
-- existing production rows or dropping live data.

-- ---------------------------------------------------------------------------
-- 1. Enum types present in production
-- ---------------------------------------------------------------------------

do $$
begin
  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'execution_quality'
  ) then
    create type public.execution_quality as enum (
      'good', 'moderate', 'poor', 'fair', 'acceptable', 'excellent', 'perfect'
    );
  end if;

  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'goal_category'
  ) then
    create type public.goal_category as enum (
      'weight', 'calories', 'protein', 'training_frequency',
      'exercise_weight', 'exercise_reps', 'measurement', 'habit', 'custom'
    );
  end if;

  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'goal_status'
  ) then
    create type public.goal_status as enum (
      'active', 'completed', 'abandoned', 'paused'
    );
  end if;

  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'meal_type'
  ) then
    create type public.meal_type as enum (
      'breakfast', 'morning_snack', 'lunch', 'afternoon_snack',
      'pre_workout', 'post_workout', 'dinner', 'evening_snack', 'other', 'snack'
    );
  end if;

  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'mood_type'
  ) then
    create type public.mood_type as enum (
      'great', 'good', 'neutral', 'bad', 'terrible', 'awful', 'excellent'
    );
  end if;

  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'session_status'
  ) then
    create type public.session_status as enum (
      'in_progress', 'completed', 'abandoned'
    );
  end if;

  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'set_type'
  ) then
    create type public.set_type as enum (
      'mobility', 'warmup', 'ramp_up', 'working', 'drop_set', 'myo_rep'
    );
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- 2. Trigger helper function (fixed search_path)
-- ---------------------------------------------------------------------------

create or replace function public.update_updated_at_column()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- 3. Missing columns & constraints on existing tables
-- ---------------------------------------------------------------------------

alter table public.user_profiles
  add column if not exists date_of_birth date,
  add column if not exists gender text,
  add column if not exists height_cm numeric(5,1),
  add column if not exists preferred_weight_unit text default 'kg',
  add column if not exists preferred_measurement_unit text default 'cm',
  add column if not exists timezone text default 'America/Sao_Paulo';

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where connamespace = 'public'::regnamespace
      and conrelid = 'public.user_profiles'::regclass
      and conname = 'user_profiles_gender_check'
  ) then
    alter table public.user_profiles
      add constraint user_profiles_gender_check
      check (gender = any (array['male'::text, 'female'::text, 'other'::text, 'prefer_not_to_say'::text]));
  end if;

  if not exists (
    select 1 from pg_constraint
    where connamespace = 'public'::regnamespace
      and conrelid = 'public.user_profiles'::regclass
      and conname = 'user_profiles_preferred_weight_unit_check'
  ) then
    alter table public.user_profiles
      add constraint user_profiles_preferred_weight_unit_check
      check (preferred_weight_unit = any (array['kg'::text, 'lbs'::text]));
  end if;

  if not exists (
    select 1 from pg_constraint
    where connamespace = 'public'::regnamespace
      and conrelid = 'public.user_profiles'::regclass
      and conname = 'user_profiles_preferred_measurement_unit_check'
  ) then
    alter table public.user_profiles
      add constraint user_profiles_preferred_measurement_unit_check
      check (preferred_measurement_unit = any (array['cm'::text, 'in'::text]));
  end if;
end $$;

alter table public.workout_sessions
  add column if not exists training_plan_id uuid references public.training_plans(id),
  add column if not exists duration_minutes integer,
  add column if not exists overall_difficulty integer,
  add column if not exists overall_notes text;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where connamespace = 'public'::regnamespace
      and conrelid = 'public.workout_sessions'::regclass
      and conname = 'workout_sessions_overall_difficulty_check'
  ) then
    alter table public.workout_sessions
      add constraint workout_sessions_overall_difficulty_check
      check (overall_difficulty >= 1 and overall_difficulty <= 10);
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- 4. Reconcile enum column types, nullability & defaults on fresh DBs
--    (all guarded so live production is touched only where needed)
-- ---------------------------------------------------------------------------

do $$
begin
  -- set_templates.set_type: text -> public.set_type
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'set_templates'
      and column_name = 'set_type' and udt_name = 'text'
  ) then
    alter table public.set_templates drop constraint if exists set_templates_set_type_check;
    alter table public.set_templates alter column set_type drop default;
    alter table public.set_templates
      alter column set_type type public.set_type using set_type::public.set_type;
    alter table public.set_templates
      alter column set_type set default 'working'::public.set_type;
  end if;

  -- workout_sessions.mood: text -> public.mood_type
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'workout_sessions'
      and column_name = 'mood' and udt_name = 'text'
  ) then
    alter table public.workout_sessions drop constraint if exists workout_sessions_mood_check;
    alter table public.workout_sessions
      alter column mood type public.mood_type using mood::public.mood_type;
  end if;

  -- workout_sessions.status: text -> public.session_status
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'workout_sessions'
      and column_name = 'status' and udt_name = 'text'
  ) then
    alter table public.workout_sessions drop constraint if exists workout_sessions_status_check;
    alter table public.workout_sessions alter column status drop default;
    alter table public.workout_sessions alter column status drop not null;
    alter table public.workout_sessions
      alter column status type public.session_status using status::public.session_status;
    alter table public.workout_sessions
      alter column status set default 'in_progress'::public.session_status;
  end if;

  -- meals.meal_type: text -> public.meal_type
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'meals'
      and column_name = 'meal_type' and udt_name = 'text'
  ) then
    alter table public.meals alter column meal_type drop not null;
    alter table public.meals
      alter column meal_type type public.meal_type using meal_type::public.meal_type;
  end if;

  -- goals.category & goals.status: text -> enum
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'goals'
      and column_name = 'category' and udt_name = 'text'
  ) then
    alter table public.goals
      alter column category type public.goal_category using category::public.goal_category;
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'goals'
      and column_name = 'status' and udt_name = 'text'
  ) then
    alter table public.goals drop constraint if exists goals_status_check;
    alter table public.goals alter column status drop default;
    alter table public.goals alter column status drop not null;
    alter table public.goals
      alter column status type public.goal_status using status::public.goal_status;
    alter table public.goals
      alter column status set default 'active'::public.goal_status;
  end if;
end $$;

-- Align nullability & defaults to match production
alter table public.user_profiles
  alter column created_at drop not null,
  alter column updated_at drop not null;

alter table public.exercises
  alter column secondary_muscles drop not null,
  alter column secondary_muscles drop default,
  alter column is_custom drop not null,
  alter column created_at drop not null,
  alter column updated_at drop not null;

alter table public.training_plans
  alter column is_active drop not null,
  alter column created_at drop not null,
  alter column updated_at drop not null;

alter table public.workouts
  alter column created_at drop not null,
  alter column updated_at drop not null;

alter table public.workout_exercises
  alter column created_at drop not null,
  alter column updated_at drop not null;

alter table public.set_templates
  alter column rest_seconds drop not null,
  alter column created_at drop not null,
  alter column updated_at drop not null;

alter table public.workout_sessions
  alter column started_at drop default,
  alter column created_at drop not null,
  alter column updated_at drop not null;

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'workout_sessions'
      and column_name = 'workout_id' and is_nullable = 'YES'
  ) and not exists (
    select 1 from public.workout_sessions where workout_id is null
  ) then
    alter table public.workout_sessions alter column workout_id set not null;
  end if;
end $$;

alter table public.weight_entries
  alter column created_at drop not null;

alter table public.body_measurements
  alter column created_at drop not null;

alter table public.progress_photos
  alter column pose drop not null,
  alter column pose drop default,
  alter column created_at drop not null;

alter table public.nutrition_goals
  alter column created_at drop not null;

alter table public.foods
  alter column serving_size drop default,
  alter column serving_unit drop not null,
  alter column calories drop not null,
  alter column calories drop default,
  alter column protein drop not null,
  alter column protein drop default,
  alter column carbs drop not null,
  alter column carbs drop default,
  alter column fat drop not null,
  alter column fat drop default,
  alter column fiber drop not null,
  alter column fiber drop default,
  alter column is_custom drop not null,
  alter column created_at drop not null,
  alter column updated_at drop not null;

alter table public.daily_nutrition
  alter column total_calories drop not null,
  alter column total_protein drop not null,
  alter column total_carbs drop not null,
  alter column total_fat drop not null,
  alter column created_at drop not null,
  alter column updated_at drop not null;

alter table public.meals
  alter column name drop not null,
  alter column created_at drop not null;

alter table public.meal_foods
  alter column calories drop not null,
  alter column calories drop default,
  alter column protein drop not null,
  alter column protein drop default,
  alter column carbs drop not null,
  alter column carbs drop default,
  alter column fat drop not null,
  alter column fat drop default,
  alter column created_at drop not null;

alter table public.goals
  alter column unit drop not null,
  alter column unit drop default,
  alter column created_at drop not null,
  alter column updated_at drop not null;

-- ---------------------------------------------------------------------------
-- 5. Missing production tables (with RLS & policies)
-- ---------------------------------------------------------------------------

create table if not exists public.custom_measurements (
  id uuid primary key default gen_random_uuid(),
  body_measurement_id uuid not null references public.body_measurements(id) on delete cascade,
  name text not null,
  value numeric(5,1) not null,
  unit text default 'cm'
);

alter table public.custom_measurements enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'custom_measurements'
      and policyname = 'Users manage own custom measurements'
  ) then
    create policy "Users manage own custom measurements"
      on public.custom_measurements
      for all
      using (
        exists (
          select 1 from public.body_measurements bm
          where bm.id = custom_measurements.body_measurement_id
            and bm.user_id = auth.uid()
        )
      );
  end if;
end $$;

create table if not exists public.exercise_performances (
  id uuid primary key default gen_random_uuid(),
  workout_session_id uuid not null references public.workout_sessions(id) on delete cascade,
  workout_exercise_id uuid not null references public.workout_exercises(id),
  exercise_id uuid not null references public.exercises(id),
  sort_order integer not null default 0,
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_performances_exercise
  on public.exercise_performances (exercise_id);
create index if not exists idx_performances_session
  on public.exercise_performances (workout_session_id);

alter table public.exercise_performances enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'exercise_performances'
      and policyname = 'Users manage own performances'
  ) then
    create policy "Users manage own performances"
      on public.exercise_performances
      for all
      using (
        exists (
          select 1 from public.workout_sessions ws
          where ws.id = exercise_performances.workout_session_id
            and ws.user_id = auth.uid()
        )
      );
  end if;
end $$;

create table if not exists public.set_performances (
  id uuid primary key default gen_random_uuid(),
  exercise_performance_id uuid not null references public.exercise_performances(id) on delete cascade,
  set_template_id uuid references public.set_templates(id),
  set_number integer not null,
  set_type public.set_type not null default 'working'::public.set_type,
  weight numeric(6,2),
  reps integer,
  rir integer,
  rest_seconds integer,
  execution_quality public.execution_quality,
  perceived_difficulty integer check (perceived_difficulty >= 1 and perceived_difficulty <= 10),
  weight_suggested numeric(6,2),
  progression_action text,
  progression_reason text,
  notes text,
  performed_at timestamptz default now(),
  created_at timestamptz default now()
);

create index if not exists idx_set_perf_exercise
  on public.set_performances (exercise_performance_id);

alter table public.set_performances enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'set_performances'
      and policyname = 'Users manage own set performances'
  ) then
    create policy "Users manage own set performances"
      on public.set_performances
      for all
      using (
        exists (
          select 1
          from public.exercise_performances ep
          join public.workout_sessions ws on ws.id = ep.workout_session_id
          where ep.id = set_performances.exercise_performance_id
            and ws.user_id = auth.uid()
        )
      );
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- 6. Missing production indexes
-- ---------------------------------------------------------------------------

create index if not exists idx_exercises_name
  on public.exercises using gin (to_tsvector('portuguese'::regconfig, name));
create index if not exists idx_foods_name
  on public.foods using gin (to_tsvector('portuguese'::regconfig, name));
create index if not exists idx_foods_user
  on public.foods (user_id);
create index if not exists idx_sessions_date
  on public.workout_sessions (user_id, started_at);
create index if not exists idx_sessions_user
  on public.workout_sessions (user_id);
create index if not exists idx_sessions_workout
  on public.workout_sessions (workout_id);
create index if not exists idx_weight_user_date
  on public.weight_entries (user_id, measured_at);
create index if not exists idx_body_user_date
  on public.body_measurements (user_id, measured_at);
create index if not exists idx_photos_user_date
  on public.progress_photos (user_id, taken_at);
create index if not exists idx_nutrition_goals_user
  on public.nutrition_goals (user_id, effective_from);
create index if not exists idx_daily_nutrition_user
  on public.daily_nutrition (user_id, date);
create index if not exists idx_goals_user
  on public.goals (user_id);
create index if not exists idx_goals_active
  on public.goals (user_id, status) where (status = 'active'::public.goal_status);
create index if not exists idx_checkpoints_goal
  on public.goal_checkpoints (goal_id, recorded_at);

-- ---------------------------------------------------------------------------
-- 7. Missing set_updated_at triggers (11 tables in production)
-- ---------------------------------------------------------------------------

do $$
declare
  tbl text;
begin
  foreach tbl in array array[
    'daily_nutrition',
    'exercise_performances',
    'exercises',
    'foods',
    'goals',
    'set_templates',
    'training_plans',
    'user_profiles',
    'workout_exercises',
    'workout_sessions',
    'workouts'
  ] loop
    if not exists (
      select 1
      from pg_trigger tg
      join pg_class c on c.oid = tg.tgrelid
      join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public'
        and c.relname = tbl
        and tg.tgname = 'set_updated_at'
        and not tg.tgisinternal
    ) then
      execute format(
        'create trigger set_updated_at before update on public.%I for each row execute function public.update_updated_at_column()',
        tbl
      );
    end if;
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- 8. Storage bucket 'progress-photos' configuration & policies
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'progress-photos',
  'progress-photos',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do nothing;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects' and policyname = 'Users view own photos'
  ) then
    create policy "Users view own photos" on storage.objects
      for select
      to authenticated
      using (
        bucket_id = 'progress-photos'
        and (storage.foldername(name))[1] = auth.uid()::text
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects' and policyname = 'Users upload own photos'
  ) then
    create policy "Users upload own photos" on storage.objects
      for insert
      to authenticated
      with check (
        bucket_id = 'progress-photos'
        and (storage.foldername(name))[1] = auth.uid()::text
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects' and policyname = 'Users delete own photos'
  ) then
    create policy "Users delete own photos" on storage.objects
      for delete
      to authenticated
      using (
        bucket_id = 'progress-photos'
        and (storage.foldername(name))[1] = auth.uid()::text
      );
  end if;
end $$;
