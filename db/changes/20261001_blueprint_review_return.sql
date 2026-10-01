-- Blueprint review return path: Gate FAIL -> Implementation repair -> re-review
-- 2026-10-01
-- Synced with live Supabase definitions on 2026-10-01.

create or replace function public.danbi_reject_blueprint(
  p_contract uuid,
  p_hash text,
  p_token uuid,
  p_issues jsonb,
  p_review jsonb default '{}'::jsonb
)
returns void
language plpgsql
set search_path to 'public', 'pg_temp'
as $function$
begin
  perform public.danbi_assert_lease('gate', p_token);

  if jsonb_typeof(p_issues) is distinct from 'array'
     or jsonb_array_length(p_issues)=0 then
    raise exception 'Blueprint rejection needs issues';
  end if;

  if exists (
    select 1 from jsonb_array_elements(p_issues) issue
    where coalesce(issue->>'return_to','') not in ('compiler','preproduction','game_design')
  ) then
    raise exception 'Every Blueprint rejection issue needs valid return_to';
  end if;

  update public.danbi_implementation_contracts
  set status='draft',
      blueprint_status='blocked',
      blueprint_issues=p_issues,
      blueprint_review=coalesce(p_review,'{}'::jsonb) || jsonb_build_object(
        'role','gate','verdict','fail','blueprint_hash',p_hash,'reviewed_at',now()
      ),
      updated_at=now()
  where id=p_contract
    and blueprint_hash=p_hash
    and blueprint_status='pending_review';

  if not found then
    raise exception 'Blueprint changed or not ready for rejection';
  end if;
end
$function$;

create or replace function public.danbi_next_compiler_candidate()
returns table(
  mode text,
  contract_id uuid,
  wireframe_pack_id uuid,
  design_id uuid,
  idea_id uuid,
  title text,
  created_at timestamptz
)
language sql
set search_path to 'public'
as $function$
  with candidates as (
    select 1 priority, 'resume_missing'::text mode, c.id contract_id,
           c.wireframe_pack_id,c.design_id,c.idea_id,c.title,c.created_at
    from public.danbi_implementation_contracts c
    where c.source='chat_automation'
      and c.status='draft'
      and c.blueprint_status='missing'

    union all

    select 2 priority, 'resume_blocked'::text mode, c.id contract_id,
           c.wireframe_pack_id,c.design_id,c.idea_id,c.title,c.created_at
    from public.danbi_implementation_contracts c
    where c.source='chat_automation'
      and c.blueprint_status='blocked'
      and not exists (
        select 1
        from jsonb_array_elements(coalesce(c.blueprint_issues,'[]'::jsonb)) issue
        where issue->>'return_to' in ('preproduction','game_design')
      )

    union all

    select 3 priority, 'new'::text mode, null::uuid contract_id,
           w.id,w.design_id,w.idea_id,w.title,w.created_at
    from public.danbi_wireframe_packs w
    where w.source='chat_automation'
      and w.status in ('wireframe','build')
      and not exists (
        select 1 from public.danbi_implementation_contracts c
        where c.wireframe_pack_id=w.id and c.status<>'archived'
      )
  )
  select mode,contract_id,wireframe_pack_id,design_id,idea_id,title,created_at
  from candidates
  order by priority,created_at
  limit 1
$function$;

create or replace function public.danbi_next_preproduction_repair_candidate()
returns table(
  contract_id uuid,
  wireframe_pack_id uuid,
  design_id uuid,
  idea_id uuid,
  title text,
  issues jsonb,
  created_at timestamptz
)
language sql
set search_path to 'public'
as $function$
  select c.id,c.wireframe_pack_id,c.design_id,c.idea_id,c.title,c.blueprint_issues,c.created_at
  from public.danbi_implementation_contracts c
  where c.source='chat_automation'
    and c.status='draft'
    and c.blueprint_status='blocked'
    and exists (
      select 1 from jsonb_array_elements(coalesce(c.blueprint_issues,'[]'::jsonb)) issue
      where issue->>'return_to'='preproduction'
    )
  order by c.updated_at,c.created_at
  limit 1
$function$;
