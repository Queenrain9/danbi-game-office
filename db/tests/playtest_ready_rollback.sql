-- Run as the migration/service role. Every fixture mutation is rolled back.
BEGIN;
DO $$
DECLARE c danbi_implementation_contracts; j uuid:=gen_random_uuid(); token uuid; bp jsonb; ts jsonb; ev uuid; gev uuid; rid uuid; run jsonb; v_claims jsonb; st text; hit boolean; h text:=repeat('a',64); sha text:=repeat('b',40); res jsonb;
BEGIN
 SELECT * INTO c FROM danbi_implementation_contracts WHERE title='Midnight Lost Property';
 IF c.id IS NULL THEN RAISE EXCEPTION 'Audit fixture source unavailable'; END IF;
 token:=danbi_acquire_lease('gate','playtest-compatibility-rollback-test');
 IF token IS NULL THEN RAISE EXCEPTION 'Pipeline busy; retry test after current lease'; END IF;
 SELECT jsonb_agg(jsonb_build_object('id','static:'||s,'kind','static','stage',s,'requirement_ids',jsonb_build_array('R1'))) INTO ts FROM unnest(array['skeleton','geometry','state','input','presentation','integration'])s;
 ts:=ts||jsonb_build_array(jsonb_build_object('id','manual:feel','kind','runtime','requirement_ids',jsonb_build_array('R1')));
 bp:=jsonb_build_object('schema_version','fidelity-v1','contract_id',c.id,'wireframe_pack_id',c.wireframe_pack_id,'blueprint_hash',h,'requirements',jsonb_build_array(jsonb_build_object('id','R1')),'screens',(select screens from danbi_wireframe_packs where id=c.wireframe_pack_id),'source',jsonb_build_object('pack',(select to_jsonb(w)-array['status','created_at','updated_at','source_run_at'] from danbi_wireframe_packs w where id=c.wireframe_pack_id),'design',(select to_jsonb(d)-array['status','created_at','updated_at','source_run_at'] from danbi_game_designs d where id=c.design_id),'requirements',jsonb_build_array(jsonb_build_object('id','R1'))),'bindings',jsonb_build_object('tests',ts));
 UPDATE danbi_implementation_contracts SET requirements=bp->'requirements',requirement_count=1,blueprint=bp,blueprint_hash=h,blueprint_status='pending_review',blueprint_issues='[]' WHERE id=c.id;
 INSERT INTO danbi_build_jobs(id,wireframe_pack_id,design_id,idea_id,contract_id,title,slug,last_commit,blueprint_hash,project_path) VALUES(j,c.wireframe_pack_id,c.design_id,c.idea_id,c.id,'rollback fixture','rollback-fixture',sha,h,'builds/rollback-fixture');
 hit:=false; BEGIN UPDATE danbi_build_jobs SET status='building' WHERE id=j; EXCEPTION WHEN OTHERS THEN IF sqlerrm NOT LIKE '%Approved current blueprint%' THEN RAISE; END IF; hit:=true; END; IF NOT hit THEN RAISE EXCEPTION 'Unapproved build accepted'; END IF;
 hit:=false; BEGIN UPDATE danbi_build_jobs SET status='playtest_ready' WHERE id=j; EXCEPTION WHEN OTHERS THEN hit:=true; END; IF NOT hit THEN RAISE EXCEPTION 'Unguarded playtest promotion'; END IF;
 PERFORM danbi_approve_blueprint(c.id,h,token,'{"source_checked":true,"validator_passed":true,"evidence_path":"rollback/report.json"}');
 PERFORM danbi_release_lease(token);
 token:=danbi_acquire_lease('builder','playtest-compatibility-rollback-test');
 UPDATE danbi_build_jobs SET status='building' WHERE id=j;
 hit:=false; BEGIN UPDATE danbi_build_jobs SET blueprint_hash=repeat('c',64) WHERE id=j; EXCEPTION WHEN OTHERS THEN hit:=true; END; IF NOT hit THEN RAISE EXCEPTION 'Stale blueprint accepted'; END IF;
 v_claims:=jsonb_build_array(jsonb_build_object('requirement_id','R1','status','IMPLEMENTED','commit',sha,'blueprint_hash',h,'implementation_refs',jsonb_build_array(jsonb_build_object('file','res://main.tscn','node_path','/root/AppRoot'))));
 INSERT INTO danbi_build_implementation_evidence(build_job_id,contract_id,claims) VALUES(j,c.id,v_claims);
 SELECT jsonb_build_object('role','builder','kind','static','status','passed','commit',sha,'blueprint_hash',h,'test_ids',jsonb_agg(t->>'id'),'results',jsonb_agg(jsonb_build_object('test_id',t->>'id','status','passed')),'artifacts',jsonb_build_array(jsonb_build_object('path','audit/static.json','sha256',h))) INTO run FROM jsonb_array_elements(ts)t WHERE danbi_is_static_test(t);
 ev:=danbi_record_evidence(j,token,run);
 hit:=false; BEGIN PERFORM danbi_record_evidence(j,token,run||'{"test_ids":["manual:feel"],"results":[{"test_id":"manual:feel","status":"passed"}]}'); EXCEPTION WHEN OTHERS THEN IF sqlerrm NOT LIKE '%Manual/runtime%' THEN RAISE; END IF; hit:=true; END; IF NOT hit THEN RAISE EXCEPTION 'Runtime test laundered as static'; END IF;
 FOREACH st IN ARRAY array['skeleton','geometry','state','input','presentation','integration'] LOOP
  PERFORM danbi_record_stage(j,token,st,'passed',array[ev],'{}');
 END LOOP;
 UPDATE danbi_build_implementation_evidence SET claims=v_claims||v_claims WHERE build_job_id=j;
 hit:=false; BEGIN UPDATE danbi_build_jobs SET status='fidelity_pending' WHERE id=j; EXCEPTION WHEN OTHERS THEN IF sqlerrm NOT LIKE '%Exact unique%' THEN RAISE; END IF; hit:=true; END; IF NOT hit THEN RAISE EXCEPTION 'Duplicate claims accepted'; END IF;
 UPDATE danbi_build_implementation_evidence e SET claims=v_claims WHERE build_job_id=j;
 UPDATE danbi_build_jobs SET status='fidelity_pending' WHERE id=j;
 PERFORM danbi_release_lease(token); token:=danbi_acquire_lease('gate','playtest-compatibility-rollback-test');
 res:=jsonb_build_array(jsonb_build_object('requirement_id','R1','verdict','VERIFIED','evidence_ids',jsonb_build_array(ev)));
 hit:=false; BEGIN PERFORM danbi_apply_review(j,token,sha,h,res,'fixture','[]'); EXCEPTION WHEN OTHERS THEN IF sqlerrm NOT LIKE '%independent matching test evidence%' THEN RAISE; END IF; hit:=true; END; IF NOT hit THEN RAISE EXCEPTION 'Builder self verification accepted'; END IF;
 gev:=danbi_record_evidence(j,token,run||'{"role":"gate"}');
 res:=jsonb_build_array(jsonb_build_object('requirement_id','R1','verdict','VERIFIED','evidence_ids',jsonb_build_array(gev)));
 rid:=danbi_apply_review(j,token,sha,h,res,'Static fixture passed; manual feel not executed','[]');
 IF NOT EXISTS(SELECT 1 FROM danbi_build_jobs WHERE id=j AND status='playtest_ready' AND verification_scope='static' AND NOT runtime_qa_performed AND manual_playtest_required) THEN RAISE EXCEPTION 'Static-only path did not reach PLAYTEST READY'; END IF;
 IF NOT EXISTS(SELECT 1 FROM danbi_fidelity_reviews WHERE id=rid AND manual_test_ids='["manual:feel"]') THEN RAISE EXCEPTION 'Manual obligation lost'; END IF;
 -- Regression after source edits must be rejected even with the same stored hash.
 UPDATE danbi_game_designs SET one_line=one_line||' changed' WHERE id=c.design_id;
 hit:=false; BEGIN UPDATE danbi_build_jobs SET status='fidelity_pending' WHERE id=j; EXCEPTION WHEN OTHERS THEN IF sqlerrm NOT LIKE '%source drift%' THEN RAISE; END IF; hit:=true; END; IF NOT hit THEN RAISE EXCEPTION 'Source drift accepted'; END IF;
END $$;
SELECT 'PASS: static-only stages and independent gate; approval/hash/coverage/manual/source protections' AS result;
ROLLBACK;
