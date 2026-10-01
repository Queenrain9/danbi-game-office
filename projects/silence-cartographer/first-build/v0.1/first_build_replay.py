from importlib.util import spec_from_file_location, module_from_spec
from pathlib import Path
import json

ROOT=Path(__file__).resolve().parents[2]
SIM=ROOT/"design-validation"/"v0.2"/"sim"/"sim.py"
spec=spec_from_file_location("silence_validation",SIM)
mod=module_from_spec(spec)
spec.loader.exec_module(mod)

data=json.loads((ROOT/"game-design"/"expeditions-v0.2.json").read_text(encoding="utf-8"))
wanted={"M1","M2","M3"}
results=[mod.run_mission(m) for m in data["missions"] if m["id"] in wanted]
assert len(results)==3
for r in results:
    print(json.dumps(r,ensure_ascii=False,sort_keys=True))
