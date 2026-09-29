"""Production adapter for approved fidelity-v1 Blueprints and static evidence.

This CLI reads exported DB rows and committed Godot files. It never changes DB
state; Builder/Gate use their own leases and existing RPCs after review.
"""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import sys

spec = importlib.util.spec_from_file_location('construction', Path(__file__).with_name('construction.py'))
construction = importlib.util.module_from_spec(spec)
spec.loader.exec_module(construction)
STAGES = construction.STAGES
VOLATILE = {'status','created_at','updated_at','source_run_at'}


def check_sources(blueprint, contract, pack, design):
    issues=[]
    def same(code, actual, expected):
        if actual != expected: issues.append({'code':code,'message':'Current DB source differs from frozen approved blueprint'})
    if contract.get('id') != blueprint.get('contract_id') or contract.get('wireframe_pack_id') != blueprint.get('wireframe_pack_id'):
        issues.append({'code':'CONTRACT_ID','message':'Contract/pack identity mismatch'})
    same('CONTRACT_REQUIREMENTS', contract.get('requirements'), blueprint.get('requirements'))
    same('PACK', {k:v for k,v in pack.items() if k not in VOLATILE}, blueprint.get('source',{}).get('pack'))
    same('DESIGN', {k:v for k,v in design.items() if k not in VOLATILE}, blueprint.get('source',{}).get('design'))
    if pack.get('design_id') != design.get('id') or contract.get('design_id') != design.get('id') or contract.get('idea_id') != pack.get('idea_id') or contract.get('idea_id') != design.get('idea_id'):
        issues.append({'code':'SOURCE_IDENTITY','message':'Current source relationship mismatch'})
    if contract.get('blueprint_hash') and contract['blueprint_hash'] != blueprint.get('blueprint_hash'):
        issues.append({'code':'BLUEPRINT_HASH','message':'DB hash mismatch'})
    return issues


def evidence_bundle(blueprint, report, artifact_file, artifact_path, role):
    """Create input for danbi_record_evidence; stage IDs are bound after RPC returns its UUID."""
    if role not in ('builder','gate'): raise ValueError('Builder or independent gate role required')
    if report.get('status') != 'passed' or report.get('errors') or report.get('blueprint_hash') != blueprint.get('blueprint_hash') or not re.fullmatch('[0-9a-f]{40}', report.get('commit') or ''):
        raise ValueError('Passing static report with matching blueprint and final commit required')
    tests = [t for t in blueprint['bindings']['tests'] if construction.is_static(t)]
    ids = [t['id'] for t in tests]
    results = report.get('results',[])
    if len(ids) != len(set(ids)) or len(results) != len(ids) or set(x.get('test_id') for x in results) != set(ids) or any(x.get('status') != 'passed' for x in results):
        raise ValueError('Exact unique passing static test coverage required')
    stages = {stage:[t['id'] for t in tests if stage=='integration' or t.get('stage')==stage] for stage in STAGES}
    if any(not v for v in stages.values()): raise ValueError('Six explicit static stage tests required')
    path=Path(artifact_path)
    if path.is_absolute() or '..' in path.parts or not path.parts or not artifact_file.is_file(): raise ValueError('Repository artifact path/file required')
    sha=hashlib.sha256(artifact_file.read_bytes()).hexdigest()
    return {'evidence_run':{
        'role':role,'kind':'static','status':'passed','commit':report['commit'],'blueprint_hash':report['blueprint_hash'],
        'test_ids':ids,'results':results,'artifacts':[{'path':path.as_posix(),'sha256':sha}],
        'environment':{'verification_scope':'static','runtime_qa_performed':False,'manual_playtest_required':True,
                       'independent_review_required':True}},
        'stage_test_ids':stages,
        'manual_test_ids':[t['id'] for t in blueprint['bindings']['tests'] if not construction.is_static(t)],
        'next':'Commit artifact outside builds/<slug> after final game commit. Record evidence via role lease; Builder records six stages with returned evidence UUID. Independent Gate reviews semantics and records its own evidence before danbi_apply_review.'}


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command',choices=['check-blueprint','check-build','bundle'])
    parser.add_argument('--blueprint',required=True);parser.add_argument('--contract');parser.add_argument('--pack');parser.add_argument('--design')
    parser.add_argument('--project');parser.add_argument('--claims');parser.add_argument('--commit')
    parser.add_argument('--report');parser.add_argument('--artifact-path');parser.add_argument('--role',choices=['builder','gate']);parser.add_argument('--output')
    a=parser.parse_args()
    read=lambda path: json.loads(Path(path).read_text())
    blueprint=read(a.blueprint)
    if a.command=='bundle':
        if not a.report or not a.artifact_path or not a.role: parser.error('bundle needs report, artifact-path and role')
        data=evidence_bundle(blueprint,read(a.report),Path(a.report),a.artifact_path,a.role)
    else:
        if not (a.contract and a.pack and a.design): parser.error('Current contract, pack and design exports are required')
        if a.command=='check-build' and not (a.project and a.claims and a.commit): parser.error('check-build requires project, claims and final commit')
        source_issues=check_sources(blueprint,read(a.contract),read(a.pack),read(a.design))
        if a.command=='check-build': construction.verify_commit(a.project,a.commit)
        data=construction.validate(blueprint,a.project if a.command=='check-build' else None,
                                   read(a.claims) if a.command=='check-build' else None,a.commit)
        data['errors'][:0]=source_issues
        data['status']='failed' if data['errors'] else 'passed'
        data['promotion_eligible']=data['status']=='passed' and a.command=='check-build'
        data['independent_semantic_review_required']=True
    serialized=json.dumps(data,ensure_ascii=False,indent=2)+'\n'
    if a.output: Path(a.output).write_text(serialized)
    else: print(serialized)
    return 0 if data.get('status','passed')=='passed' else 1


if __name__=='__main__':
    try: sys.exit(main())
    except (ValueError,TypeError,KeyError,OSError) as exc:
        print(json.dumps({'status':'blocked','error':str(exc)}),file=sys.stderr);sys.exit(2)
