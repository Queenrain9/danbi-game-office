-- Large Blueprint chunked safe write
-- Applied to Supabase project hmblaasagxyntyfrfztg on 2026-10-01.
-- Purpose: avoid giant raw SQL / tool payload serialization when storing large Fidelity Blueprints.

create table if not exists public.danbi_blueprint_write_staging (
  contract_id uuid not null references public.danbi_implementation_contracts(id) on delete cascade,
  write_id uuid not null,
  part_no integer not null check (part_no >= 0),
  payload_b64 text not null,
  created_at timestamptz not null default now(),
  primary key (write_id, part_no)
);

create index if not exists danbi_blueprint_write_staging_contract_idx
  on public.danbi_blueprint_write_staging(contract_id, write_id, part_no);

alter table public.danbi_blueprint_write_staging enable row level security;

create or replace function public.danbi_blueprint_write_begin(p_contract_id uuid,p_write_id uuid)
returns jsonb language plpgsql security definer
set search_path to 'public','extensions','pg_temp'
as $function$
declare c public.danbi_implementation_contracts%rowtype; cov jsonb;
begin
  select * into c from public.danbi_implementation_contracts where id=p_contract_id for update;
  if not found then raise exception 'contract_not_found'; end if;
  if c.blueprint_status='approved' then raise exception 'approved_contract_is_immutable'; end if;
  if c.source_coverage_version='source-coverage-v1' then
    cov := public.danbi_contract_source_coverage(c.id);
    if coalesce((cov->>'missing_count')::int,0) <> 0 then raise exception 'source_coverage_incomplete'; end if;
    if c.source_coverage is distinct from cov then raise exception 'stored_source_coverage_drift'; end if;
  end if;
  delete from public.danbi_blueprint_write_staging
  where contract_id=p_contract_id and created_at < now()-interval '24 hours';
  delete from public.danbi_blueprint_write_staging where write_id=p_write_id;
  return jsonb_build_object('ok',true,'contract_id',c.id,'write_id',p_write_id,
    'blueprint_status',c.blueprint_status,'requirement_count',c.requirement_count,'source_coverage',c.source_coverage);
end
$function$;

create or replace function public.danbi_blueprint_write_part(
  p_contract_id uuid,p_write_id uuid,p_part_no integer,p_payload_b64 text
)
returns jsonb language plpgsql security definer
set search_path to 'public','extensions','pg_temp'
as $function$
declare byte_len integer;
begin
  if p_part_no < 0 then raise exception 'invalid_part_no'; end if;
  if p_payload_b64 is null or length(p_payload_b64)=0 then raise exception 'empty_payload_chunk'; end if;
  if length(p_payload_b64) > 65536 then raise exception 'payload_chunk_too_large'; end if;
  begin byte_len := octet_length(decode(p_payload_b64,'base64'));
  exception when others then raise exception 'invalid_base64_chunk'; end;
  insert into public.danbi_blueprint_write_staging(contract_id,write_id,part_no,payload_b64,created_at)
  values(p_contract_id,p_write_id,p_part_no,p_payload_b64,now())
  on conflict(write_id,part_no) do update
    set contract_id=excluded.contract_id,payload_b64=excluded.payload_b64,created_at=excluded.created_at;
  return jsonb_build_object('ok',true,'write_id',p_write_id,'part_no',p_part_no,'decoded_bytes',byte_len);
end
$function$;

create or replace function public.danbi_blueprint_write_status(p_contract_id uuid,p_write_id uuid)
returns jsonb language sql security definer
set search_path to 'public','extensions','pg_temp'
as $function$
  select jsonb_build_object('contract_id',p_contract_id,'write_id',p_write_id,
    'part_count',count(*),'min_part',min(part_no),'max_part',max(part_no),
    'encoded_chars',coalesce(sum(length(payload_b64)),0))
  from public.danbi_blueprint_write_staging
  where contract_id=p_contract_id and write_id=p_write_id
$function$;

create or replace function public.danbi_blueprint_write_finalize(
  p_contract_id uuid,p_write_id uuid,p_expected_parts integer,p_expected_blueprint_hash text
)
returns jsonb language plpgsql security definer
set search_path to 'public','extensions','pg_temp'
as $function$
declare
  c public.danbi_implementation_contracts%rowtype;
  part_count integer; min_part integer; max_part integer;
  payload_text text; bp jsonb; computed_hash text; checkpoint jsonb;
begin
  if p_expected_parts <= 0 then raise exception 'invalid_expected_parts'; end if;
  select * into c from public.danbi_implementation_contracts where id=p_contract_id for update;
  if not found then raise exception 'contract_not_found'; end if;
  if c.blueprint_status='approved' then raise exception 'approved_contract_is_immutable'; end if;

  select count(*),min(part_no),max(part_no)
  into part_count,min_part,max_part
  from public.danbi_blueprint_write_staging
  where contract_id=p_contract_id and write_id=p_write_id;

  if part_count <> p_expected_parts or min_part <> 0 or max_part <> p_expected_parts-1 then
    raise exception 'staged_parts_incomplete';
  end if;

  select string_agg(convert_from(decode(payload_b64,'base64'),'utf8'),'' order by part_no)
  into payload_text
  from public.danbi_blueprint_write_staging
  where contract_id=p_contract_id and write_id=p_write_id;

  begin bp := payload_text::jsonb;
  exception when others then raise exception 'staged_blueprint_json_invalid'; end;

  computed_hash := public.danbi_canonical_jsonb_sha256(bp - 'blueprint_hash');
  if bp->>'blueprint_hash' is distinct from computed_hash then raise exception 'embedded_blueprint_hash_mismatch'; end if;
  if p_expected_blueprint_hash is distinct from computed_hash then raise exception 'expected_blueprint_hash_mismatch'; end if;
  if bp->>'contract_id' is distinct from c.id::text then raise exception 'contract_identity_mismatch'; end if;
  if bp->>'wireframe_pack_id' is distinct from c.wireframe_pack_id::text then raise exception 'wireframe_identity_mismatch'; end if;

  if c.source_coverage_version='source-coverage-v1' then
    if bp->>'source_coverage_version' is distinct from c.source_coverage_version then raise exception 'source_coverage_version_mismatch'; end if;
    if bp->'source_coverage' is distinct from c.source_coverage then raise exception 'source_coverage_report_mismatch'; end if;
    if coalesce(bp->'design_wireframe_notes','[]'::jsonb) is distinct from coalesce(c.design_wireframe_notes,'[]'::jsonb) then
      raise exception 'design_wireframe_notes_mismatch';
    end if;
  end if;

  update public.danbi_implementation_contracts
  set blueprint=bp,blueprint_hash=computed_hash,blueprint_status='pending_review',
      blueprint_issues='[]'::jsonb,blueprint_review=null,status='draft',updated_at=now()
  where id=c.id;

  checkpoint := public.danbi_compiler_checkpoint(c.id);
  if coalesce((checkpoint->>'complete')::boolean,false) is not true then
    raise exception 'compiler_checkpoint_incomplete_after_finalize';
  end if;

  delete from public.danbi_blueprint_write_staging
  where contract_id=p_contract_id and write_id=p_write_id;

  return jsonb_build_object('ok',true,'contract_id',c.id,'blueprint_hash',computed_hash,'checkpoint',checkpoint);
end
$function$;

create or replace function public.danbi_blueprint_write_abort(p_contract_id uuid,p_write_id uuid)
returns void language sql security definer
set search_path to 'public','extensions','pg_temp'
as $function$
  delete from public.danbi_blueprint_write_staging
  where contract_id=p_contract_id and write_id=p_write_id
$function$;

revoke all on table public.danbi_blueprint_write_staging from anon, authenticated;
revoke execute on function public.danbi_blueprint_write_begin(uuid,uuid) from public, anon, authenticated;
revoke execute on function public.danbi_blueprint_write_part(uuid,uuid,integer,text) from public, anon, authenticated;
revoke execute on function public.danbi_blueprint_write_status(uuid,uuid) from public, anon, authenticated;
revoke execute on function public.danbi_blueprint_write_finalize(uuid,uuid,integer,text) from public, anon, authenticated;
revoke execute on function public.danbi_blueprint_write_abort(uuid,uuid) from public, anon, authenticated;
grant execute on function public.danbi_blueprint_write_begin(uuid,uuid) to service_role;
grant execute on function public.danbi_blueprint_write_part(uuid,uuid,integer,text) to service_role;
grant execute on function public.danbi_blueprint_write_status(uuid,uuid) to service_role;
grant execute on function public.danbi_blueprint_write_finalize(uuid,uuid,integer,text) to service_role;
grant execute on function public.danbi_blueprint_write_abort(uuid,uuid) to service_role;
