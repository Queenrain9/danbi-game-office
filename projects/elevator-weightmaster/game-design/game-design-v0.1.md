# Elevator Weightmaster — Playable Game Design Spec v0.1
## 1. Product Definition
세로 모바일 physics packing puzzle. 45~90초 운행, 4~7분 근무. 제한된 승강기 바닥에서 하중과 무게중심을 직접 배치로 해결한다. Non-goals: 사실적 강체 시뮬레이터, 승강기 경영, 대화 중심 게임.
## 2. Player Fantasy
괴물 호텔의 노련한 화물 담당자로서 한눈에 무게와 공간을 읽고 아슬아슬한 승강기를 안전하게 운행한다.
## 3. Core Player Verbs
Load, Reposition, Rotate, Dispatch, Correct. 각 행동의 input/target/condition/state/feedback은 구조화 필드에 명시.
## 4. Core Loop
대기열 읽기 → 배치/균형 → 출발 → 이동 중 흔들림 보정 → 하차/점수 → 다음 manifest.
## 5. Round / Session Structure
Doors Open/Load → Ready Check → Travel → Arrival. 45~90초, 3~5회가 한 세션.
## 6. Game Rules
용량 1000kg, safe center offset 0.18, warning 0.28, critical 0.38, critical 3초 지속 시 비상정지. 배송/균형/효율 점수.
## 7. State Model
QueuePreview, Loading, InvalidReady, Travel, Correction, Arrival. 상태별 입력과 HUD가 다르다.
## 8. Interaction Spec
드래그, 20cm grid snap, 12px hitbox 확장, 겹침 drop 거부, 90도 rotate button, 문 밖으로 drag해 제거. 자동 재배치 금지.
## 9. Content Model
Ride manifest = passenger shape/mass × cargo footprint/behavior × destination × cabin modifier.
## 10. Difficulty / Variation
질량/균형 → 큰 footprint/하차 순서 → 이동 물체/fragile/blocked tile. 단순 시간 단축이 아니다.
## 11. Progression
근무 평점으로 층과 새 규칙을 해금. 영구 수치 강화보다 규칙 확장.
## 12. Economy
Not required for MVP.
## 13. Screen Inventory
Shift Select, Manifest Brief, Elevator Loading, Travel/Correction, Arrival Result, Shift Result.
## 14. Screen Flow
Select → Brief → Loading ↔ InvalidReady → Travel ↔ Correction → Arrival → next ride → Shift Result. 비상정지는 Failure/Retry.
## 15. Feedback System
Footprint ghost, grid snap, weight thump, 실시간 needle/suspension, invalid shake, motor cue, sway warning, recovery haptic.
## 16. Visual Direction Brief
세로 중앙에 승강기 65~70%. 정면+약한 탑다운으로 바닥 footprint를 읽게 한다. 사실적 물리보다 실루엣과 게이지 판독성 우선.
## 17. MVP Scope
승강기 1, 4~6 물체, drag/collision/snap, 질량+1축 center 계산, 3 manifest, sway 1종, correction, 결과.
## 18. Test Scenarios
2회 내 균형 원리 이해, 30초 배치와 복수 해법, invalid 원인 2초 내 식별, correction 즉시성, 규칙 기반 흔들림의 납득성.
## 19. Known Risks
계산 문제화, 작은 화면 정밀 조작, 물리 연출 불일치, correction 반복성, footprint 제작량.
## 20. Wireframe Handoff
Manifest 정보, drag/snap 상태, invalid drop, 3단계 balance gauge, dispatch disabled 이유, Travel/Sway, locked input, Arrival/Failure, 전체 transition을 표현한다.
