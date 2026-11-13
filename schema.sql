-- Run this in Supabase: SQL Editor > New query > Run
create table if not exists submissions(
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  kind text not null,
  ref text unique not null,
  data jsonb not null default '{}',
  status text not null default 'new'
);
alter table submissions enable row level security;
revoke all on submissions from anon;
grant insert on submissions to anon;
grant select, update, delete on submissions to authenticated;

-- Visitors can only INSERT new, small, known kinds
create policy "visitors insert" on submissions for insert to anon
  with check (status='new' and length(data::text)<5000 and
  kind in ('rescue','pickup','booking','volunteer','lost_found','cruelty','adoption'));

-- Only YOU can read, update, delete. CHANGE THE EMAIL BELOW.
create policy "admin select" on submissions for select to authenticated
  using ((auth.jwt()->>'email')='you@example.com');
create policy "admin update" on submissions for update to authenticated
  using ((auth.jwt()->>'email')='you@example.com');
create policy "admin delete" on submissions for delete to authenticated
  using ((auth.jwt()->>'email')='you@example.com');

-- Lets a visitor see ONLY the status of their own rescue reference
create or replace function track_request(p_ref text) returns text
language sql security definer set search_path=public as
$$ select status from submissions where ref=p_ref and kind='rescue' limit 1 $$;
grant execute on function track_request(text) to anon;
