#!/usr/bin/env pwsh

[CmdletBinding()]
param(
  [Parameter()]
  [ValidatePattern('^\d+\.\d+\.\d+$')]
  [string]$Version,

  [Parameter()]
  [string]$OutputDirectory = (Join-Path $PSScriptRoot 'dist'),

  [Parameter()]
  [string]$NsisPath = 'makensis.exe'
)

$ErrorActionPreference = 'Stop'
$moduleName = 'PWSHProfile'
$sourceDirectory = Join-Path $PSScriptRoot 'src'
$manifestPath = Join-Path $sourceDirectory "$moduleName.psd1"

if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
  throw "모듈 매니페스트를 찾을 수 없습니다: $manifestPath"
}

if (-not $Version) {
  $Version = (Import-PowerShellDataFile -Path $manifestPath).ModuleVersion.ToString()
}

Update-ModuleManifest -Path $manifestPath -ModuleVersion $Version

$outputDirectoryPath = [System.IO.Path]::GetFullPath($OutputDirectory)
$outputFile = Join-Path $outputDirectoryPath "$moduleName-$Version-setup.exe"
$nsisFile = Join-Path $PSScriptRoot 'install.nsi'

if (-not (Test-Path -LiteralPath $nsisFile -PathType Leaf)) {
  throw "NSIS 스크립트를 찾을 수 없습니다: $nsisFile"
}

$nsisCommand = Get-Command $NsisPath -ErrorAction SilentlyContinue
if (-not $nsisCommand) {
  throw "NSIS 컴파일러를 찾을 수 없습니다. NSIS를 설치한 뒤 -NsisPath로 makensis.exe 경로를 지정하세요."
}

New-Item -ItemType Directory -Path $outputDirectoryPath -Force | Out-Null

Push-Location $PSScriptRoot
try {
  & $nsisCommand.Source "/DAPPVERSION=$Version" "/DOUTPUT_FILE=$outputFile" $nsisFile
  if ($LASTEXITCODE -ne 0) {
    throw "NSIS 빌드에 실패했습니다. 종료 코드: $LASTEXITCODE"
  }
}
finally {
  Pop-Location
}

if (-not (Test-Path -LiteralPath $outputFile -PathType Leaf)) {
  throw "NSIS 빌드 산출물을 찾을 수 없습니다: $outputFile"
}

Write-Host "빌드를 완료했습니다: $outputFile" -ForegroundColor Green
