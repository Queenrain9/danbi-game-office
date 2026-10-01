# Pre-production Front Design Pipeline v0.4

Status: Phase 1 implementation baseline

## Goal

Keep the existing company1 downstream pipeline intact while strengthening the work before Pre-production.

The front pipeline for opted-in designs is:

```
Idea Lab
→ Full Game Design
→ Independent Design Validation
→ DESIGN READY
→ First Build Planning
→ FIRST BUILD READY
→ Pre-production / Interaction Wireframe
→ WIREFRAME READY
→ Implementation Contract / Fidelity Blueprint
→ Build Farm
→ CI / Runtime checks
→ Static Fidelity Gate
→ Playtest
```

This is opt-in during Phase 1. Legacy designs that are not enrolled continue to use the existing path.

## New rooms

### Game Design Validation

Owns one validation loop, not two serial gates.

```
document critic
→ simulation OR alternative validation
→ numeric re-critique
→ batched defect return
→ Game Design revision
→ re-run
```

There is one final validation verdict.

- PASS: blocking defects are zero.
- REPAIR: return one defect batch to Game Design.
- UNRESOLVED: the design does not converge after serious attempts; send to CEO decision instead of looping forever.

Validation ↔ Game Design revisions are tracked separately from downstream repair bounces and do not count toward the normal three-bounce escalation rule.

Simulation-friendly games should produce a frozen reference model. Feel-heavy or real-time games may use an alternative validation, including a disposable Godot interaction spike owned by Validation. A spike is never production source.

For real-time games, rule time must be independent from rendering. Fixed-step simulation must support deterministic stepping such as `debug_step(seconds)`, so identical initial state + input sequence + simulated time yields identical rule state.

Validation output freezes one `validation_reference_hash`.

## First Build Planning

Does not redesign the whole game and must not modify the frozen validation reference.

It chooses the smallest complete playable that answers 1–3 First Build Goals and produces:

- semantic `FIRST_BUILD_SPEC.json`
- include / not-now scope
- fixed content
- fragment validation
- Must Work IDs
- expected results
- observability contract
- locked RULE tests

If the First Build Goal can be bypassed in the fixed content, the fragment fails. First try different fixed content, then re-scope. If the team intentionally continues anyway, record the validation gap and a mandatory playtest question and mark the result conditional.

Expected results have two supported paths:

1. simulation → replay/expected states
2. no simulation → manually or script-derived expected states with the derivation recorded

No-simulation does not mean no RULE tests.

## Two locked test contracts

### RULE test

Owner: First Build Planning  
Freeze point: FIRST BUILD READY

Uses only rule-facing hooks such as:

- `debug_act(action)`
- `debug_step(seconds)`
- `debug_load_fixture(data)`
- state readers

The Builder may not edit the locked RULE test.

### INPUT test

Owner: Pre-production  
Freeze point: WIREFRAME READY

Created only after screens, gestures and input policy are known. Uses the real production input mapping through hooks such as:

- `debug_tap(position)`
- `debug_swipe(from,to)`
- `debug_drag(path)`
- `debug_press(control_id)`

The Builder may not edit the locked INPUT test.

## Rule/presentation boundary

Turn-based games may resolve one accepted action immediately.

Real-time games advance rules on a fixed simulation time base independent of rendered frames.

In both cases, Presentation follows rule state/events rather than owning game semantics.

## Source of Truth

| Meaning | Source |
| --- | --- |
| game intent, fantasy, why it should be fun | Full Game Design |
| deterministic rule semantics, order, tie-breaks, fixed-time state transitions | frozen Validation Reference |
| first playable scope and what it must prove | First Build Contract |
| screens, gestures, feedback, presentation | Interaction Wireframe / Fidelity Blueprint |

A downstream room never silently chooses between conflicting sources. It returns the artifact to the owner.

## Semantic hashes and compatible extensions

Hashes are dependency identities, not hashes of every explanatory Markdown file.

- `validation_reference_hash`: executable/frozen validation reference
- `first_build_spec_hash`: semantic first-build JSON only
- `observability_hash`: read-only observation interface
- `rules_test_hash`: RULE test
- `wireframe_semantic_hash`: machine-readable Wireframe meaning
- `input_test_hash`: INPUT test

A wording-only Markdown edit does not stale downstream artifacts.

Adding a read-only state observer without changing existing rule semantics is a compatible observability extension. It may change `observability_hash`, but does not invalidate an already-valid RULE test by itself.

Semantic changes do propagate staleness.

```
validation reference change
→ First Build stale
→ downstream stale

first-build semantic spec change
→ RULE contract/Wireframe/Input/Blueprint stale

wireframe semantic change
→ INPUT contract/Blueprint stale
```

## DB Phase 1

Canonical migration:

`supabase/migrations/20261001_front_design_pipeline_v0_4.sql`

New operational objects:

- `danbi_design_pipeline_optins`
- `danbi_design_validations`
- `danbi_first_build_plans`
- `danbi_front_pipeline_overview`
- `danbi_next_design_validation_candidate()`
- `danbi_submit_design_validation(...)`
- `danbi_next_first_build_candidate()`
- `danbi_submit_first_build_plan(...)`
- `danbi_set_wireframe_input_contract(...)`

Opted-in designs are guarded at Wireframe creation and Contract creation, so an old manual Pre-production or Compiler run cannot bypass the new ready gates.

## Phase 2 test pair

Use two different designs.

- Test A: deterministic/simulation-friendly.
- Test B: real-time or feel-heavy / simulation-unfriendly.

Measure quality and operational cost together.

Phase 3 metrics include:

- design changes caused by Validation
- defects found by simulation/alternative validation
- fragment-validation failures
- upstream questions from Pre-production
- Compiler ambiguity
- Build repair rounds
- RULE/INPUT test failure categories
- Fidelity rule defects
- "what am I supposed to do?" playtest failures
- total manual executions per game

If quality improves only by requiring an unreasonable number of manual executions, simplify the gates rather than adding more documents.

## Validation strength in Playtest

When validation used a weaker alternative path, keep `validation_strength='reduced'` and surface it in the Playtest card so the CEO knows the limitation before judging the game.
