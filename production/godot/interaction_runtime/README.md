# Danbi Godot Interaction Runtime
Stable reusable Godot 4.x interaction primitives. Game Design/Wireframe never name adapter ids; Wireframe provides semantic `interaction_semantics`, Blueprint Compiler maps it to adapters, Build Farm copies used scripts to `res://runtime/interaction/`.

Adapters: `drag_v1`, `snap_v1`, `hold_v1`, `swipe_v1`, `trace_v1`, `pinch_v1`.

Unknown game-specific mechanics remain `explicit_script_v1` with a recorded `fallback_reason`.

When Godot CLI is available:
`godot --headless --path production/godot/interaction_runtime --script res://headless_tests.gd`
