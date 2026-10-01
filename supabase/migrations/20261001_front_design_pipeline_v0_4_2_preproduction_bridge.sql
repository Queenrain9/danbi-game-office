-- Front Design Pipeline v0.4.2
-- Manual-first Pre-production bridge for FIRST BUILD READY experiments.

create or replace function public.danbi_next_front_preproduction_candidate()
returns table(
  design_id uuid,
  title text,
  idea_id uuid,
  pipeline_stage text,
  first_build_plan_id uuid,
  first_build_status text,
  first_build_spec jsonb,
  observability_contract jsonb,
  must_work jsonb,
  rules_test_path text,
  rules_test_hash text,
  validation_reference_hash text,
  first_build_spec_hash text,
  validation_strength text,
  known_validation_gap text,
  manual_run_count integer
)
language sql stable security definer set search_path=public
as $$
  select
    d.id,d.title,d.idea_id,o.stage,
    f.id,f.status,f.spec,f.observability_contract,f.must_work,
    f.rules_test_path,f.rules_test_hash,f.validation_reference_hash,f.first_build_spec_hash,
    v.validation_strength,f.known_validation_gap,o.manual_run_count
  from public.danbi_design_pipeline_optins o
  join public.danbi_game_designs d on d.id=o.design_id
  join lateral (
    select x.* from public.danbi_first_build_plans x
    where x.design_id=d.id and x.status in ('ready','conditional')
    order by x.version desc limit 1
  ) f on true
  join public.danbi_design_validations v on v.id=f.validation_id
  where o.stage in ('first_build_ready','first_build_conditional')
    and not exists (
      select 1 from public.danbi_wireframe_packs w
      where w.design_id=d.id and w.first_build_plan_id=f.id
    )
  order by d.human_priority desc nulls last,o.updated_at asc
  limit 1;
$$;

create or replace function public.danbi_front_record_pipeline_bounce(
  p_design_id uuid,
  p_return_to text,
  p_reason text
) returns integer
language plpgsql security definer set search_path=public
as $$
declare n integer;
begin
  if coalesce(trim(p_reason),'')='' then raise exception 'return_reason_required'; end if;
  update public.danbi_design_pipeline_optins
  set pipeline_bounce_count=pipeline_bounce_count+1,
      last_note=format('return_to=%s: %s',coalesce(p_return_to,'unknown'),p_reason),
      stage=case
        when pipeline_bounce_count+1 >= 3 then 'held'
        when p_return_to='first_build' then 'design_ready'
        when p_return_to='validation' then 'validation_pending'
        when p_return_to='game_design' then 'game_design_repair'
        else stage
      end,
      updated_at=now()
  where design_id=p_design_id
  returning pipeline_bounce_count into n;
  if n is null then raise exception 'design_not_opted_in'; end if;
  return n;
end $$;
