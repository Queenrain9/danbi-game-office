-- Playtest Showroom decision + Directed Development handoff
-- Applied to Supabase project hmblaasagxyntyfrfztg on 2026-10-01.

create table if not exists public.danbi_playtest_decisions (
  id uuid primary key default gen_random_uuid(),
  showcase_id uuid not null unique references public.danbi_playtest_showcase(id) on delete cascade,
  build_job_id uuid not null references public.danbi_build_jobs(id) on delete restrict,
  decision text not null check (decision in ('KEEP','MAYBE','KILL')),
  selected_art_option text null check (selected_art_option is null or selected_art_option in ('A','B','C')),
  decision_note text not null default '',
  handoff_stage text not null check (handoff_stage in ('directed','playtest_hold','archive')),
  handoff_status text not null default 'completed' check (handoff_status in ('pending','completed','blocked')),
  decided_at timestamptz not null default now(),
  source text not null default 'human',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists danbi_playtest_decisions_decision_idx
  on public.danbi_playtest_decisions(decision, decided_at desc);

create table if not exists public.danbi_directed_projects (
  id uuid primary key default gen_random_uuid(),
  decision_id uuid not null unique references public.danbi_playtest_decisions(id) on delete restrict,
  showcase_id uuid not null unique references public.danbi_playtest_showcase(id) on delete restrict,
  build_job_id uuid not null references public.danbi_build_jobs(id) on delete restrict,
  design_id uuid not null references public.danbi_game_designs(id) on delete restrict,
  idea_id uuid not null references public.danbi_game_ideas(id) on delete restrict,
  title text not null,
  one_line text not null default '',
  project_path text not null,
  repo_full_name text null,
  repo_branch text not null default 'main',
  final_commit text not null,
  blueprint_hash text not null,
  selected_art_option text null check (selected_art_option is null or selected_art_option in ('A','B','C')),
  handoff_note text not null default '',
  status text not null default 'intake' check (status in ('intake','directing','visual_ready','archived')),
  source text not null default 'playtest_keep',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists danbi_directed_projects_status_idx
  on public.danbi_directed_projects(status, created_at desc);

alter table public.danbi_playtest_decisions enable row level security;
alter table public.danbi_directed_projects enable row level security;

comment on table public.danbi_playtest_decisions is
  'Human playtest verdicts. KEEP hands off to Directed Development, MAYBE remains on hold, KILL closes to Archive classification.';
comment on table public.danbi_directed_projects is
  'Durable intake queue for KEEP decisions handed off from the Playtest Showroom into Directed Development.';
