# One-Way Wizard — Independent Design Validation v0.1

Status: **REPAIR**  
Design source: `projects/one-way-wizard/game-design/game-design-v0.1.md`  
Validation method: fixed-step partial rule simulation  
Validation strength: reduced until the missing real-time constants are specified.

## Round 1 — document attack

The persistent-projectile idea has a clear systemic promise, and several deterministic rules are already explicit: cap 8, lifetime 18 s, projectile speed 0.22 arena-width/s, mana 4 with 4 s regeneration, Redirect 90°, Split 30°, Merge <=45°, carry max 3 with 12 s lifetime.

However, the complete run cannot yet be simulated deterministically.

### Blocking defect batch

**DV-OW-001 — real-time movement and combat constants are missing.**

Game Design does not currently define all numbers required for a fixed-time reference model:

- wizard movement speed,
- Chaser speed,
- Drifter speed / authored-vector magnitudes,
- enemy HP by archetype,
- wave spawn cadence / exact spawn schedule,
- Cast Bolt cooldown duration,
- collision radii for wizard, enemies and projectiles,
- Redirect / Split pulse speed, radius and lifetime,
- Anchor hazard ring interval, expansion speed/radius, damage and collision rule.

Without these, a simulation cannot test the stated wave solvability contract, pressure curve, HP/contact balance, or whether carry is advantage rather than requirement.

**DV-OW-002 — Split direction semantics are under-specified.**

“mirrored 30° from original direction” does not identify the mirror/reference axis or how the player's pulse impact determines left vs right. A deterministic Builder and RULE test need one answer.

**DV-OW-003 — Redirect impact semantics are not fully pinned.**

The rule says 90° clockwise relative to impact normal, while the interaction summary reads as a simple 90° turn. The reference must specify how pulse trajectory / impact normal selects the resulting projectile direction.

## Fixed-step partial simulation

`sim/sim.py` uses a 0.05 s fixed rule timestep independent from rendering. It validates only the rules whose numbers are currently defined:

- projectile movement and edge wrap without lifetime reset,
- deterministic lifetime countdown,
- cap-8 Bolt rejection without mana loss,
- mana regeneration,
- 90° transformation kernel,
- Split child creation / cap behavior at the abstract rule level,
- compatible merge angle, damage and bounded lifetime.

The model intentionally does not invent the missing enemy/wave/input constants.

## Round 2 — numerical re-critique

The supplied projectile/resource kernel is deterministic, but no honest run-level difficulty or solvability result can be produced while enemy speeds, HP, spawn times and collision geometry are unspecified.

The correct result is **REPAIR**, not an invented “feel” verdict.

## Required Game Design repair

Pin every missing real-time constant above and clarify Split / Redirect direction semantics. The repaired design must be sufficient for a fixed-step reference in which identical initial state + inputs + simulated seconds yields identical rule state.

## Non-blocking human-play risks retained

- eight trails may still become visually unreadable,
- toroidal wrap may be hard to predict,
- merge tolerance may create accidental merges,
- Carry Select may become bookkeeping,
- capacity feedback may make or break whether casting feels strategic rather than spammy.

## Verdict

`REPAIR → Game Design`

Blocking defects: 3
