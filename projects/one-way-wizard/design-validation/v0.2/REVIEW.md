# One-Way Wizard — Independent Design Validation v0.2

Status: **PASS (reduced validation strength)**  
Design source: `game-design-v0.2.md` + `rules-v0.2.json`  
Validation method: **alternative validation**  
Frozen reference type: **rule table**

## Why alternative validation

The design is a real-time action-strategy game whose central uncertainty includes control feel, visual trajectory readability and the player's ability to manipulate persistent projectiles while under pressure.

A deterministic rule reference is still required, but a headless bot result would overstate what has been proven. Therefore v0.2 freezes the complete numeric rule table and checks deterministic completeness while explicitly leaving feel/readability questions for playable testing.

## Repair verification

The v0.1 blocking defects are closed.

- wizard speed/radius are defined,
- Chaser/Drifter speed and all enemy HP are defined,
- wave spawn schedules and positions are frozen,
- Cast cooldown is defined,
- collision radii are defined,
- Redirect/Split pulse geometry is defined,
- Anchor hazard timing/geometry/damage is defined,
- Split side selection is deterministic,
- Redirect no longer depends on an ambiguous impact normal,
- Merge output direction/position are deterministic,
- rule time is fixed at 60 Hz and independent from render FPS,
- ROADMAP is present.

## Executed alternative checks

`reference_check.py` verifies the required rule-table fields and derived invariants.

Derived facts:

- rule clock: 60 Hz,
- one standard projectile can travel 3.96 arena widths during its 18 s lifetime, so edge wrap is structurally relevant rather than decorative,
- a player who spends mana as it returns can create up to 8 fresh Bolt casts over an 18 s interval before considering carry/transforms,
- enemy counts are 6 / 7 / 8 across waves,
- last scheduled spawns occur at 9.0 / 9.6 / 10.5 seconds,
- projectile cap remains 8 and carry max remains 3.

## Blocking defects

None.

## Reduced-strength boundary

Validation does **not** claim that the resulting action game already feels good or that Redirect/Split/Merge are superior to simply casting fresh Bolts.

Those questions require the first playable.

Mandatory human questions:

1. Can players read old projectile lanes quickly enough to make deliberate decisions?
2. Do Redirect/Split/Merge feel like manipulating a living spell machine rather than extra UI chores?
3. Does fresh-cast spam dominate transformation play in practice?
4. Does toroidal wrap remain predictable while enemies and trails overlap?

## Verdict

**DESIGN VALIDATION PASS — validation_strength=reduced**

The design is semantically complete enough for First Build Planning, but the reduced evidence level must remain visible on the Playtest card.
