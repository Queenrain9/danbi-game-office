# Playable Game Design Spec v0.1 — Haunted Record Press

## 1. Product Definition
유령의 목표 파형을 읽고 회전하는 레코드의 구간별 홈 깊이와 흔들림을 직접 새겨 잃어버린 노래를 복원하는 portrait mobile 정밀 제작 퍼즐. Mission 3–6분. 목표 감각은 듣고 본 패턴을 손의 궤적·압력·속도로 번역하는 장인 숙련감이다. Non-goals: 실제 오디오 분석, 마이크 입력, 자유곡 import, 화폐/상점, 온라인 경쟁.

## 2. Player Fantasy
플레이어는 폐점 후 음반 공장의 마지막 커팅 기사다. 유령이 남긴 허밍을 시각적 파형과 촉각적 조각 규칙으로 번역해 망가진 노래를 다시 들리게 만드는 숙련과 복원 완료의 정서적 보상을 느낀다.

## 3. Core Player Verbs
Preview는 현재 target phrase를 듣고 본다. Set Pressure는 1/2/3 깊이를 선택한다. Carve는 active arc start에서 end까지 한 손가락으로 홈을 긋는다. Replay는 target/player 결과를 비교한다. Correct는 실패/비완벽 trace를 지우고 남은 attempt로 다시 새긴다. Accept는 score>=70 segment를 잠그고 다음으로 진행한다.

## 4. Core Loop
Mission Brief → Preview → Pressure → Carve → Replay/Review → score>=70 Accept 또는 Correct → 모든 segment 복원 → Full Playback → Result → 다음 record/Retry.

## 5. Round / Session Structure
Mission은 ordered segment 3–6개. 각 segment attempts 3. Inspect→Carve Ready→Carving→Review. Valid carve는 attempt 1을 소비한다. score>=70이면 Accept 가능. score<70이고 attempts가 남으면 Correct. score<70이고 attempts=0이면 즉시 mission failure. 모든 segment Accept면 success. 평균 3–6분.

## 6. Game Rules
판정 좌표는 회전 화면이 아니라 segment local normalized space다. u=0 start, u=1 end; v는 authored centerline에 수직인 signed normalized offset이며 segment half-width=1. Drag path는 u 기준 32개 등간격 sample로 보간한다. Pressure는 attempt 동안 고정 integer 1–3. Duration은 valid start touch부터 valid end release까지 초 단위.

각 target은 32 target_v, target_pressure, target_duration_seconds를 가진다. Valid start/end zone radius는 0.12 segment-width units. Raw sample 사이 u가 0.08보다 크게 역행하면 invalid. End release는 end zone 안이며 authored arc의 80% 이상을 진행해야 한다. Invalid carve는 attempt를 소비하지 않는다.

shape_error=mean(abs(player_v-target_v)) clamped0..1. pressure_error=abs(player_pressure-target_pressure)/2. tempo_error=min(abs(player_duration-target_duration)/target_duration,1). score=round(100*(1-(0.65*shape_error+0.20*pressure_error+0.15*tempo_error))). Pass70, Perfect90.

Valid carve 완료 즉시 attempts_left-1. score<70이고 attempts_left=0이면 failure. Success는 모든 segment Accept. Success rating은 accepted segment score 평균: 1 star=success, 2>=80, 3>=90. Pause는 playback/timer를 정지한다. Carving 중 Pause는 미완성 carve를 무비용 취소하고 Carve Ready로 복귀한다. Retry는 mission-local trace/score/attempt/progress를 reset한다.

## 7. State Model
Mission Select→Mission Brief→Inspect→Carve Ready→Carving→Review. Review에서 Accept는 다음 Inspect, Retry는 Carve Ready, attempts0+fail은 Result. 마지막 Accept는 Full Playback→Result. Pause는 현재 상태를 보존하되 Carving만 무비용 cancel semantics를 가진다.

## 8. Interaction Spec
Preview tap/hold. Pressure vertical drag를 1/2/3으로 quantize. Carve는 single pointer; valid/invalid는 Game Rules 기준. Active carve가 pointer priority를 가진다. Review Accept는 score>=70, Retry는 attempts_left>0. Invalid action은 state change 없음.

## 9. Content Model
MVP 10 missions. Content classes: Clean Melody(기본), Wavering Voice(잦은 v 부호 변화), Pressure Phrase(target pressure 변화), Tempo Phrase(target duration 1.5–5.0s 변화), Composite Record(5–6 segments에서 세 축 결합). Mission topology는 ordered linear segments이며 이전 Accept 전 다음 segment는 열리지 않는다. Variation axes는 segment count, trace amplitude/frequency, pressure, duration, target complexity다. 모든 후반 content는 동일 state graph/interaction을 재사용한다.

## 10. Difficulty / Variation
1–2 Clean, 3–4 Wavering, 5–6 Pressure, 7–8 Tempo, 9–10 Composite. 난도는 랜덤/시간제한이 아니라 목표 궤적·pressure·duration 조합으로 증가한다.

## 11. Progression
Mission1 최초 해금. 성공 시 정확히 다음 mission 해금. mission별 best score와 best stars 저장. Stars는 판정 능력을 변경하지 않는다.

## 12. Economy
Not required. Attempts는 mission-local 기회이며 화폐가 아니다.

## 13. Screen Inventory
Record Shelf / Mission Select, Mission Brief, Record Carving Gameplay, Full Playback, Mission Result.

## 14. Screen Flow
Shelf→Brief→Inspect→Ready→Carving→Review. Accept→next segment, Correct→Ready, third failed valid attempt→failure Result. Last Accept→Full Playback→success Result. Next→next Brief, Retry→same mission reset, Shelf→select. Pause semantics는 section6과 동일.

## 15. Feedback System
Preview는 ghost hum/target trace. Carve는 groove와 cutting texture. Invalid는 scratch reject+no cost. Review는 mismatch region과 shape/pressure/tempo component를 보여준다. Accept는 restored segment. Full Playback은 assembled song. Failure는 failed segment에서 복원 중단을 명확히 전달한다.

## 16. Visual Direction Brief
Portrait mobile. 중심은 회전 record/current groove segment. finger path, target trace, start/end, pressure가 판독되어야 한다. 판정은 normalized local space로 결정론적이다. 어두운 공장과 제한된 ghost glow. 구체 UI 좌표는 Wireframe 책임이다.

## 17. MVP Scope
10 authored missions, 3–6 segments each, 5 content classes, 32-sample trace judging, pressure1–3, target duration1.5–5.0s, attempts3, pass70/perfect90, correction, Full Playback, stars, linear unlock, pause/retry/best score. NOT IN MVP: real audio analysis, microphone, freeform import, procedural targets, currency/shop, cosmetics, branching narrative, leaderboard, multi-touch carve.

## 18. Test Scenarios
shape_error0.10/pressure0/tempo0.10 valid carve는 score92로 pass. Valid carve만 attempt 소비. 세 번 sub70 valid carve로 3→2→1→0 failure. Carving Pause는 no-cost cancel. pressure target3/player1은 pressure weighted penalty20. 5 classes는 same state graph. Last Accept→Full Playback→success+next unlock. Retry는 mission-local reset, meta progress 보존.

## 19. Known Risks
Finger occlusion, scoring harshness, synthetic audio와 점수 체감 불일치, long trace touch jitter, authored target 다양성 생산 부담.

## 20. Wireframe Handoff
5 screen types와 Inspect/Ready/Carving/Review/Full Playback/Result/Pause를 표현한다. Target/player groove, start/end validity, pressure1–3, attempts3, component error/score, invalid no-cost reset, valid attempt consumption, Accept/Correct, 5 content variations, Carving pause cancel, third-fail Result, Full Playback, linear unlock/star variants를 전체 MVP 범위에서 표현한다.