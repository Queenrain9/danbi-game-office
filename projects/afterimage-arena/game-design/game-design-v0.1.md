# Afterimage Arena — Playable Game Design Spec v0.1

## 1. Product Definition
Top-down action-tactics duel where every path traveled becomes an attack seconds later. MVP tests whether one movement input creates satisfying present evasion and near-future offense.

## 2. Player Fantasy
Survive now with movement that becomes your weapon moments later; fight by reading where both fighters will be, not only where they are.

## 3. Core Player Verbs
Move/steer; dash; evade/lure; pause. Movement always changes current position and writes future attack geometry. Dash is recorded and grants no invulnerability.

## 4. Core Loop
Move and record → read both pending trails → lure or evade → delayed trails replay once as attacks → hits reduce HP → repeat to knockout → resolve best-of-3.

## 5. Round / Session Structure
Best-of-3. Each round: 2s neutral countdown, 3 HP each, opposite spawns, empty trails, dash ready. Recording windows are 2.5s; closed paths warn 1.0s then replay over 0.8s. Knockout clears unresolved trails. First to 2 round wins. Match target 3–6 min.

## 6. Game Rules
Every 2.5s recording window queues as an immutable afterimage while a new window starts immediately. Stationary windows create a stationary pulse. After 1.0s warning, path replays over 0.8s; touching opponent loses 1 HP, gains 0.75s immunity, and cannot be hit twice by that afterimage. Own trails are safe. Dash: 0.35s burst, 4.0s cooldown, no invulnerability. Bounds clamp positions. Fighter overlap only separates. HP 0 ends round immediately. Pause freezes every gameplay timer; restart resets full match; exit returns title.

## 7. State Model
Global: title, match_intro, round_countdown, round_active, round_resolve, match_result, paused. Fighter: HP, legal position, dash cooldown, hit immunity, recording path, queued afterimages. No transition lacks an exit.

## 8. Interaction Spec
Primary input is continuous steering: immediate locomotion + future path writing. Recording is harmless; queued is warned; only active replay damages. Dash and pause are secondary explicit actions.

## 9. Content Model
Arena, fighter, trail window, afterimage, CPU profile. Arena is one connected legal region with no holes, obstacles, or trail blockers. Variation changes silhouette and CPU behavior without new rules.

## 10. Difficulty / Variation
Rookie reacts mainly to active lines; Rival reads queued paths and dashes; Echo predicts intersections and lures. HP/timings/player rules stay fixed.

## 11. Progression
Tutorial → Rookie → Rival → Echo. Win Rookie unlocks Rival; win Rival unlocks Echo. Unlocks persist locally; losses remove nothing; no stat progression.

## 12. Economy
Not required.

## 13. Screen Inventory
Title / Mode Select; Rules Tutorial; Match Arena; Pause Overlay; Round Result; Match Result.

## 14. Screen Flow
Title → tutorial or tier → intro/countdown → active arena → round result → next round or match result → rematch/title. Pause interrupts countdown/active and resumes exact frozen state or restarts/exits.

## 15. Feedback System
Recording, queued, active and spent trail states are unmistakable. Hit pairs impact with HP decrement and immunity. Dash communicates ready/cooldown/rejection. Danger cannot rely on color alone.

## 16. Visual Direction Brief
Fixed top-down full-arena camera. Quiet floor, compact silhouettes, high-readability world-space trails. HUD confirms HP, score, dash and timing without covering geometry.

## 17. MVP Scope + NOT IN MVP
Complete player-vs-CPU delayed-trail duel, best-of-3, dash, damage/immunity, three CPU profiles, tutorial, pause/restart/exit, result/rematch and persistent tier unlocks. Not in MVP: online, unique abilities, upgrades/economy, obstacles/destruction, ranked, campaign.

## 18. Test Scenarios
Success and failure dry runs use the exact timings and HP above; additionally verify cooldown rejection, exact pause/resume, stationary pulse continuation and legal boundary samples.

## 19. Known Risks
Timing can become predictable; overlapping trails can become unreadable; touch can obscure geometry; CPU prediction can feel unfair.

## 20. Wireframe Handoff
Fun promise: every movement solves the present and writes an attack for the near future. Wireframes must cover every screen/state, simultaneous old-replay/new-recording, all trail phases, HP/round/dash/timers/immunity, hit/miss/bounds/cooldown/stationary/knockout/pause feedback, and the three CPU profiles without adding obstacles or new rules.