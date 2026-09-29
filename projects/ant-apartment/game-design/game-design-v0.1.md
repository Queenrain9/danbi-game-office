# Ant Apartment — Playable Game Design Spec v0.1
## 1. Product Definition
세로 모바일 colony stealth/path-planning. 2~3분 라운드. 안전하고 효율적인 운반로를 설계하고 실시간 변화에 재계획한다. Non-goals: 개별 일개미 마이크로, 대형 기지건설, 전투 중심 플레이.
## 2. Player Fantasy
군체의 길잡이가 되어 거대한 생활 공간을 읽고 작은 행렬을 무사히 귀환시킨다.
## 3. Core Player Verbs
Scout, Draw Route, Edit Route, Dispatch, Pause/Reroute. 각 입력·조건·상태 변화·즉시 피드백은 구조화 필드에 정의.
## 4. Core Loop
정찰 → 경로 설계 → 행렬 출발 → 위험 감시/재계획 → 전달 → 정산.
## 5. Round / Session Structure
Brief → Scout → RouteEdit → Haul → Result. 150초 제한, 평균 2~3분.
## 6. Game Rules
일개미 12, 정찰 1, 목표 음식 8, 경로 예산 100, 1.2초 출발 간격. 음식·생존·시간·예산으로 점수화하고 3회 무손실 전달 콤보를 둔다.
## 7. State Model
Brief, Scout, RouteEdit, Haul, Result를 분리하고 상태별 허용 입력과 HUD를 제한한다.
## 8. Interaction Spec
노드에서 drag, 12px waypoint sampling, 40px endpoint snap. path tap 후 waypoint drag, segment long-press delete. UI > waypoint > path > world 우선순위.
## 9. Content Model
Room mission = layout × food × hazard × route constraint × objective.
## 10. Difficulty / Variation
정적 장애물 → 주기 차단 → 복수 목표 → 교차 경로/불완전 정보. 단순 속도 상승이 아니다.
## 11. Progression
별로 새 방과 역할 해금. 수치 강화보다 새 규칙/도구 중심.
## 12. Economy
Not required for MVP.
## 13. Screen Inventory
Mission Select, Mission Brief, Apartment Room, Pause/Route Edit Overlay, Result.
## 14. Screen Flow
Select → Brief → Scout → RouteEdit → Haul ↔ Pause/Edit → Result → Next/Retry.
## 15. Feedback System
Fog reveal, pheromone trail, snap haptic, danger pulse, delivery absorb, local loss cue.
## 16. Visual Direction Brief
세로 탑다운. 거대한 생활 사물과 작은 개미의 스케일 대비. 밤 분위기에서도 바닥·경로·위험은 높은 판독성을 유지.
## 17. MVP Scope
주방 1개, 정찰/일개미, 경로 편집, 추종/운반, 이동 위험 1종, 정지/재개, 결과. 메타·상점·절차생성은 제외.
## 18. Test Scenarios
30초 내 첫 경로, 운반 중 재계획, 2초 경고 적정성, 12 에이전트 60fps, 거리-안전 tradeoff를 검증.
## 19. Known Risks
관전화, 입력 충돌, 에이전트 비용, 패턴 암기, 모바일 판독성.
## 20. Wireframe Handoff
Brief, reveal 상태, 경로 4상태, draw/edit gesture, Haul warning, Pause overlay, 전달/손실, Result, 수정 유예, disabled dispatch, 전환을 표현한다.
