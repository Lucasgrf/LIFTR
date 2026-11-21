-- Post first-use fixes:
-- 1. Default rest_seconds = 180 (3 minutes)
-- 2. Target prescription snapshots on workout_session_exercises
-- 3. Structured drop_sets JSONB on logged_sets
-- 4. Profile columns on public.user_profiles + optimized RLS + 'avatars' Storage bucket

-- 1. Default rest duration: 3 minutes (180s)
alter table public.set_templates
  alter column rest_seconds set default 180;

-- 2. Prescription targets on workout_session_exercises
alter table public.workout_session_exercises
  add column if not exists target_sets_count integer,
  add column if not exists target_reps_min integer,
  add column if not exists target_reps_max integer,
  add column if not exists target_rir integer,
  add column if not exists target_rest_seconds integer;

-- 3. Drop-set entries on logged_sets
alter table public.logged_sets
  add column if not exists drop_sets jsonb not null default '[]'::jsonb;

-- 4. User Profiles columns & optimized RLS (non-destructive)
create table if not exists public.user_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.user_profiles
  add column if not exists avatar_url text,
  add column if not exists avatar_storage_path text,
  add column if not exists biological_sex text,
  add column if not exists age integer,
  add column if not exists weight_kg numeric(5,2),
  add column if not exists body_fat_percent numeric(4,1),
  add column if not exists goal text,
  add column if not exists experience text,
  add column if not exists activity_level text;

alter table public.user_profiles enable row level security;

do $$
begin
  if exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'user_profiles'
      and policyname = 'Users manage own profile'
  ) then
    alter policy "Users manage own profile" on public.user_profiles
      to authenticated
      using ((select auth.uid()) = id)
      with check ((select auth.uid()) = id);
  elsif not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'user_profiles'
      and policyname = 'user_profiles_own_all'
  ) then
    create policy "user_profiles_own_all" on public.user_profiles
      for all
      to authenticated
      using ((select auth.uid()) = id)
      with check ((select auth.uid()) = id);
  end if;
end $$;

-- 5. 'avatars' Storage bucket & RLS policies (INSERT + SELECT + UPDATE + DELETE)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'avatars',
  'avatars',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects' and policyname = 'avatars_bucket_read'
  ) then
    create policy "avatars_bucket_read" on storage.objects
      for select
      to public
      using (bucket_id = 'avatars');
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects' and policyname = 'avatars_bucket_insert_own'
  ) then
    create policy "avatars_bucket_insert_own" on storage.objects
      for insert
      to authenticated
      with check (
        bucket_id = 'avatars'
        and (select auth.uid())::text = (storage.foldername(name))[1]
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects' and policyname = 'avatars_bucket_update_own'
  ) then
    create policy "avatars_bucket_update_own" on storage.objects
      for update
      to authenticated
      using (
        bucket_id = 'avatars'
        and (select auth.uid())::text = (storage.foldername(name))[1]
      )
      with check (
        bucket_id = 'avatars'
        and (select auth.uid())::text = (storage.foldername(name))[1]
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects' and policyname = 'avatars_bucket_delete_own'
  ) then
    create policy "avatars_bucket_delete_own" on storage.objects
      for delete
      to authenticated
      using (
        bucket_id = 'avatars'
        and (select auth.uid())::text = (storage.foldername(name))[1]
      );
  end if;
end $$;
