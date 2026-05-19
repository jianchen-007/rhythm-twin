-- Rhythm Twin: research data schema for Supabase
-- Run this in the Supabase SQL Editor after creating a new project.
-- See DEPLOY.md for the full step-by-step.

create table if not exists twin_sessions (
  id              bigserial primary key,
  anon_id         text not null,
  user_name       text,
  twin_name       text,
  game_version    text,
  session_num     integer,
  level           integer,
  player_score    integer,
  twin_score_sim  integer,
  total_coins     integer,
  observations    jsonb,
  gravity_mult    real,
  user_agent      text,
  leveled_up      boolean,
  created_at      timestamptz default now()
);

-- Useful query indexes
create index if not exists idx_twin_sessions_anon       on twin_sessions (anon_id, session_num);
create index if not exists idx_twin_sessions_created    on twin_sessions (created_at desc);
create index if not exists idx_twin_sessions_user_name  on twin_sessions (user_name);

-- Row-level security: anonymous browsers can INSERT but cannot read other rows.
-- You (the researcher) use the service_role key on the Supabase dashboard to SELECT.
alter table twin_sessions enable row level security;

drop policy if exists "anon_insert_only" on twin_sessions;
create policy "anon_insert_only" on twin_sessions
  for insert
  to anon
  with check (true);

-- Optional convenience view: latest session per user
create or replace view latest_sessions as
select distinct on (anon_id)
  anon_id, user_name, twin_name, session_num, level,
  player_score, twin_score_sim, total_coins, created_at
from twin_sessions
order by anon_id, session_num desc;
