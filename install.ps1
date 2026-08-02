#!/usr/bin/env pwsh
# pwsh -ExecutionPolicy ByPass -c "irm https://raw.githubusercontent.com/PurewellBIZ/pwsh-profile/main/install.ps1 | iex"
# 로컬 설치 예: pwsh -File .\install.ps1 -Local

param(
    [Alias('UseCurrentDirectory')]
    [switch]$Local
)

$ErrorActionPreference = 'Stop'
$moduleName = 'PWSHProfile'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceRoot = Join-Path $scriptRoot 'src'
$moduleRoot = Join-Path $HOME 'Documents\PowerShell\Modules'
$moduleVersion = '1.0.0'

$manifestCandidate = Join-Path $sourceRoot "$moduleName.psd1"
$repoRoot = $null
$gitBranch = $null

if (Get-Command git -ErrorAction SilentlyContinue) {
    try {
        $repoRoot = git -C $scriptRoot rev-parse --show-toplevel 2>$null | Out-String
        $repoRoot = $repoRoot.Trim()
    }
    catch {
        $repoRoot = $null
    }

    if ($repoRoot) {
        try {
            $gitBranch = git -C $repoRoot rev-parse --abbrev-ref HEAD 2>$null | Out-String
            $gitBranch = $gitBranch.Trim()
            if ([string]::IsNullOrWhiteSpace($gitBranch) -or $gitBranch -eq 'HEAD') {
                $gitBranch = $null
            }
        }
        catch {
            $gitBranch = $null
        }

        if ($Local) {
            try {
                $gitTag = git -C $repoRoot describe --tags --abbrev=0 2>$null | Out-String
                $gitTag = $gitTag.Trim()
                if ($gitTag) {
                    $moduleVersion = $gitTag.TrimStart('v','V')
                }
            }
            catch {
                # Git 태그를 읽을 수 없는 경우, 매니페스트나 기본값을 사용
            }
        }
    }
}

if ($moduleVersion -eq '1.0.0' -and (Test-Path $manifestCandidate)) {
    try {
        $moduleVersion = (Import-PowerShellDataFile -Path $manifestCandidate).ModuleVersion.ToString()
    }
    catch {
        Write-Host "모듈 매니페스트에서 버전을 읽을 수 없습니다. 기본값 $moduleVersion 을 사용합니다." -ForegroundColor Yellow
    }
}

$installDir = Join-Path $moduleRoot $moduleName $moduleVersion
$libraryDir = Join-Path $installDir 'Functions'

if (!(Test-Path -Path $libraryDir)) {
    New-Item -ItemType Directory -Path $libraryDir -Force | Out-Null
    Write-Host "모듈 설치 디렉터리를 생성합니다: $installDir" -ForegroundColor Cyan
}

$scriptFiles = @("$moduleName.psm1", "$moduleName.psd1")
$libraryRoot = Join-Path $sourceRoot 'Functions'
$libraryFiles = if (Test-Path -Path $libraryRoot -PathType Container) {
    Get-ChildItem -Path $libraryRoot -Filter '*.ps1' -File | Select-Object -ExpandProperty Name
}
else {
    @()
}

function Remove-PathIfExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [switch]$Recurse
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return
    }

    if (Test-Path -LiteralPath $Path) {
        try {
            Remove-Item -LiteralPath $Path -Force -Recurse:$Recurse -ErrorAction SilentlyContinue
        }
        catch {
            # 이미 제거되었거나 접근 권한 문제가 있어도 진행한다.
        }
    }
}

if ($Local) {
    foreach ($fileName in $scriptFiles) {
        $sourcePath = Join-Path $sourceRoot $fileName
        $destPath = Join-Path $installDir $fileName

        if (!(Test-Path -Path $sourcePath -PathType Leaf)) {
            throw "현재 디렉터리에 $fileName 파일이 없습니다: $sourcePath"
        }

        Write-Host "로컬 스크립트를 설치합니다: $sourcePath -> $destPath" -ForegroundColor Cyan
        Copy-Item -Path $sourcePath -Destination $destPath -Force
    }

    foreach ($fileName in $libraryFiles) {
        $sourcePath = Join-Path $sourceRoot 'Functions' $fileName
        $destPath = Join-Path $libraryDir $fileName

        if (!(Test-Path -Path $sourcePath -PathType Leaf)) {
            throw "현재 디렉터리에 $fileName 파일이 없습니다: $sourcePath"
        }

        Write-Host "로컬 라이브러리 스크립트를 설치합니다: $sourcePath -> $destPath" -ForegroundColor Cyan
        Copy-Item -Path $sourcePath -Destination $destPath -Force
    }
}
else {
    $branchName = if ($gitBranch) { $gitBranch } else { 'main' }
    $archiveUrl = "https://github.com/PurewellBIZ/pwsh-profile/archive/refs/heads/$branchName.zip"
    $zipFile = Join-Path $env:TEMP 'pwsh-profile-install.zip'
    $extractRoot = Join-Path $env:TEMP 'pwsh-profile-install'

    Remove-PathIfExists -Path $zipFile
    Remove-PathIfExists -Path $extractRoot -Recurse

    Write-Host "저장소 ZIP을 다운로드합니다: $archiveUrl" -ForegroundColor Cyan
    Invoke-WebRequest -Uri $archiveUrl -OutFile $zipFile -UseBasicParsing
    Expand-Archive -Path $zipFile -DestinationPath $extractRoot -Force

    $repoRoot = Get-ChildItem -Path $extractRoot -Directory | Select-Object -First 1
    if (-not $repoRoot) {
        throw "다운로드한 ZIP에서 리포지토리 루트 폴더를 찾을 수 없습니다."
    }

    $downloadRoot = Join-Path $repoRoot.FullName 'src'

    foreach ($fileName in $scriptFiles) {
        $sourcePath = Join-Path $downloadRoot $fileName
        $destPath = Join-Path $installDir $fileName

        if (!(Test-Path -Path $sourcePath -PathType Leaf)) {
            throw "ZIP에서 $fileName 파일을 찾을 수 없습니다: $sourcePath"
        }

        Write-Host "ZIP에서 설치할 스크립트를 복사합니다: $sourcePath -> $destPath" -ForegroundColor Cyan
        Copy-Item -Path $sourcePath -Destination $destPath -Force
    }

    foreach ($fileName in $libraryFiles) {
        $sourcePath = Join-Path $downloadRoot 'Functions' $fileName
        $destPath = Join-Path $libraryDir $fileName

        if (!(Test-Path -Path $sourcePath -PathType Leaf)) {
            throw "ZIP에서 $fileName 파일을 찾을 수 없습니다: $sourcePath"
        }

        Write-Host "ZIP에서 설치할 라이브러리 스크립트를 복사합니다: $sourcePath -> $destPath" -ForegroundColor Cyan
        Copy-Item -Path $sourcePath -Destination $destPath -Force
    }

    Remove-PathIfExists -Path $zipFile
    Remove-PathIfExists -Path $extractRoot -Recurse
}

$moduleBaseDir = Join-Path $moduleRoot $moduleName
if (Test-Path -Path $moduleBaseDir -PathType Container) {
    $existingVersionDirs = Get-ChildItem -Path $moduleBaseDir -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -ne $installDir }

    foreach ($existingVersionDir in $existingVersionDirs) {
        Write-Host "이전 모듈 버전을 제거합니다: $($existingVersionDir.FullName)" -ForegroundColor Yellow
        Remove-Item -Path $existingVersionDir.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "설치를 완료하였습니다!" -ForegroundColor Green
Write-Host "모듈이 아래 경로에 설치되었습니다: $installDir" -ForegroundColor Green
Write-Host "PowerShell 표준 모듈 경로에 설치되었으므로, 새 세션에서 'Import-Module $moduleName' 또는 자동 로드가 가능합니다." -ForegroundColor Green
