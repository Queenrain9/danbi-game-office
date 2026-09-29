# Parcel X-Ray Night Shift — Playable Game Design Spec v0.1

## 1. Product Definition
심야 택배 허브에서 상자를 손으로 회전하고 엑스레이 단면을 훑어 내부 배치와 위험 규칙을 추론한 뒤 올바른 처리 레인으로 보내는 공간 판독 퍼즐.
Genre / Platform: Inspection Puzzle / Mobile portrait
Session: 상자 35~55초 · Shift 6~9분
Target feel: 숙련 보안 검사원처럼 몇 번의 회전과 단면 스캔으로 내부 관계를 읽고 정확하게 분류한다.
Non-goals: 실제 X-ray 시뮬레이터, 반사신경 게임, 숨은그림찾기, 현실 위험물 교육.

## 2. Player Fantasy
플레이어는 야간 물류 허브의 숙련 보안 검사원이다. 빠름보다 정확한 공간 추론과 확신 있는 분류에서 만족을 느낀다.

## 3. Core Player Verbs
Rotate: 상자 위 1-finger drag → yaw/pitch 변경 → 상자와 내부 실루엣 즉시 회전.
Slice Scan: 우측 scan rail 세로 swipe → slice_depth 0~100 → 절단면이 내부를 연속 통과.
Pin Evidence: 현재 단면의 의심 물체 tap → 관찰 마커 추가/제거.
Classify: 상자를 하단 PASS/REPACK/ISOLATE 레인으로 drag-release → 판정 잠금 → snap + result.

## 4. Core Loop
라벨 확인 → 상자 회전/slice scan → 규칙과 관찰 대조 → 3개 레인 중 하나로 drag 분류 → 결과 근거 확인 → 다음 상자.

## 5. Round / Session Structure
한 Shift는 8개 상자. Intake→Inspect→Classify→Result. 8개 처리 후 Shift Summary.

## 6. Game Rules
R1 금속성 고밀도 물체가 완충재 없이 외벽 10% 이내면 REPACK.
R2 서로 다른 두 고밀도 물체가 케이블형 구조로 연결되고 전원 셀과 접촉하면 ISOLATE.
R3 위험 조건이 없으면 PASS.
정답 +100, critical isolate +150, wrong PASS -180, 기타 오답 -80, false pin -5. 3연속 정답부터 streak +10. 2 Critical Miss 이상이면 grade 최대 C.

## 7. State Model
intake → inspect ↔ classifying → result → next intake / shift_summary. Rule Manual과 Pause는 modal overlay.

## 8. Interaction Spec
Priority: classification drag > scan rail > box rotate > hotspot tap.
Rotate hit = box + padding; UI/rail start ignored; pointer loss keeps pose.
Scan = right rail only; release freezes slice; classification drag 중 disabled.
Pin = visible internal shape; max 4; empty tap gives no-target feedback.
Classify = box center enters lane and release; outside release springs to table; valid release locks input.

## 9. Content Model
Parcel Case axes: box size, internal object set/pose, packing, hazard tags, decoys, label metadata. MVP 10 fixed cases, 6 primitive internal object types, 3 rules.

## 10. Difficulty / Variation
큰 단일 물체 → 가림/회전 + 복합 규칙 → decoy + 관계 규칙. 시간 압박보다 관찰 각도와 관계 해석을 늘린다.

## 11. Progression
Shift grade로 새 규칙/상자군 해금. 도구 능력치 강화 제외.

## 12. Economy
Not required.

## 13. Screen Inventory
Night Hub / Shift Select; Parcel Intake; X-Ray Inspection Table; Classification Result; Shift Summary; Rule Manual Overlay; Pause.

## 14. Screen Flow
Night Hub → Intake → Inspection → valid lane drop → Result → Intake 또는 Summary → Hub. Inspect 중 Rule Manual. invalid drop은 Inspect 복귀.

## 15. Feedback System
직접 회전, slice plane, pin ring, lane outline/snap, result stamp, critical warning.

## 16. Visual Direction Brief
Portrait greybox. 검사대 60~65%, 상단 HUD, 우측 scan rail, 하단 3 lanes. 내부 관계 판독 우선.

## 17. MVP Scope
Greybox 1 Shift. 고정 상자 10개 중 8개 출제, primitive 6종, 위험 규칙 3개, 회전, slice scan, evidence pin, 3레인 drag 분류, 결과 설명, Summary.

## 18. Test Scenarios
30초 내 rotate/rail 이해; 공간 관계로 8/10 이상 판정; 평균 55초 이하; drag 조작 실패 오분류 10% 미만; 오답 근거 설명 가능.

## 19. Known Risks
단순 색/모양 찾기 퇴화, 회전+단면 부담, 작은 화면 겹침, 케이스 제작비, 텍스트 암기 위험.

## 20. Wireframe Handoff
Intake label/begin; Inspection rotate/scan/pin; scan rail; three drag targets + invalid drop; Rule Manual; Result evidence replay; Summary; conflict/cancel/input-lock states.
