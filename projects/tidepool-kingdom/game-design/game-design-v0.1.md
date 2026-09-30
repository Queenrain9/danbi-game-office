# Playable Game Design Spec v0.1 — Tidepool Kingdom

## 1. Product Definition
한 화면의 바위 웅덩이에서 밀물에 유입된 생물과 자원이 썰물에 고립되며, 플레이어가 다음 조수의 생태 결과를 예측해 서식처와 제한 개입을 설계하는 모바일 미니 생태 전략 게임. MVP는 3개 authored run×6 tide cycle이며, 작은 공간의 생태 연쇄와 조수 리셋을 전략의 중심으로 둔다.

## 2. Player Fantasy
작은 조수 웅덩이의 관리자가 되어 조수를 직접 지배하지 않고, 들어올 생물의 조건과 썰물 동안의 제한된 손길만 설계해 먹이망이 스스로 굴러가는 결과를 읽고 다음 주기를 더 영리하게 준비한다.

## 3. Core Player Verbs
- **Place** — input: drag habitat/lure token to eligible rock slot; target: one of 6 habitat slots; condition: Preparation and token available; state_change: slot modifier assigned; preparation point spent; feedback: eligible slots highlight; predicted attraction tags update
- **Observe** — input: no input / tap organism; target: tidepool simulation; condition: Flood or Ebb simulation; state_change: none; inspection reveals species needs/current energy; feedback: water level, arrivals, feeding/breeding events animate
- **Intervene** — input: drag one intervention token onto organism/slot; target: valid organism or habitat; condition: Ebb Intervention window and intervention charge available; state_change: heal/relocate/shelter effect resolves; charge spent; feedback: cause/effect pulse and projected survival indicators update
- **Keep** — input: tap up to capacity survivors/resources at Cycle Review; target: eligible carryover units; condition: Review; state_change: selected units become next-cycle retained pool; feedback: capacity meter and next-cycle preview update
- **Advance** — input: tap Next Tide; target: cycle; condition: Review selection valid; state_change: cycle index+1; retained units and permanent unlocks seed next Preparation; feedback: new tide forecast revealed

## 4. Core Loop
조수 예보와 목표 확인 → 3 Preparation Points로 서식처/유도물을 6개 슬롯에 배치 → Flood에서 태그 일치 생물 유입 → Ebb가 6턴 진행되며 먹이·포식·번식·고립 규칙 자동 해결 → 각 Ebb 턴 사이 한 번의 Intervention window에서 제한 charge를 쓸지 관찰만 할지 선택 → Cycle Review에서 생존자/자원 중 carryover를 고름 → 다음 밀물에서 달라진 먹이망을 시험한다. 핵심 재미는 제한 개입이 낳은 연쇄 결과를 읽고 다음 조수를 예측하는 데 있다.

## 5. Round / Session Structure
한 Run은 6 Tide Cycles, 약 12–18분. 각 Cycle은 Forecast/Preparation → Flood Arrival → Ebb 6 turns(각 turn: Ecology Resolve → Intervention Window) → Cycle Review. Preparation은 시간 제한 없음. Ebb ecology resolve는 1.0초 연출 후 intervention 입력 대기이며 자동 진행하지 않는다. 플레이어가 Continue를 누르면 다음 turn. Cycle 6 Review 뒤 Run Result. 각 cycle 목표를 달성하면 1 Reef Mark, 실패해도 run은 계속되며 최종 4+ Marks면 run success, 0–3이면 run failure. Pause는 모든 연출/입력을 정지. Retry Cycle은 해당 cycle 시작 snapshot으로 복구하며 run당 1회.

## 6. Game Rules
```json
{
  "board": {
    "slots": 6,
    "adjacency": "ring: slot i adjacent to (i+5)%6 and (i+1)%6",
    "occupancy": "each slot holds max 1 habitat modifier; organisms have no hard count cap but species population per slot max 4"
  },
  "resources": {
    "preparation_points": "3 each cycle; placement costs 1; unspent do not carry",
    "intervention_charges": "2 each cycle; each intervention costs 1; do not carry",
    "carryover_capacity": "2 units at Review; unit is one organism OR one resource bundle",
    "reef_marks": "0..6, +1 when cycle objective passes; never spent"
  },
  "flood": {
    "trigger": "Preparation confirmed",
    "arrival": "case table lists 3 candidate species. Each candidate has required attraction tag. If at least one slot modifier exposes that tag, spawn authored count into lowest-index matching slot with population<4; otherwise it does not enter. Ties use lowest slot index.",
    "resources": "each resource-producing habitat creates 1 resource bundle in its slot at Flood"
  },
  "ebb": {
    "turns": 6,
    "order": [
      "resource production",
      "feeding",
      "predation",
      "energy loss",
      "death",
      "breeding"
    ],
    "sampling": "integer state at start of each substep; slot order 0→5, species priority authored per case"
  },
  "feeding": "Herbivore/forager with matching food bundle in same slot consumes 1 bundle and gains +2 energy, capped at species max_energy.",
  "predation": "Each predator with energy below max_energy targets one prey in same slot first, then clockwise adjacent slot, then counterclockwise; eligible prey tags are species-authored. Target lowest current energy, tie by authored species priority. Predator gains +2 energy capped; prey removed.",
  "energy": "After feeding/predation, every organism loses 1 energy. energy<=0 removes organism.",
  "breeding": "At breeding substep, if same-species count in a slot >=2, each has energy>=2, and population<4, create exactly 1 offspring energy=2; parents each lose 1 energy. Max one birth per species per slot per turn.",
  "interventions": {
    "heal": "target organism; +2 energy capped; costs 1 charge",
    "relocate": "target organism then adjacent slot; destination population for species <4; move organism; costs 1",
    "shelter": "target slot; until next ecology resolve ends, first predation attempt against prey in that slot is cancelled; then shelter expires; costs 1",
    "invalid": "invalid target or no charge spends nothing"
  },
  "objectives": "Each cycle has one authored boolean objective evaluated after Ebb turn 6: species_survival(species,count>=N), balanced_pair(A>=N and B>=M), or resource_reserve(tag,bundles>=N). N/M are explicit case data.",
  "review": "Eligible carryover = surviving organisms plus resource bundles. Select 0–2. Unselected organisms/resources are discarded at next cycle start. Retained organisms seed their current energy and slot if slot remains valid; retained resource bundle stays same slot. New Preparation may replace habitat modifier without removing retained organism.",
  "failure_recovery": "A cycle objective miss awards no Mark but proceeds. Run failure only after cycle 6 if marks<4. Retry Cycle once per run restores exact cycle-start snapshot including marks, retained pool, and retry availability then consumes retry; it does not reroll authored forecast.",
  "success": "After cycle 6, marks>=4.",
  "pause": "Freezes ecology animation and prevents state changes; Resume returns exact state."
}
```

## 7. State Model
```json
[
  {
    "state": "Run Map",
    "enter": "game entry/result",
    "allowed_inputs": [
      "start unlocked run"
    ],
    "variables": [
      "unlocked_run",
      "best_marks"
    ],
    "exit": "run selected",
    "failure_cancel": "none",
    "next": "Forecast"
  },
  {
    "state": "Forecast",
    "enter": "cycle start",
    "allowed_inputs": [
      "continue",
      "quit"
    ],
    "variables": [
      "cycle",
      "candidate species",
      "objective"
    ],
    "exit": "continue",
    "failure_cancel": "quit→Run Map",
    "next": "Preparation"
  },
  {
    "state": "Preparation",
    "enter": "forecast continue",
    "allowed_inputs": [
      "place/remove modifiers",
      "confirm",
      "pause"
    ],
    "variables": [
      "3 prep points",
      "6 slots"
    ],
    "exit": "confirm",
    "failure_cancel": "remove refunds point before confirm",
    "next": "Flood"
  },
  {
    "state": "Flood",
    "enter": "confirm",
    "allowed_inputs": [
      "pause"
    ],
    "variables": [
      "arrivals",
      "resources"
    ],
    "exit": "arrival animation complete",
    "failure_cancel": "none",
    "next": "Ebb Resolve"
  },
  {
    "state": "Ebb Resolve",
    "enter": "flood or Continue",
    "allowed_inputs": [
      "pause"
    ],
    "variables": [
      "turn 1..6",
      "populations",
      "energy",
      "resources"
    ],
    "exit": "ordered ecology steps complete",
    "failure_cancel": "none",
    "next": "Intervention"
  },
  {
    "state": "Intervention",
    "enter": "resolve complete",
    "allowed_inputs": [
      "heal",
      "relocate",
      "shelter",
      "continue",
      "pause"
    ],
    "variables": [
      "charges"
    ],
    "exit": "continue",
    "failure_cancel": "invalid input no-op",
    "next": "Ebb Resolve or Review after turn6"
  },
  {
    "state": "Review",
    "enter": "turn6 intervention continue",
    "allowed_inputs": [
      "select carryover",
      "next tide",
      "retry cycle if available",
      "pause"
    ],
    "variables": [
      "objective pass",
      "marks",
      "eligible units"
    ],
    "exit": "next/retry",
    "failure_cancel": "selection >2 invalid",
    "next": "Forecast, Preparation(snapshot retry), or Run Result after cycle6"
  },
  {
    "state": "Pause",
    "enter": "pause",
    "allowed_inputs": [
      "resume",
      "quit"
    ],
    "variables": [
      "return_state"
    ],
    "exit": "choice",
    "failure_cancel": "quit abandons run",
    "next": "return_state or Run Map"
  },
  {
    "state": "Run Result",
    "enter": "cycle6 review completion",
    "allowed_inputs": [
      "replay",
      "map"
    ],
    "variables": [
      "marks",
      "success"
    ],
    "exit": "choice",
    "failure_cancel": "none",
    "next": "Forecast or Run Map"
  }
]
```

## 8. Interaction Spec
```json
{
  "placement": "Drag modifier to slot; valid only Preparation, empty modifier slot and prep point>0. Drag existing modifier away removes/refunds before confirm.",
  "inspect": "Tap organism opens read-only species/energy/food/predator tags; never changes simulation.",
  "intervene": "One drag/tap action resolves immediately and spends exactly 1 charge only if valid.",
  "continue": "During Intervention advances exactly one ecology turn; after turn6 goes Review.",
  "carryover": "Tap toggles eligible unit selection; max2; Next Tide always valid with 0–2 selected.",
  "priority": "Pause blocks all play input; active drag owns pointer; Continue disabled while drag active."
}
```

## 9. Content Model
```json
{
  "unit": "6-cycle authored tidepool run",
  "mvp_runs": 3,
  "classes": [
    {
      "type": "Food Chain",
      "difference": "producer/forager/predator dependencies; uses feeding+predation"
    },
    {
      "type": "Crowded Nursery",
      "difference": "population cap and breeding are objective-relevant"
    },
    {
      "type": "Refuge Puzzle",
      "difference": "predation pressure makes Shelter/Relocate timing objective-relevant"
    },
    {
      "type": "Resource Reserve",
      "difference": "resource bundles must survive unconsumed for objective/carryover"
    },
    {
      "type": "Mixed Web",
      "difference": "combines prior classes without new rules"
    }
  ],
  "species_schema": "id,tags,food_tag,prey_tags,max_energy,start_energy,priority,attraction_tag",
  "run_schema": "6 cycle forecasts; candidate species/spawn counts; modifier pool/tags; objective type+explicit thresholds",
  "variation_axes": [
    "candidate species mix",
    "spawn counts",
    "modifier tag choices",
    "starting retained units",
    "objective type/threshold",
    "species energy/prey graph",
    "resource production",
    "cycle ordering"
  ],
  "coverage": "Across 3 runs/18 cycles every base class appears at least twice and each intervention is required by at least one solvable authored cycle.",
  "solvability": "Every cycle is admitted only with at least one validated sequence from its cycle-start snapshot that can satisfy its objective using <=3 prep points and <=2 interventions."
}
```

## 10. Difficulty / Variation
Run 1 isolates attraction→feeding, then simple predator and breeding. Run 2 introduces competing food demand, adjacency predation and resource-reserve tradeoffs. Run 3 uses Mixed Web cycles where carryover choices alter the next forecast response and two dependencies must be managed simultaneously. No faster timer; difficulty grows through dependency depth, competing uses of charges, and carryover opportunity cost.

## 11. Progression
Three authored runs unlock linearly; Run 1 available initially, success (>=4 Marks) unlocks next. Best Marks 0–6 stored per run. Species encountered are added to a read-only Field Guide, which is informational only and grants no bonuses.

## 12. Economy
Not required. Prep points/intervention charges are cycle-local action budgets; Reef Marks are run score/progression and are not spent.

## 13. Screen Inventory
- Run Select / Tidepool Map
- Cycle Forecast
- Tidepool Gameplay (Preparation/Flood/Ebb/Intervention)
- Cycle Review
- Run Result
- Field Guide

## 14. Screen Flow
Entry→Run Select→Forecast→Preparation→Flood→(Ebb Resolve→Intervention)×6→Review→next Forecast; after cycle6 Review→Run Result→Map/replay. Review can Retry Cycle once per run, restoring cycle-start snapshot. Pause overlays Preparation/Flood/Ebb/Intervention/Review and resumes exact state. Field Guide opens from Run Select and returns there.

## 15. Feedback System
```json
{
  "forecast": "candidate silhouettes/tags and objective shown before commitment",
  "placement": "valid slots highlight; attraction tag response updates",
  "ecology": "feeding/predation/birth/death each has distinct concise animation and cause icon",
  "intervention": "valid target highlight and charge decrement; invalid target shakes/no spend",
  "review": "objective terms individually show pass/fail and carryover capacity",
  "progression": "Reef Mark gain and next-run unlock shown only after relevant result"
}
```

## 16. Visual Direction Brief
Landscape or wide portrait-compatible single-screen rock tidepool diorama with six logically distinct habitat pockets arranged as a ring; water level visibly changes between Flood and Ebb. Organisms must be readable by silhouette/tag at small scale and cause/effect events should be legible without spreadsheet density. UI supports the living pool rather than replacing it. Exact coordinates, panel geometry and final art treatment are Wireframe responsibility.

## 17. MVP Scope + NOT IN MVP
3 authored runs × 6 tide cycles = 18 cycles; 6-slot ring topology; 8–10 species drawn from producer/forager/predator roles; habitat/lure modifiers using attraction/resource tags; Flood arrival; six-turn deterministic Ebb ecology; Heal/Relocate/Shelter interventions; three objective families; 2-unit carryover; one cycle retry per run; Reef Marks, linear run unlock, best score, read-only Field Guide, pause/quit.

**NOT IN MVP**
- Freeform terrain building
- Real-time continuous ecosystem simulation
- Weather/seasons beyond authored tide forecasts
- Genetics/evolution
- Breeding trait inheritance
- Currency/shop
- Online features
- Procedural runs
- More than 3 MVP runs
- Species combat controlled directly

## 18. Test Scenarios
- Preparation with a matching attraction tag spawns candidate species in the lowest-index eligible slot; no matching tag means no arrival.
- Predator target order is same slot→clockwise→counterclockwise, lowest energy then species priority; prey removal and predator energy happen before global energy loss.
- Two same-species organisms energy>=2 in a slot with count<4 create exactly one offspring then each parent loses 1 energy.
- Shelter cancels exactly the first predation attempt into its slot during the next Resolve and then expires.
- An invalid intervention with zero charges or invalid target changes nothing and spends nothing.
- After turn6 an explicit survival objective passes/fails from final integer population and awards exactly 1 or 0 Reef Mark.
- Selecting 2 carryover units seeds next cycle; selecting a third is rejected; selecting zero remains valid.
- Retry Cycle restores the cycle-start snapshot and consumes the run's single retry without rerolling forecast.
- After six cycles marks>=4 reaches success and unlocks next run; marks<=3 reaches failure but replay remains available.

## 19. Known Risks
- Deterministic ordered ecology can feel opaque unless event causality is visually clear
- Six turns times eighteen cycles may become repetitive if authored dependency shapes are too similar
- Carryover can create unwinnable-looking states unless every authored cycle is validated from reachable snapshots
- Ring adjacency must be visually obvious without forcing a board-game abstraction
- Inspection information can become text-heavy on mobile

## 20. Wireframe Handoff
- fun_promise: 밀물/썰물의 리셋 리듬 속에서 제한된 개입 하나가 먹이망의 연쇄 결과를 바꾸고, 그 결과를 학습해 다음 조수를 준비하는 느낌이 중심이다.
- Represent all screens: Run Select, Forecast, Tidepool Gameplay, Cycle Review, Run Result, Field Guide.
- Represent Preparation, Flood, Ebb Resolve, Intervention, Review, Pause and terminal result states, including exact return paths.
- Show six-slot ring adjacency as rule-relevant structure without changing adjacency semantics.
- Cover Food Chain, Crowded Nursery, Refuge Puzzle, Resource Reserve and Mixed Web content classes.
- Show modifier drag/place/remove/refund, organism inspect, Heal/Relocate/Shelter targeting, Continue, carryover select and invalid/no-op states.
- Show 3 prep points, 2 intervention charges, 6 Ebb turns, 0–2 carryover capacity, Reef Marks 0–6 and one-run retry availability.
- Make feeding, predation, energy loss, death, breeding and shelter cancellation distinguishable as ordered causes; do not invent new simulation rules.
- Represent cycle objective pass/fail, carryover, next tide, retry snapshot, cycle6 run success/failure and unlock/replay flows.