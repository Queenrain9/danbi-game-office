-- Applied via Supabase apply_migration: playtest_ready_static_fidelity_v2.
-- Additive metadata; existing game states and evidence are not rewritten.
ALTER TABLE public.danbi_build_jobs ADD COLUMN IF NOT EXISTS verification_scope text NOT NULL DEFAULT 'legacy_unknown';
ALTER TABLE public.danbi_build_jobs ADD COLUMN IF NOT EXISTS runtime_qa_performed boolean NOT NULL DEFAULT false;
ALTER TABLE public.danbi_build_jobs ADD COLUMN IF NOT EXISTS manual_playtest_required boolean NOT NULL DEFAULT true;
ALTER TABLE public.danbi_fidelity_reviews ADD COLUMN IF NOT EXISTS verification_scope text NOT NULL DEFAULT 'legacy_unknown';
ALTER TABLE public.danbi_fidelity_reviews ADD COLUMN IF NOT EXISTS manual_test_ids jsonb NOT NULL DEFAULT '[]';
COMMENT ON COLUMN public.danbi_build_jobs.status IS 'qa_ready and playtest_ready mean ready for human Godot/Xogot playtest, never runtime QA completion; inspect verification_scope for legacy rows.';
CREATE OR REPLACE FUNCTION public.danbi_is_static_test(t jsonb) RETURNS boolean
LANGUAGE sql IMMUTABLE SET search_path TO public, pg_temp AS $$
 SELECT coalesce(t->>'verification_scope',case when t->>'kind'='static' then 'static' else 'manual_playtest' end)='static'
$$;
CREATE OR REPLACE FUNCTION public.danbi_assert_build_source(j public.danbi_build_jobs) RETURNS void
LANGUAGE plpgsql SET search_path TO public, pg_temp AS $$
DECLARE c danbi_implementation_contracts; p jsonb; d jsonb;
BEGIN
 SELECT * INTO c FROM danbi_implementation_contracts WHERE id=j.contract_id;
 IF c.id IS NULL OR c.blueprint_status IS DISTINCT FROM 'approved' OR j.blueprint_hash IS DISTINCT FROM c.blueprint_hash OR c.blueprint_hash IS NULL THEN RAISE EXCEPTION 'Approved current blueprint required'; END IF;
 IF j.wireframe_pack_id IS DISTINCT FROM c.wireframe_pack_id OR j.design_id IS DISTINCT FROM c.design_id OR j.idea_id IS DISTINCT FROM c.idea_id THEN RAISE EXCEPTION 'Build/contract/source identity mismatch'; END IF;
 SELECT to_jsonb(w)-array['status','created_at','updated_at','source_run_at'] INTO p FROM danbi_wireframe_packs w WHERE id=c.wireframe_pack_id;
 SELECT to_jsonb(g)-array['status','created_at','updated_at','source_run_at'] INTO d FROM danbi_game_designs g WHERE id=c.design_id;
 IF p IS NULL OR d IS NULL OR p->>'design_id' IS DISTINCT FROM c.design_id::text OR p->>'idea_id' IS DISTINCT FROM c.idea_id::text OR d->>'idea_id' IS DISTINCT FROM c.idea_id::text OR c.blueprint#>'{source,pack}' IS DISTINCT FROM p OR c.blueprint#>'{source,design}' IS DISTINCT FROM d OR c.blueprint->'requirements' IS DISTINCT FROM c.requirements THEN RAISE EXCEPTION 'Blueprint source drift'; END IF;
END $$;
CREATE OR REPLACE FUNCTION public.danbi_assert_claims(j public.danbi_build_jobs) RETURNS void
LANGUAGE plpgsql SET search_path TO public, pg_temp AS $$
DECLARE c danbi_implementation_contracts; claims jsonb; r jsonb;
BEGIN
 SELECT * INTO c FROM danbi_implementation_contracts WHERE id=j.contract_id;
 SELECT e.claims INTO claims FROM danbi_build_implementation_evidence e WHERE e.build_job_id=j.id AND e.contract_id=c.id;
 IF jsonb_typeof(claims) IS DISTINCT FROM 'array' OR jsonb_array_length(claims)<>jsonb_array_length(c.requirements) OR jsonb_array_length(claims)=0 OR (SELECT count(DISTINCT x->>'requirement_id') FROM jsonb_array_elements(claims)x)<>jsonb_array_length(claims) THEN RAISE EXCEPTION 'Exact unique implementation claims required'; END IF;
 FOR r IN SELECT * FROM jsonb_array_elements(claims) LOOP
  IF NOT EXISTS(SELECT 1 FROM jsonb_array_elements(c.requirements)x WHERE x->>'id'=r->>'requirement_id') OR r->>'status' IS DISTINCT FROM 'IMPLEMENTED' OR r->>'commit' IS DISTINCT FROM j.last_commit OR r->>'blueprint_hash' IS DISTINCT FROM j.blueprint_hash OR jsonb_typeof(r->'implementation_refs') IS DISTINCT FROM 'array' OR jsonb_array_length(r->'implementation_refs')=0 THEN RAISE EXCEPTION 'Missing/stale implementation claim'; END IF;
  IF EXISTS(SELECT 1 FROM jsonb_array_elements(r->'implementation_refs')x WHERE coalesce(x->>'file','') !~ '^res://[^.].*' OR coalesce(x->>'file','') ~ '(^|/)\.\.(/|$)' OR (coalesce(x->>'node_path','')='' AND coalesce(x->>'symbol','')='')) THEN RAISE EXCEPTION 'Implementation file and node/symbol required'; END IF;
 END LOOP;
END $$;
CREATE OR REPLACE FUNCTION public.danbi_contract_blueprint_guard()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare v_pack jsonb; v_design jsonb; v_oldhash text;
begin
 if tg_op='UPDATE' then v_oldhash=old.blueprint_hash; end if;
 if new.blueprint is null then
  new.blueprint_status='missing'; new.blueprint_hash=null; new.blueprint_review=null; return new;
 end if;
 if new.blueprint->>'schema_version' is distinct from 'fidelity-v1' or new.blueprint->>'contract_id' is distinct from new.id::text or new.blueprint->>'wireframe_pack_id' is distinct from new.wireframe_pack_id::text then raise exception 'Blueprint identity mismatch'; end if;
 if new.blueprint_hash is distinct from new.blueprint->>'blueprint_hash' or new.blueprint_hash !~ '^[0-9a-f]{64}$' then raise exception 'Blueprint hash missing/mismatch'; end if;
 select to_jsonb(w)-array['status','created_at','updated_at','source_run_at'] into v_pack from danbi_wireframe_packs w where id=new.wireframe_pack_id;
 select to_jsonb(d)-array['status','created_at','updated_at','source_run_at'] into v_design from danbi_game_designs d where id=new.design_id;
 if new.blueprint#>'{source,pack}' is distinct from v_pack or new.blueprint#>'{source,design}' is distinct from v_design or new.blueprint#>'{source,requirements}' is distinct from new.requirements or new.blueprint->'screens' is distinct from v_pack->'screens' or new.blueprint->'requirements' is distinct from new.requirements then raise exception 'Blueprint source drift'; end if;
 if tg_op='UPDATE' and new.blueprint is distinct from old.blueprint and new.blueprint_hash is not distinct from old.blueprint_hash then raise exception 'Changed blueprint must receive a new hash'; end if;
 if v_oldhash is distinct from new.blueprint_hash then
  new.blueprint_review=null;
  if new.blueprint_status='approved' then raise exception 'Changed blueprint requires independent review'; end if;
  insert into danbi_blueprint_history(contract_id,blueprint_hash,blueprint) values(new.id,new.blueprint_hash,new.blueprint) on conflict do nothing;
 end if;
 if new.blueprint_status='approved' then
  if jsonb_typeof(new.requirements) is distinct from 'array' or jsonb_array_length(new.requirements)=0 or (select count(distinct x->>'id') from jsonb_array_elements(new.requirements)x where coalesce(x->>'id','')<>'')<>jsonb_array_length(new.requirements) then raise exception 'Unique nonempty requirements required'; end if;
  if jsonb_typeof(new.blueprint#>'{bindings,tests}') is distinct from 'array' or (select count(distinct x->>'id') from jsonb_array_elements(new.blueprint#>'{bindings,tests}')x where coalesce(x->>'id','')<>'')<>jsonb_array_length(new.blueprint#>'{bindings,tests}') then raise exception 'Unique test IDs required'; end if;
  if exists(select 1 from jsonb_array_elements(new.requirements)r where not exists(select 1 from jsonb_array_elements(new.blueprint#>'{bindings,tests}')t where danbi_is_static_test(t) and (t->'requirement_ids') ? (r->>'id'))) then raise exception 'Each requirement needs static implementation verification; runtime tests remain manual'; end if;
  if new.blueprint_issues<>'[]'::jsonb or coalesce(new.blueprint_review->>'role','')<>'gate' or new.blueprint_review->>'blueprint_hash' is distinct from new.blueprint_hash then raise exception 'Independent blueprint approval required'; end if;
  if tg_op='INSERT' or old.blueprint_status<>'approved' then
   if coalesce(current_setting('danbi.operation',true),'')<>'approve_blueprint' then raise exception 'Use danbi_approve_blueprint'; end if;
  end if;
 end if;
 return new;
end $function$;

CREATE OR REPLACE FUNCTION public.danbi_job_promotion_guard() RETURNS trigger
LANGUAGE plpgsql SET search_path TO public, pg_temp AS $$
DECLARE n int;
BEGIN
 IF new.status IN ('building','fidelity_pending','qa_ready','playtest_ready') AND
 (tg_op='INSERT' OR new.status IS DISTINCT FROM old.status OR new.last_commit IS DISTINCT FROM old.last_commit OR new.blueprint_hash IS DISTINCT FROM old.blueprint_hash OR new.contract_id IS DISTINCT FROM old.contract_id OR new.wireframe_pack_id IS DISTINCT FROM old.wireframe_pack_id OR new.design_id IS DISTINCT FROM old.design_id OR new.idea_id IS DISTINCT FROM old.idea_id OR new.fidelity_status IS DISTINCT FROM old.fidelity_status OR new.blockers IS DISTINCT FROM old.blockers OR new.verification_scope IS DISTINCT FROM old.verification_scope) THEN
  PERFORM danbi_assert_build_source(new);
  IF new.status<>'building' THEN
   IF coalesce(new.last_commit,'') !~ '^[0-9a-f]{40}$' THEN RAISE EXCEPTION 'Final commit SHA required'; END IF;
   IF new.blockers IS DISTINCT FROM '[]'::jsonb THEN RAISE EXCEPTION 'Static blockers remain'; END IF;
   PERFORM danbi_assert_claims(new);
   SELECT count(DISTINCT stage) INTO n FROM danbi_build_stage_runs WHERE build_job_id=new.id AND blueprint_hash=new.blueprint_hash AND commit_sha=new.last_commit AND status='passed' AND detail->>'verification_scope'='static';
   IF n<>6 THEN RAISE EXCEPTION 'All six static stages must pass at submitted commit'; END IF;
   IF new.status IN ('qa_ready','playtest_ready') THEN
    IF coalesce(current_setting('danbi.operation',true),'')<>'apply_review' OR NOT EXISTS(SELECT 1 FROM danbi_fidelity_reviews WHERE build_job_id=new.id AND contract_id=new.contract_id AND reviewed_commit=new.last_commit AND blueprint_hash=new.blueprint_hash AND verdict='pass' AND status='complete' AND verification_scope='static') THEN RAISE EXCEPTION 'Only matching independent static review may promote PLAYTEST READY'; END IF;
    new.verification_scope='static'; new.runtime_qa_performed=false; new.manual_playtest_required=true;
   END IF;
  END IF;
 END IF;
 RETURN new;
END $$;

CREATE OR REPLACE FUNCTION public.danbi_record_evidence(p_job uuid, p_token uuid, p_run jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare v uuid; j danbi_build_jobs; c danbi_implementation_contracts;
begin
 perform danbi_assert_lease(p_run->>'role',p_token);
 if coalesce(p_run->>'role','') not in ('builder','gate') then raise exception 'Evidence role required'; end if;
 select * into j from danbi_build_jobs where id=p_job for update;
 select * into c from danbi_implementation_contracts where id=j.contract_id;
 if c.blueprint_status is distinct from 'approved' or p_run->>'blueprint_hash' is distinct from c.blueprint_hash or p_run->>'commit' is distinct from j.last_commit then raise exception 'Stale evidence'; end if;
 perform danbi_assert_build_source(j);
 if coalesce(j.last_commit,'') !~ '^[0-9a-f]{40}$' then raise exception 'Final commit SHA required'; end if;
 if jsonb_typeof(p_run->'results') is distinct from 'array' or jsonb_typeof(p_run->'artifacts') is distinct from 'array' then raise exception 'Results and artifact manifest required'; end if;
 if p_run->>'status'='passed' then
  if jsonb_typeof(p_run->'test_ids') is distinct from 'array' or jsonb_array_length(p_run->'results')=0 or jsonb_array_length(p_run->'artifacts')=0 then raise exception 'Empty evidence cannot pass'; end if;
  if jsonb_array_length(p_run->'test_ids')<>jsonb_array_length(p_run->'results') or (select count(distinct x#>>'{}') from jsonb_array_elements(p_run->'test_ids')x)<>jsonb_array_length(p_run->'test_ids') or (select count(distinct x->>'test_id') from jsonb_array_elements(p_run->'results')x)<>jsonb_array_length(p_run->'results') then raise exception 'Duplicate or unmatched evidence test IDs'; end if;
  if exists(select 1 from jsonb_array_elements(p_run->'results') x where coalesce(x->>'status','')<>'passed' or not (p_run->'test_ids') ? (x->>'test_id') or not exists(select 1 from jsonb_array_elements(c.blueprint#>'{bindings,tests}')t where t->>'id'=x->>'test_id')) then raise exception 'Contradictory or unknown test result'; end if;
  if p_run->>'kind'='static' and exists(select 1 from jsonb_array_elements(c.blueprint#>'{bindings,tests}')t where (p_run->'test_ids') ? (t->>'id') and not danbi_is_static_test(t)) then raise exception 'Manual/runtime test cannot be reported as static passed'; end if;
  if exists(select 1 from jsonb_array_elements(p_run->'artifacts') a where coalesce(length(a->>'path'),0)=0 or coalesce(a->>'sha256','') !~ '^[0-9a-f]{64}$') then raise exception 'Artifact path and SHA256 required'; end if;
 end if;
 insert into danbi_evidence_runs(build_job_id,blueprint_hash,commit_sha,role,kind,status,test_ids,results,artifacts,environment)
 values(p_job,c.blueprint_hash,j.last_commit,p_run->>'role',p_run->>'kind',p_run->>'status',array(select jsonb_array_elements_text(p_run->'test_ids')),p_run->'results',p_run->'artifacts',coalesce(p_run->'environment','{}')) returning id into v;
 return v;
end $function$;

CREATE OR REPLACE FUNCTION public.danbi_record_stage(p_job uuid, p_token uuid, p_stage text, p_status text, p_evidence uuid[], p_detail jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare t jsonb; stages text[]=array['skeleton','geometry','state','input','presentation','integration']; n int; j danbi_build_jobs; c danbi_implementation_contracts;
begin
 perform danbi_assert_lease('builder',p_token);
 n=array_position(stages,p_stage);if n is null then raise exception 'Invalid stage'; end if;
 select * into j from danbi_build_jobs where id=p_job for update;
 select * into c from danbi_implementation_contracts where id=j.contract_id;
 if c.blueprint_status is distinct from 'approved' or j.blueprint_hash is distinct from c.blueprint_hash or coalesce(j.last_commit,'') !~ '^[0-9a-f]{40}$' then raise exception 'Approved blueprint and committed code required'; end if;
 perform danbi_assert_build_source(j);
 if p_status='passed' then
  if n>1 and exists(select 1 from unnest(stages[1:n-1]) s where not exists(select 1 from danbi_build_stage_runs r where r.build_job_id=j.id and r.blueprint_hash=c.blueprint_hash and r.commit_sha=j.last_commit and r.stage=s and r.status='passed')) then raise exception 'Preceding stages must pass at this commit'; end if;
  if coalesce(cardinality(p_evidence),0)=0 or exists(select 1 from unnest(p_evidence) e where not exists(select 1 from danbi_evidence_runs r where r.id=e and r.build_job_id=j.id and r.blueprint_hash=c.blueprint_hash and r.commit_sha=j.last_commit and r.role='builder' and r.status='passed' and r.kind='static')) then raise exception 'Matching stage evidence required'; end if;
  -- Only static construction tests gate automation. Runtime obligations stay manual.
  if not exists(select 1 from jsonb_array_elements(c.blueprint#>'{bindings,tests}')x where danbi_is_static_test(x) and (p_stage='integration' or coalesce(x->>'stage',case when x->>'kind'='static' then 'skeleton' else x->>'kind' end)=p_stage)) then raise exception 'Stage needs an explicit static test'; end if;
  for t in select * from jsonb_array_elements(c.blueprint#>'{bindings,tests}') x
   where danbi_is_static_test(x) and (p_stage='integration' or coalesce(x->>'stage',case when x->>'kind'='static' then 'skeleton' else x->>'kind' end)=p_stage)
  loop
   if not exists(select 1 from danbi_evidence_runs e where e.id=any(p_evidence) and t->>'id'=any(e.test_ids)) then raise exception 'Stage test missing: %',t->>'id'; end if;
  end loop;
 end if;
 insert into danbi_build_stage_runs(build_job_id,blueprint_hash,commit_sha,stage,status,evidence_ids,detail) values(j.id,c.blueprint_hash,j.last_commit,p_stage,p_status,p_evidence,coalesce(p_detail,'{}')||jsonb_build_object('verification_scope','static','runtime_qa_performed',false,'manual_playtest_required',true))
 on conflict(build_job_id,blueprint_hash,commit_sha,stage) do update set status=excluded.status,evidence_ids=excluded.evidence_ids,detail=excluded.detail,created_at=now();
 update danbi_build_jobs set pipeline_stage=p_stage,stage_evidence=stage_evidence||jsonb_build_object(p_stage,jsonb_build_object('status',p_status,'commit',j.last_commit,'blueprint_hash',c.blueprint_hash,'evidence_ids',p_evidence)) where id=j.id;
end $function$;

CREATE OR REPLACE FUNCTION public.danbi_apply_review(p_job uuid, p_token uuid, p_commit text, p_hash text, p_results jsonb, p_summary text, p_groups jsonb DEFAULT '[]'::jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare j danbi_build_jobs; c danbi_implementation_contracts; r jsonb; t jsonb; v_id uuid; v_verdict text; v_round int; v_bad int; v_unknown int; v_ambiguous int; v_good int; g jsonb; seen text[]='{}';
begin
 perform danbi_assert_lease('gate',p_token);
 select * into j from danbi_build_jobs where id=p_job for update;
 select * into c from danbi_implementation_contracts where id=j.contract_id;
 perform danbi_assert_build_source(j);
 perform danbi_assert_claims(j);
 if j.status is distinct from 'fidelity_pending' or j.last_commit is distinct from p_commit or c.blueprint_hash is distinct from p_hash or c.blueprint_status<>'approved' or j.blueprint_hash is distinct from p_hash then raise exception 'Stale or ineligible review'; end if;
 if jsonb_typeof(p_results) is distinct from 'array' or jsonb_array_length(p_results)<>jsonb_array_length(c.requirements) or jsonb_array_length(p_results)=0 then raise exception 'Exact complete requirement coverage required'; end if;
 if (select count(distinct x->>'requirement_id') from jsonb_array_elements(p_results)x)<>jsonb_array_length(c.requirements) then raise exception 'Duplicate requirement result'; end if;
 for r in select * from jsonb_array_elements(p_results) loop
  if not exists(select 1 from jsonb_array_elements(c.requirements)x where x->>'id'=r->>'requirement_id') or coalesce(r->>'verdict','') not in ('VERIFIED','PARTIAL','MISSING','CONFLICT','BROKEN','BLOCKED','INCONCLUSIVE','SPEC_AMBIGUOUS') then raise exception 'Invalid requirement/verdict'; end if;
  if r->>'verdict'='VERIFIED' then
   if not exists(select 1 from jsonb_array_elements(c.blueprint#>'{bindings,tests}')x where danbi_is_static_test(x) and (x->'requirement_ids') ? (r->>'requirement_id')) then raise exception 'Requirement has no tests'; end if;
   for t in select * from jsonb_array_elements(c.blueprint#>'{bindings,tests}')x where danbi_is_static_test(x) and (x->'requirement_ids') ? (r->>'requirement_id') loop
    if not exists(select 1 from danbi_evidence_runs e where e.id::text in (select jsonb_array_elements_text(coalesce(r->'evidence_ids','[]'))) and e.build_job_id=j.id and e.commit_sha=p_commit and e.blueprint_hash=p_hash and e.role='gate' and e.status='passed' and t->>'id'=any(e.test_ids) and e.kind='static') then raise exception 'VERIFIED lacks independent matching test evidence: %',r->>'requirement_id'; end if;
   end loop;
  elsif r->>'verdict' in ('PARTIAL','MISSING','CONFLICT','BROKEN') then
   if coalesce(length(r->>'expected'),0)=0 or coalesce(length(r->>'observed'),0)=0 or coalesce(length(r->>'rationale'),0)=0 then raise exception 'Defect needs expected, observed and rationale'; end if;
  end if;
 end loop;
 if jsonb_typeof(p_groups) is distinct from 'array' then raise exception 'Repair groups must be an ordered array'; end if;
 for g in select * from jsonb_array_elements(p_groups) loop
  if coalesce(length(g->>'id'),0)=0 or g->>'id'=any(seen) or jsonb_typeof(g->'depends_on') is distinct from 'array' or jsonb_typeof(g->'requirement_ids') is distinct from 'array' then raise exception 'Invalid or duplicate repair group'; end if;
  if exists(select 1 from jsonb_array_elements_text(g->'depends_on')d where not d=any(seen)) then raise exception 'Repair dependencies must precede dependents (no cycles/unknown refs)'; end if;
  if exists(select 1 from jsonb_array_elements_text(g->'requirement_ids')id where not exists(select 1 from jsonb_array_elements(p_results)x where x->>'requirement_id'=id and x->>'verdict' in ('PARTIAL','MISSING','CONFLICT','BROKEN') and x->>'repair_group'=g->>'id')) then raise exception 'Repair group contains unrelated requirement'; end if;
  seen=array_append(seen,g->>'id');
 end loop;
 if exists(select 1 from jsonb_array_elements(p_results)x where x->>'verdict' in ('PARTIAL','MISSING','CONFLICT','BROKEN') and not exists(select 1 from jsonb_array_elements(p_groups)grp where grp->>'id'=x->>'repair_group' and (grp->'requirement_ids') ? (x->>'requirement_id'))) then raise exception 'Every confirmed defect needs a repair group'; end if;
 select count(*) filter(where x->>'verdict'='VERIFIED'),count(*) filter(where x->>'verdict' in ('PARTIAL','MISSING','CONFLICT','BROKEN')),count(*) filter(where x->>'verdict' in ('BLOCKED','INCONCLUSIVE')),count(*) filter(where x->>'verdict'='SPEC_AMBIGUOUS') into v_good,v_bad,v_unknown,v_ambiguous from jsonb_array_elements(p_results)x;
 v_verdict=case when v_bad>0 then 'fail' when v_ambiguous>0 then 'spec_blocked' when v_unknown>0 then 'inconclusive' else 'pass' end;
 select coalesce(max(review_round),0)+1 into v_round from danbi_fidelity_reviews where build_job_id=j.id;
 insert into danbi_fidelity_reviews(build_job_id,contract_id,review_round,status,verdict,results,verified_count,partial_count,missing_count,conflict_count,broken_count,blocked_count,inconclusive_count,ambiguous_count,review_summary,reviewed_commit,blueprint_hash,source_run_at,completed_at,verification_scope,manual_test_ids)
 select j.id,c.id,v_round,'complete',v_verdict,p_results,v_good,
 count(*) filter(where x->>'verdict'='PARTIAL'),count(*) filter(where x->>'verdict'='MISSING'),count(*) filter(where x->>'verdict'='CONFLICT'),count(*) filter(where x->>'verdict'='BROKEN'),count(*) filter(where x->>'verdict'='BLOCKED'),count(*) filter(where x->>'verdict'='INCONCLUSIVE'),v_ambiguous,p_summary,p_commit,p_hash,now(),now(),'static',(select coalesce(jsonb_agg(x->>'id'),'[]') from jsonb_array_elements(c.blueprint#>'{bindings,tests}')x where not danbi_is_static_test(x)) from jsonb_array_elements(p_results)x returning id into v_id;
 for r in select * from jsonb_array_elements(p_results) loop
  if r->>'verdict'='VERIFIED' then
   update danbi_repair_tickets set status='verified',last_review_id=v_id,updated_at=now() where build_job_id=j.id and requirement_id=r->>'requirement_id' and status in ('open','fixed');
  elsif r->>'verdict' in ('PARTIAL','MISSING','CONFLICT','BROKEN') then
   update danbi_repair_tickets set status='open',verdict=r->>'verdict',expected=r->>'expected',observed=r->>'observed',detail=r->>'rationale',last_review_id=v_id,repair_group=r->>'repair_group',depends_on=array(select jsonb_array_elements_text(coalesce(r->'depends_on','[]'))),updated_at=now() where build_job_id=j.id and requirement_id=r->>'requirement_id' and status in ('open','fixed','verified');
   if not found then insert into danbi_repair_tickets(build_job_id,fidelity_review_id,last_review_id,contract_id,requirement_id,verdict,title,detail,expected,observed,repair_group,depends_on) values(j.id,v_id,v_id,c.id,r->>'requirement_id',r->>'verdict',coalesce(r->>'title',r->>'requirement_id'),r->>'rationale',r->>'expected',r->>'observed',r->>'repair_group',array(select jsonb_array_elements_text(coalesce(r->'depends_on','[]'))));end if;
  end if;
 end loop;
 if p_groups<>'[]'::jsonb then insert into danbi_repair_plans(build_job_id,review_id,groups)values(j.id,v_id,p_groups);end if;
 perform set_config('danbi.operation','apply_review',true);
 update danbi_build_jobs set verification_scope='static',runtime_qa_performed=false,manual_playtest_required=true,status=case when v_verdict='pass' then 'playtest_ready' when v_verdict='fail' then 'repair' else 'blocked' end,fidelity_status=case when v_verdict='pass' then 'passed' else 'failed' end,qa_round=qa_round+1,progress=case when v_verdict='pass' then 100 else progress end,build_summary=p_summary,blockers=case when v_verdict in ('inconclusive','spec_blocked') then jsonb_build_array(jsonb_build_object('kind',v_verdict,'review_id',v_id)) else '[]'::jsonb end where id=j.id;
 update danbi_implementation_contracts set status=case when v_verdict='pass' then 'verified' when v_verdict='fail' then 'repair' else status end where id=c.id;
 return v_id;
end $function$;
REVOKE ALL ON FUNCTION public.danbi_is_static_test(jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.danbi_is_static_test(jsonb) TO service_role;
REVOKE ALL ON FUNCTION public.danbi_assert_build_source(public.danbi_build_jobs) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.danbi_assert_build_source(public.danbi_build_jobs) TO service_role;
REVOKE ALL ON FUNCTION public.danbi_assert_claims(public.danbi_build_jobs) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.danbi_assert_claims(public.danbi_build_jobs) TO service_role;
