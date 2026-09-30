# Borrowed Shadow Repair — Interaction Adapter Compatibility Probe

This is the first non-invasive game-level compatibility probe for the shared interaction runtime.

The audited Build Job remains pinned to its immutable final game commit. The active `builds/borrowed-shadow-repair` files are **not** rewritten by this experiment.

The probe mirrors interaction constants already present in the audited implementation:

- piece movement: drag with return/collision recovery behavior
- snap acceptance: 18 px positional tolerance
- snap rotation acceptance: 12 degrees
- seam trace corridor: 20 px
- pose hold threshold: 600 ms

The shared runtime can represent those repeated primitives as `drag_v1`, `snap_v1`, `trace_v1`, and `hold_v1`. Borrowed Shadow's two-finger piece rotation remains game-specific because the current `pinch_v1` is a scale primitive, not a rotation primitive; it should therefore stay an explicit fallback unless a reusable rotate/twist adapter is introduced later.

Run, when a Godot 4 CLI is actually available:

```
godot --headless --path production/godot/interaction_runtime --script res://borrowed_shadow_probe.gd
```

Expected success marker:

```
BORROWED_SHADOW_ADAPTER_COMPATIBILITY_PASS
```

Creating this probe is not the same as executing it. Until an actual Godot process produces that marker with exit code 0, this remains an unexecuted compatibility test, not runtime evidence.
