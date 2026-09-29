# 단비 게임회사 · DANBI GAME OFFICE

단비 게임회사의 게임 제작 파이프라인을 관리하는 웹 대시보드입니다.

## 현재 구조

- **GitHub (`Queenrain9/danbi-game-office`)**: 사이트 코드, 파이프라인 도구, 문서의 Source of Truth
- **Supabase (`hmblaasagxyntyfrfztg`)**: Idea Lab, Game Design, Wireframe, Implementation Contract, Build Job, Fidelity/Repair와 회사 상태의 중앙 저장소
- **Supabase Edge Function (`danbi-game-office-sync`)**: 브라우저가 DB의 관리자 키를 직접 가지지 않도록 하는 동기화 게이트웨이
- **GitHub Pages**: 어느 PC에서든 접속할 수 있는 정적 웹 배포 경로
- **Supabase Auth**: 단비 계정 로그인과 세션 관리
- **브라우저 localStorage**: 네트워크 장애 시 사용할 로컬 캐시만 저장

즉, PC 한 대가 회사의 원본을 들고 있는 구조가 아닙니다. GitHub + Supabase가 원본이고 PC는 접속 단말입니다.

## 다른 PC에서 이어서 작업하기

1. 배포 주소를 엽니다: `https://queenrain9.github.io/danbi-game-office/`
2. **단비 계정 로그인**을 누르고 등록된 이메일로 로그인합니다.
3. 로그인 세션이 만들어지면 Supabase에 저장된 동일한 회사 상태와 파이프라인 데이터를 자동으로 불러옵니다.
4. Godot 프로젝트를 직접 수정할 때만 해당 게임의 GitHub 저장소를 새 PC에 clone해서 Godot로 엽니다.

연결키 복사/붙여넣기 방식은 더 이상 사용하지 않습니다.

## 로컬 실행

배포 사이트 대신 로컬에서 확인할 수도 있습니다.

```bash
npm install
npm run dev
```

또는 단순 정적 서버:

```bash
python -m http.server 5173
```

그 뒤 `http://127.0.0.1:5173`에서 열면 됩니다.

## 배포

`.github/workflows/pages.yml`이 `main` push마다 GitHub Pages에 정적 사이트를 배포합니다.

처음 한 번 GitHub Pages가 아직 활성화되지 않은 저장소라면:

**Repository → Settings → Pages → Build and deployment → Source → GitHub Actions**

로 지정하면 이후에는 `main` 업데이트 때 자동 배포됩니다.

## 보안 원칙

- Supabase `service_role` / secret key는 브라우저 코드나 공개 GitHub에 넣지 않습니다.
- 브라우저는 Supabase Auth로 로그인한 뒤 `danbi-game-office-sync` Edge Function만 호출합니다.
- Edge Function은 로그인 JWT를 검증하고 단비 계정만 허용한 뒤 서버 측 Supabase 권한으로 DB를 읽고 씁니다.
- 공개 저장소나 브라우저 코드에는 `service_role` 같은 관리자 비밀키를 두지 않습니다.
- `danbi_game_office_state` 및 제작 파이프라인 DB는 이 배포 작업에서 삭제하거나 reset하지 않습니다.

## 제작 파이프라인

`Idea Lab → Game Design → Interaction Wireframe Pack → Implementation Contract / Fidelity Blueprint → Build Farm → Static Fidelity Gate → Playtest Ready`

현재 대시보드는 예약 ChatGPT 작업과 Supabase의 실제 제작 데이터를 읽어 운영 상태를 보여줍니다.
