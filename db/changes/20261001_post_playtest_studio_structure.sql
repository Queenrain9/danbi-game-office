-- Post-playtest studio structure
-- Applied to Supabase project hmblaasagxyntyfrfztg on 2026-10-01.

alter table public.danbi_playtest_decisions
  drop constraint if exists danbi_playtest_decisions_decision_check,
  drop constraint if exists danbi_playtest_decisions_handoff_stage_check;

alter table public.danbi_playtest_decisions
  add constraint danbi_playtest_decisions_decision_check
    check (decision in ('UNJUDGEABLE','KEEP','MAYBE','KILL')),
  add constraint danbi_playtest_decisions_handoff_stage_check
    check (handoff_stage in ('diagnostic','enhancement','playtest_hold','graveyard'));

alter table public.danbi_directed_projects
  rename to danbi_game_enhancement_projects;

alter table public.danbi_game_enhancement_projects
  drop constraint if exists danbi_directed_projects_status_check;

alter table public.danbi_game_enhancement_projects
  rename column handoff_note to direction_note;

alter table public.danbi_game_enhancement_projects
  add column if not exists minimum_asset_spec jsonb not null default '{}'::jsonb,
  add column if not exists asset_spec_status text not null default 'pending'
    check (asset_spec_status in ('pending','drafting','ready')),
  add column if not exists current_goal text not null default '',
  add column if not exists playtest_round integer not null default 1 check (playtest_round > 0);

alter table public.danbi_game_enhancement_projects
  add constraint danbi_game_enhancement_projects_status_check
    check (status in ('intake','minimum_asset_spec','enhancing','retest_ready','art_sync','complete','archived'));

create table if not exists public.danbi_playtest_diagnostics (
  id uuid primary key default gen_random_uuid(),
  decision_id uuid not null unique references public.danbi_playtest_decisions(id) on delete cascade,
  showcase_id uuid not null unique references public.danbi_playtest_showcase(id) on delete cascade,
  build_job_id uuid not null references public.danbi_build_jobs(id) on delete restrict,
  title text not null,
  issue_note text not null default '',
  diagnosis text not null default '',
  issue_type text not null default 'unknown'
    check (issue_type in ('unknown','launch','runtime','input','progression_block','fidelity_mismatch','environment','design_conflict','other')),
  route_target text null
    check (route_target is null or route_target in ('build_farm','implementation','fidelity','game_design','manual')),
  status text not null default 'open'
    check (status in ('open','diagnosing','routed','fixing','retest_ready','closed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists danbi_playtest_diagnostics_status_idx
  on public.danbi_playtest_diagnostics(status, created_at desc);
alter table public.danbi_playtest_diagnostics enable row level security;

create table if not exists public.danbi_art_projects (
  id uuid primary key default gen_random_uuid(),
  enhancement_project_id uuid not null unique references public.danbi_game_enhancement_projects(id) on delete cascade,
  showcase_id uuid not null unique references public.danbi_playtest_showcase(id) on delete restrict,
  build_job_id uuid not null references public.danbi_build_jobs(id) on delete restrict,
  title text not null,
  selected_art_option text null check (selected_art_option is null or selected_art_option in ('A','B','C')),
  art_direction_note text not null default '',
  visual_direction jsonb not null default '{}'::jsonb,
  asset_manifest jsonb not null default '[]'::jsonb,
  stage text not null default 'direction'
    check (stage in ('direction','asset_spec','production','integration','complete','archived')),
  status text not null default 'waiting'
    check (status in ('waiting','in_progress','blocked','ready','complete','archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists danbi_art_projects_stage_idx
  on public.danbi_art_projects(stage, status, created_at desc);
alter table public.danbi_art_projects enable row level security;

create table if not exists public.danbi_project_graveyard (
  id uuid primary key default gen_random_uuid(),
  decision_id uuid not null unique references public.danbi_playtest_decisions(id) on delete restrict,
  showcase_id uuid not null unique references public.danbi_playtest_showcase(id) on delete restrict,
  build_job_id uuid not null references public.danbi_build_jobs(id) on delete restrict,
  design_id uuid not null references public.danbi_game_designs(id) on delete restrict,
  idea_id uuid not null references public.danbi_game_ideas(id) on delete restrict,
  title text not null,
  one_line text not null default '',
  kill_reason text not null default '',
  project_path text not null,
  repo_full_name text null,
  repo_branch text not null default 'main',
  final_commit text not null,
  blueprint_hash text not null,
  reached_stage text not null default 'playtest',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists danbi_project_graveyard_created_idx
  on public.danbi_project_graveyard(created_at desc);
alter table public.danbi_project_graveyard enable row level security;
