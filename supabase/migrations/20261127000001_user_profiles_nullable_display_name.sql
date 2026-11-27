-- Allow partial upserts on public.user_profiles (such as saveProfile with null
-- displayName or uploadAvatar mirror) without failing NOT NULL before ON CONFLICT.
alter table public.user_profiles
  alter column display_name drop not null;
