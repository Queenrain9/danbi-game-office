# Clockwork Pet Dentist — Playable Game Design Spec v0.1

## 1. Product Definition
Portrait mobile Precision Repair/Simulation. 기계동물의 톱니 이빨을 진단·제거·가공·교체하고 물림을 시험한다. 환자당 3~6분. 목표는 정밀 수리의 손맛과 원인-결과 판독이다. Non-goals: 현실 치과 시뮬레이션, 경제/상점, 복잡한 rigid-body 물리.

## 2. Player Fantasy
작은 기계동물을 치료하는 치과공. 결함을 찾아 손으로 정확히 고쳐 다시 부드럽게 움직이게 한다.

## 3. Core Player Verbs
Inspect(pinch/pan), Probe(tap/drag), Extract(axis drag), Grind(contact drag), Lubricate(hold-drag), Align(circular drag), Seat(drag/snap), Bite Test(crank hold). 모든 행동은 실제 mechanism state를 바꾼다.

## 4. Core Loop
증상 확인 → 확대 탐색 → 결함 진단 → retainer 해제/부품 제거 → 가공·윤활 → 회전 정렬/삽입 → Bite Test → 결함 재수리 또는 완료.

## 5. Round / Session Structure
환자당 결함 2~4개, 3~6분. 성공은 full crank cycle 무 jam. 치명적 파손 3회 실패. Result 후 Retry/Next.

## 6. Game Rules
Fit tolerance 12%, alignment ±12°. Wrong size는 seat 불가. locked gear는 retainer 해제 전 추출 불가. 과연마는 부품 폐기. Bite Test가 fit/alignment/friction 오류를 노출한다. 성공/무손상/par 이하로 3별.

## 7. State Model
Patient Brief → Inspection ↔ Repair ↔ Part Bench → Testing → Result. Testing 중 crank 외 입력 잠금.

## 8. Interaction Spec
카메라 pinch/pan, part/tool drag, circular gear rotation, grinder hold-drag, crank hold. held object가 camera pan보다 우선. invalid action은 state 변경 없이 저항/경고 feedback.

## 9. Content Model
Patient Case = mouth layout + fault set + gear sizes/phases + retainer + tool limits + par. 재사용 mechanism 데이터 조합. MVP 4개.

## 10. Difficulty / Variation
명백한 단일 결함 → 진단 필요한 결함 → 연쇄 gear train → 접근 제한과 복합 결함. 속도 대신 진단/공차/접근성으로 상승.

## 11. Progression
환자 완료로 동물 종과 fault type unlock. MVP는 4환자 선형 진행.

## 12. Economy
Not required.

## 13. Screen Inventory
Patient Select, Patient Brief, Treatment/Mouth, Part Bench Overlay, Pause Overlay, Treatment Result.

## 14. Screen Flow
Select → Brief → Treatment(Inspection/Repair/Bench) → Bite Test → Treatment 또는 Result → Retry/Next.

## 15. Feedback System
Probe rattle, extraction snap, grinding sparks, alignment ghost/detent, seating click, jam stress pulse와 대응 사운드/햅틱.

## 16. Visual Direction Brief
Portrait 2D cutaway. 입 구조가 65~75%. 큰 gear silhouette와 socket depth가 우선. 하단 얕은 tool tray. 생물 외형은 프레임, 조작 판독성이 중심.

## 17. MVP Scope
4환자, gear/socket/retainer, inspection, probe, extraction, grinding, lubrication, alignment, seating, bite test, jam/failure/rating/retry-next.

## 18. Test Scenarios
무설명 첫 환자 완주, wrong-size reject, alignment-jam 재현, camera/part gesture 충돌 없음, 환자 간 state reset.

## 19. Known Risks
작은 터치 타깃, grinding 노동화, 진단 feedback 부족, 물리 의존 gear train 불안정.

## 20. Wireframe Handoff
모든 화면/overlay와 gear lifecycle variant를 표현한다. extract axis, grinder contact, circular alignment, snap, crank hold를 annotation하고 locked/wrong-size/overgrind/jam/disabled test error state를 포함한다.
