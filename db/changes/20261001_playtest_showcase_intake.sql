-- Playtest showroom intake: fidelity-passed build -> 3 art previews -> site inventory
-- 2026-10-01

create table if not exists public.danbi_playtest_showcase (
  id uuid primary key default gen_random_uuid(),
  build_job_id uuid not null references public.danbi_build_jobs(id) on delete cascade,
  contract_id uuid not null references public.danbi_implementation_contracts(id) on delete cascade,
  fidelity_review_id uuid references public.danbi_fidelity_reviews(id) on delete set null,
  design_id uuid not null,
  idea_id uuid not null,
  title text not null,
  one_line text not null default '',
  project_path text not null,
  repo_full_name text,
  repo_branch text not null default 'main',
  final_commit text not null,
  blueprint_hash text not null,
  art_options jsonb not null default '[]'::jsonb,
  status text not null default 'preparing',
  generation_provider text,
  generation_project_id text,
  generation_note text,
  last_error text,
  source text not null default 'chat_automation',
  source_run_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(build_job_id, final_commit)
);

create index if not exists danbi_playtest_showcase_status_idx
  on public.danbi_playtest_showcase(status, created_at);

create or replace function public.danbi_next_playtest_showcase_candidate()
returns table(
  mode text,
  showcase_id uuid,
  build_job_id uuid,
  contract_id uuid,
  fidelity_review_id uuid,
  design_id uuid,
  idea_id uuid,
  title text,
  one_line text,
  project_path text,
  repo_full_name text,
  repo_branch text,
  final_commit text,
  blueprint_hash text,
  art_options jsonb,
  created_at timestamptz
)
language sql
set search_path to 'public'
as $function$
  with resume as (
    select
      1 as priority,
      'resume_preparing'::text as mode,
      s.id as showcase_id,
      b.id as build_job_id,
      c.id as contract_id,
      s.fidelity_review_id,
      b.design_id,
      b.idea_id,
      b.title,
      coalesce(d.one_line,'') as one_line,
      b.project_path,
      b.repo_full_name,
      b.repo_branch,
      b.last_commit as final_commit,
      b.blueprint_hash,
      s.art_options,
      s.created_at
    from public.danbi_playtest_showcase s
    join public.danbi_build_jobs b on b.id=s.build_job_id
    join public.danbi_implementation_contracts c on c.id=b.contract_id
    left join public.danbi_game_designs d on d.id=b.design_id
    where s.status='preparing'
      and b.status='playtest_ready'
      and b.fidelity_status='passed'
      and b.last_commit=s.final_commit
      and b.blueprint_hash=s.blueprint_hash
    order by s.created_at
    limit 1
  ),
  fresh as (
    select
      2 as priority,
      'new'::text as mode,
      null::uuid as showcase_id,
      b.id as build_job_id,
      c.id as contract_id,
      fr.id as fidelity_review_id,
      b.design_id,
      b.idea_id,
      b.title,
      coalesce(d.one_line,'') as one_line,
      b.project_path,
      b.repo_full_name,
      b.repo_branch,
      b.last_commit as final_commit,
      b.blueprint_hash,
      '[]'::jsonb as art_options,
      b.created_at
    from public.danbi_build_jobs b
    join public.danbi_implementation_contracts c on c.id=b.contract_id
    left join public.danbi_game_designs d on d.id=b.design_id
    join lateral (
      select r.id
      from public.danbi_fidelity_reviews r
      where r.build_job_id=b.id
        and r.verdict='pass'
        and r.reviewed_commit=b.last_commit
        and r.blueprint_hash=b.blueprint_hash
      order by r.review_round desc
      limit 1
    ) fr on true
    where b.status='playtest_ready'
      and b.fidelity_status='passed'
      and length(b.last_commit)=40
      and b.blueprint_hash ~ '^[0-9a-f]{64}$'
      and not exists (
        select 1
        from public.danbi_playtest_showcase s
        where s.build_job_id=b.id
          and s.final_commit=b.last_commit
      )
    order by b.updated_at, b.created_at
    limit 1
  ),
  candidates as (
    select * from resume
    union all
    select * from fresh
  )
  select mode,showcase_id,build_job_id,contract_id,fidelity_review_id,
         design_id,idea_id,title,one_line,project_path,repo_full_name,
         repo_branch,final_commit,blueprint_hash,art_options,created_at
  from candidates
  order by priority,created_at
  limit 1
$function$;
