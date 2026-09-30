# Moving City Blocks — Playable Game Design Spec v0.1

## 1. Product Definition
매일 밤 도시의 건물들이 한 칸씩 이동하는 세계에서 도로와 서비스망이 끊기기 전에 건물 이동 순서를 설계하는 도시 전략 게임. A deterministic mobile strategy/puzzle MVP about ordering forecasted building movement so a city's road, power, and resident-service networks survive nightly topology changes. The core promise is planning a sequence, then watching the city visibly break and reconnect because of that sequence.

## 2. Player Fantasy
매일 밤 도시 자체가 움직이는 불안정한 세계에서, 내일의 이동 규칙을 읽고 건물의 이동 순서를 설계해 필수 서비스망을 살아 있게 만드는 야간 도시 조정관.

## 3. Core Player Verbs
- **inspect** — input: tap/select; target: next-night rule and building; condition: planning; state_change: reveals legal destination and dependency impact preview; feedback: affected links and service coverage preview.
- **schedule** — input: select building then order slot; target: movable building; condition: planning and unused order slot; state_change: adds/reorders building in move queue; feedback: ghost destination and projected network changes.
- **commit** — input: confirm; target: move queue; condition: all mandatory movers scheduled or explicitly left to automatic rule order; state_change: planning→night_resolution; feedback: queue locks and moves resolve one by one.
- **repair** — input: select one eligible building and adjacent legal cell; target: disconnected city; condition: repair state and repair charge available; state_change: one post-night adjacent relocation; feedback: network recomputes immediately.
- **advance** — input: continue; target: resolved day; condition: success evaluation complete; state_change: day index advances and next rule loads; feedback: day result and next-night forecast.

## 4. Core Loop
Forecast the next night rule → inspect dependencies → order eligible building moves → commit → watch sequential moves alter roads/power/resident access → if still viable, optionally spend the single repair move to restore a broken critical link → evaluate city viability → advance to a harder rule/day. The fun is prediction plus watching a planned sequence create cascading disconnections/reconnections, not freeform city building.

## 5. Round / Session Structure
One day is one planning/resolution cycle. Planning has no timer. Commit resolves the queued legal moves in order. Then a single repair phase occurs only if a repair can change topology. Evaluation ends the day. An MVP session is 5 days; clearing at least 4 days and the final day wins the session. A failed day may be retried from that day's pre-planning snapshot; three failed day attempts end the session.

## 6. Game Rules
- **Grid:** Orthogonal square grid. Each cell is empty or holds exactly one building. Network adjacency is orthogonal only; diagonal contact never connects.
- **Night move:** Each night rule defines eligible building classes, direction vector, and move count (MVP count=1 cell). Scheduled buildings move sequentially. A move is legal only if destination is in bounds and empty at that exact resolution step. Illegal queued moves are skipped and marked blocked; they still consume that building's scheduled action.
- **Queue:** Every eligible building receives exactly one night action. Player orders any subset; unscheduled eligible buildings resolve afterward in stable reading order top-to-bottom then left-to-right. Reordering therefore changes occupancy and network outcomes without inventing extra movement.
- **Networks:** Road connectivity is a graph of road-bearing cells by orthogonal adjacency. Power flows from each power source through power-link cells/buildings. A residence is served only if it has orthogonal access to the road network containing a civic hub AND is powered through the power graph.
- **Success:** After repair, day succeeds when at least 70% of residences are served and every critical building (civic hub, clinic, power source) is road-connected to the civic hub; power source itself need not be powered.
- **Failure/recovery:** If success condition is false after repair or player chooses Evaluate with no repair, day fails. Retry restores exact pre-planning snapshot including rule and repair charge. After 3 failed attempts on one day, session fails.
- **Repair:** One repair charge per day, non-bankable. During repair, relocate exactly one non-critical building one orthogonal cell into an empty in-bounds cell; destination must be legal. It cannot move civic hub, clinic, or power source. Repair is optional and then consumed.
- **Pause/persistence:** Pause is available in planning and repair; it freezes input/resolution state and can resume. During night resolution pause may stop animation but not alter queue. Exit during a day resumes from pre-planning snapshot, never mid-resolution.
- **Progression rule:** Day completion unlocks the next day. Session day 1 uses one moving class and simple vector; later days combine building classes, blockers, denser dependencies, and alternating direction rules. No permanent stat upgrades.

## 7. State Model
- session_setup → planning
- planning → night_resolution, paused
- night_resolution → repair, evaluation, paused
- repair → evaluation, paused
- evaluation → day_result
- day_result → planning, session_result
- paused → planning, repair, night_resolution
- session_result → session_setup

## 8. Interaction Spec
- **forecast inspection:** Selecting rule/building previews only deterministic effects of current queue; it never changes state.
- **queue editing:** Tap eligible building to add; drag/order controls reorder scheduled actions; remove returns it to automatic tail.
- **commit:** Explicit confirmation required; queue editing disabled until resolution completes.
- **repair relocation:** Select eligible building then one highlighted adjacent empty cell; confirm consumes charge.
- **retry:** From failed day result, Retry restores pre-planning snapshot and increments failed-attempt count.

## 9. Content Model
Content classes: residence, road segment, civic hub, clinic, power source, power-link building, neutral blocker. Night rule schema: eligible class set + cardinal direction + one-cell distance + row-major automatic tail. Topology: finite orthogonal grid, one occupant per cell, orthogonal road and power edges, residence service requires both hub-road access and power. Variation axes: grid shape/size, starting occupancy, eligible class set, movement direction, critical-building placement, road/power overlap, neutral blockers, residence count. Every authored scenario must be solvable under the one-repair limit.

## 10. Difficulty / Variation
Days escalate by dependency density rather than faster input: Day 1 single moving class and spare cells; Day 2 tighter road continuity; Day 3 power and road interactions; Day 4 two eligible classes and occupancy-order conflicts; Day 5 combines dense critical links and alternating forecast rule. Exact maps and numeric content instances remain content-authoring choices subject to solvability constraint.

## 11. Progression
Five-day run. Clearing a day records best result (served residence ratio, repair unused, blocked moves) for feedback only. Next day unlocks linearly. No grind, XP, unlock currency, or meta-upgrades in MVP.

## 12. Economy
Not required. Repair is a per-day tactical allowance, not currency.

## 13. Screen Inventory
- Session Select / Day Map
- Planning Board
- Night Resolution
- Repair Phase
- Day Result
- Session Result
- Pause Overlay

## 14. Screen Flow
Session Select → Planning Board → Commit → Night Resolution → (Repair Phase if available/desired) → Evaluation → Day Result. Success → next Planning Board or Session Result after Day 5. Failure → Retry same day from snapshot or, after third failure, Session Result. Pause overlays Planning/Resolution/Repair and returns to the exact prior state.

## 15. Feedback System
- **queue change:** numbered move order, ghost destination, projected broken/formed network links
- **move resolves:** building slides one cell; affected road/power edges switch immediately
- **blocked move:** move stops, blocked marker and reason shown
- **service change:** residence served/unserved state changes immediately after each move
- **repair:** eligible cells highlight; confirmed relocation recomputes networks
- **evaluation:** served ratio, critical connectivity, pass/fail reasons
- **retry:** board visibly restores to exact start-of-day snapshot and attempt counter increments

## 16. Visual Direction Brief
Readable top-down/near-top-down city board with persistent grid topology. Buildings must read primarily by silhouette/icon class, while road/power links remain legible above decorative art. Night resolution emphasizes one move at a time and cascading link changes. UI supports the world board rather than obscuring it; no fixed coordinates are prescribed.

## 17. MVP Scope + NOT IN MVP
**MVP:** One complete five-day run; deterministic orthogonal grid; 7 building/content classes; forecasted nightly one-cell movement rules; player move ordering; road + power + residence service simulation; one optional repair per day; pass/fail/retry/session result; pause/resume and pre-day persistence.
**NOT IN MVP:** freeform construction, economy/currency, procedural infinite city, citizen simulation, combat, online features, cosmetic shop, meta upgrades, diagonal networks, multi-cell nightly movement.

## 18. Test Scenarios
- Success dry run: 10 residences start served; after ordered moves 8 remain served, all civic hub/clinic/power source road-connected; player skips repair; 80%≥70%, day succeeds and next day loads.
- Repair success: after night 6/10 residences served because one movable neutral building breaks a road gap; repair relocates that non-critical building to an adjacent empty cell, road reconnects, 8/10 served and critical buildings connected; day succeeds and repair is consumed.
- Failure/retry: after night 5/10 residences served and clinic disconnected; repair cannot produce both conditions; evaluation fails. Retry restores exact initial board/rule, attempt becomes 2; third failed attempt ends session.
- Order conflict: A and B target cells affected by occupancy. A-first opens B destination and both move; B-first finds its destination occupied and is blocked. Network recomputes after each resolved action.
- Pause/exit: pause during planning returns unchanged; exit during repair and reopen restores the day's pre-planning snapshot, not partial resolution.

## 19. Known Risks
- Move-order consequences may be hard to predict if previews do not clearly distinguish current versus projected topology.
- Two overlapping networks can create visual clutter; road, power, and service status need distinct readable channels.
- Authored day content can accidentally be unsolvable; every day instance requires solvability validation against the one-repair rule.
- Automatic tail order must remain visible or players may misread unscheduled buildings as stationary.

## 20. Wireframe Handoff
- fun_promise: The player should enjoy predicting and then watching a chosen building-move order break and reconnect a living city network; ordering consequences are the center of play.
- Represent all seven screen types and planning/resolution/repair/evaluation/result/pause states; do not collapse later-day two-class/order-conflict variations into the tutorial case.
- Planning must expose next-night eligible classes, direction, automatic tail order, current queue, deterministic destination previews, and projected network/service changes.
- Resolution must show sequential occupancy changes and immediate road/power/service recomputation; blocked actions remain visible with reason.
- Repair must permit exactly one optional adjacent relocation of a non-critical building into an empty legal cell, then evaluation.
- Day Result must state served ratio, critical connectivity, repair use, blocked moves, attempt count, and retry/continue availability.
- Wireframes may choose layout and control placement, but may not alter orthogonal topology, movement legality, success threshold, retry snapshot semantics, or five-day session structure.

### Card Fields
- primary_interaction: Inspect forecast, order building moves, commit, then optionally relocate one building to repair network continuity.
- session_length: 10–20 minutes for a five-day MVP run; individual day 2–4 minutes.
- content_unit: One day scenario = starting grid + building instances + night rule + solvability-valid topology.
- mvp_scope: One complete five-day run; deterministic orthogonal grid; 7 building/content classes; forecasted nightly one-cell movement rules; player move ordering; road + power + residence service simulation; one optional repair per day; pass/fail/retry/session result; pause/resume and pre-day persistence.
- screen_inventory: Session Select / Day Map, Planning Board, Night Resolution, Repair Phase, Day Result, Session Result, Pause Overlay
- known_risks: Move-order consequences may be hard to predict if previews do not clearly distinguish current versus projected topology. | Two overlapping networks can create visual clutter; road, power, and service status need distinct readable channels. | Authored day content can accidentally be unsolvable; every day instance requires solvability validation against the one-repair rule. | Automatic tail order must remain visible or players may misread unscheduled buildings as stationary.
