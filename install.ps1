# Wilson Team Market - 스킬 설치 스크립트
# 사용법: .\install.ps1 -Plugin wilson-tools
# 또는 원격 실행: irm https://raw.githubusercontent.com/bbora1513/wilson-team-market/master/install.ps1 | iex

param(
  [string]$Plugin = ""
)

$REPO_RAW  = "https://raw.githubusercontent.com/bbora1513/wilson-team-market/master"
$CATALOG   = "$REPO_RAW/catalog.json"
$SKILLS_DIR = "$env:APPDATA\Claude\local-agent-mode-sessions\skills-plugin"

function Write-Header {
  Write-Host ""
  Write-Host "  🎾 Wilson Team Market - 스킬 설치 관리자" -ForegroundColor White
  Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
  Write-Host ""
}

function Get-Catalog {
  try {
    $catalog = Invoke-RestMethod -Uri $CATALOG -ErrorAction Stop
    return $catalog
  } catch {
    Write-Host "  ❌ catalog.json을 불러올 수 없습니다. 네트워크 연결을 확인하세요." -ForegroundColor Red
    exit 1
  }
}

function Find-SkillsPluginDir {
  # Claude Desktop의 skills-plugin 폴더 자동 탐색
  # 스킬이 가장 많이 등록된 manifest.json을 우선 선택 (활성 세션)
  $dirs = Get-ChildItem -Path $SKILLS_DIR -Recurse -Filter "manifest.json" -ErrorAction SilentlyContinue
  if (-not $dirs) { return $null }

  $best = $dirs | Sort-Object {
    try {
      $m = Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json
      @($m.skills).Count
    } catch { 0 }
  } -Descending | Select-Object -First 1

  return $best.DirectoryName
}

function Install-Plugin {
  param($pluginInfo, $pluginDir)

  $pluginId   = $pluginInfo.id
  $version    = $pluginInfo.version
  $fileUrl    = "$REPO_RAW/$($pluginInfo.file)"
  $tmpZip     = "$env:TEMP\${pluginId}.zip"
  $tmpExtract = "$env:TEMP\${pluginId}_extract"

  Write-Host "  📦 $($pluginInfo.name) v$version 설치 중..." -ForegroundColor Cyan

  # 다운로드
  try {
    Invoke-WebRequest -Uri $fileUrl -OutFile $tmpZip -ErrorAction Stop
    Write-Host "  ✅ 다운로드 완료" -ForegroundColor Green
  } catch {
    Write-Host "  ❌ 다운로드 실패: $fileUrl" -ForegroundColor Red
    return $false
  }

  # .skill → zip 복사 후 압축 해제
  $tmpZip2 = "$env:TEMP\${pluginId}_tmp.zip"
  Copy-Item -LiteralPath $tmpZip -Destination $tmpZip2 -Force
  if (Test-Path -LiteralPath $tmpExtract) {
    Remove-Item -Recurse -LiteralPath $tmpExtract -Force
  }
  Expand-Archive -LiteralPath $tmpZip2 -DestinationPath $tmpExtract -Force

  # skills/ 폴더 내 각 스킬을 Claude skills 폴더에 복사
  $skillFolders = Get-ChildItem -Path $tmpExtract -Directory -Recurse |
    Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") }

  $installed = 0
  foreach ($sf in $skillFolders) {
    $destSkillDir = Join-Path $pluginDir "skills\$($sf.Name)"
    if (-not (Test-Path -LiteralPath $destSkillDir)) {
      New-Item -ItemType Directory -Path $destSkillDir -Force | Out-Null
    }
    Copy-Item -LiteralPath (Join-Path $sf.FullName "SKILL.md") `
              -Destination (Join-Path $destSkillDir "SKILL.md") -Force
    Write-Host "  ✅ 스킬 설치: /$($sf.Name)" -ForegroundColor Green
    $installed++
  }

  # manifest.json 업데이트
  $manifestPath = Join-Path $pluginDir "manifest.json"
  if (Test-Path -LiteralPath $manifestPath) {
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json

    foreach ($skill in $pluginInfo.skills) {
      $existing = $manifest.skills | Where-Object { $_.name -eq $skill.name }
      if (-not $existing) {
        $newSkill = [PSCustomObject]@{
          skillId     = "$pluginId-$($skill.name)"
          name        = $skill.name
          description = $skill.summary
          creatorType = "user"
          updatedAt   = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
          enabled     = $true
        }
        $manifest.skills = @($newSkill) + $manifest.skills
        Write-Host "  ✅ manifest 등록: $($skill.name)" -ForegroundColor Green
      } else {
        Write-Host "  ⚠️  이미 등록됨: $($skill.name)" -ForegroundColor Yellow
      }
    }

    $manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
  }

  # 정리
  Remove-Item -LiteralPath $tmpZip   -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $tmpZip2  -Force -ErrorAction SilentlyContinue
  Remove-Item -Recurse -LiteralPath $tmpExtract -Force -ErrorAction SilentlyContinue

  return $installed -gt 0
}

function Show-Menu {
  param($catalog)
  Write-Host "  사용 가능한 플러그인:" -ForegroundColor White
  Write-Host ""
  $i = 1
  foreach ($p in $catalog.plugins) {
    Write-Host "  [$i] $($p.name) v$($p.version) — $($p.description.Substring(0, [Math]::Min(60, $p.description.Length)))..." -ForegroundColor Cyan
    $i++
  }
  Write-Host ""
  $choice = Read-Host "  번호를 입력하세요 (종료: q)"
  if ($choice -eq 'q') { exit 0 }
  $idx = [int]$choice - 1
  if ($idx -ge 0 -and $idx -lt $catalog.plugins.Count) {
    return $catalog.plugins[$idx]
  }
  return $null
}

# ── MAIN ─────────────────────────────────────────────────────────────
Write-Header

$catalog   = Get-Catalog
$pluginDir = Find-SkillsPluginDir

if (-not $pluginDir) {
  Write-Host "  ❌ Claude Desktop의 skills 폴더를 찾을 수 없습니다." -ForegroundColor Red
  Write-Host "     Claude Desktop이 설치되어 있는지 확인하세요." -ForegroundColor DarkGray
  exit 1
}

Write-Host "  📂 Claude 스킬 폴더: $pluginDir" -ForegroundColor DarkGray
Write-Host ""

# 플러그인 선택
$pluginInfo = $null
if ($Plugin) {
  $pluginInfo = $catalog.plugins | Where-Object { $_.id -eq $Plugin }
  if (-not $pluginInfo) {
    Write-Host "  ❌ 플러그인 '$Plugin'을 찾을 수 없습니다." -ForegroundColor Red
    $pluginInfo = Show-Menu $catalog
  }
} else {
  $pluginInfo = Show-Menu $catalog
}

if (-not $pluginInfo) {
  Write-Host "  ❌ 잘못된 선택입니다." -ForegroundColor Red
  exit 1
}

$ok = Install-Plugin $pluginInfo $pluginDir

if ($ok) {
  Write-Host ""
  Write-Host "  ✅ 설치 완료! Claude Desktop을 재시작하면 스킬이 활성화됩니다." -ForegroundColor Green
  Write-Host ""
} else {
  Write-Host ""
  Write-Host "  ❌ 설치 중 문제가 발생했습니다." -ForegroundColor Red
}
