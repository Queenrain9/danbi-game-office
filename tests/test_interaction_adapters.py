import importlib.util
from pathlib import Path
import unittest
spec=importlib.util.spec_from_file_location("construction",Path(__file__).parents[1]/"tools/fidelity/construction.py")
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class InteractionAdapterTests(unittest.TestCase):
    def test_registry(self):
        self.assertEqual(set(m.INTERACTION_ADAPTERS),{"drag_v1","snap_v1","hold_v1","swipe_v1","trace_v1","pinch_v1"})
    def test_drag_snap(self):
        src={"interaction_semantics":{"kind":"drag","target_component_id":"piece","cancel":"return_origin","completion":{"kind":"snap","target_component_id":"slot","tolerance_px":24}}}
        plan=m.compile_interaction_adapters(src);self.assertIsNone(plan["fallback_reason"]);self.assertEqual([x["adapter_id"] for x in plan["adapter_bindings"]],["drag_v1","snap_v1"]);self.assertEqual(plan["adapter_bindings"][1]["params"]["tolerance_px"],24)
    def test_unknown_fallback(self):
        self.assertTrue(m.compile_interaction_adapters({"interaction_semantics":{"kind":"shadow_morph"}})["fallback_reason"].startswith("unsupported_semantic_kind:"))
    def test_legacy(self):
        self.assertEqual(m.compile_interaction_adapters({"input":"drag"})["fallback_reason"],"legacy_unstructured_interaction")
if __name__=="__main__":unittest.main()
