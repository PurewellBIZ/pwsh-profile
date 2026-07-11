#!/usr/bin/env pwsh
# pwsh -ExecutionPolicy ByPass -c "irm https://raw.githubusercontent.com/PurewellBIZ/pwsh-profile/main/install.ps1 | iex"

$ErrorActionPreference = "Stop"

# 1. $PROFILE 디렉토리 경로 확인 및 폴더 생성
$profileDir = Split-Path -Parent $PROFILE
if (!(Test-Path -Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    Write-Host "프로필 디렉토리를 생성합니다: $profileDir" -ForegroundColor Cyan
}

$targetPath = Join-Path $profileDir "pwsh-profile.ps1"
$sourceUrl = "https://raw.githubusercontent.com/PurewellBIZ/pwsh-profile/main/pwsh-profile.ps1"

# 2. pwsh-profile.ps1 파일 다운로드
Write-Host "스크립트 다운로드 중: $targetPath..." -ForegroundColor Cyan
Invoke-RestMethod -Uri $sourceUrl -OutFile $targetPath

# 3. $PROFILE 파일이 없으면 새 파일 생성
if (!(Test-Path -Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    Write-Host "새로운 프로파일 스크립트를 작성하고 있습니다: $PROFILE" -ForegroundColor Green
}

# 4. 기존 $PROFILE 내용 검사 (중복 include 방지)
$profileContent = Get-Content -Path $PROFILE -Raw

# 이미 'pwsh-profile.ps1'이 언급되어 있다면 중복 추가하지 않음
if (!($profileContent -and ($profileContent.Contains("pwsh-profile.ps1")))) {
    Write-Host "pw-profile.ps1 을 포함하도록 합니다: $PROFILE" -ForegroundColor Cyan

    # 5. $PSScriptRoot를 활용한 동적 Include 블록 생성
    # Here-String 내의 변수 기호($)를 빽틱(`)으로 이스케이프하여 문자열 그대로 저장되게 합니다.
    $blockToAdd = @"

# Added by NeoGenius pwsh-profile installer
if (`$PSScriptRoot) {
    `$_purewell_profile = Join-Path `$PSScriptRoot "pwsh-profile.ps1"
    if (Test-Path -Path `$_purewell_profile) {
        . `$_purewell_profile
    }
}
"@

    # $PROFILE 맨 밑에 추가
    Add-Content -Path $PROFILE -Value $blockToAdd
}

Write-Host "설치를 완료하였습니다!" -ForegroundColor Green
