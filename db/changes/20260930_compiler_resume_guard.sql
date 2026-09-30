-- Compiler resume queue + completion checkpoint.
-- Applied to Supabase project hmblaasagxyntyfrfztg on 2026-09-30.
-- Purpose: a partially written Contract is a resumable checkpoint, never a reason
-- to skip ahead or duplicate the Contract.

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
security invoker
set search_path = public
as $$
  with candidates as (
    select
      1 as priority,
      'resume_missing'::text as mode,
      c.id as contract_id,
      c.wireframe_pack_id,
      c.design_id,
      c.idea_id,
      c.title,
      c.created_at
    from public.danbi_implementation_contracts c
    where c.source='chat_automation'
      and c.status='draft'
      and c.blueprint_status='missing'

    union all

    select
      2 as priority,
      'new'::text as mode,
      null::uuid as contract_id,
      w.id as wireframe_pack_id,
      w.design_id,
      w.idea_id,
      w.title,
      w.created_at
    from public.danbi_wireframe_packs w
    where w.source='chat_automation'
      and w.status in ('wireframe','build')
      and not exists (
        select 1
        from public.danbi_implementation_contracts c
        where c.wireframe_pack_id=w.id
          and c.status<>'archived'
      )

    union all

    select
      3 as priority,
      'resume_blocked'::text as mode,
      c.id as contract_id,
      c.wireframe_pack_id,
      c.design_id,
      c.idea_id,
      c.title,
      c.created_at
    from public.danbi_implementation_contracts c
    where c.source='chat_automation'
      and c.blueprint_status='blocked'
  )
  select mode,contract_id,wireframe_pack_id,design_id,idea_id,title,created_at
  from candidates
  order by priority,created_at
  limit 1
$$;

create or replace function public.danbi_compiler_checkpoint(p_contract_id uuid)
returns jsonb
language sql
security invoker
set search_path = public
as $$
  select jsonb_build_object(
    'contract_id', c.id,
    'title', c.title,
    'status', c.status,
    'blueprint_status', c.blueprint_status,
    'complete',
      c.blueprint is not null
      and c.blueprint_status in ('pending_review','approved')
      and c.blueprint_hash ~ '^[0-9a-f]{64}$'
      and coalesce(jsonb_array_length(c.blueprint_issues),0)=0
      and exists (
        select 1
        from public.danbi_blueprint_history h
        where h.contract_id=c.id
          and h.blueprint_hash=c.blueprint_hash
          and h.blueprint=c.blueprint
      ),
    'missing_parts',
      to_jsonb(array_remove(array[
        case when c.blueprint is null then 'blueprint' end,
        case when c.blueprint_status not in ('pending_review','approved') then 'pending_review_status' end,
        case when c.blueprint_hash is null or c.blueprint_hash !~ '^[0-9a-f]{64}$' then 'blueprint_hash' end,
        case when coalesce(jsonb_array_length(c.blueprint_issues),0)<>0 then 'blueprint_issues' end,
        case when not exists (
          select 1
          from public.danbi_blueprint_history h
          where h.contract_id=c.id
            and h.blueprint_hash=c.blueprint_hash
            and h.blueprint=c.blueprint
        ) then 'blueprint_history' end
      ],null))
  )
  from public.danbi_implementation_contracts c
  where c.id=p_contract_id
$$;

revoke all on function public.danbi_next_compiler_candidate() from public;
revoke all on function public.danbi_next_compiler_candidate() from anon;
revoke all on function public.danbi_next_compiler_candidate() from authenticated;
grant execute on function public.danbi_next_compiler_candidate() to postgres;

revoke all on function public.danbi_compiler_checkpoint(uuid) from public;
revoke all on function public.danbi_compiler_checkpoint(uuid) from anon;
revoke all on function public.danbi_compiler_checkpoint(uuid) from authenticated;
grant execute on function public.danbi_compiler_checkpoint(uuid) to postgres;
