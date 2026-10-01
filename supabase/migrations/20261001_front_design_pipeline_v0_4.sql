-- Front Design Pipeline v0.4
-- Additive/opt-in only. Existing Game Design -> Pre-production flow remains valid for
-- designs that are not explicitly enrolled in danbi_design_pipeline_optins.

create extension if not exists pgcrypto;

create table if not exists public.danbi_design_pipeline_optins (
  design_id uuid primary key references public.danbi_game_designs(id) on delete cascade,
  mode text not null default 'experiment' check (mode in ('experiment','production')),
  stage text not null default 'validation_pending' check (stage in (
    'validation_pending','validation_running','game_design_repair','validation_unresolved',
    'design_ready','first_build_running','first_build_ready','first_build_conditional',
    'preproduction_running','wireframe_ready','held','completed'
  )),
  validation_revision_count integer not null default 0 check (validation_revision_count >= 0),
  pipeline_bounce_count integer not null default 0 check (pipeline_bounce_count >= 0),
  manual_run_count integer not null default 0 check (manual_run_count >= 0),
  last_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.danbi_design_validations (
  id uuid primary key default gen_random_uuid(),
  design_id uuid not null references public.danbi_game_designs(id) on delete cascade,
  version integer not null,
  status text not null check (status in ('pass','repair','unresolved')),
  validation_method text not null check (validation_method in ('simulation','alternative')),
  validation_strength text not null default 'normal' check (validation_strength in ('normal','reduced')),
  design_version text,
  design_archive_commit text,
  review_rounds jsonb not null default '[]'::jsonb,
  defect_batch jsonb not null default '[]'::jsonb,
  blocking_defects jsonb not null default '[]'::jsonb,
  known_risks jsonb not null default '[]'::jsonb,
  playtest_questions jsonb not null default '[]'::jsonb,
  reference_type text check (reference_type in ('simulation','rule_table','alternative')),
  reference_path text,
  reference_hash text check (reference_hash is null or reference_hash ~ '^[0-9a-f]{64}$'),
  report_markdown text,
  source_repo text not null default 'Queenrain9/danbi-game-office',
  source_commit text check (source_commit is null or source_commit ~ '^[0-9a-f]{7,40}$'),
  created_at timestamptz not null default now(),
  completed_at timestamptz not null default now(),
  unique(design_id, version)
);
create index if not exists danbi_design_validations_design_idx
  on public.danbi_design_validations(design_id, version desc);

create table if not exists public.danbi_first_build_plans (
  id uuid primary key default gen_random_uuid(),
  design_id uuid not null references public.danbi_game_designs(id) on delete cascade,
  validation_id uuid not null references public.danbi_design_validations(id) on delete restrict,
  version integer not null,
  status text not null check (status in ('ready','conditional','stale','blocked')),
  goal jsonb not null default '[]'::jsonb,
  spec jsonb not null default '{}'::jsonb,
  observability_contract jsonb not null default '{}'::jsonb,
  include_scope jsonb not null default '[]'::jsonb,
  not_now jsonb not null default '[]'::jsonb,
  fixed_content jsonb not null default '[]'::jsonb,
  fragment_validation jsonb not null default '{}'::jsonb,
  must_work jsonb not null default '[]'::jsonb,
  expectation_source text not null check (expectation_source in ('simulation','manually_derived')),
  expected_results jsonb not null default '{}'::jsonb,
  validation_reference_hash text not null check (validation_reference_hash ~ '^[0-9a-f]{64}$'),
  first_build_spec_hash text not null check (first_build_spec_hash ~ '^[0-9a-f]{64}$'),
  observability_hash text not null check (observability_hash ~ '^[0-9a-f]{64}$'),
  rules_test_path text not null,
  rules_test_hash text not null check (rules_test_hash ~ '^[0-9a-f]{64}$'),
  known_validation_gap text,
  playtest_questions jsonb not null default '[]'::jsonb,
  stale_reason text,
  source_repo text not null default 'Queenrain9/danbi-game-office',
  source_commit text check (source_commit is null or source_commit ~ '^[0-9a-f]{7,40}$'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(design_id, version)
);
create index if not exists danbi_first_build_plans_design_idx
  on public.danbi_first_build_plans(design_id, version desc);

alter table public.danbi_wireframe_packs
  add column if not exists first_build_plan_id uuid references public.danbi_first_build_plans(id) on delete set null,
  add column if not exists validation_reference_hash text,
  add column if not exists first_build_spec_hash text,
  add column if not exists rules_test_hash text,
  add column if not exists wireframe_semantic_hash text,
  add column if not exists input_test_path text,
  add column if not exists input_test_hash text;

alter table public.danbi_implementation_contracts
  add column if not exists first_build_plan_id uuid references public.danbi_first_build_plans(id) on delete set null,
  add column if not exists validation_reference_hash text,
  add column if not exists first_build_spec_hash text,
  add column if not exists rules_test_hash text,
  add column if not exists input_test_hash text;

create or replace function public.danbi_front_json_hash(p_value jsonb)
returns text
language sql immutable
as $$
  select encode(digest(convert_to(coalesce(p_value, 'null'::jsonb)::text, 'UTF8'), 'sha256'), 'hex');
$$;

create or replace function public.danbi_front_pipeline_opt_in(
  p_design_id uuid,
  p_mode text default 'experiment'
) returns uuid
language plpgsql security definer set search_path=public
as $$
declare
  d public.danbi_game_designs;
begin
  if p_mode not in ('experiment','production') then
    raise exception 'mode must be experiment|production';
  end if;
  select * into d from public.danbi_game_designs where id=p_design_id;
  if not found then raise exception 'design_not_found'; end if;
  if d.status <> 'design' then raise exception 'design_not_available:%', d.status; end if;
  if exists(select 1 from public.danbi_wireframe_packs where design_id=p_design_id) then
    raise exception 'wireframe_already_exists';
  end if;

  insert into public.danbi_design_pipeline_optins(design_id,mode,stage,updated_at)
  values(p_design_id,p_mode,'validation_pending',now())
  on conflict(design_id) do update
    set mode=excluded.mode, updated_at=now()
  where public.danbi_design_pipeline_optins.stage in ('validation_pending','game_design_repair','validation_unresolved','design_ready');
  return p_design_id;
end $$;

create or replace function public.danbi_front_pipeline_record_manual_run(
  p_design_id uuid,
  p_note text default null
) returns integer
language plpgsql security definer set search_path=public
as $$
declare n integer;
begin
  update public.danbi_design_pipeline_optins
  set manual_run_count=manual_run_count+1,
      last_note=coalesce(p_note,last_note),
      updated_at=now()
  where design_id=p_design_id
  returning manual_run_count into n;
  if n is null then raise exception 'design_not_opted_in'; end if;
  return n;
end $$;

create or replace function public.danbi_next_design_validation_candidate()
returns table(
  design_id uuid,
  title text,
  idea_id uuid,
  pipeline_stage text,
  validation_revision_count integer,
  manual_run_count integer,
  human_priority boolean,
  design_version text,
  archive_commit text,
  last_note text
)
language sql stable security definer set search_path=public
as $$
  select d.id,d.title,d.idea_id,o.stage,o.validation_revision_count,o.manual_run_count,
         d.human_priority,d.version,d.archive_commit,o.last_note
  from public.danbi_design_pipeline_optins o
  join public.danbi_game_designs d on d.id=o.design_id
  where o.stage='validation_pending'
  order by d.human_priority desc nulls last,
           d.human_priority_at asc nulls last,
           o.created_at asc
  limit 1;
$$;

create or replace function public.danbi_submit_design_validation(
  p_design_id uuid,
  p_status text,
  p_validation_method text,
  p_validation_strength text,
  p_reference_type text,
  p_reference_path text,
  p_reference_hash text,
  p_review_rounds jsonb default '[]'::jsonb,
  p_defect_batch jsonb default '[]'::jsonb,
  p_blocking_defects jsonb default '[]'::jsonb,
  p_known_risks jsonb default '[]'::jsonb,
  p_playtest_questions jsonb default '[]'::jsonb,
  p_report_markdown text default null,
  p_source_commit text default null
) returns uuid
language plpgsql security definer set search_path=public
as $$
declare
  o public.danbi_design_pipeline_optins;
  d public.danbi_game_designs;
  v_id uuid;
  v_version integer;
  v_previous_hash text;
begin
  if p_status not in ('pass','repair','unresolved') then raise exception 'invalid_validation_status'; end if;
  if p_validation_method not in ('simulation','alternative') then raise exception 'invalid_validation_method'; end if;
  if p_validation_strength not in ('normal','reduced') then raise exception 'invalid_validation_strength'; end if;
  if p_reference_type not in ('simulation','rule_table','alternative') then raise exception 'invalid_reference_type'; end if;
  if p_reference_hash !~ '^[0-9a-f]{64}$' then raise exception 'invalid_reference_hash'; end if;
  if jsonb_typeof(coalesce(p_blocking_defects,'[]'::jsonb)) <> 'array' then raise exception 'blocking_defects_must_be_array'; end if;
  if p_status='pass' and jsonb_array_length(coalesce(p_blocking_defects,'[]'::jsonb)) <> 0 then
    raise exception 'blocking_defects_must_be_zero_for_pass';
  end if;

  select * into o from public.danbi_design_pipeline_optins where design_id=p_design_id for update;
  if not found then raise exception 'design_not_opted_in'; end if;
  if o.stage not in ('validation_pending','validation_running','game_design_repair') then
    raise exception 'validation_stage_invalid:%',o.stage;
  end if;
  select * into d from public.danbi_game_designs where id=p_design_id;
  select coalesce(max(version),0)+1 into v_version from public.danbi_design_validations where design_id=p_design_id;
  select reference_hash into v_previous_hash
    from public.danbi_design_validations
    where design_id=p_design_id and status='pass'
    order by version desc limit 1;

  insert into public.danbi_design_validations(
    design_id,version,status,validation_method,validation_strength,design_version,design_archive_commit,
    review_rounds,defect_batch,blocking_defects,known_risks,playtest_questions,
    reference_type,reference_path,reference_hash,report_markdown,source_commit
  ) values(
    p_design_id,v_version,p_status,p_validation_method,p_validation_strength,d.version,d.archive_commit,
    coalesce(p_review_rounds,'[]'::jsonb),coalesce(p_defect_batch,'[]'::jsonb),
    coalesce(p_blocking_defects,'[]'::jsonb),coalesce(p_known_risks,'[]'::jsonb),
    coalesce(p_playtest_questions,'[]'::jsonb),
    p_reference_type,p_reference_path,lower(p_reference_hash),p_report_markdown,lower(p_source_commit)
  ) returning id into v_id;

  if p_status='pass' then
    if v_previous_hash is not null and v_previous_hash <> lower(p_reference_hash) then
      update public.danbi_first_build_plans
      set status='stale', stale_reason='validation_reference_changed', updated_at=now()
      where design_id=p_design_id and status in ('ready','conditional');
    end if;
    update public.danbi_design_pipeline_optins
    set stage='design_ready',
        validation_revision_count=validation_revision_count+1,
        manual_run_count=manual_run_count+1,
        last_note='validation PASS',
        updated_at=now()
    where design_id=p_design_id;
  elsif p_status='repair' then
    update public.danbi_design_pipeline_optins
    set stage='game_design_repair',
        validation_revision_count=validation_revision_count+1,
        manual_run_count=manual_run_count+1,
        last_note='validation defect batch returned to Game Design',
        updated_at=now()
    where design_id=p_design_id;
  else
    update public.danbi_design_pipeline_optins
    set stage='validation_unresolved',
        validation_revision_count=validation_revision_count+1,
        manual_run_count=manual_run_count+1,
        last_note='validation unresolved; CEO decision required',
        updated_at=now()
    where design_id=p_design_id;
  end if;
  return v_id;
end $$;

create or replace function public.danbi_resume_design_validation(
  p_design_id uuid,
  p_note text default null
) returns void
language plpgsql security definer set search_path=public
as $$
begin
  update public.danbi_design_pipeline_optins
  set stage='validation_pending',
      last_note=coalesce(p_note,'Game Design revision submitted; revalidate'),
      updated_at=now()
  where design_id=p_design_id and stage='game_design_repair';
  if not found then raise exception 'design_not_waiting_for_repair'; end if;
end $$;

create or replace function public.danbi_next_first_build_candidate()
returns table(
  design_id uuid,
  title text,
  validation_id uuid,
  validation_reference_hash text,
  validation_strength text,
  validation_method text,
  manual_run_count integer
)
language sql stable security definer set search_path=public
as $$
  select d.id,d.title,v.id,v.reference_hash,v.validation_strength,v.validation_method,o.manual_run_count
  from public.danbi_design_pipeline_optins o
  join public.danbi_game_designs d on d.id=o.design_id
  join lateral (
    select x.* from public.danbi_design_validations x
    where x.design_id=d.id and x.status='pass'
    order by x.version desc limit 1
  ) v on true
  where o.stage='design_ready'
  order by d.human_priority desc nulls last,o.updated_at asc
  limit 1;
$$;

create or replace function public.danbi_submit_first_build_plan(
  p_design_id uuid,
  p_status text,
  p_goal jsonb,
  p_spec jsonb,
  p_observability_contract jsonb,
  p_include_scope jsonb,
  p_not_now jsonb,
  p_fixed_content jsonb,
  p_fragment_validation jsonb,
  p_must_work jsonb,
  p_expectation_source text,
  p_expected_results jsonb,
  p_rules_test_path text,
  p_rules_test_hash text,
  p_known_validation_gap text default null,
  p_playtest_questions jsonb default '[]'::jsonb,
  p_source_commit text default null
) returns uuid
language plpgsql security definer set search_path=public
as $$
declare
  o public.danbi_design_pipeline_optins;
  v public.danbi_design_validations;
  v_id uuid;
  v_version integer;
  v_spec_hash text;
  v_obs_hash text;
begin
  if p_status not in ('ready','conditional') then raise exception 'invalid_first_build_status'; end if;
  if p_expectation_source not in ('simulation','manually_derived') then raise exception 'invalid_expectation_source'; end if;
  if p_rules_test_hash !~ '^[0-9a-f]{64}$' then raise exception 'invalid_rules_test_hash'; end if;
  if coalesce(trim(p_rules_test_path),'')='' then raise exception 'rules_test_path_required'; end if;
  if p_status='conditional' and coalesce(trim(p_known_validation_gap),'')='' then
    raise exception 'conditional_requires_known_validation_gap';
  end if;

  select * into o from public.danbi_design_pipeline_optins where design_id=p_design_id for update;
  if not found then raise exception 'design_not_opted_in'; end if;
  if o.stage not in ('design_ready','first_build_running') then raise exception 'first_build_stage_invalid:%',o.stage; end if;

  select * into v from public.danbi_design_validations
  where design_id=p_design_id and status='pass'
  order by version desc limit 1;
  if not found then raise exception 'validation_pass_required'; end if;

  v_spec_hash := public.danbi_front_json_hash(coalesce(p_spec,'{}'::jsonb));
  v_obs_hash := public.danbi_front_json_hash(coalesce(p_observability_contract,'{}'::jsonb));
  select coalesce(max(version),0)+1 into v_version from public.danbi_first_build_plans where design_id=p_design_id;

  update public.danbi_first_build_plans
  set status='stale', stale_reason='superseded_by_new_first_build_plan', updated_at=now()
  where design_id=p_design_id and status in ('ready','conditional');

  insert into public.danbi_first_build_plans(
    design_id,validation_id,version,status,goal,spec,observability_contract,include_scope,not_now,
    fixed_content,fragment_validation,must_work,expectation_source,expected_results,
    validation_reference_hash,first_build_spec_hash,observability_hash,
    rules_test_path,rules_test_hash,known_validation_gap,playtest_questions,source_commit
  ) values(
    p_design_id,v.id,v_version,p_status,coalesce(p_goal,'[]'::jsonb),coalesce(p_spec,'{}'::jsonb),
    coalesce(p_observability_contract,'{}'::jsonb),coalesce(p_include_scope,'[]'::jsonb),
    coalesce(p_not_now,'[]'::jsonb),coalesce(p_fixed_content,'[]'::jsonb),
    coalesce(p_fragment_validation,'{}'::jsonb),coalesce(p_must_work,'[]'::jsonb),
    p_expectation_source,coalesce(p_expected_results,'{}'::jsonb),
    v.reference_hash,v_spec_hash,v_obs_hash,p_rules_test_path,lower(p_rules_test_hash),
    p_known_validation_gap,coalesce(p_playtest_questions,'[]'::jsonb),lower(p_source_commit)
  ) returning id into v_id;

  update public.danbi_design_pipeline_optins
  set stage=case when p_status='conditional' then 'first_build_conditional' else 'first_build_ready' end,
      manual_run_count=manual_run_count+1,
      last_note=case when p_status='conditional' then 'First Build conditional ready' else 'First Build ready' end,
      updated_at=now()
  where design_id=p_design_id;

  return v_id;
end $$;

create or replace function public.danbi_front_wireframe_guard()
returns trigger
language plpgsql security definer set search_path=public
as $$
declare
  o public.danbi_design_pipeline_optins;
  p public.danbi_first_build_plans;
begin
  select * into o from public.danbi_design_pipeline_optins where design_id=new.design_id for update;
  if not found then return new; end if;

  if o.stage not in ('first_build_ready','first_build_conditional','preproduction_running') then
    raise exception 'FRONT_PIPELINE_NOT_READY:%',o.stage;
  end if;

  select * into p from public.danbi_first_build_plans
  where design_id=new.design_id and status in ('ready','conditional')
  order by version desc limit 1;
  if not found then raise exception 'FIRST_BUILD_PLAN_REQUIRED'; end if;

  new.first_build_plan_id := p.id;
  new.validation_reference_hash := p.validation_reference_hash;
  new.first_build_spec_hash := p.first_build_spec_hash;
  new.rules_test_hash := p.rules_test_hash;

  update public.danbi_design_pipeline_optins
  set stage='preproduction_running',updated_at=now()
  where design_id=new.design_id;
  return new;
end $$;

drop trigger if exists danbi_front_wireframe_guard_trg on public.danbi_wireframe_packs;
create trigger danbi_front_wireframe_guard_trg
before insert on public.danbi_wireframe_packs
for each row execute function public.danbi_front_wireframe_guard();

create or replace function public.danbi_set_wireframe_input_contract(
  p_wireframe_id uuid,
  p_wireframe_semantic_hash text,
  p_input_test_path text,
  p_input_test_hash text
) returns void
language plpgsql security definer set search_path=public
as $$
declare
  w public.danbi_wireframe_packs;
begin
  if p_wireframe_semantic_hash !~ '^[0-9a-f]{64}$' then raise exception 'invalid_wireframe_semantic_hash'; end if;
  if p_input_test_hash !~ '^[0-9a-f]{64}$' then raise exception 'invalid_input_test_hash'; end if;
  if coalesce(trim(p_input_test_path),'')='' then raise exception 'input_test_path_required'; end if;

  select * into w from public.danbi_wireframe_packs where id=p_wireframe_id for update;
  if not found then raise exception 'wireframe_not_found'; end if;
  if w.first_build_plan_id is null then raise exception 'wireframe_not_in_front_pipeline'; end if;

  update public.danbi_wireframe_packs
  set wireframe_semantic_hash=lower(p_wireframe_semantic_hash),
      input_test_path=p_input_test_path,
      input_test_hash=lower(p_input_test_hash),
      updated_at=now()
  where id=p_wireframe_id;

  update public.danbi_design_pipeline_optins
  set stage='wireframe_ready',
      manual_run_count=manual_run_count+1,
      last_note='Wireframe + INPUT test ready',
      updated_at=now()
  where design_id=w.design_id;
end $$;

create or replace function public.danbi_front_contract_guard()
returns trigger
language plpgsql security definer set search_path=public
as $$
declare
  w public.danbi_wireframe_packs;
  o public.danbi_design_pipeline_optins;
begin
  select * into w from public.danbi_wireframe_packs where id=new.wireframe_pack_id;
  if not found then return new; end if;
  select * into o from public.danbi_design_pipeline_optins where design_id=w.design_id;
  if not found then return new; end if;

  if o.stage <> 'wireframe_ready' then raise exception 'FRONT_PIPELINE_WIREFRAME_NOT_READY:%',o.stage; end if;
  if w.input_test_hash is null or w.rules_test_hash is null then raise exception 'LOCKED_TEST_HASHES_REQUIRED'; end if;

  new.first_build_plan_id := w.first_build_plan_id;
  new.validation_reference_hash := w.validation_reference_hash;
  new.first_build_spec_hash := w.first_build_spec_hash;
  new.rules_test_hash := w.rules_test_hash;
  new.input_test_hash := w.input_test_hash;
  return new;
end $$;

drop trigger if exists danbi_front_contract_guard_trg on public.danbi_implementation_contracts;
create trigger danbi_front_contract_guard_trg
before insert on public.danbi_implementation_contracts
for each row execute function public.danbi_front_contract_guard();

create or replace view public.danbi_front_pipeline_overview as
select
  o.design_id,
  d.idea_id,
  d.title,
  d.one_line,
  d.human_priority,
  o.mode,
  o.stage,
  o.validation_revision_count,
  o.pipeline_bounce_count,
  o.manual_run_count,
  o.last_note,
  v.id as validation_id,
  v.status as validation_status,
  v.validation_method,
  v.validation_strength,
  v.reference_type,
  v.reference_hash as validation_reference_hash,
  v.known_risks as validation_known_risks,
  v.playtest_questions as validation_playtest_questions,
  f.id as first_build_plan_id,
  f.status as first_build_status,
  f.first_build_spec_hash,
  f.observability_hash,
  f.rules_test_hash,
  f.known_validation_gap,
  f.playtest_questions as first_build_playtest_questions,
  o.updated_at
from public.danbi_design_pipeline_optins o
join public.danbi_game_designs d on d.id=o.design_id
left join lateral (
  select x.* from public.danbi_design_validations x
  where x.design_id=o.design_id order by x.version desc limit 1
) v on true
left join lateral (
  select x.* from public.danbi_first_build_plans x
  where x.design_id=o.design_id order by x.version desc limit 1
) f on true;

alter table public.danbi_design_pipeline_optins enable row level security;
alter table public.danbi_design_validations enable row level security;
alter table public.danbi_first_build_plans enable row level security;

drop policy if exists front_pipeline_read on public.danbi_design_pipeline_optins;
create policy front_pipeline_read on public.danbi_design_pipeline_optins for select using (true);
drop policy if exists design_validations_read on public.danbi_design_validations;
create policy design_validations_read on public.danbi_design_validations for select using (true);
drop policy if exists first_build_plans_read on public.danbi_first_build_plans;
create policy first_build_plans_read on public.danbi_first_build_plans for select using (true);

revoke insert,update,delete on public.danbi_design_pipeline_optins from anon,authenticated;
revoke insert,update,delete on public.danbi_design_validations from anon,authenticated;
revoke insert,update,delete on public.danbi_first_build_plans from anon,authenticated;
