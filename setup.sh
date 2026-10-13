#!/bin/bash
# claude-kit 설치 스크립트 (맥 / 리눅스)
#
# 한 줄 설치 (터미널에 붙여넣고 엔터):
#   bash <(curl -fsSL https://raw.githubusercontent.com/deockhyeon-hub/claude-kit/main/setup.sh)
#
# 같은 줄을 다시 실행하면 = 최신으로 업데이트. 몇 번을 실행해도 안전합니다.
#
# 하는 일:
#   1) giver-pack(내 Fork)과 insane-search를 홈 폴더에 내려받기
#   2) Claude Code에 플러그인으로 등록 / 설치 (이미 있으면 업데이트)
#   3) 읽기 도구(yt-dlp, curl_cffi 등) 설치
#   4) Aside가 깔려 있으면 Claude Code에 연결
# 계정 로그인 정보와 API 키는 건드리지 않습니다.

GIVER_REPO="https://github.com/deockhyeon-hub/giver-pack.git"
GIVER_UPSTREAM="https://github.com/giversaran/giver-pack.git"
GPTAKU_REPO="https://github.com/fivetaku/gptaku_plugins.git"
GIVER_DIR="$HOME/giver-pack"
GPTAKU_DIR="$HOME/gptaku_plugins"

ok()   { echo "  ✅ $1"; }
warn() { echo "  ⚠️  $1"; }
step() { echo ""; echo "▶ $1"; }
die()  { echo ""; warn "설치 중단: $1"; echo "     → 이 화면을 캡처해서 Claude에게 보여주면 원인을 찾아줍니다."; exit 1; }

echo "=============================================="
echo " claude-kit 설치"
echo "=============================================="

# 1. 준비물 확인 ---------------------------------------------------------
step "준비물 확인"
if ! command -v git >/dev/null 2>&1; then
  warn "git이 없습니다."
  echo "     → 맥: 터미널에 xcode-select --install 입력 후, 끝나면 다시 실행해주세요."
  exit 1
fi
ok "git"

# 터미널용 Claude Code가 없으면 Claude 데스크톱 앱에 들어있는 것을 찾는다.
CLAUDE="$(command -v claude 2>/dev/null)"
[ -z "$CLAUDE" ] && [ -x "$HOME/.local/bin/claude" ] && CLAUDE="$HOME/.local/bin/claude"
if [ -z "$CLAUDE" ]; then
  APP_CC="$HOME/Library/Application Support/Claude/claude-code"
  if [ -d "$APP_CC" ]; then
    VER="$(ls -1 "$APP_CC" | sort -t. -k1,1n -k2,2n -k3,3n | tail -n1)"
    CLAUDE="$(find "$APP_CC/$VER" -type f -name claude -perm -u+x 2>/dev/null | head -n1)"
  fi
fi
if [ -z "$CLAUDE" ]; then
  warn "Claude Code를 찾지 못했습니다."
  echo "     → Claude 데스크톱 앱을 설치하고 로그인한 뒤 Code 탭을 한 번 열어보고, 다시 실행해주세요."
  exit 1
fi
ok "Claude Code ($CLAUDE)"

# 2. 내려받기 ------------------------------------------------------------
step "giver-pack 내려받기 (내 Fork)"
if [ -d "$GIVER_DIR/.git" ]; then
  git -C "$GIVER_DIR" remote set-url origin "$GIVER_REPO" || die "giver-pack 주소 설정 실패"
  git -C "$GIVER_DIR" remote | grep -qx upstream || git -C "$GIVER_DIR" remote add upstream "$GIVER_UPSTREAM"
  git -C "$GIVER_DIR" pull --ff-only origin main \
    || warn "최신화 실패 - 이 컴퓨터에서 고친 내용이 있는지 확인하세요. 설치는 계속합니다."
else
  git clone "$GIVER_REPO" "$GIVER_DIR" || die "giver-pack 내려받기 실패"
  git -C "$GIVER_DIR" remote add upstream "$GIVER_UPSTREAM"
fi
ok "$GIVER_DIR"

step "insane-search 내려받기"
if [ -d "$GPTAKU_DIR/.git" ]; then
  git -C "$GPTAKU_DIR" pull --ff-only || warn "최신화 실패 - 기존 버전으로 계속합니다."
else
  git clone --depth 1 "$GPTAKU_REPO" "$GPTAKU_DIR" || die "gptaku_plugins 내려받기 실패"
fi
git -C "$GPTAKU_DIR" submodule update --init --depth 1 plugins/insane-search || die "insane-search 내려받기 실패"
ok "$GPTAKU_DIR"

# 3. Claude Code에 등록 / 설치 ------------------------------------------
step "Claude Code에 플러그인 등록"
MARKETS="$("$CLAUDE" plugin marketplace list 2>/dev/null)"
for pair in "giver-pack|$GIVER_DIR" "gptaku-plugins|$GPTAKU_DIR"; do
  name="${pair%%|*}"; dir="${pair#*|}"
  if echo "$MARKETS" | grep -Eq "^[[:space:]]*>[[:space:]]*$name[[:space:]]*$"; then
    "$CLAUDE" plugin marketplace update "$name" >/dev/null 2>&1
  else
    "$CLAUDE" plugin marketplace add "$dir" || die "$name 등록 실패"
  fi
done

INSTALLED="$("$CLAUDE" plugin list 2>/dev/null)"
for p in giver-core@giver-pack insane-search@gptaku-plugins; do
  if echo "$INSTALLED" | grep -qF "$p"; then
    "$CLAUDE" plugin update "$p" -y >/dev/null 2>&1
    ok "$p (업데이트 확인)"
  else
    "$CLAUDE" plugin install "$p" || die "$p 설치 실패"
    ok "$p 설치"
  fi
done

# 4. 읽기 도구 (막힌 사이트 / 유튜브 자막) ------------------------------
step "읽기 도구 설치"
BIN="$HOME/.local/bin"
case "$(uname -s)" in
  Darwin) YTDLP_ASSET="yt-dlp_macos" ;;
  *)      YTDLP_ASSET="yt-dlp_linux" ;;
esac
if command -v yt-dlp >/dev/null 2>&1; then
  ok "yt-dlp 이미 있음"
else
  mkdir -p "$BIN"
  if curl -fsSL -o "$BIN/yt-dlp" "https://github.com/yt-dlp/yt-dlp/releases/latest/download/$YTDLP_ASSET" \
     && chmod +x "$BIN/yt-dlp"; then
    for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
      [ -f "$RC" ] || continue
      grep -qs '.local/bin' "$RC" || printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$RC"
    done
    ok "yt-dlp 설치"
  else
    rm -f "$BIN/yt-dlp"
    warn "yt-dlp를 받지 못했습니다 (인터넷/방화벽 확인). 유튜브 자막 읽기만 안 되고 나머지는 정상입니다."
  fi
fi

if command -v pip3 >/dev/null 2>&1; then
  pip3 install --user -q --upgrade curl_cffi beautifulsoup4 pyyaml >/dev/null 2>&1 \
    && ok "우회 부품 (curl_cffi, beautifulsoup4, pyyaml)" \
    || warn "우회 부품 설치 실패 - insane-search가 첫 실행 때 다시 시도합니다."
else
  warn "Python(pip3)이 없습니다 - 막힌 사이트 우회가 일부 제한됩니다."
fi

# 5. Aside 연결 ----------------------------------------------------------
step "Aside 연결"
ASIDE="$(command -v aside 2>/dev/null)"
[ -z "$ASIDE" ] && [ -x "$HOME/.local/bin/aside" ] && ASIDE="$HOME/.local/bin/aside"
if [ -z "$ASIDE" ]; then
  echo "  ⏭  Aside CLI가 없어서 건너뜀"
  echo "     (Aside 설정 > Developers 에서 CLI를 설치한 뒤 이 스크립트를 다시 실행하면 연결됩니다)"
elif "$CLAUDE" mcp get aside >/dev/null 2>&1; then
  ok "Aside 이미 연결됨"
else
  "$CLAUDE" mcp add --scope user aside -- "$ASIDE" mcp >/dev/null || die "Aside 연결 실패"
  ok "Aside 연결 완료"
fi

echo ""
echo "=============================================="
echo " ✅ 설치 완료"
echo "=============================================="
echo " - Claude 앱(또는 터미널)을 완전히 껐다가 다시 켜주세요."
echo " - '/' 를 눌러 planning-first 가 보이면 성공입니다."
echo " - 업데이트: 같은 한 줄을 다시 실행하면 됩니다."
echo "=============================================="
