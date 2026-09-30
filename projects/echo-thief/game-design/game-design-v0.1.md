# Playable Game Design Spec v0.1 — Echo Thief

## 1. Product Definition
Portrait mobile top-down stealth puzzle. In compact museum missions, the player records environmental sounds, stores up to two as tokens, throws them onto floor positions to redirect sound-driven guards, steals one target exhibit, and escapes. Sessions are 3–7 minutes. The Original Fun Promise is that sound itself is understandable ammunition: capture it, place it, watch patrol logic bend.

## 2. Player Fantasy
플레이어는 소리를 훔쳐 미끼처럼 저장하고 재배치해 경비의 청각을 속이는 침입자다. 총이나 전투 대신 ‘무엇을 어디서 녹음해 어디에 울릴지’로 순찰 동선을 바꾸고 전시품을 훔쳐 빠져나가는 것이 핵심 판타지다.

## 3. Core Player Verbs
Observe — inspect patrols and recordable sources. Record — hold 1.0s within 1.5 tiles to store a sound token. Throw — drag a token to a valid floor tile within 6 tiles to create a lure. Move — tap a reachable tile to path there. Steal — hold 0.6s adjacent to the target while unseen. Escape — enter the exit while carrying the target.

## 4. Core Loop
Read room topology and patrols → record useful sound → throw it where its propagation will pull a guard → move through the opened route → repeat with new/reused sources as needed → steal target → reconstruct route with lures → reach exit.

## 5. Round / Session Structure
Mission Brief → Planning → Infiltration → Success or Caught → Result. Each mission has one target and one exit, 1–3 guards, 2–4 reusable sound sources, and no global timer. Success unlocks the next mission; failure offers Retry. Expected 3–7 minutes.

## 6. Game Rules
Rooms are orthogonally connected walkable tile graphs. Walls block movement, sight, throw line, and sound unless a doorway edge connects space. Guard vision extends 5 tiles in facing cone; 0.75s continuous exposure or sharing a tile causes Caught. A thrown sound lasts 2s and propagates by shortest walkable path up to its lure strength. Hearing guards choose strongest audible event, newest on ties, path to it, investigate 2s, then return to the patrol node they left. A new audible event replaces their investigation.
Record requires 1.0s uninterrupted hold within 1.5 path-distance tiles; cancel costs nothing. Inventory capacity is 2. Throw consumes one token only on valid release to a walkable tile within Manhattan distance 6 with unobstructed throw segment; invalid release changes nothing. Steal requires adjacency and 0.6s stationary hold while not visible; visibility cancels the hold, while 0.75s exposure still causes Caught. Exit succeeds only while carrying target. Pause freezes actors/timers/events; Retry resets all mission-local state. Every mission must retain at least one reachable reusable source and a start→target→exit walkable route so depletion cannot soft-lock play.

## 7. State Model
Mission: Brief, Planning, Infiltration, Caught, Success, Result, Paused. Player: Free, Recording, Moving, Stealing, CarryingTarget. Guard: Patrol, InvestigateSound, ReturnToPatrol. Detection overrides holds; Pause preserves exact active state except timers are frozen.

## 8. Interaction Spec
Top-down fixed gameplay view. Tap floor to move, hold a source to record, drag a stored token to throw, hold target to steal, tap guards/sources to inspect. Active token drag suppresses move taps; Record/Steal holds lock movement until complete/cancel. Invalid actions never mutate state and always return immediate feedback.

## 9. Content Model
MVP: 8 authored missions. Mission schema = walkable room graph + player start + one target + one exit + 1–3 guards with cyclic patrol nodes + 2–4 sources. Sound classes: Clock strength4, Squeaky Cart5, Radio6, Bell7. Guard content varies patrol length but uses one rule set. Variation axes: topology, guard count, patrol overlap, source placement/strength, target/exit separation. No content type adds a new mechanic.

## 10. Difficulty / Variation
Missions 1–2 teach one-guard lure and recovery; 3–4 add longer routes and weaker/stronger source choices; 5–6 add two guards and overlapping hearing zones; 7–8 use 2–3 guards, tighter topology, and overlapping patrol/vision. Difficulty comes from composing the same sound-placement rule, not extra systems.

## 11. Progression
Mission 1 unlocked initially. Successful mission unlocks exactly the next mission. Best completion is stored per mission; failure never removes unlocks. No mechanical upgrades.

## 12. Economy
Not required. Sound tokens are mission-local tactical resources and not currency.

## 13. Screen Inventory
Mission Select; Mission Brief; Museum Gameplay; Pause Overlay; Mission Result.

## 14. Screen Flow
Select → Brief → Planning → Infiltration. Detection → Caught → failure Result → Retry/Select. Exit with target → Success → Result → Next/Retry/Select. Pause can overlay Planning/Infiltration and resumes exact state.

## 15. Feedback System
Guard vision cone plus exposure meter; sound propagation ring/path and attention cue on hearing; record fill and token waveform; valid throw preview and invalid rejection; investigation marker; target pickup changes objective to exit; Result names caught/success cause. Exposure clears after 0.5s fully unseen.

## 16. Visual Direction Brief
Readable top-down museum diorama, compact rooms, high contrast between walkable space/walls/doorways, guard vision, sound propagation, player and objective. UI should support the world simulation rather than obscure it. Camera framing must keep tactical relationships legible; exact coordinates/layout belong to Wireframe.

## 17. MVP Scope + NOT IN MVP
8 authored missions, 1 target each, 1–3 guards, 2–4 sources, four source strengths, two-token inventory, deterministic sound priority/pathing, patrol/investigate/return, sight detection, steal/escape, pause/retry, linear unlock. NOT IN MVP: combat, takedowns, procedural maps, hub, upgrades, currency/shop, online play, microphone/player-authored sounds, multi-target missions.

## 18. Test Scenarios
1) Record Radio6 → throw behind guard → guard investigates → pass behind → steal unseen → lure again if needed → exit with target → Success. 2) Stay in vision 0.75s → Caught → Retry → exact authored reset. 3) Invalid throw through wall/beyond 6 keeps token. 4) Two audible sounds resolve strongest then newest. 5) Full two-token inventory blocks record until one is thrown. 6) Pause freezes investigation timer. 7) Later multi-guard missions use identical rules without new interactions.

## 19. Known Risks
Sound reach may be hard to predict; rerouting may feel arbitrary without priority feedback; tap movement and token drag may conflict; layouts may permit trivial lure-and-run solutions; overlapping guards can create accidental impossibility.

## 20. Wireframe Handoff
fun_promise: 소리를 탄약처럼 녹음·저장·던져 경비 동선을 직접 재구성하는 잠입 놀이를 가장 선명하게 보여준다.
Cover all five screens and Brief/Planning/Infiltration/Caught/Success/Paused states. Show topology, guards/patrol/vision, sources, two-token inventory, record hold, throw validity and propagation, investigate/return, detection exposure, steal hold/cancel, carried-target exit objective, failure retry, success progression, pause/resume. Include basic one-guard and later overlapping multi-guard variations without inventing new rules.
