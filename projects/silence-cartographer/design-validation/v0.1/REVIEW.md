# Silence Cartographer — Independent Design Validation v0.1

Status: **REPAIR**  
Design source: `projects/silence-cartographer/game-design/game-design-v0.1.md`  
Validation method: deterministic rule simulation  
Validation strength: normal for the encoded core rules, but the authored-content contract is not yet testable.

## Round 1 — document attack

The core information/risk loop is coherent: every accepted gameplay action spends Air and advances the predator, while Ping / Knock / Clicker trade different reveal radii against different hearing radii. The rules also define deterministic Patrol/Hunt behavior and tie-breaking, so they are suitable for a reference simulation.

### Blocking defect batch

**DV-SC-001 — the six authored expeditions do not exist as machine-readable mission fixtures.**

Game Design promises six authored expeditions, each with 16–26 walkable nodes, one Entrance, one Relic, 1–3 Alcoves, a patrol cycle, tie-break indices and a solvability contract. The project archive currently contains only the design document. Without the six concrete graphs and starting values, Validation cannot test:

- whether every expedition is solvable,
- whether Air 22–30 is sufficient,
- whether Clicker/Ping/Knock dominance changes by mission,
- whether the difficulty curve actually rises,
- whether permanent reveal trivializes the return trip,
- whether deterministic Patrol/Hunt collapses into memorized single solutions,
- whether the Combined Expedition really combines earlier skills rather than adding only length.

This is a Game Design authoring gap, not a Builder problem.

## Simulation

`sim/sim.py` implements the stated deterministic core semantics on synthetic fixtures:

- graph-distance movement and hearing,
- permanent reveal,
- Ping / Knock / Clicker retarget,
- Patrol / Hunt,
- invalid-action no-cost behavior,
- one-resolution Hide,
- success-before-Air-failure priority.

The synthetic fixture exists only to test rule consistency. It is not a substitute for the promised six authored expeditions.

## Round 2 — numerical re-critique

The encoded core rules can execute deterministically, but the most important design claims are content-dependent. Because no authored expedition data exists, any bot win-rate, dominant-strategy result or difficulty measurement would be evidence about an invented test map rather than this game.

The correct result is therefore **REPAIR**, not PASS.

## Required Game Design repair

Add machine-readable definitions for all six MVP expeditions. Each fixture must include at least:

- graph / wall topology,
- Entrance / Relic / Alcoves,
- predator start,
- authored cyclic patrol path,
- per-node tie-break index,
- starting Air and Clickers.

For each expedition, provide at least one validated success route or enough data for Validation to compute one. The six fixtures must remain Game Design content; Validation must not invent them.

## Non-blocking risks retained for later human playtest

- permanent reveal may reduce late-run uncertainty,
- finite Air may read as an arbitrary timer,
- deterministic predator movement may become memorization,
- hidden-predator cues can accidentally leak exact information,
- Clicker may dominate local sound choices.

## Verdict

`REPAIR → Game Design`

Blocking defects: 1  
Validation revisions are tracked separately from downstream pipeline bounces.
