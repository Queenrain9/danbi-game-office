# 단비 게임회사 · DANBI GAME OFFICE

Work/Sites에서 만들던 내부 게임 제작 대시보드를, 현재 채팅에서 바로 실행 가능한 독립 웹앱으로 재구성한 v0.1입니다.

## 핵심 구조
- Idea Lab
- Greenlight
- Concept Studio
- Pre-production / Wireframe
- Build Farm
- Review Room
- Directed Development
- Archive / Activity / Settings

## 실제 동작
- `Studio Cycle` 버튼으로 mock 자동 제작 라인이 진행됩니다.
- 아이디어 생성 / 단계 이동 / 빌드 진행이 실제 UI 데이터에 반영됩니다.
- Review Room에서 KEEP / MAYBE / KILL 결정을 할 수 있습니다.
- KEEP은 Directed Development로 이동합니다.
- 디렉팅 메모를 저장할 수 있습니다.
- 설정에서 자동화 단계를 켜고 끌 수 있습니다.
- 상태는 브라우저 `localStorage`에 저장되어 새로고침 후에도 유지됩니다.
- Repo 주소 복사 기능이 있습니다.
- 데스크톱 / 모바일 반응형입니다.

## 실행
가장 간단하게는 `index.html`을 브라우저로 열면 됩니다.

또는 로컬 서버:
```bash
python -m http.server 5173
```
그 뒤:
`http://127.0.0.1:5173`

## 다음 연결 포인트
현재 v0.1은 자동 제작 라인을 **실제로 경험 가능한 mock production system**으로 만든 상태입니다.
다음 단계에서 GPT API, 이미지 생성, GitHub API, Godot build agent를 각각 adapter로 연결하면 됩니다.

## Cloud Sync (v0.2)

- 중앙 상태 저장소: Supabase `danbi_game_office_state`
- 브라우저는 DB에 직접 접근하지 않고 `danbi-game-office-sync` Edge Function만 호출합니다.
- Edge Function은 별도 연결키를 SHA-256으로 검증한 뒤 server-side 권한으로 상태를 읽고 씁니다.
- PC / iPhone / 다른 PC에서 같은 연결키를 입력하면 동일한 회사 상태를 불러옵니다.
- 로컬 저장도 계속 유지하므로 일시적인 네트워크 오류에서도 화면은 동작합니다.
