# Silence Cartographer — Interaction Wireframe Pack v1.0

## First Build boundary
This pack implements only M1 Basic Echo Maze, M2 Alcove Crossing, and M3 Remote Decoy from FIRST BUILD v0.1. M4–M6, persistent grades/unlocks, and final audiovisual polish remain NOT NOW.

The deterministic rule source remains the frozen Validation/First Build package. This pack owns screen structure, touch mapping, presentation ordering, input cancellation/priority, visible feedback, and the INPUT test contract.

## Screens
1. Expedition Select — choose M1–M3.
2. Mission Brief — objective, starting Air/Clickers, read-only preview, controls.
3. Cave Exploration — primary 4×4 play surface.
4. Pause Overlay — exact resume, retry, select.
5. Mission Result — success/contact/Air result with retry/select and success-only next.

## Core interaction
The cave map dominates play. Cardinal swipe attempts one Move. A shared SOUND control preserves the authored rule: release before 600 ms = Ping; hold to at least 600 ms then release = Knock. Dragging off cancels the whole sound action. Clicker is dragged to a revealed valid tile; invalid release snaps back with no resource or predator change. HIDE is enabled only on an Alcove.

Accepted turn actions become rule-authoritative immediately. Echo and Predator presentation then replay while gameplay input is locked, so duplicate input cannot queue turns. Pause may freeze and resume presentation without re-running the rule action.

## Hidden information
Exact predator position is shown only when its current tile is revealed. Hidden sound response is directional only; exact hidden tile, distance, future path and return target are not exposed.

## Input contract
Reference canvas: 540×960 portrait.

- Move: cardinal swipe, min 24 px, max 450 ms, dominant-axis ratio 1.35.
- Ping: SOUND release before 600 ms.
- Knock: SOUND release at/after 600 ms.
- SOUND drag-off: leave expanded bounds by >12 px => cancel with no Ping fallback.
- Clicker: drag/release; production rule query owns revealed/walkable/range<=4 validity.
- Hide: tap HIDE, available only on Alcove.
- Pause: tap; modal blocks background gameplay.

## Locked tests
RULE: `projects/silence-cartographer/first-build/v0.1/tests/rules_smoke.gd`

INPUT: `projects/silence-cartographer/preproduction/v1.0/tests/input_smoke.gd`

INPUT hooks must use the same production hit testing / gesture recognizer used by touch and mouse. Rule fixture hooks are allowed only for deterministic setup and observation.

## Frozen upstream identities
- Validation reference: `49f93d312ce6c8188677564361646ed40c49151b712134bf94f99eaf04c2cdb9`
- First Build semantic spec: `355d9ecda46759731bf7ad8b5bcabf748e4d3eaa0517dbe29e198d221ca9354a`
- RULE test: `a619fb56f7fc06a6970cef38e7bedc9f6fa7a76d979faa44bfd0c73b445d46ad`

Machine-readable screen/state/input meaning is in `WIREFRAME_SEMANTIC.json`.
