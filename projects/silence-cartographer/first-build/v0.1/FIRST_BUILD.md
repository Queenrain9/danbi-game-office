# Silence Cartographer — FIRST BUILD v0.1

## Goal

1. Make the sound-information tradeoff legible: revealing more cave must also visibly change predator risk.
2. Prove the deterministic Patrol/Hunt/ReturnToPatrol loop can support a complete Relic-out-and-back mission.

## Include

Use authored missions M1–M3 from `expeditions-v0.2.json`.

Include Move, Ping, Knock, Throw Clicker, Hide, Air, Clickers, permanent reveal, deterministic predator AI, Relic pickup/return, contact failure, Air failure, Pause and Retry.

The playable must have a complete start → exploration → success/failure → retry/next loop.

## Not now

M4–M6, persistent grades/unlocks and final audiovisual polish remain on the Game Design ROADMAP.

## Fragment validation

The fixed content cannot be completed without revealing additional tiles because unrevealed tiles are not enterable and the Relic is outside the initial Entrance+neighbors reveal set. Therefore the First Build Goal's sound-for-information behavior is structurally required.

M2's authored route exercises Hide and M3's authored route exercises Clicker. This does not prove those actions are the only winning strategies; that remains a human/balance question.

## Rule authority

Game intent: Game Design v0.2.  
Deterministic rule semantics: frozen Validation reference hash `49f93d31…c2cdb9`.  
This planner reads/imports that reference and does not modify it.

## RULE test interface

See `OBSERVABILITY.json`. Tests use rule-facing hooks only. Touch/swipe/button input is intentionally absent and belongs to Pre-production.

## Playtest questions

- Does the player understand that more information also changes predator risk?
- Is hidden predator movement predictable enough to feel fair without leaking exact position?
- Does Clicker feel meaningfully different from simply using the loudest local sound?
