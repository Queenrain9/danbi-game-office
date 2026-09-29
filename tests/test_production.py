import hashlib
import importlib.util
import json
import pathlib
import subprocess
import sys
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location('production', ROOT/'tools/fidelity/production.py')
p = importlib.util.module_from_spec(SPEC)


class ProductionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        SPEC.loader.exec_module(p)

    def test_source_boundary_rejects_changed_contract(self):
        from test_fidelity import FidelityTests
        b=FidelityTests().fixture()
        contract={'id':'contract','wireframe_pack_id':'pack','requirements':[{'id':'wrong'}]}
        pack=b['source']['pack']; design=b['source']['design']
        self.assertIn('CONTRACT_REQUIREMENTS', {e['code'] for e in p.check_sources(b,contract,pack,design)})

    def test_evidence_bundle_uses_independent_static_results_and_real_artifact_digest(self):
        from test_fidelity import FidelityTests
        b=FidelityTests().fixture()
        with tempfile.TemporaryDirectory() as d:
            artifact=pathlib.Path(d)/'report.json'
            report={'status':'passed','errors':[],'commit':'a'*40,'blueprint_hash':b['blueprint_hash'],
                    'results':[{'test_id':t['id'],'status':'passed'} for t in b['bindings']['tests'] if t['kind']=='static']}
            artifact.write_text(json.dumps(report))
            result=p.evidence_bundle(b,report,artifact,'production/evidence/report.json','builder')
            run=result['evidence_run']
            self.assertEqual(run['kind'],'static')
            self.assertEqual(run['artifacts'][0]['sha256'],hashlib.sha256(artifact.read_bytes()).hexdigest())
            self.assertEqual(set(result['stage_test_ids']),set(p.STAGES))
            self.assertEqual(set(result['stage_test_ids']['integration']),set(run['test_ids']))
            self.assertEqual(result['manual_test_ids'],['M1'])
            with self.assertRaises(ValueError):
                p.evidence_bundle(b,dict(report,results=[]),artifact,'production/evidence/report.json','builder')

    def test_bundle_rejects_inconsistent_report_and_outside_artifact(self):
        from test_fidelity import FidelityTests
        b=FidelityTests().fixture()
        with tempfile.TemporaryDirectory() as d:
            artifact=pathlib.Path(d)/'r.json';artifact.write_text('{}')
            report={'status':'passed','errors':[],'commit':'a'*40,'blueprint_hash':'wrong','results':[]}
            with self.assertRaises(ValueError): p.evidence_bundle(b,report,artifact,'production/evidence/r.json','builder')
            report['blueprint_hash']=b['blueprint_hash']
            report['results']=[{'test_id':t['id'],'status':'passed'} for t in b['bindings']['tests'] if t['kind']=='static']
            with self.assertRaises(ValueError): p.evidence_bundle(b,report,artifact,'../out.json','gate')

    def test_committed_godot_project_to_static_report_and_evidence(self):
        from test_fidelity import FidelityTests
        b=FidelityTests().fixture()
        with tempfile.TemporaryDirectory() as d:
            repo=pathlib.Path(d)
            project=repo/'builds'/'fixture'; project.mkdir(parents=True)
            FidelityTests().project(b,project)
            subprocess.run(['git','init','-q',str(repo)],check=True)
            subprocess.run(['git','-C',str(repo),'add','builds'],check=True)
            subprocess.run(['git','-C',str(repo),'-c','user.name=Fixture','-c','user.email=fixture@example.invalid','commit','-qm','fixture'],check=True)
            sha=subprocess.check_output(['git','-C',str(repo),'rev-parse','HEAD'],text=True).strip()
            claims=[{'requirement_id':'R1','status':'IMPLEMENTED','commit':sha,'blueprint_hash':b['blueprint_hash'],
                     'implementation_refs':b['bindings']['implementations']['R1']}]
            contract={'id':'contract','wireframe_pack_id':'pack','design_id':'design','requirements':b['requirements'],'blueprint_hash':b['blueprint_hash']}
            inputs={'blueprint':b,'contract':contract,'pack':b['source']['pack'],'design':b['source']['design'],'claims':claims}
            paths={}
            for name,value in inputs.items():
                path=repo/(name+'.json');path.write_text(json.dumps(value));paths[name]=str(path)
            report=repo/'static-report.json'
            cmd=[sys.executable,str(ROOT/'tools/fidelity/production.py'),'check-build',
                 '--project',str(project),'--commit',sha,'--output',str(report)]
            for name in inputs:cmd.extend(['--'+name,paths[name]])
            result=subprocess.run(cmd,text=True,capture_output=True)
            self.assertEqual(result.returncode,0,result.stderr+'\n'+report.read_text() if report.exists() else result.stderr)
            data=json.loads(report.read_text())
            self.assertTrue(data['promotion_eligible'])
            bundle=p.evidence_bundle(b,data,report,'production/evidence/fixture.json','builder')
            self.assertEqual(len(bundle['stage_test_ids']),6)


if __name__ == '__main__': unittest.main()
