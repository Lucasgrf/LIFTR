-- Migration: Cardio as time (`logged_sets.duration_seconds` + `cardio_logs`),
-- persistent weekly snapshots (`weekly_snapshots`), and automatic session
-- execution score (`workout_sessions.execution_score`).

-- 1. Timed cardio support inside strength workout sessions
alter table public.logged_sets
  add column if not exists duration_seconds integer;

do $$
begin
  alter table public.logged_sets
    add constraint chk_logged_sets_duration_non_negative
    check (duration_seconds is null or duration_seconds >= 0);
exception
  when duplicate_object then null;
end $$;

-- 2. Automatic execution score (0-100%) on completed workout sessions
alter table public.workout_sessions
  add column if not exists execution_score integer;

do $$
begin
  alter table public.workout_sessions
    add constraint chk_workout_sessions_execution_score_range
    check (execution_score is null or (execution_score >= 0 and execution_score <= 100));
exception
  when duplicate_object then null;
end $$;

-- 3. Standalone cardio logs (non-lifting / rest days)
create table if not exists public.cardio_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  modality text not null default 'Cardio',
  duration_seconds integer not null check (duration_seconds > 0),
  performed_at timestamptz not null default now(),
  notes text,
  created_at timestamptz not null default now()
);

create index if not exists idx_cardio_logs_user_performed
  on public.cardio_logs (user_id, performed_at desc);

alter table public.cardio_logs enable row level security;

drop policy if exists "cardio_logs_select_own" on public.cardio_logs;
create policy "cardio_logs_select_own" on public.cardio_logs
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "cardio_logs_insert_own" on public.cardio_logs;
create policy "cardio_logs_insert_own" on public.cardio_logs
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "cardio_logs_update_own" on public.cardio_logs;
create policy "cardio_logs_update_own" on public.cardio_logs
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "cardio_logs_delete_own" on public.cardio_logs;
create policy "cardio_logs_delete_own" on public.cardio_logs
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

-- 4. Persistent weekly snapshots for longitudinal week-over-week comparison
create table if not exists public.weekly_snapshots (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  week_start date not null,
  week_end date not null,
  workouts_completed integer not null default 0 check (workouts_completed >= 0),
  cardio_duration_seconds integer not null default 0 check (cardio_duration_seconds >= 0),
  training_duration_seconds integer not null default 0 check (training_duration_seconds >= 0),
  working_sets_count integer not null default 0 check (working_sets_count >= 0),
  total_volume_kg numeric(12,2) not null default 0 check (total_volume_kg >= 0),
  avg_rpe numeric(4,1),
  avg_execution_score numeric(5,1),
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint uq_weekly_snapshots_user_week unique (user_id, week_start),
  constraint chk_weekly_snapshots_dates check (week_end >= week_start)
);

alter table public.weekly_snapshots enable row level security;

drop policy if exists "weekly_snapshots_select_own" on public.weekly_snapshots;
create policy "weekly_snapshots_select_own" on public.weekly_snapshots
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "weekly_snapshots_insert_own" on public.weekly_snapshots;
create policy "weekly_snapshots_insert_own" on public.weekly_snapshots
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "weekly_snapshots_update_own" on public.weekly_snapshots;
create policy "weekly_snapshots_update_own" on public.weekly_snapshots
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "weekly_snapshots_delete_own" on public.weekly_snapshots;
create policy "weekly_snapshots_delete_own" on public.weekly_snapshots
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

-- 5. Expose new tables to Data API authenticated role
grant select, insert, update, delete on public.cardio_logs, public.weekly_snapshots to authenticated;
