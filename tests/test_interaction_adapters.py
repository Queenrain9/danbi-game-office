import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).parents[1]
spec=importlib.util.spec_from_file_location("construction",ROOT/"tools/fidelity/construction.py")
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)

class InteractionAdapterTests(unittest.TestCase):
    def test_registry_exposes_only_production_entries_to_compiler(self):
        registry=m.load_adapter_registry()
        production={adapter_id for adapter_id,entry in registry["adapters"].items() if entry["status"]=="production"}
        self.assertEqual(set(m.INTERACTION_ADAPTERS),production)

    def test_registry_entries_have_lifecycle_and_frozen_metadata(self):
        registry=m.load_adapter_registry()
        self.assertEqual(registry["schema_version"],"interaction-runtime-registry-v1")
        for adapter_id,entry in registry["adapters"].items():
            self.assertEqual(entry["adapter_id"],adapter_id)
            self.assertIn(entry["status"],{"candidate","production","deprecated"})
            if entry["status"] in {"production","deprecated"}:
                self.assertRegex(entry["sha256"],r"^[0-9a-f]{64}$")
                self.assertTrue(entry["validated_godot"])
                self.assertTrue(entry["ci_run"])

    def test_production_selector_excludes_candidate_and_deprecated(self):
        fake={
            "a_v1":{"adapter_id":"a_v1","semantic_kind":"drag","status":"deprecated"},
            "a_v2":{"adapter_id":"a_v2","semantic_kind":"drag","status":"production"},
            "a_v3":{"adapter_id":"a_v3","semantic_kind":"drag","status":"candidate"},
        }
        self.assertEqual(m.select_production_adapter("drag",fake)["adapter_id"],"a_v2")

    def test_production_entry_is_frozen_but_may_deprecate(self):
        previous={"adapters":{"drag_v1":{"adapter_id":"drag_v1","semantic_kind":"drag","status":"production","sha256":"a"*64,"source_path":"a.gd","script_path":"res://a.gd","class_name":"DanbiDragV1","entry_symbol":"handle_event","required_params":[],"validated_godot":["4.7.2"],"ci_run":"1","superseded_by":None}}}
        same={"adapters":{"drag_v1":dict(previous["adapters"]["drag_v1"])}}
        same["adapters"]["drag_v1"]["status"]="deprecated"
        same["adapters"]["drag_v1"]["superseded_by"]="drag_v2"
        self.assertEqual(m.registry_transition_issues(previous,same),[])
        changed={"adapters":{"drag_v1":dict(previous["adapters"]["drag_v1"])}}
        changed["adapters"]["drag_v1"]["sha256"]="b"*64
        self.assertTrue(any(x["code"]=="ADAPTER_FROZEN" for x in m.registry_transition_issues(previous,changed)))

    def test_new_adapter_must_enter_registry_as_candidate(self):
        previous={"adapters":{}}
        current={"adapters":{"drag_v2":{
            "adapter_id":"drag_v2","semantic_kind":"drag","status":"production",
            "sha256":"a"*64,"source_path":"production/godot/interaction_runtime/drag_v2.gd",
            "script_path":"res://runtime/interaction/drag_v2.gd","class_name":"DanbiDragV2",
            "entry_symbol":"handle_event","required_params":[],"validated_godot":["4.7.2"],
            "ci_run":"123","superseded_by":None
        }}}
        issues=m.registry_transition_issues(previous,current)
        self.assertTrue(any(x["code"]=="ADAPTER_LIFECYCLE" for x in issues))

    def test_candidate_can_promote_to_production(self):
        base={
            "adapter_id":"drag_v2","semantic_kind":"drag","status":"candidate",
            "sha256":None,"source_path":"production/godot/interaction_runtime/drag_v2.gd",
            "script_path":"res://runtime/interaction/drag_v2.gd","class_name":"DanbiDragV2",
            "entry_symbol":"handle_event","required_params":[],"validated_godot":[],"ci_run":None,
            "superseded_by":None
        }
        previous={"adapters":{"drag_v2":dict(base)}}
        promoted={"adapters":{"drag_v2":dict(base,status="production",sha256="a"*64,validated_godot=["4.7.2"],ci_run="123")}}
        self.assertEqual(m.registry_transition_issues(previous,promoted),[])

    def test_adapter_class_name_version_matches_file_version(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d)
            runtime=root/"production/godot/interaction_runtime"
            runtime.mkdir(parents=True)
            (runtime/"drag_v2.gd").write_text("class_name DanbiDragV1\nextends RefCounted\n",encoding="utf-8")
            registry={
                "schema_version":"interaction-runtime-registry-v1",
                "hash_algorithm":"sha256-lf-bytes-v1",
                "lifecycle":["candidate","production","deprecated"],
                "adapters":{
                    "drag_v2":{
                        "adapter_id":"drag_v2","status":"candidate","semantic_kind":"drag",
                        "source_path":"production/godot/interaction_runtime/drag_v2.gd",
                        "script_path":"res://runtime/interaction/drag_v2.gd","sha256":None,
                        "class_name":"DanbiDragV1","entry_symbol":"handle_event","required_params":[],
                        "validated_godot":[],"ci_run":None,"superseded_by":None
                    }
                }
            }
            (runtime/"registry.json").write_text(json.dumps(registry),encoding="utf-8")
            issues=m.verify_adapter_registry(root)
            self.assertTrue(any(x["code"]=="ADAPTER_CLASS_VERSION" for x in issues))

    def test_drag_snap_compilation_pins_immutable_adapter_metadata(self):
        src={"interaction_semantics":{"kind":"drag","target_component_id":"piece","cancel":"return_origin","completion":{"kind":"snap","target_component_id":"slot","tolerance_px":24}}}
        plan=m.compile_interaction_adapters(src)
        self.assertIsNone(plan["fallback_reason"])
        self.assertEqual([x["adapter_id"] for x in plan["adapter_bindings"]],["drag_v1","snap_v1"])
        self.assertEqual(plan["adapter_bindings"][1]["params"]["tolerance_px"],24)
        for binding in plan["adapter_bindings"]:
            self.assertEqual(binding["adapter_status"],"production")
            self.assertRegex(binding["adapter_sha256"],r"^[0-9a-f]{64}$")
            self.assertTrue(binding["adapter_class_name"].startswith("Danbi"))

    def test_hash_normalizes_crlf_to_git_lf_bytes(self):
        lf=b"class_name Example\nextends RefCounted\n"
        crlf=b"class_name Example\r\nextends RefCounted\r\n"
        self.assertEqual(m.adapter_content_sha256(lf),m.adapter_content_sha256(crlf))

    def test_production_registry_matches_canonical_files(self):
        self.assertEqual(m.verify_adapter_registry(ROOT),[])

    def test_blueprint_hash_includes_adapter_pin(self):
        base={"source":{},"bindings":{"interactions":[{"adapter_bindings":[{"adapter_id":"drag_v1","adapter_sha256":"a"*64}]}]}}
        changed={"source":{},"bindings":{"interactions":[{"adapter_bindings":[{"adapter_id":"drag_v1","adapter_sha256":"b"*64}]}]}}
        self.assertNotEqual(m.seal(base)["blueprint_hash"],m.seal(changed)["blueprint_hash"])

    def test_unknown_fallback(self):
        self.assertTrue(m.compile_interaction_adapters({"interaction_semantics":{"kind":"shadow_morph"}})["fallback_reason"].startswith("unsupported_semantic_kind:"))

    def test_legacy(self):
        self.assertEqual(m.compile_interaction_adapters({"input":"drag"})["fallback_reason"],"legacy_unstructured_interaction")

if __name__=="__main__":
    unittest.main()
