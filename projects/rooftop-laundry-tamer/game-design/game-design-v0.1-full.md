# Playable Game Design Spec v0.1 — Rooftop Laundry Tamer

## 1. Product Definition
바람 센 옥상에서 살아 움직이는 빨래의 고정점을 집게로 잡고 줄 장력을 조절해 돌풍을 버티며 목표 실루엣으로 말리는 모바일 물리 배치 퍼즐. Portrait mobile physics placement puzzle. Session 3–8 minutes. Non-goals: Freeform cloth editor, Cosmetic shop, Currency, Narrative dialogue, Online leaderboards, Real fluid simulation, More than two lines, Procedural missions.

## 2. Player Fantasy
플레이어는 괴짜 옥상 세탁소의 빨래 조련사다. 천의 당김과 바람 방향을 읽어 최소한의 집게와 장력 조작으로 거대한 빨래를 안정시키고, 돌풍 직전의 불안을 손으로 제압하는 촉각적 숙련감을 느낀다.

## 3. Core Player Verbs
- **Pin** — input: drag cloth anchor to free line clip point then release; target: cloth anchor + line clip point; condition: Setup/Recovery; clip available; anchor unpinned; state change: clip_count-1; anchor pinned; cloth constraint created; feedback: snap/tension preview.
- **Unpin** — input: long-press pinned anchor then drag away; target: pinned anchor; condition: Setup/Recovery; state change: constraint removed; clip_count+1; feedback: release snap.
- **Slide Clip** — input: drag pinned clip along its line; target: pinned clip; condition: Setup/Recovery; state change: clip normalized line position changes and cloth tension recalculates; feedback: live tension/shape.
- **Adjust Tension** — input: vertical drag on line tension handle; target: active clothesline; condition: Setup/Recovery; state change: line tension changes among Loose/Medium/Tight; feedback: line sag and cloth response.
- **Commit Drying** — input: tap Dry; target: current setup; condition: at least 2 pins and no anchor overstressed; state change: enters Wind Test; feedback: wind forecast locks and test starts.

## 4. Core Loop
의뢰의 목표 실루엣·바람 예보 확인 → 천의 anchor를 줄에 Pin하고 clip 위치/line tension 조정 → Dry를 눌러 8초 Wind Test → 돌풍 중 pin이 풀리거나 shape가 무너지면 Recovery에서 제한 시간 없이 재배치 → 안정 구간을 모두 통과하면 shape accuracy로 등급 산정 → 다음 의뢰/재도전.

## 5. Round / Session Structure
MVP 의뢰 12개. 각 의뢰는 Setup → Wind Test 1~3 phases → 필요 시 Recovery → Result. Setup/Recovery는 무제한 시간. Wind phase는 8초이며 phase 종료 시 stability 판정. 모든 phases를 통과하면 success. Cloth의 pinned anchors가 1개 이하가 되는 순간 즉시 Blowaway failure. Result에서 Next/Retry/Home. 세션은 의뢰 1~3개, 3~8분.

## 6. Game Rules
```json
{
  "cloth": {
    "anchors": "각 cloth는 4~8개의 authored perimeter anchors. anchor는 pinned/unpinned이며 한 anchor당 clip 1개.",
    "shape_accuracy": "목표 silhouette의 8개 authored landmark와 현재 cloth landmark 사이 normalized distance 평균을 사용: accuracy=max(0,100-mean_distance*100). normalized distance는 mission cloth bounding-box diagonal=1 기준.",
    "success_accuracy": 75
  },
  "clips": {
    "capacity": "mission별 3~6개",
    "pin": "free clip point에만 사용; 동일 line point 중복 불가",
    "refund": "Unpin 즉시 1개 반환"
  },
  "lines": {
    "count": "mission별 1~2개",
    "clip_points": "각 line에 9개의 논리 slot(0.0,0.125...1.0). Slide는 인접 slot 단위로 snap.",
    "tension": [
      "Loose",
      "Medium",
      "Tight"
    ],
    "stress_multiplier": {
      "Loose": 0.75,
      "Medium": 1,
      "Tight": 1.3
    }
  },
  "wind": {
    "direction": "8방향 enum",
    "strength": "1~3",
    "phase_seconds": 8,
    "gusts": "phase마다 authored 2~4회; 각 gust는 1초 예고 후 1.5초 적용",
    "load": "anchor load = wind_strength * exposed_factor(1.0) * tension multiplier. MVP는 모든 pinned anchor에 동일 load."
  },
  "pin_failure": {
    "threshold": 3,
    "trigger": "gust 적용 중 anchor load>3.0이면 해당 gust 시작 0.5초 후 그 anchor가 풀림",
    "result": "constraint 제거, clip은 line에 남아 free clip이 되어 inventory로 즉시 반환되지 않음; Recovery 진입 시 free line clips가 inventory로 회수됨",
    "recovery": "gust 종료 즉시 Wind Test 중단 후 Recovery. 이미 통과한 phase는 유지; 해당 phase는 처음부터 재시험."
  },
  "blowaway": {
    "trigger": "어느 시점이든 pinned anchor<=1",
    "result": "즉시 mission failure Result",
    "recovery": "Retry only"
  },
  "stability": {
    "phase_pass": "8초 종료 시 pinned anchors>=2 and accuracy>=75",
    "phase_fail": "accuracy<75이면 Recovery; phase restart",
    "mission_success": "모든 authored phases pass"
  },
  "score": "success score = accuracy_final*10 + unused_clips*100 + first_try_phases*150. failure score=0.",
  "pause": "Wind Test timer/gust/cloth simulation 모두 정지. Setup/Recovery도 입력 정지.",
  "reset": "Retry는 cloth pose, anchors, clips, line tension, phase index, score를 mission initial state로 reset."
}
```

## 7. State Model
- **Mission Select** — enter: Home/Result Next; allowed: select unlocked mission, Home; variables: ; exit: mission selected; failure/cancel: none; next: Setup.
- **Setup** — enter: mission start; allowed: Pin, Unpin, Slide Clip, Adjust Tension, Dry, Pause; variables: anchors, clips, line tension, accuracy; exit: valid Dry; failure/cancel: none; next: Wind Test.
- **Wind Test** — enter: Dry/Recovery retry; allowed: Pause; variables: phase timer, gust state, pinned count, accuracy; exit: phase pass or gust/accuracy fail; failure/cancel: pinned<=1 -> Result failure; next: Wind Test next phase/Recovery/Result.
- **Recovery** — enter: pin failure or phase accuracy fail; allowed: Pin, Unpin, Slide Clip, Adjust Tension, Retry Phase, Pause; variables: same setup plus recovered clips; exit: Retry Phase; failure/cancel: none; next: Wind Test same phase.
- **Result** — enter: mission success or blowaway failure; allowed: Retry, Next if success, Home; variables: ; exit: choice; failure/cancel: none; next: Setup/Mission Select/Home.

## 8. Interaction Spec
```json
{
  "pin": "Drag begins only from cloth anchor. Valid release requires free logical line slot and inventory clip>0; invalid returns anchor with no state change.",
  "unpin": "Long-press 0.35s then drag >24 normalized-screen px equivalent logical threshold; release removes constraint and returns clip.",
  "slide": "Pinned clip moves only among its line's 9 slots; occupied slot cannot be crossed or selected; invalid release returns previous slot.",
  "tension": "Vertical drag is quantized to Loose/Medium/Tight; change is atomic on release.",
  "dry": "Disabled unless >=2 pinned anchors and current static load for every anchor<=3.0. Dry locks setup controls.",
  "priority": "One active pointer manipulation at a time; pause overrides all; Wind Test accepts no cloth manipulation."
}
```

## 9. Content Model
```json
{
  "unit": "laundry drying mission",
  "classes": [
    {
      "type": "Single-Line Cloth",
      "rules": "1 line, 4~6 anchors, 3~4 clips; base Pin/Slide/Tension"
    },
    {
      "type": "Dual-Line Wide Cloth",
      "rules": "2 lines, 6~8 anchors, 4~6 clips; anchors may pin to either line, adding cross-line shape choices"
    },
    {
      "type": "Fragile Cloth",
      "rules": "same interactions; mission pin threshold=2.4 instead of 3.0, explicitly shown before Setup"
    },
    {
      "type": "Heavy Cloth",
      "rules": "same interactions; wind load exposed_factor=1.25 for all anchors; requires tension tradeoff"
    },
    {
      "type": "Multi-Phase Weather",
      "rules": "2~3 wind phases with direction/strength changes; passed phases persist through Recovery"
    }
  ],
  "topology": "1~2 logical clotheslines; each line 9 ordered clip slots; cloth anchors connect to exactly one slot; no physical UI coordinates are rule data.",
  "variation_axes": [
    "anchor count",
    "clip budget",
    "line count",
    "wind direction sequence",
    "wind strength",
    "threshold modifier",
    "target silhouette",
    "phase count"
  ],
  "mvp_count": "12 missions spanning all five classes; individual layouts/data remain tunable."
}
```

## 10. Difficulty / Variation
Missions 1–3 teach single line, pin/slide and one wind direction. 4–6 add tension tradeoff and Heavy/Fragile modifiers. 7–9 add dual-line wide cloth and direction reversals. 10–12 combine dual line + modifier + 3-phase weather. Difficulty grows by constraint combinations and forecast changes, not shorter timers.

## 11. Progression
12 missions unlock linearly: success unlocks next. Each mission stores best score and 1–3 clothespin medal: 1=success, 2=score>=1000, 3=score>=1400. Medals do not alter physics.

## 12. Economy
Not required. Clips are mission-local capacity, not currency.

## 13. Screen Inventory
- Rooftop Home / Mission Select
- Mission Brief
- Laundry Gameplay
- Mission Result

## 14. Screen Flow
Home/Mission Select → Mission Brief → Gameplay Setup → Wind Test ↔ Recovery → success/failure Result. Success unlocks next and Result Next opens next Mission Brief; failure offers Retry/Home. Pause overlays Setup/Wind/Recovery and resumes exact state.

## 15. Feedback System
```json
{
  "pin": "snap+haptic+tension line",
  "stress": "anchor strain cue when projected gust load exceeds threshold",
  "forecast": "direction/strength/phase preview",
  "gust": "1s warning then cloth reaction",
  "failure": "specific anchor release + Recovery transition; blowaway distinct failure",
  "accuracy": "shape accuracy state updates during Setup/Recovery and phase end",
  "progression": "medal/unlock on Result"
}
```

## 16. Visual Direction Brief
Portrait mobile rooftop side/three-quarter presentation. Cloth occupies most of playfield; anchors, lines, clip slots, tension state, target silhouette and wind direction must remain legible. Cloth deformation may be simplified mesh/chain physics, but rule feedback must be deterministic. Rooftop/weather mood supports depth without obscuring cloth. UI coordinates remain Wireframe responsibility.

## 17. MVP Scope
12 authored missions covering Single-Line, Dual-Line, Fragile, Heavy, Multi-Phase classes; 4 cloth silhouette families reused with parameter variants; 1–2 lines, 4–8 anchors, 3–6 clips, 3 tension states, wind 8 directions×strength1–3, 1–3 phases, pin failure/Recovery/blowaway, scoring, medals, linear unlock, pause/retry.
NOT IN MVP: Freeform cloth editor, Cosmetic shop, Currency, Narrative dialogue, Online leaderboards, Real fluid simulation, More than two lines, Procedural missions.

## 18. Test Scenarios
- Pin/Unpin/Slide/Tension each changes only defined state and invalid releases change nothing.
- Projected static load>threshold prevents Dry; gust load>threshold releases anchor after 0.5s and enters Recovery.
- Pinned anchors dropping to 1 reaches failure Result.
- Accuracy>=75 after full 8s passes phase; <75 enters Recovery and repeats same phase.
- Pause freezes gust timer and cloth simulation exactly.
- All five content classes can be represented without new interaction rules.
- Mission success unlocks exactly next mission and medal thresholds do not change physics.
- Retry fully resets mission-local state.

## 19. Known Risks
- Simplified cloth physics may feel arbitrary unless deformation feedback matches deterministic rules
- Small mobile anchors/clip slots may become hard to manipulate
- Accuracy metric can feel opaque if silhouette mismatch is not readable
- Recovery loops may become repetitive in late multi-phase missions
- Dual-line topology increases visual clutter

## 20. Wireframe Handoff
- Represent all 4 screen types and Setup/Wind Test/Recovery/Result/Pause states.
- Represent Single-Line and Dual-Line topology, 4–8 cloth anchors, 9 logical slots per line, occupied/free clips.
- Show Fragile threshold and Heavy exposed-factor modifiers as mission rules, not new gestures.
- Show Pin/Unpin/Slide/Tension valid-invalid-cancel states and one-pointer priority.
- Show forecast, 1s gust warning, 1.5s gust, pin strain/release, Recovery and blowaway terminal failure.
- Show target silhouette/accuracy>=75 phase rule, 1–3 phase progression, retry-same-phase behavior.
- Show mission unlock and 1–3 medal Result variants across full 12-mission MVP.
