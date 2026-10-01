# One-Way Wizard — Validation Results v0.1

Reference: `sim/sim.py`  
Fixed timestep: **0.05 s**

## Executed checks

The partial reference model passed:

1. a projectile crossing an arena edge wraps and keeps the same lifetime clock,
2. cap 8 rejects a new Bolt without spending mana,
3. mana regenerates deterministically on simulated time,
4. the 90° transformation kernel is deterministic,
5. Split can create exactly one child when capacity permits,
6. compatible <=45° projectiles merge to damage 2 with bounded lifetime.

## Result

```
PARTIAL_RULE_CHECKS PASS
fixed_dt 0.05
blocking_missing=wizard_speed,enemy_speeds,enemy_hp,spawn_cadence,cast_cooldown,pulse_geometry,collision_radii,anchor_hazard_numbers
split_semantics=AMBIGUOUS: mirrored30 needs reference axis/sign
```

## Interpretation

This proves that a fixed-time RULE-test path is feasible for the game.

It does **not** prove wave solvability, difficulty, carry balance or enemy pressure. Those require the missing Game Design constants. Validation strength remains `reduced` until the reference covers the complete run semantics.
