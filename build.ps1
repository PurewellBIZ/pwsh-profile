#!/usr/bin/env pwsh
# 빌드 스크립트 예시: pwsh -File .\build.ps1 -Version 1.0.2


param(
  [Parameter(Mandatory = $true)]
  [string]$Version
)

$psd1Path = ".\src\PWSHProfile.psd1"

# psd1 버전 수정
Update-ModuleManifest -Path $psd1Path -ModuleVersion $Version

# git 커밋 & 태그 자동 생성
git add $psd1Path
git commit -m "bump: version $Version"
git tag "v$Version"

Write-Host "버전 등록 완료: $psd1Path -> v$Version" -ForegroundColor Green
