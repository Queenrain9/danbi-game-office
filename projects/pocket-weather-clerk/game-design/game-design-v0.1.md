# Pocket Weather Clerk — Playable Game Design Spec v0.1

## 1. Product Definition
Portrait mobile tactile puzzle/simulation. 4~6분 세션. 구름·바람·습도를 직접 조작해 국지 날씨 주문을 맞춘다. 목표 감각은 촉각적 조정과 환경 반응 읽기. Non-goals: 도시경영, 경제, 복잡 유체물리.
## 2. Player Fantasy
작은 동네의 기상 사무원. 변수 결합을 이해해 원하는 미기후를 만드는 숙련감을 준다.
## 3. Core Player Verbs
Cloud drag, wind circular drag, humidity vertical drag, Observe, Submit. 각 입력은 즉시 월드 피드백과 상태 변화에 연결된다.
## 4. Core Loop
Brief → 상태 읽기 → 장치 조절 → settle 관찰 → 미세조정 → submit → compare → next.
## 5. Round / Session Structure
의뢰 45~90초, 5개가 한 Shift. Retry/Next로 연속 진행.
## 6. Game Rules
Cloud cover/altitude, 8-way wind/strength, humidity. 결합 규칙으로 clear/fog/rain 등을 파생. tolerance 15, budget 8, 3-star 평가.
## 7. State Model
order_brief, adjusting, settling, evaluating, result, shift_complete. evaluating 입력 잠금.
## 8. Interaction Spec
Cloud silhouette drag, nozzle circular drag, valve vertical drag. snap/cancel/locked/disabled 처리 포함.
## 9. Content Model
Weather Order 데이터 = district layout, targets, initial variables, device limits, forbidden states, budget. MVP 5개.
## 10. Difficulty / Variation
단일 목표 → 상충 다중 구역 → 장치 제한/금지 조건/정착 지연.
## 11. Progression
Shift 완료 시 Hard Orders 2개와 새 레이아웃 unlock.
## 12. Economy
Not required.
## 13. Screen Inventory
Shift Board, Order Brief, Weather Desk, Pause Overlay, Order Result, Shift Complete.
## 14. Screen Flow
Board → Brief → Desk ↔ Settle → Evaluate → Result → Retry/Next → Complete.
## 15. Feedback System
그림자, drift, haze, 강수, detent sound, haptic tick, stamp, district compare.
## 16. Visual Direction Brief
Portrait fixed top-down miniature diorama; town central, hardware edges; small-screen readability first.
## 17. MVP Scope
5 orders, three tactile controls, settle/evaluate/result/full Shift loop. Store/season/procedural/final polish 제외.
## 18. Test Scenarios
무설명 Order1, wind spatial effect, all-three-control order, invalid safety, repeat Shift reset.
## 19. Known Risks
규칙 불투명성, 판독성, drag count, 효과 과밀.
## 20. Wireframe Handoff
모든 화면과 hit area, 3 gestures, adjusting/settling/evaluating/result/locked/disabled states, feedback and transitions를 명시한다.
