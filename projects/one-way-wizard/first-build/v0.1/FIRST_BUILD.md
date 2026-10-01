# One-Way Wizard — FIRST BUILD v0.1

## Goal

1. Test whether long-lived wrapping projectiles remain readable tactical assets instead of visual noise.
2. Test whether Redirect and Split are understandable and useful when applied to an already-living projectile.

## Include

Use the frozen **Wave2 Split Lane** arena and Wave2 spawn schedule from `rules-v0.2.json`.

Include Move, Cast Bolt, Redirect, Split, HP, mana/charges, cap8, 18s lifetime, toroidal projectile wrap, Chasers, Drifters, Wave2 clear/failure, Pause and Retry.

## Not now

Do not build the full three-wave run, Anchor hazards, Carry Select, persistent score, or final polish. Merge remains covered by the RULE contract but is not required as a player-facing decision in this first playable.

## Fragment validation

Persistence is structurally unavoidable: a Bolt travels 3.96 arena widths during its 18s lifetime, so old trajectories remain in the arena across multiple edge wraps unless the cap/lifetime removes them.

**Known validation gap:** Wave2 can theoretically be cleared without using Redirect/Split. The First Build therefore enters **conditional ready** rather than pretending the transformation goal is mechanically forced.

The gap is intentional because the exact question to answer with the playable is whether players *want* to transform existing projectiles rather than simply cast fresh ones.

## Rule authority

Game intent: Game Design v0.2.  
Deterministic real-time semantics: frozen `rules-v0.2.json` hash `30e8fd88…f79a13`.  
First Build Planning reads but does not edit that reference.

## Fixed-time contract

Rules advance at 60Hz independently from render FPS. `debug_step(seconds)` drives the same production rule clock used by the game.

## Mandatory playtest questions

- Can old projectile lanes be read quickly under pressure?
- Do Redirect/Split feel like manipulating a living spell machine or like UI chores?
- Does fresh-cast spam dominate transformation play?
- Is toroidal wrap predictable once enemies and trails overlap?
