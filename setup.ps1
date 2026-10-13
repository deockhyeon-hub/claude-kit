# claude-kit 설치 스크립트 (Windows)
#
# 한 줄 설치 (PowerShell에 붙여넣고 엔터):
#   irm https://raw.githubusercontent.com/deockhyeon-hub/claude-kit/main/setup.ps1 | iex
#
# 같은 줄을 다시 실행하면 = 최신으로 업데이트. 몇 번을 실행해도 안전합니다.
#
# 하는 일:
#   1) giver-pack(내 Fork)과 insane-search를 홈 폴더에 내려받기
#   2) Claude Code에 플러그인으로 등록 / 설치 (이미 있으면 업데이트)
#   3) 읽기 도구(yt-dlp, curl_cffi 등) 설치
#   4) Aside가 깔려 있으면 Claude Code에 연결
# 계정 로그인 정보와 API 키는 건드리지 않습니다.

& {
# 'Stop'으로 두면 Windows PowerShell 5.1에서 git/pip이 안내문만 출력해도 오류로 멈춘다.
# 실패 판단은 Check(종료 코드)로 직접 한다.
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

$GiverRepo     = 'https://github.com/deockhyeon-hub/giver-pack.git'
$GiverUpstream = 'https://github.com/giversaran/giver-pack.git'
$GptakuRepo    = 'https://github.com/fivetaku/gptaku_plugins.git'
$GiverDir      = Join-Path $HOME 'giver-pack'
$GptakuDir     = Join-Path $HOME 'gptaku_plugins'

function Ok($msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "  [!!] $msg" -ForegroundColor Yellow }
function Step($msg) { Write-Host ""; Write-Host "> $msg" }
function Check($what) { if ($LASTEXITCODE -ne 0) { throw "$what 실패 (코드 $LASTEXITCODE)" } }

Write-Host '=============================================='
Write-Host ' claude-kit 설치'
Write-Host '=============================================='

try {
    # 1. 준비물 확인 -------------------------------------------------------
    Step '준비물 확인'
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Warn 'git이 없습니다.'
        Write-Host '     -> https://git-scm.com/download/win 에서 설치 후, PowerShell을 새로 열고 다시 실행해주세요.'
        return
    }
    Ok 'git'

    # 터미널용 Claude Code가 없으면 Claude 데스크톱 앱에 들어있는 것을 찾는다.
    $claude = (Get-Command claude -ErrorAction SilentlyContinue).Source
    if (-not $claude) {
        $local = Join-Path $HOME '.local\bin\claude.exe'
        if (Test-Path $local) { $claude = $local }
    }
    if (-not $claude) {
        $claude = Get-ChildItem -Path @(
                (Join-Path $env:APPDATA 'Claude\claude-code\*\claude.exe'),
                (Join-Path $env:LOCALAPPDATA 'Packages\Claude_*\LocalCache\Roaming\Claude\claude-code\*\claude.exe')
            ) -ErrorAction SilentlyContinue |
            Sort-Object { try { [version]$_.Directory.Name } catch { [version]'0.0' } } -Descending |
            Select-Object -First 1 -ExpandProperty FullName
    }
    if (-not $claude) {
        Warn 'Claude Code를 찾지 못했습니다.'
        Write-Host '     -> Claude 데스크톱 앱을 설치하고 로그인한 뒤 Code 탭을 한 번 열어보고, 다시 실행해주세요.'
        return
    }
    Ok "Claude Code ($claude)"

    # 2. 내려받기 ----------------------------------------------------------
    Step 'giver-pack 내려받기 (내 Fork)'
    if (Test-Path (Join-Path $GiverDir '.git')) {
        git -C $GiverDir remote set-url origin $GiverRepo; Check 'giver-pack 주소 설정'
        if ((git -C $GiverDir remote) -notcontains 'upstream') { git -C $GiverDir remote add upstream $GiverUpstream }
        git -C $GiverDir pull --ff-only origin main
        if ($LASTEXITCODE -ne 0) { Warn '최신화 실패 - 이 컴퓨터에서 고친 내용이 있는지 확인하세요. 설치는 계속합니다.' }
    } else {
        git clone $GiverRepo $GiverDir; Check 'giver-pack 내려받기'
        git -C $GiverDir remote add upstream $GiverUpstream
    }
    Ok $GiverDir

    Step 'insane-search 내려받기'
    if (Test-Path (Join-Path $GptakuDir '.git')) {
        git -C $GptakuDir pull --ff-only
        if ($LASTEXITCODE -ne 0) { Warn '최신화 실패 - 기존 버전으로 계속합니다.' }
    } else {
        git clone --depth 1 $GptakuRepo $GptakuDir; Check 'gptaku_plugins 내려받기'
    }
    git -C $GptakuDir submodule update --init --depth 1 plugins/insane-search; Check 'insane-search 내려받기'
    Ok $GptakuDir

    # 3. Claude Code에 등록 / 설치 ----------------------------------------
    Step 'Claude Code에 플러그인 등록'
    $markets = (& $claude plugin marketplace list) | Out-String
    foreach ($m in @(@{ Name = 'giver-pack'; Dir = $GiverDir }, @{ Name = 'gptaku-plugins'; Dir = $GptakuDir })) {
        if ($markets -match "(?m)^\s*>\s*$([regex]::Escape($m.Name))\s*$") {
            & $claude plugin marketplace update $m.Name | Out-Null
        } else {
            & $claude plugin marketplace add $m.Dir; Check "$($m.Name) 등록"
        }
    }

    $installed = (& $claude plugin list) | Out-String
    foreach ($p in @('giver-core@giver-pack', 'insane-search@gptaku-plugins')) {
        if ($installed -match [regex]::Escape($p)) {
            & $claude plugin update $p -y | Out-Null
            Ok "$p (업데이트 확인)"
        } else {
            & $claude plugin install $p; Check "$p 설치"
            Ok "$p 설치"
        }
    }

    # 4. 읽기 도구 (막힌 사이트 / 유튜브 자막) ----------------------------
    Step '읽기 도구 설치'
    if (Get-Command yt-dlp -ErrorAction SilentlyContinue) {
        Ok 'yt-dlp 이미 있음'
    } else {
        try {
            $dest = Join-Path $env:LOCALAPPDATA 'Programs\yt-dlp'
            New-Item -ItemType Directory -Force -Path $dest -ErrorAction Stop | Out-Null
            Invoke-WebRequest -UseBasicParsing -ErrorAction Stop -OutFile (Join-Path $dest 'yt-dlp.exe') `
                -Uri 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe'
            $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
            if ($userPath -notlike "*$dest*") {
                [Environment]::SetEnvironmentVariable('Path', "$userPath;$dest", 'User')
            }
            $env:Path += ";$dest"
            Ok 'yt-dlp 설치'
        } catch {
            Warn 'yt-dlp를 받지 못했습니다 (인터넷/방화벽 확인). 유튜브 자막 읽기만 안 되고 나머지는 정상입니다.'
        }
    }

    if (Get-Command pip3 -ErrorAction SilentlyContinue) {
        pip3 install -q --upgrade curl_cffi beautifulsoup4 pyyaml 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) { pip3 install --user -q --upgrade curl_cffi beautifulsoup4 pyyaml 2>$null | Out-Null }
        if ($LASTEXITCODE -eq 0) { Ok '우회 부품 (curl_cffi, beautifulsoup4, pyyaml)' } else { Warn '우회 부품 설치 실패 - insane-search가 첫 실행 때 다시 시도합니다.' }
    } else {
        Warn 'Python(pip3)이 없습니다 - 막힌 사이트 우회가 일부 제한됩니다. (python.org 에서 설치 가능)'
    }

    # 5. Aside 연결 --------------------------------------------------------
    Step 'Aside 연결'
    $aside = Join-Path $env:LOCALAPPDATA 'Aside\CLI\current\aside.exe'
    if (-not (Test-Path $aside)) { $aside = (Get-Command aside -ErrorAction SilentlyContinue).Source }
    if (-not $aside) {
        Write-Host '  [--] Aside가 없어서 건너뜀 (나중에 Aside를 설치하고 이 스크립트를 다시 실행하면 연결됩니다)'
    } else {
        & $claude mcp get aside *> $null
        if ($LASTEXITCODE -eq 0) {
            Ok 'Aside 이미 연결됨'
        } else {
            & $claude mcp add --scope user aside -- $aside mcp | Out-Null; Check 'Aside 연결'
            Ok 'Aside 연결 완료'
        }
    }

    Write-Host ''
    Write-Host '=============================================='
    Write-Host ' [OK] 설치 완료'
    Write-Host '=============================================='
    Write-Host ' - Claude 앱(또는 터미널)을 완전히 껐다가 다시 켜주세요.'
    Write-Host " - '/' 를 눌러 planning-first 가 보이면 성공입니다."
    Write-Host ' - 업데이트: 같은 한 줄을 다시 실행하면 됩니다.'
    Write-Host '=============================================='
} catch {
    Write-Host ''
    Warn "설치 중단: $($_.Exception.Message)"
    Write-Host '     -> 이 화면을 캡처해서 Claude에게 보여주면 원인을 찾아줍니다.'
}
}
