# Playable Game Design Spec v0.1 — Tiny Rival Restaurant
## 1. Product Definition
공유 골목 손님을 경쟁하는 mobile management game. 4–6분/day. Non-goals: cooking minigame, idle tycoon, PvP.
## 2. Player Fantasy
거리 흐름을 읽어 경쟁점보다 영리하게 손님을 끌어오는 작은 식당 주인.
## 3. Core Player Verbs
Offer=tap menu, Aroma=drag legal zone, Seat=drag waiting party, Clear=swipe dirty table.
## 4. Core Loop
Prep→45초 Service에서 관찰/아로마/착석/청소→Wave Result, 4회.
## 5. Round / Session Structure
Cash60, tables4, menu3. 4 waves. cash<0 실패. Retry는 day seed 전체 초기화.
## 6. Game Rules
Party는 decision node에서 taste+price tolerance+aroma-queue utility를 비교하고 선택 후 바꾸지 않는다. Patience18초, 0이면 이탈. Seating 시 정지, meal8–16초 뒤 cash 획득/table dirty. Cleaning3초. Aroma 3 zones, cooldown5초. Rival wave당1회. Pause는 전 timer freeze.
## 7. State Model
Prep→Service; Waiting→Dining→Dirty→Cleaning→Free. Wave/Day Result. Bankruptcy failure. Pause/resume state 보존.
## 8. Interaction Spec
Party drag는 free compatible table만 valid; invalid queue 복귀. Aroma는 3 zones만 snap. Dirty만 swipe. Party drag 우선.
## 9. Content Model
3 days, 5 dishes, 4 party archetypes, 1 rival, 1 street.
## 10. Difficulty / Variation
Taste→group/budget tradeoff→rival counter/peak mix. Speed-only 금지.
## 11. Progression
3 days와 menu 순차 unlock, best score.
## 12. Economy
Cash 단일 자원, start60, price6–18, day 사이 소비 없음.
## 13. Screen Inventory
Day Select, Restaurant Gameplay, Wave Result Overlay, Day Result, Pause.
## 14. Screen Flow
Select→Prep→Service→Wave Result 반복→Day Result. Failure→Result→Retry. Pause overlay.
## 15. Feedback System
Route turn, seat snap, patience break, wipe, rival bell, tally.
## 16. Visual Direction Brief
두 가게와 공유 보행로가 동시에 보이며 NPC 흐름 중심. HUD 보조적. 좌표는 Wireframe 책임.
## 17. MVP Scope
3 days/1 street/2 restaurants/4 tables/5 dishes/4 archetypes/4 waves/day/3 aroma zones와 닫힌 choice/patience/meal/clean/cash rules.
## 18. Test Scenarios
선택 예측, aroma 반영, queue recovery, rival 대응, 3-day 비반복성.
## 19. Known Risks
선택식 가독성, 입력 과부하, scripted rival 반복성, 가격 지배전략.
## 20. Wireframe Handoff
확정된 state/gesture/feedback/error/transition만 표현하고 새 규칙은 만들지 않는다.