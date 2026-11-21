-- Delta migration for existing projects initialized with 20240115000000_initial_schema.
-- Safely extends Postgres enums, evolves workout_sessions columns, sets auth.uid() defaults,
-- ensures workout_session_exercises and logged_sets exist with RLS, and applies security fixes.
--
-- Optional manual statement for ad-hoc workoutless sessions in existing databases:
--   alter table public.workout_sessions alter column workout_id drop not null;

-- ---------------------------------------------------------------------------
-- 1. Extend legacy Postgres enums when present
-- ---------------------------------------------------------------------------

do $$
begin
  if exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'mood_type'
  ) then
    alter type public.mood_type add value if not exists 'awful';
    alter type public.mood_type add value if not exists 'excellent';
  end if;

  if exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'set_type'
  ) then
    alter type public.set_type add value if not exists 'drop_set';
    alter type public.set_type add value if not exists 'myo_rep';
  end if;

  if exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'execution_quality'
  ) then
    alter type public.execution_quality add value if not exists 'fair';
    alter type public.execution_quality add value if not exists 'acceptable';
    alter type public.execution_quality add value if not exists 'excellent';
    alter type public.execution_quality add value if not exists 'perfect';
  end if;

  if exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'meal_type'
  ) then
    alter type public.meal_type add value if not exists 'snack';
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- 2. Security advisor remediations (idempotent)
-- ---------------------------------------------------------------------------

do $$
begin
  alter function public.update_updated_at_column() set search_path = public;
exception when undefined_function then
  null;
end $$;

do $$
begin
  revoke execute on function public.rls_auto_enable() from anon, authenticated, public;
exception when undefined_function then
  null;
end $$;

-- ---------------------------------------------------------------------------
-- 3. Evolve workout_sessions & ensure auth.uid() defaults
-- ---------------------------------------------------------------------------

alter table public.workout_sessions add column if not exists workout_name text;
alter table public.workout_sessions add column if not exists duration_seconds integer not null default 0;
alter table public.workout_sessions add column if not exists perceived_exertion numeric(4,1);
alter table public.workout_sessions add column if not exists notes text;
alter table public.workout_sessions add column if not exists readiness_score integer;

alter table public.training_plans alter column user_id set default auth.uid();
alter table public.workout_sessions alter column user_id set default auth.uid();
alter table public.weight_entries alter column user_id set default auth.uid();
alter table public.body_measurements alter column user_id set default auth.uid();
alter table public.progress_photos alter column user_id set default auth.uid();
alter table public.nutrition_goals alter column user_id set default auth.uid();
alter table public.daily_nutrition alter column user_id set default auth.uid();
alter table public.goals alter column user_id set default auth.uid();

-- ---------------------------------------------------------------------------
-- 4. Ensure workout_session_exercises & logged_sets exist with RLS
-- ---------------------------------------------------------------------------

create table if not exists public.workout_session_exercises (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.workout_sessions(id) on delete cascade,
  exercise_id uuid not null references public.exercises(id),
  sort_order integer not null default 0,
  notes text,
  replaced_exercise_id uuid references public.exercises(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_session_exercises_session
  on public.workout_session_exercises(session_id, sort_order);
create index if not exists idx_session_exercises_exercise
  on public.workout_session_exercises(exercise_id);

create table if not exists public.logged_sets (
  id uuid primary key default gen_random_uuid(),
  session_exercise_id uuid not null references public.workout_session_exercises(id) on delete cascade,
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
  on public.logged_sets(session_exercise_id, set_number);

alter table public.workout_session_exercises enable row level security;
alter table public.logged_sets enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'workout_session_exercises'
      and policyname = 'workout_session_exercises_own_all'
  ) then
    execute $policy$
      create policy "workout_session_exercises_own_all" on public.workout_session_exercises
        for all
        using (
          exists (
            select 1 from public.workout_sessions ws
            where ws.id = workout_session_exercises.session_id and ws.user_id = auth.uid()
          )
        )
        with check (
          exists (
            select 1 from public.workout_sessions ws
            where ws.id = workout_session_exercises.session_id and ws.user_id = auth.uid()
          )
        )
    $policy$;
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'logged_sets'
      and policyname = 'logged_sets_own_all'
  ) then
    execute $policy$
      create policy "logged_sets_own_all" on public.logged_sets
        for all
        using (
          exists (
            select 1
            from public.workout_session_exercises wse
            join public.workout_sessions ws on ws.id = wse.session_id
            where wse.id = logged_sets.session_exercise_id and ws.user_id = auth.uid()
          )
        )
        with check (
          exists (
            select 1
            from public.workout_session_exercises wse
            join public.workout_sessions ws on ws.id = wse.session_id
            where wse.id = logged_sets.session_exercise_id and ws.user_id = auth.uid()
          )
        )
    $policy$;
  end if;
end $$;
