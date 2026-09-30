# The Floor Is Yesterday — Playable Game Design Spec v0.1
## 1. Product Definition
한 화면 추격 액션 퍼즐. 지나간 rewind zone은 이탈 3초 뒤 라운드 시작 상태로 복원된다.
## 2. Player Fantasy
내 발자국 뒤로 세계가 과거로 접히는 가운데 그 파동을 함정이자 길로 쓰는 도주자.
## 3. Core Player Verbs
Move: 방향→통행 공간→위치 변경→궤적. Interact: 인접 장치→연결 장치 toggle→즉시 반응. Escape: 출구 진입→clear.
## 4. Core Loop
공간 읽기→이동/조작→복원 예약→복원 전 통과/추격 유도→topology 복원→다음 경로→출구/피격.
## 5. Round / Session Structure
기준상태→5초 grace→추격→성공/실패→Next·Retry·Select. 세션 3–8분, 스테이지 30–120초.
## 6. Game Rules
Zone 이탈 시 3초 예약, 중복 예약 없음. 만료 시 rewindable 장치를 baseline으로 복원하며 캐릭터 위치는 되감지 않는다. 복원 위치 점유 시 0.25초씩 최대 2초 유예 후 계속 점유면 해당 복원을 취소한다. 스위치는 연결 장치를 즉시 toggle한다. 추격자는 현재 통행 그래프 최단경로를 사용하고 no-path면 0.25초마다 재계산한다. 접촉=fail, 활성 출구=clear. Pause는 타이머/이동 정지. Restart는 baseline부터.
## 7. State Model
Global intro→grace→chase→clear|fail. Zone idle→armed→restoring 또는 deferred→cancelled. Pursuer dormant/chasing/waiting_no_path. Pause overlay.
## 8. Interaction Spec
연속 방향 이동, 인접 장치 interact, 출구 접촉 자동 판정, zone 이탈 자동 rewind, pause.
## 9. Content Model
Stage={topology,zones,devices,links,spawns,exit}. Zone={corridor/door/platform restore}. Device={switch,door,platform}. Variation={zone 수,경로 중첩,우회,추격 거리,연결,출구 접근}. current graph로 판정.
## 10. Difficulty / Variation
단일 zone/문→연속 zone·우회→복수 타이머·연결 장치. 3초 고정.
## 11. Progression
클리어 시 다음 스테이지 해금. 능력 성장 없음. best time 저장.
## 12. Economy
Not required.
## 13. Screen Inventory
Stage Select, Stage Intro, Gameplay, Pause Overlay, Clear Result, Fail Result.
## 14. Screen Flow
Select→Intro→Gameplay→Clear/Fail. Clear=Next/Retry/Select, Fail=Retry/Select, Pause=Resume/Restart/Select.
## 15. Feedback System
3초 예고+방향성 파동, 1초 이하 강화, restore baseline snap, 장치 즉시 반응, 추격 활성/막힘/재개, 결과 즉시 표시.
## 16. Visual Direction Brief
한 화면 또는 제한 카메라. 현재 경로와 복원 예정 구역 동시 판독. 형태·잔상·방향성 우선.
## 17. MVP Scope + NOT IN MVP
MVP: 이동, rewind, 장치, 단일 추격자, 출구, 진행, pause/retry, best time. 제외: 전투, 성장, 다중 추격자, 임의 시간조작, 절차생성, 서사, 온라인 순위.
## 18. Test Scenarios
성공: 문 개방→zone 이탈→3초 내 통과→문 복원으로 추격 우회→출구. 실패: 접촉→fail→Retry. 점유: 2초 유예 후 취소. no-path: 대기/재계산.
## 19. Known Risks
공간/캐릭터 되감기 혼동, 약한 예고, 과도한 추격 속도, 복원 취소 악용.
## 20. Wireframe Handoff
fun_promise: 지나온 공간의 지연된 과거 복원을 예측해 추격자의 길을 끊는 쾌감. 모든 화면과 grace/chase/armed/restoring/deferred/clear/fail/pause를 전달. current topology, zone 경계, 남은 시간, baseline 대상, 추격자·출구를 판독 가능하게 하고 move/interact/pause/exit/retry/next/select 및 corridor/door/platform variation을 포함한다.