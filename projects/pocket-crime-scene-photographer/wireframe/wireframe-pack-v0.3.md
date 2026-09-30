# Pocket Crime Scene Photographer — Interaction Wireframe Pack v0.3
fun_promise: Compose evidence relationships through the camera, not tap hidden objects.
Flow: Archive → Brief → Compose → 1.2s Review → Compose/Result, with Pause/Retry/abandon semantics preserved.
Core: landscape viewfinder dominates; direct drag/pinch/evidence-focus/flash/shutter inputs retain exact Game Design thresholds and evaluator meaning.
Variants: Context, Occlusion, Focus, Flash, Combined are data/state variants of the same camera screen.
Result: exposure efficiency maps to 3/2/1 stars; any success unlocks next case.
Implementation boundary: preserve rule math and data semantics; choose Godot scene/node architecture downstream.

## Structural repair 2026-09-30
Normalized camera_gameplay flow references, structured core interactions/content variants, added explicit non-core navigation interactions, and assigned unique screen/overlay order values without changing Game Design rules.
