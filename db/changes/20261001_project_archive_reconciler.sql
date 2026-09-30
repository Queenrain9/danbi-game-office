-- Track whether each game's durable GitHub project archive is caught up with live Supabase production state.
-- Applied 2026-10-01.

create table if not exists public.danbi_project_archive_state (
  design_id uuid primary key references public.danbi_game_designs(id) on delete cascade,
  project_root text not null,
  synced_at timestamptz not null default now(),
  archive_commit text,
  stage_fingerprint jsonb not null default '{}'::jsonb,
  last_error text,
  updated_at timestamptz not null default now()
);

create or replace function public.danbi_project_source_updated_at(p_design_id uuid)
returns timestamptz
language sql
stable
set search_path to 'public'
as $function$
  select greatest(
    coalesce((select d.updated_at from public.danbi_game_designs d where d.id=p_design_id),'-infinity'::timestamptz),
    coalesce((select max(w.updated_at) from public.danbi_wireframe_packs w where w.design_id=p_design_id),'-infinity'::timestamptz),
    coalesce((select max(c.updated_at) from public.danbi_implementation_contracts c where c.design_id=p_design_id),'-infinity'::timestamptz),
    coalesce((select max(b.updated_at) from public.danbi_build_jobs b where b.design_id=p_design_id and b.status<>'archived'),'-infinity'::timestamptz),
    coalesce((
      select max(coalesce(r.completed_at,r.created_at))
      from public.danbi_fidelity_reviews r
      join public.danbi_build_jobs b on b.id=r.build_job_id
      where b.design_id=p_design_id
    ),'-infinity'::timestamptz)
  )
$function$;

create or replace function public.danbi_next_project_archive_candidate()
returns table(
  design_id uuid,
  title text,
  project_root text,
  source_updated_at timestamptz,
  archive_synced_at timestamptz,
  reason text
)
language sql
stable
set search_path to 'public'
as $function$
  select
    d.id,
    d.title,
    public.danbi_project_root(d.id),
    public.danbi_project_source_updated_at(d.id),
    s.synced_at,
    case
      when s.design_id is null then 'never_synced'
      when s.last_error is not null then 'retry_error'
      else 'source_advanced'
    end
  from public.danbi_game_designs d
  left join public.danbi_project_archive_state s on s.design_id=d.id
  where d.source='chat_automation'
    and (
      s.design_id is null
      or s.last_error is not null
      or public.danbi_project_source_updated_at(d.id) > s.synced_at
    )
  order by
    case when s.last_error is not null then 0 when s.design_id is null then 1 else 2 end,
    coalesce(s.synced_at,d.created_at) asc,
    d.created_at asc
  limit 1
$function$;
