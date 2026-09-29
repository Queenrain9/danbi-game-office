# Paper Dragon Tailor — Playable Game Design Spec v0.1
## 1. Product Definition
종이 용의 손상 부위를 직접 펼치고 재단·접기·접착해 비행 가능한 구조로 복원하는 촉각형 수선 퍼즐. 장르: craft repair puzzle / Mobile portrait / 2–4분/repair case. 목표 감각은 직접 만지고 조립하는 명료한 손맛과 결과 원인의 가독성. Non-goals: persistent shop/economy, freeform cosmetic decoration, procedural paper physics, multiple dragon species, social sharing.
## 2. Player Fantasy
나는 종이 생명체의 구조를 읽는 장인이다. 찢어진 날개를 예쁘게 꾸미는 것이 아니라 힘이 전달되는 접힘과 겹침을 정확히 만들어 다시 날게 한다.
## 3. Core Player Verbs
- inspect: input=tap; target=damage marker; condition=inspection; state=reveals tear/fold/grain constraints; feedback=damage outline + paper rustle
- cut: input=drag along cut path; target=patch sheet; condition=pattern selected; state=creates patch geometry; feedback=cut line + snip sound
- fold: input=swipe across fold guide; target=patch/wing; condition=fold guide active; state=toggles fold segment and orientation; feedback=crease + snap
- glue: input=drag glue stroke; target=adhesive zone; condition=patch ready; state=records coverage; feedback=wet sheen
- place: input=drag/rotate then release; target=repair zone; condition=patch prepared; state=attaches if overlap/orientation valid; feedback=magnetic snap or peel-back
- test: input=tap launch; target=flight button; condition=repair committed; state=runs structural evaluation; feedback=flight path + stress highlights
## 4. Core Loop
손상 검사 10~20초 → 패치 종이 선택/재단 20~40초 → 접힘과 방향 조정 20~45초 → 풀칠·배치 15~30초 → 시험 비행 8~12초 → 실패 원인을 스트레스 표시로 읽고 한 번 수정하거나 결과 확정. 한 수선은 약 2~4분.
## 5. Round / Session Structure
Repair Brief에서 용/손상/요구 성능을 확인하고 Workbench로 진입한다. Inspect→Prepare→Attach→Flight Test 순서. 비행 기준을 만족하면 결과 화면, 실패하면 남은 수정 기회 내 Workbench 복귀. MVP는 수선당 최대 2회 시험 비행, 두 번째 실패 시 부분 성공 결과.
## 6. Game Rules
{
  "repair_attempts": 2,
  "cut_tolerance_px": 12,
  "fold_angle_tolerance_deg": 12,
  "required_glue_coverage": 0.8,
  "required_patch_overlap": 0.85,
  "orientation_tolerance_deg": 15,
  "score": {
    "structure": 50,
    "material_efficiency": 20,
    "craft_accuracy": 20,
    "first_flight_bonus": 10
  },
  "success_structure_min": 70,
  "perfect_structure_min": 90,
  "material_budget": "each case supplies 2 patch sheets; discarded cut consumes sheet area",
  "combo": "three consecutive valid craft actions without invalid release gives +1 precision chain, max 5; chain affects feedback only in MVP"
}
## 7. State Model
[
  {
    "id": "brief",
    "entry": "case selected",
    "inputs": [
      "start"
    ],
    "exit": "start",
    "ui": "damage silhouette + constraints"
  },
  {
    "id": "inspect",
    "entry": "workbench start",
    "inputs": [
      "tap damage"
    ],
    "exit": "all required damage revealed",
    "ui": "damage/fold/grain overlays"
  },
  {
    "id": "prepare",
    "entry": "damage selected",
    "inputs": [
      "cut",
      "fold"
    ],
    "exit": "patch can be placed",
    "ui": "pattern + guides"
  },
  {
    "id": "attach",
    "entry": "prepared patch",
    "inputs": [
      "glue",
      "drag",
      "rotate",
      "cancel"
    ],
    "exit": "valid attach committed",
    "ui": "repair zone + overlap preview"
  },
  {
    "id": "test",
    "entry": "launch",
    "inputs": [],
    "exit": "simulation complete",
    "ui": "flight + stress overlay"
  },
  {
    "id": "result",
    "entry": "success or attempts exhausted",
    "inputs": [
      "next",
      "retry"
    ],
    "exit": "selection",
    "ui": "score breakdown"
  }
]
## 8. Interaction Spec
{
  "pointer_priority": [
    "active tool stroke",
    "dragged patch",
    "damage hotspot",
    "camera/UI"
  ],
  "cancel": "drag outside workbench returns patch to tray; two-finger/explicit cancel aborts active cut before release",
  "cut": "sample drag path; accept only when path begins/ends on pattern boundary and remains within tolerance",
  "fold": "swipe must cross guide roughly perpendicular; reverse swipe unfolds before attachment",
  "place": "patch follows finger with preserved grab offset; rotate via two-finger twist or rotate handle; release evaluates overlap/orientation",
  "invalid": "no penalty for exploratory hover; invalid commit shakes target and returns object; consumed material only after valid cut",
  "hit_targets": "minimum 44pt UI; paper geometry uses polygon hit areas"
}
## 9. Content Model
{
  "unit": "repair case",
  "axes": [
    "dragon body part",
    "tear shape",
    "required stiffness",
    "paper grain",
    "fold pattern",
    "patch material",
    "wind condition"
  ],
  "mvp_cases": 6,
  "combination": "case template selects 1 damage geometry + 1 structural requirement + 1 material constraint; later cases combine two damage zones"
}
## 10. Difficulty / Variation
초반은 단일 직선 찢김과 표시된 접힘. 중반은 곡선 손상, 종이결 방향, 제한된 패치 면적. 후반은 두 부위가 서로 영향을 주고 비행 중 굽힘/양력 요구가 충돌한다. 속도 제한 대신 공간 정확도와 구조적 trade-off를 늘린다.
## 11. Progression
MVP는 6개 케이스 순차 해금. 별도 RPG 성장 없음. 이후에는 새 종이 재질/접기 기법이 새로운 문제 해결 방식으로 해금될 수 있으나 수치 업그레이드는 지양.
## 12. Economy
Not required for MVP. Material budget is per-case puzzle resource, not persistent currency.
## 13. Screen Inventory
- Case Select
- Repair Brief
- Workbench
- Flight Test
- Result
## 14. Screen Flow
Case Select → Repair Brief → Workbench(Inspect/Prepare/Attach) → Flight Test → 성공이면 Result, 실패이고 시도 남음이면 Workbench의 실패 부위 선택 상태로 복귀 → Result → Next/Case Select.
## 15. Feedback System
{
  "inspect": "damage edge pulses and paper rustle",
  "cut": "continuous cut trace; valid completion crisp snip+haptic",
  "fold": "crease darkens; correct fold soft snap+haptic",
  "glue": "coverage fills translucently",
  "place": "green overlap ghost only when structurally valid; invalid red stress edge",
  "test": "wing deformation and stress heat overlay explain outcome",
  "success": "clean lift + short celebratory flutter; no full-screen interruption during craft"
}
## 16. Visual Direction Brief
세로 모바일. 화면 상단 15%는 목표/재료, 중앙 65%는 큰 종이 용/작업대, 하단 20%는 도구 트레이. 정면에 가까운 2D top-down craft table. 종이 가장자리·접힘·결이 판정 정보이므로 장식보다 대비 우선. UI는 월드를 가리지 않는 얇은 작업도구 레이어.
## 17. MVP Scope
MUST: 6 repair cases, one dragon body rig, cut/fold/glue/place interactions, polygon overlap/orientation checks, two-attempt flight test, structural score and explanatory stress feedback.
NOT IN MVP: persistent shop/economy, freeform cosmetic decoration, procedural paper physics, multiple dragon species, social sharing
## 18. Test Scenarios
- 첫 플레이어가 설명 없이 30초 내 손상→재단 행동을 시작한다
- 드래그 재단/접기/배치의 오입력률이 첫 3케이스 후 15% 이하로 내려간다
- 의도적으로 잘못 붙인 패치가 비행 결과의 stress overlay로 원인을 설명한다
- 동일 케이스에서 서로 다른 유효 패치 배치가 최소 2개 존재한다
- 한 케이스가 평균 4분 이내에 완료된다
## 19. Known Risks
- 자유형 절단 판정이 답답하면 공예 판타지가 즉시 무너짐
- 비행 판정이 숨은 공식처럼 느껴지면 시행착오가 임의적으로 보임
- 종이 물리 표현을 실제 physics로 과도 구현하면 MVP 비용 급증
## 20. Wireframe Handoff
- Case Select/Brief/Workbench/Flight/Result 5화면
- Workbench의 inspect/prepare/attach 상태별 도구와 input lock
- cut path 시작·진행·invalid·complete 상태
- fold guide와 folded/unfolded variant
- patch drag/rotate/overlap preview/snap-back
- glue coverage overlay
- flight failure stress overlay와 Workbench 복귀 transition
- material exhausted/attempt exhausted error states
