# Moonlight Window Washer — Playable Game Design Spec v0.1

## 1. Product Definition
Portrait mobile Cleaning Puzzle/Discovery. 거대 온실의 창을 직접 닦아 숨은 별자리 생물을 발견한다. 창당 2~4분, route 7~10분. 목표는 표면이 손가락 아래 깨끗해지는 촉각 만족과 발견. Non-goals: 자유 이동, 복잡 rope physics, 경제.

## 2. Player Fantasy
밤의 로프 청소부. 효율적인 동선으로 거대한 유리를 깨끗이 만들고 숨은 생물을 발견한다.

## 3. Core Player Verbs
Reposition, Spray, Scrub, Squeegee, Trace Discovery, Safety Latch. 각 gesture가 동일 pane의 surface/rope/discovery state를 직접 바꾼다.

## 4. Core Loop
위치 이동 → 적시기 → 문지르기 → 스퀴지 → 발견 노출 → 별자리 연결 → 청결/발견 완료 → 다음 창.

## 5. Round / Session Structure
Pane 2~4분. Cleanliness 90%+필수 발견 완료 시 Finish. 기본 시간 제한 없음. 위험 pane은 safety miss 3회 실패. 3 panes가 route.

## 6. Game Rules
Surface는 dry/wet/loosened/removed와 dry/wet/streaked/clear를 가진다. Dry hard dirt는 scrub 효율 낮음. Squeegee는 물 제거에 강하지만 hardened dirt 제거에는 약함. Dirty/abrupt stroke는 streak. Local reveal 70% 후 node 활성. Rope가 reachable band를 결정한다.

## 7. State Model
Pane Brief → Cleaning Idle ↔ Tool Gesture / Hazard Warning / Discovery → Result → Next/Retry. Tool gesture 중 다른 tool/reposition lock.

## 8. Interaction Spec
Spray hold-drag, scrub rub path, directional squeegee, side-gutter rope drag, revealed-node trace, safety tap. Reach 밖은 state 변경 없이 limit cue.

## 9. Content Model
Pane = shape + dirt mask/hardness + reach zones + streak sensitivity + constellation coordinates + hazard schedule + cleaner par. MVP 5.

## 10. Difficulty / Variation
단순 넓은 얼룩 → hardness/좁은 reach → streak 관리+발견 노출+telegraphed hazard. 시간 단축 대신 표면/공간/발견/인터럽트 결합.

## 11. Progression
Pane 완료로 온실 구역과 constellation creature unlock. MVP 5-pane 선형 route/도감.

## 12. Economy
Not required.

## 13. Screen Inventory
Night Route, Pane Brief, Window Cleaning, Discovery Overlay, Pause Overlay, Pane Result, Route Complete.

## 14. Screen Flow
Route → Brief → Cleaning ↔ Discovery/Hazard → Result → Next; route 완료 → Route Complete. Failure → Result → Retry.

## 15. Feedback System
Wet sheen, progressive dirt erase, crisp squeegee band, streak line, star bloom, constellation creature reveal, hazard rope telegraph + 대응 sound/haptic.

## 16. Visual Direction Brief
Portrait tall pane. 유리 70~80%, side rope gutter, compact bottom tool dock. Dirt/wet/clear/streak/star 상태가 작은 화면에서도 구별되어야 한다. 배경은 낮은 대비.

## 17. MVP Scope
5 panes, cleaning masks, 3 cleaning gestures, streak, rope reach, discovery trace, reusable hazard, scoring, retry/next/route completion.

## 18. Test Scenarios
상태 순서 인지, dry scrub low-effect 이해, squeegee 폭/줄무늬 재현, reveal threshold node gating, reach reject, pane 간 reset.

## 19. Known Risks
mask 성능, 무목적 문지르기, tool-switch 마찰, discovery 분리감, hazard의 cleaning fantasy 훼손.

## 20. Wireframe Handoff
전체 화면과 Cleaning surface state를 표현한다. reachable band/tool dock/Finish gating을 보이고 spray/scrub/squeegee/reposition/trace gesture, dry/wet/loosened/clear/streak, hidden/revealed/connected, out-of-reach/invalid/hazard/error transition을 annotation한다.
