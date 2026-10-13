# claude-kit

내 컴퓨터 어디서든 **같은 Claude 작업 환경**을 한 줄로 설치하는 키트입니다.

| 설치되는 것 | 하는 일 |
|---|---|
| **giver-core** (스킬 23개) | 기획 먼저, 쉬운 설명, 일상어로 스킬 찾기 등 작업 방식 ([내 Fork](https://github.com/deockhyeon-hub/giver-pack)) |
| **insane-search** | 막힌 사이트·유튜브 자막 읽기 |
| **읽기 도구** | yt-dlp, curl_cffi 등 (insane-search가 씀) |
| **Aside 연결** | 그 컴퓨터에 Aside가 있으면 Claude Code가 Aside 브라우저를 부려 쓸 수 있게 연결 |

> eden- 으로 시작하는 스킬, 영업·마케팅 플러그인은 **Claude 계정에 붙어 있어서** 같은 계정으로 로그인만 하면 자동으로 들어옵니다. 이 키트와 상관없습니다.

---

## 설치 (컴퓨터마다 한 번)

**준비물:** Claude 데스크톱 앱(로그인 + Code 탭 한 번 열어보기), git

### 윈도우

시작 버튼 → `PowerShell` 검색 → 실행 → 아래 한 줄 붙여넣기(마우스 오른쪽 클릭) → 엔터

```powershell
irm https://raw.githubusercontent.com/deockhyeon-hub/claude-kit/main/setup.ps1 | iex
```

### 맥

`⌘ + 스페이스` → `터미널` → 아래 한 줄 붙여넣기 → 엔터

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/deockhyeon-hub/claude-kit/main/setup.sh)
```

### 확인

Claude 앱을 **완전히 껐다가 다시 켜고**, Code 탭에서 `/` 를 눌러 `planning-first` 가 보이면 성공입니다.

---

## 업데이트

**같은 한 줄을 다시 실행**하면 됩니다. 몇 번을 실행해도 안전합니다.

### 전문가(원본)의 새 버전을 받고 싶을 때

이 키트는 원본(`giversaran/giver-pack`)이 아니라 **내 Fork**에서 받아옵니다. 그래서 원본이 업데이트돼도 자동으로 들어오지 않습니다.

1. https://github.com/deockhyeon-hub/giver-pack 열기
2. 초록 버튼 위쪽의 **Sync fork → Update branch** 클릭
3. 각 컴퓨터는 Claude를 켤 때 자동으로 최신 내용을 받아옵니다 (또는 설치 한 줄 다시 실행)

---

## 내 규칙·스킬 고치기

`giver-pack`(내 Fork)을 고치면 모든 컴퓨터에 퍼집니다.

- 규칙: `plugins/giver-core/CLAUDE.md`
- 스킬: `plugins/giver-core/skills/<스킬이름>/SKILL.md`

깃허브 웹사이트에서 파일을 열고 ✏️(연필) 버튼으로 고쳐도 되고, Claude에게 "~/giver-pack 의 ○○ 규칙 고쳐서 깃허브에 올려줘" 라고 해도 됩니다.

---

## 되돌리기

윈도우 PowerShell / 맥 터미널에서 Claude Code 기준:

```
claude plugin uninstall giver-core@giver-pack
claude plugin uninstall insane-search@gptaku-plugins
claude mcp remove aside -s user
```

그다음 홈 폴더의 `giver-pack`, `gptaku_plugins` 폴더를 지우면 흔적이 남지 않습니다.
