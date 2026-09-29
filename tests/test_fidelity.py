import copy
import importlib.util
import pathlib
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location('construction', ROOT / 'tools/fidelity/construction.py')
m = importlib.util.module_from_spec(SPEC) if SPEC else None

class FidelityTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        assert SPEC and SPEC.loader and pathlib.Path(SPEC.origin).exists(), 'Canonical construction tool is missing'
        SPEC.loader.exec_module(m)

    def fixture(self):
        req = [{'id': 'R1', 'source_ref': '/source/pack/screens/0/components/0'}]
        box = {'x': 10, 'y': 20, 'w': 30, 'h': 10}
        screens = [{'id': 'home', 'components': [{'id': 'start', 'type': 'button', 'box': box}], 'interactions': [{'trigger': 'tap', 'target': 'start'}]}]
        b = {'schema_version': 'fidelity-v1', 'hash_algorithm': 'sha256-canonical-json-v1',
             'contract_id': 'contract', 'wireframe_pack_id': 'pack', 'screens': screens, 'requirements': req,
             'source': {'pack': {'id': 'pack', 'design_id': 'design', 'reference_size': {'width': 390, 'height': 844}, 'screens': screens}, 'design': {'id': 'design'}, 'requirements': req},
             'bindings': {'scene_path': 'res://main.tscn', 'reference_size': {'width': 390, 'height': 844}, 'coordinate_space': 'screen_percent', 'stretch_mode': 'canvas_items',
                 'nodes': [{'node_path': '/root/AppRoot', 'godot_type': 'Control', 'full_rect': True, 'script_path': 'res://main.gd'},
                           {'node_path': '/root/AppRoot/home', 'godot_type': 'Control', 'full_rect': True}],
                 'components': [{'screen_id': 'home', 'component_id': 'start', 'node_path': '/root/AppRoot/home/start', 'godot_type': 'Button', 'source_box': box, 'construction_pattern': 'button_tap_v1'}],
                 'interactions': [{'screen_id': 'home', 'interaction_index': 0, 'input': 'tap', 'source_target': 'start', 'target_node': '/root/AppRoot/home/start', 'action_symbol': 'start_game', 'action_script': 'res://main.gd'}],
                 'connections': [{'from': '/root/AppRoot/home/start', 'signal': 'pressed', 'to': '/root/AppRoot', 'method': 'start_game'}],
                 'implementations': {'R1': [{'file': 'res://main.tscn', 'node_path': '/root/AppRoot/home/start'}, {'file': 'res://main.gd', 'symbol': 'start_game', 'kind': 'func'}]},
                 'symbols': [{'file': 'res://main.gd', 'symbol': 'ready_to_start', 'kind': 'var'}],
                 'tests': [{'id': 'T1', 'kind': 'static', 'stage': 'input', 'requirement_ids': ['R1'], 'checks': [{'kind': 'symbol', 'file': 'res://main.gd', 'symbol': 'start_game', 'symbol_kind': 'func'}]},
                           *[{'id': 'T:'+stage, 'kind': 'static', 'stage': stage, 'requirement_ids': ['R1'], 'checks': [{'kind': 'file', 'file': 'res://main.tscn'}]} for stage in ('skeleton','geometry','state','presentation','integration')],
                           {'id': 'M1', 'kind': 'runtime', 'requirement_ids': ['R1']} ]}}
        return m.seal(b)

    def project(self, b, folder):
        p = pathlib.Path(folder)
        (p/'main.gd').write_text('extends Control\nvar ready_to_start := true\nfunc start_game() -> void:\n\tready_to_start = false\n')
        (p/'main.tscn').write_text(m.construct(b))
        (p/'project.godot').write_text('[application]\nrun/main_scene="res://main.tscn"\n[display]\nwindow/size/viewport_width=390\nwindow/size/viewport_height=844\nwindow/stretch/mode="canvas_items"\n')
        return p

    def codes(self, b, p=None, claims=None):
        return {e['code'] for e in m.validate(b, p, claims=claims)['errors']}

    def test_canonical_reference_size_prefers_source_then_orientation_fallback(self):
        self.assertEqual(m.canonical_reference_size({'orientation':'portrait','reference_size':{'width':390,'height':844}}), {'width':390,'height':844})
        self.assertEqual(m.canonical_reference_size({'orientation':'portrait'}), {'width':540,'height':960})
        self.assertEqual(m.canonical_reference_size({'orientation':'landscape'}), {'width':960,'height':540})
        with self.assertRaises(ValueError):
            m.canonical_reference_size({'orientation':'square'})

    def test_exact_geometry_and_parent_relative_offset(self):
        r = m.geometry({'x': 18, 'y': 83, 'w': 64, 'h': 9}, {'width': 390, 'height': 844})
        self.assertEqual(r, {'x': 70.2, 'y': 700.52, 'w': 249.6, 'h': 75.96})
        b = self.fixture()
        b['bindings']['nodes'][1].update(full_rect=False, source_box={'x': 5, 'y': 10, 'w': 90, 'h': 80})
        scene = m.construct(m.seal(b))
        self.assertIn('offset_left = 19.5', scene)
        self.assertIn('offset_top = 84.4', scene)

    def test_valid_project_passes_without_runtime(self):
        b = self.fixture()
        with tempfile.TemporaryDirectory() as d:
            report = m.validate(b, self.project(b,d))
            self.assertEqual(report['errors'], [])
            self.assertEqual(report['manual_test_ids'], ['M1'])
            self.assertFalse(report['runtime_qa_performed'])

    def test_missing_script_resource_node_symbol_and_geometry(self):
        for mutation, expected in [('script','MISSING_FILE'),('resource','RESOURCE_PATH'),('node','NODE_PATH'),('symbol','SYMBOL'),('geometry','GEOMETRY')]:
            with self.subTest(mutation=mutation), tempfile.TemporaryDirectory() as d:
                b=self.fixture(); p=self.project(b,d)
                if mutation=='script': (p/'main.gd').unlink()
                elif mutation=='resource': (p/'main.gd').write_text((p/'main.gd').read_text()+'\nconst Missing = preload("res://missing.gd")\n')
                elif mutation=='node': (p/'main.tscn').write_text((p/'main.tscn').read_text().replace('name="start"','name="wrong"'))
                elif mutation=='symbol': (p/'main.gd').write_text('extends Control\n# func start_game():\nvar ready_to_start := true\n')
                else: (p/'main.tscn').write_text((p/'main.tscn').read_text().replace('offset_left = 39','offset_left = 99'))
                self.assertIn(expected,self.codes(b,p))

    def test_drift_duplicate_requirement_and_unresolved_source_fail(self):
        for mutation, expected in [('hash','HASH'),('duplicate','REQUIREMENT_IDS'),('source','SOURCE_REF')]:
            b=self.fixture()
            if mutation=='hash': b['bindings']['stretch_mode']='viewport'
            elif mutation=='duplicate': b['requirements'].append(copy.deepcopy(b['requirements'][0])); b=m.seal(b)
            else: b['requirements'][0]['source_ref']='/source/pack/screens/99'; b=m.seal(b)
            self.assertIn(expected,self.codes(b))

    def test_drag_cannot_be_replaced_with_button(self):
        b=self.fixture(); b['screens'][0]['interactions'][0]['trigger']='drag'; b=m.seal(b)
        self.assertIn('INPUT_MODALITY',self.codes(b))

    def test_non_button_tap_uses_explicit_script_and_preserves_source_target(self):
        b=self.fixture()
        b['screens'][0]['components'][0]['type']='card'
        b['source']['pack']['screens']=b['screens']
        comp=b['bindings']['components'][0]
        comp['godot_type']='Panel'
        comp['construction_pattern']='explicit_script_v1'
        comp['script_path']='res://tap_target.gd'
        interaction=b['bindings']['interactions'][0]
        interaction['source_target']='start'
        interaction['input_handler']='handle_tap'
        b['bindings']['connections']=[]
        b=m.seal(b)
        self.assertNotIn('INPUT_MODALITY',self.codes(b))
        interaction=b['bindings']['interactions'][0]
        interaction['source_target']='wrong'
        b=m.seal(b)
        self.assertIn('INPUT_TARGET',self.codes(b))

    def test_tap_can_bind_multiple_explicit_buttons(self):
        b=self.fixture()
        box2={'x':50,'y':20,'w':30,'h':10}
        b['screens'][0]['components'].append({'id':'other','type':'button','box':box2})
        b['source']['pack']['screens']=b['screens']
        b['bindings']['components'].append({'screen_id':'home','component_id':'other','node_path':'/root/AppRoot/home/other','godot_type':'Button','source_box':box2,'construction_pattern':'button_tap_v1'})
        b['bindings']['interactions'][0]['source_target']='start'
        b['bindings']['interactions'][0]['related_nodes']=['/root/AppRoot/home/other']
        b['bindings']['connections'].append({'from':'/root/AppRoot/home/other','signal':'pressed','to':'/root/AppRoot','method':'start_game'})
        b=m.seal(b)
        self.assertNotIn('CONNECTION',self.codes(b))

    def test_current_wireframe_semantic_types_have_registry_entries(self):
        for name in ('animation','button','canvas','card','chip','chip_group','comparison','drop_target','dropzone','grade','hold_button','hotspots','indicator','interactive_object','label','list','manipulable','metric','modal','object','overlay','panel','portrait','preview','result_stamp','slider','status','text_card','tray'):
            self.assertIn(name,m.SOURCE_COMPONENT_TYPES)

    def test_reusable_mapping_requires_real_script(self):
        b=self.fixture(); b['bindings']['components'][0]['reusable_component']='ShadowPiece'; b=m.seal(b)
        self.assertIn('REUSABLE', self.codes(b))

    def test_missing_duplicate_stale_claims(self):
        b=self.fixture()
        good={'requirement_id':'R1','status':'IMPLEMENTED','commit':'b'*40,'blueprint_hash':b['blueprint_hash'],'implementation_refs':b['bindings']['implementations']['R1']}
        for claims,code in [([], 'CLAIM_COVERAGE'),([good,good],'CLAIM_COVERAGE'),([dict(good,blueprint_hash='c'*64)],'CLAIM_STALE')]:
            self.assertIn(code,self.codes(b,claims=claims))

    def test_unsupported_static_check_fails_closed(self):
        b=self.fixture(); b['bindings']['tests'][0]['checks']=[{'kind':'looks_good'}]; b=m.seal(b)
        self.assertIn('TEST_CHECK',self.codes(b))

    def test_every_stage_needs_static_test(self):
        b=self.fixture(); b['bindings']['tests']=[t for t in b['bindings']['tests'] if t.get('stage')!='geometry']; b=m.seal(b)
        self.assertIn('STAGE_COVERAGE',self.codes(b))

    def test_static_checks_actually_run(self):
        with tempfile.TemporaryDirectory() as d:
            b=self.fixture(); b['bindings']['tests'][0]['checks']=[{'kind':'file','file':'res://missing.gd'}]; b=m.seal(b)
            self.assertIn('MISSING_FILE',self.codes(b,self.project(b,d)))
            b=self.fixture(); b['bindings']['tests'][0]['checks']=[{'kind':'resources','file':'res://missing.gd'}]; b=m.seal(b)
            self.assertIn('MISSING_FILE',self.codes(b,self.project(b,d)))

    def test_unexpected_scene_node_and_missing_reusable_use_site(self):
        with tempfile.TemporaryDirectory() as d:
            b=self.fixture(); p=self.project(b,d)
            (p/'main.tscn').write_text((p/'main.tscn').read_text()+'\n[node name="Surprise" type="Button" parent="."]\n')
            self.assertIn('UNDECLARED_NODE',self.codes(b,p))
        b=self.fixture(); b['bindings']['reusable_components']={'NeverUsed':{'script_path':'res://reusable.gd','godot_type':'Control'}}; b=m.seal(b)
        self.assertIn('REUSABLE',self.codes(b))

    def test_state_binding_must_have_actual_owner_and_symbol(self):
        b=self.fixture(); node=b['bindings']['components'][0]; node['enabled_when']='ready'; node['enabled_when_ref']={'file':'res://missing.gd','symbol':'ready','kind':'var'}; b=m.seal(b)
        with tempfile.TemporaryDirectory() as d: self.assertIn('MISSING_FILE',self.codes(b,self.project(b,d)))

    def test_invalid_manual_scope_cannot_launder_runtime_as_static(self):
        b=self.fixture(); b['bindings']['tests'][-1]['verification_scope']='static'; b['bindings']['tests'][-1]['checks']=[{'kind':'file','file':'res://main.gd'}]; b=m.seal(b)
        self.assertIn('TEST_SCOPE',self.codes(b))

    def test_states_transitions_and_rules_need_implementation_location(self):
        b=self.fixture(); b['bindings']['states']=[{'id':'ready','screen_id':'home'}]; b=m.seal(b)
        self.assertIn('BINDING_REF',self.codes(b))
        b=self.fixture(); b['screens'][0]['transitions']=[{'from':'ready','to':'game','trigger':'tap start'}]
        b['bindings']['transitions']=[{'screen_id':'home','from':'ready','to':'game','trigger':'tap start','implementation_ref':{'file':'res://main.gd','symbol':'start_game','kind':'func'}}]; b=m.seal(b)
        with tempfile.TemporaryDirectory() as d: self.assertNotIn('BINDING_REF',self.codes(b,self.project(b,d)))

    def test_requirement_static_test_must_check_its_implementation(self):
        b=self.fixture()
        for t in b['bindings']['tests']:
            if t['kind']=='static': t['checks']=[{'kind':'file','file':'res://unrelated.gd'}]
        b=m.seal(b)
        self.assertIn('TEST_TRACE',self.codes(b))

    def test_existing_binary_resource_does_not_fail_text_decoding(self):
        with tempfile.TemporaryDirectory() as d:
            b=self.fixture(); b['bindings']['tests'][0]['checks']=[{'kind':'file','file':'res://image.png'}]; b=m.seal(b)
            project=self.project(b,d)
            (project/'image.png').write_bytes(b'\x89PNG\r\n\x1a\n\xff')
            self.assertNotIn('MISSING_FILE',self.codes(b,project))

    def test_missing_source_state_transition_and_variant_mapping(self):
        b=self.fixture(); b['screens'][0]['states']=['ready']; b=m.seal(b)
        self.assertIn('STATE_COVERAGE',self.codes(b))
        b=self.fixture(); b['screens'][0]['transitions']=[{'from':'ready','to':'game','trigger':'tap start'}]; b=m.seal(b)
        self.assertIn('TRANSITION_COVERAGE',self.codes(b))
        b=self.fixture(); b['screens'][0]['state_variants']=[{'id':'disabled'}]; b=m.seal(b)
        self.assertIn('VARIANT_COVERAGE',self.codes(b))

    def test_path_traversal_nan_and_duplicate_nodes(self):
        with self.assertRaises(ValueError): m.geometry({'x':float('nan'),'y':0,'w':1,'h':1},{'width':390,'height':844})
        b=self.fixture(); b['bindings']['nodes'][0]['script_path']='res://../escape.gd'; b=m.seal(b)
        self.assertIn('PATH',self.codes(b))
        b=self.fixture(); b['bindings']['nodes'].append(copy.deepcopy(b['bindings']['nodes'][0])); b=m.seal(b)
        self.assertIn('NODE_DUPLICATE',self.codes(b))

if __name__ == '__main__': unittest.main()
