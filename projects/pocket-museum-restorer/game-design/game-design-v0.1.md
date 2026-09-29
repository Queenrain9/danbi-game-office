# Pocket Museum Restorer — Playable Game Design Spec v0.1
## 1. Product Definition
폐관 후 박물관 작업대에서 깨진 유물을 조립하고 조사광으로 가짜 복원재를 판독해 제거·재접합하는 portrait tactile restoration puzzle. 유물당 60–120초, 세션 4–7분. 목표는 관찰→공간조작→정밀 복원의 손맛. Non-goals: 숨은그림찾기, 정답 버튼 선택, 사실적 화학 시뮬레이터, 시간압박 아케이드.
## 2. Player Fantasy
야간 신참 보존처리사로서 형태·재질 차이를 읽고 원형을 되살린다.
## 3. Core Player Verbs
Inspect(artifact drag/pinch), Place Fragment(drag+rotate+snap), Scan Surface(lamp drag), Scrape(mask stroke), Bond Crack(seam trace), Submit.
## 4. Core Loop
Intake → 관찰 → 조각 조립 → 조사광 판독 → 이질 재료 제거 → 균열 접합 → 평가 → 다음 유물.
## 5. Round / Session Structure
3 ArtifactCase. Intake→Assembly→Inspection→Bonding→Evaluation; 필요 없는 단계 skip; 세 번째 뒤 Summary.
## 6. Game Rules
Snap 26px/14°, near 45px. Patch/seam 90%. Integrity 100, bad scrape -3. Base 1000; fragment +80, patch +120, seam +100, damage point -6, unnecessary stroke -8, hint -80. 3 clean ops부터 +25 chain. Hard time fail 없음.
## 7. State Model
case_intake, assembly, surface_inspection, scraping, bonding, evaluation, summary. Pause/Help는 이전 상태 보존 blocking overlay.
## 8. Interaction Spec
modal > tool stroke > fragment drag > lamp > artifact rotate > pinch. Fragment 위치+회전 모두 허용오차 통과 시 snap. Scrape는 revealed foreign mask 교차만 제거. Bond는 18px seam corridor. Active tool 중 pinch 금지.
## 9. Content Model
ArtifactCase를 family/silhouette/fragments/fracture/foreign material/cracks/surface response 축으로 저작. MVP fixed masks/sockets.
## 10. Difficulty / Variation
큰 이형 조각/강한 신호 → 유사 조각/복수 재료 → 단계 의존 균열/약한 신호/근접 영역. 단순 속도 증가는 사용하지 않는다.
## 11. Progression
향후 Conservation Rank로 유물군·판독 규칙 unlock. MVP는 단일 세션.
## 12. Economy
Not required for MVP.
## 13. Screen Inventory
Night Desk, Artifact Intake, Restoration Workspace, Evaluation, Session Summary, Pause/Tool Help.
## 14. Screen Flow
Desk→Intake→Workspace states→Evaluation→next; third→Summary→Desk. Early submit은 confirm.
## 15. Feedback System
Snap click/light haptic, lamp fluorescence, scrape flakes/resistance, damage amber warning, bond wet seam, evaluation before/after stamp.
## 16. Visual Direction Brief
9:16; 중앙 대형 유물, 하단 tray/tools, 상단 최소 HUD. 어두운 박물관+따뜻한 작업광+차가운 조사광. 판독성이 장식보다 우선.
## 17. MVP Scope
3 authored artifacts, full flow, rotate/zoom, fragment snap, lamp, foreign masks, scrape, seam trace, integrity/score/grade, overlays. 실제 geometry/mask 판정.
## 18. Test Scenarios
rotation tolerance, transformed hit-test, lamp-only discovery, damage, seam corridor, case reset, first-use discoverability.
## 19. Known Risks
transform/hit-test, scrape 노동화, lamp 자동정답화, authoring 병목, multitouch 충돌, UI 과밀.
## 20. Wireframe Handoff
6화면, Workspace boxes/variants, gesture priority, fragment outcomes, lamp discovery, scrape/bond states, modals, transitions, 동일 transform 판정 규칙을 명시한다.
