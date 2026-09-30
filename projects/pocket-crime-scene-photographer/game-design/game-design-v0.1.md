# Playable Game Design Spec v0.1 — Pocket Crime Scene Photographer

## 1. Product Definition
작은 사건 현장에서 촬영 위치·줌·초점·플래시 각도를 직접 조절해, 결정적 증거들이 가려지지 않고 관계가 읽히는 단 한 장의 기록 사진을 완성하는 landscape mobile 공간 관찰/촬영 퍼즐. 한 case는 2–4분이며 MVP는 10개 case다. 목표 감각은 숨은 물건을 찾는 것이 아니라 동일한 현장도 촬영 구성이 달라지면 증거 관계가 보이거나 사라진다는 것을 손으로 이해하는 것이다. Non-goals: free 3D camera, moving-character action, interrogation, inventory, shop/economy.

## 2. Player Fantasy
플레이어는 봉쇄 직전 현장에 들어가는 기록 전문 수사 사진가다. 증거 자체보다 증거 사이의 거리·가림·깊이·빛을 읽고, 한 장의 사진으로 사건의 구조를 증명한다.

## 3. Core Player Verbs
- Reposition: scene 위 single-finger horizontal drag → camera_x 변경 → depth별 parallax로 evidence/occluder projection 변경.
- Frame: two-finger pinch → zoom 1.0–2.2x 변경 → proof set의 화면 크기와 관계 거리 변경.
- Focus: 현재 in-frame이며 unoccluded evidence tap → focus_depth를 해당 evidence depth로 설정.
- Aim Flash: flash toggle tap + angle drag → flash_on/flash_angle 변경, flash-sensitive surface preview 변화.
- Shoot: shutter tap → exposure 1 소비 → 현재 구성 전체를 한 번에 판정하고 Review 진입.

## 4. Core Loop
Case Brief에서 어떤 관계를 증명해야 하는지 확인 → camera_x를 옮겨 가림을 푼다 → zoom으로 증거 관계가 읽히는 크기를 만든다 → 필요한 case에서 focus/flash를 맞춘다 → shutter → 실패 범주만 확인하고 남은 exposure 안에서 재구성 → valid photo 한 장 확보 시 case 완료/다음 case 해금.

## 5. Round / Session Structure
MVP 10 authored cases. Case는 Brief → Compose → Review → Result. 시작값은 exposures=3, camera_x=0, zoom=1.0, focus_depth=null, flash_off, flash_angle=0°. 전역 timer는 없다. Shoot은 먼저 exposure 1을 소비하고 같은 순간의 구성값을 판정한다. Valid면 남은 exposure가 0이어도 success. Invalid 후 exposure가 남으면 1.2초 Review 뒤 Compose 복귀, 세 번째 invalid로 0이면 failure. Retry는 case-local 상태만 초기화한다.

## 6. Game Rules
### Coordinate / Projection
Evidence와 occluder는 base_center=(x,y)∈[0,1], depth d∈[0,1](0 foreground, 1 background), base_radius r를 가진다. camera_x∈[-1,1], zoom∈[1.0,2.2].
- parallax p = 0.08 + 0.16×(1-d)
- pre_x = base_x - camera_x×p
- screen_x = 0.5 + (pre_x-0.5)×zoom
- screen_y = 0.5 + (base_y-0.5)×zoom
- screen_radius = r×zoom
판정은 shutter 순간 값을 사용한다.

### In Frame
Required evidence circle 전체가 x/y 모두 [0.03,0.97] 안에 있어야 한다.

### Occlusion
Evidence E보다 앞(depth가 더 작은) authored occluder O와 projected circle이 겹치면 E는 occluded다: center distance < E.radius+O.radius. Relation이 line_clearance=true면 A-B projected segment와 relation-blocking occluder center의 최소 거리가 occluder.radius+0.02 이상이어야 한다.

### Relation Readability
각 relation pair는 authored min_distance/max_distance를 가지며 projected center distance가 범위 안이어야 한다. 모든 required evidence circle을 감싼 axis-aligned bbox의 diagonal/√2인 composition_span도 case의 min_span/max_span 안이어야 한다. 따라서 작은 증거를 한 프레임에 넣기만 해서는 통과하지 않는다.

### Focus
Valid evidence tap은 focus_depth를 그 evidence depth로 설정한다. focus_required evidence는 |depth-focus_depth|≤0.08이어야 한다. 기본 focus_depth=null은 실패다.

### Flash
flash_angle은 camera forward 기준 -60°..+60°. Flash-sensitive evidence는 flash_on=true이며 |flash_angle-ideal_flash_angle|≤authored tolerance(12°–20°)일 때만 통과한다. Flash는 소비 자원이 아니다.

### Shot / Recovery
Shutter → exposure-1 → in-frame → occlusion/relation-line → pair-distance/span → focus → flash 순으로 평가한다. 하나라도 실패하면 invalid. Review는 failed category만 알려주고 숨겨진 목표 숫자는 공개하지 않는다. exposure가 남으면 camera/zoom/focus/flash를 바꿔 재촬영한다.

### Success / Failure / Rating
Valid photo가 success. Invalid third shot로 exposures=0이면 failure. Success stars=exposures_remaining+1(첫 shot 3, 둘째 2, 셋째 1). Pause는 Compose/Review에서 가능하며 Review countdown을 포함한 진행을 정지한다. Retry는 exposures/camera/zoom/focus/flash/Review를 초기화한다.

## 7. State Model
- Case Select: unlocked case 선택, best stars 표시. → Brief.
- Case Brief: Start/Back. → Compose 또는 Select.
- Compose: Reposition/Frame/Focus/Flash/Shoot/Pause. Shoot → Review.
- Review: 1.2초 shot 결과 표시. Pause 가능. valid→success Result, invalid+exposures>0→Compose, invalid+0→failure Result.
- Pause: Resume/Retry/Case Select. Resume은 exact return state.
- Result: success/failure. Next(success), Retry, Case Select.

## 8. Interaction Spec
Reposition은 horizontal drag의 normalized dx×1.2를 camera_x에 더해 case rail range로 clamp한다. horizontal delta가 0.05 미만인 vertical-only drag는 위치를 바꾸지 않는다. Pinch는 zoom을 multiplicative scale로 바꾸며 1.0–2.2 clamp, 두 pointer가 있는 동안 Reposition보다 우선한다. Focus tap은 projected evidence circle 안이며 in-frame/unoccluded일 때만 valid; drag가 0.05 이상이면 release는 tap이 아니다. Flash angle drag는 dx×120°를 더해 -60..60 clamp. Shoot은 continuous gesture가 활성 중이면 무시한다.

## 9. Content Model
Content unit은 authored crime-scene photo case. MVP 10개.
- Context Relation: 2–4 evidence, pair-distance와 composition-span으로 관계를 읽게 함.
- Occlusion Relation: foreground occluder/relation blocker로 camera_x parallax가 필수.
- Focus Anchor: focus_required evidence를 포함.
- Raking Flash: flash-sensitive evidence와 angle tolerance 포함.
- Combined Reconstruction: 앞의 두 가지 이상을 조합하며 새 rule/input은 추가하지 않음.
10개 전체에서 네 base class가 각각 최소 2개 case에 등장하고 Combined가 최소 2개 존재한다. Exact scene 이름/배치/순서는 data로 남긴다.
Case schema는 camera rail range, entities, occluders, relations, composition span, 2–4 evidence proof_set을 가진다. 모든 authored case는 최소 1개 valid control tuple이 검증되어야 MVP에 들어간다.

## 10. Difficulty / Variation
초반은 넓은 relation window와 가림 없는 2-object 관계. 중반은 foreground occlusion으로 camera_x 해법을 좁히고 Focus와 Flash를 각각 도입. 후반은 3–4 evidence, 두 relation pair, occlusion+focus 또는 occlusion+flash를 조합한다. 속도나 timer가 아니라 동시에 만족해야 하는 공간 조건 수로 난도가 오른다.

## 11. Progression
10 cases linear unlock. 어떤 star 수든 success면 다음 case unlock. Case Select는 best 1–3 stars를 저장하며 replay로 개선 가능. Rule-changing upgrade는 없다.

## 12. Economy
Not required. Exposure는 case-local attempt이고 stars는 mastery record이며 소비되지 않는다.

## 13. Screen Inventory
1. Case Select / Archive
2. Case Brief
3. Camera Gameplay
4. Case Result

## 14. Screen Flow
Game Entry → Case Select → Brief → Compose → Shoot → Review → success Result → Next/Select. Invalid+exposure remaining → Compose. Third invalid → failure Result → Retry/Select. Pause는 Compose/Review overlay이며 Resume은 exact state로 복귀. Case Select abandon은 progression을 바꾸지 않는다.

## 15. Feedback System
Reposition은 parallax로 overlap 변화가 즉시 보인다. Frame은 lens scale 변화와 zoom clamp feedback. Focus는 marker/lock cue. Flash는 유효 cone에 가까워질수록 surface sheen이 강해지고 cone 진입 haptic을 준다. Shoot은 capture freeze+shutter. Invalid Review는 Frame/Occlusion/Relation/Focus/Flash category만 표시. Success는 사진을 archive에 봉인하고 stars/unlock을 보여준다.

## 16. Visual Direction Brief
Landscape mobile의 compact static crime-scene diorama. Evidence silhouette, foreground occluder, depth separation이 읽혀야 하며 camera_x parallax와 zoom이 관계를 실제로 바꾸는 것이 중심이다. 사진 frame 자체가 주 play surface이며 정보 UI가 checklist 게임처럼 지배하지 않는다. 늦은 밤의 절제된 forensic photography, practical light, reflective detail을 사용한다. UI 좌표/box는 Wireframe 책임이다.

## 17. MVP Scope + NOT IN MVP
10 authored cases, shared camera/evaluator 1세트. 모든 case는 horizontal camera rail, zoom, shutter 3 exposures를 사용한다. Context/Occlusion/Focus/Flash/Combined classes를 전체 MVP에서 커버하며 proof set 2–4 evidence, relation pair 1–2개. Projection, circle occlusion, relation-line clearance, distance/span, focus depth, directional flash, 1.2s Review, result, stars, unlock, pause/retry를 포함한다.
NOT IN MVP: free 3D/vertical camera movement, continuous autofocus, multi-bounce/ray-traced flash, moving evidence, interrogation, inventory/upgrades, economy, procedural scenes, >10 MVP cases, online sharing.

## 18. Test Scenarios
- Context case는 object 포함만으로 통과하지 않고 pair-distance+composition-span을 만족해야 한다.
- camera_x 변화가 고정 parallax 식으로 foreground overlap을 바꿔 occlusion을 풀 수 있다.
- relation-blocking occluder가 A-B segment를 가리면 endpoints가 clear여도 Relation fail.
- focus_required는 null 또는 error>0.08에서 fail, valid tap 후 pass.
- flash_required는 flash_off/outside tolerance에서 fail, inside tolerance에서 pass.
- 첫/둘째/셋째 valid shot은 각각 3/2/1 stars; 셋째 shot이 exposure0이어도 valid면 success.
- 세 invalid shot은 failure. Retry는 case-local 상태 reset.
- Review 중 Pause는 1.2s countdown freeze.
- 다섯 content class가 정의된 evaluator/input만으로 표현된다.

## 19. Known Risks
Evaluator circle과 실제 art silhouette가 다르면 occlusion이 부당하게 느껴질 수 있다. Horizontal rail만으로 scene authoring이 반복될 수 있다. Failed-category feedback이 너무 친절하면 발견성이 줄 수 있다. Focus/Flash가 framing을 보조하지 않고 checklist처럼 느껴질 위험이 있다. 10개 authored case 모두 solvability validation이 필요하다.

## 20. Wireframe Handoff
fun_promise: 이 게임은 숨은 물건을 탭하는 것이 아니라 카메라로 증거 관계를 구성하는 게임이어야 한다.
Case Select/Brief/Camera/Result 4 screen type과 Compose/Review/Pause/success/failure를 모두 표현한다. Context/Occlusion/Focus/Flash/Combined variation을 커버한다. Reposition drag, pinch Frame, Focus tap, Flash toggle/angle drag, Shutter의 priority/cancel/invalid semantics를 표현한다. Required evidence의 in-frame, clear/occluded, relation-line clear/blocked, distance/span, focus, flash pass/fail 상태를 보여준다. Invalid Review 1.2초와 remaining exposure flow, star mapping, unlock/replay, Pause/abandon/Retry를 표현한다. Wireframe은 배치와 표현 방식을 결정할 수 있지만 projection/occlusion/focus/flash/relation/exposure 규칙은 변경하지 않는다.
