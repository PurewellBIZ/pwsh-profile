#!/usr/bin/env pwsh
# 스팀 관련 유틸리티를 모아둔 스크립트입니다.
# 필요하면 직접 불러와도 됩니다: . "$PWSHLibraryPath\SteamManipulate.ps1"

function Repair-SteamShortcuts {
  [CmdletBinding()]
  param(
    [string]$SourceFolder = [Environment]::GetFolderPath('Desktop'),
    [string]$TargetFolder,
    [string]$SteamPath = 'C:\Program Files (x86)\Steam'
  )

  if (-not $TargetFolder) {
    $TargetFolder = Join-Path $SourceFolder 'converted_shortcuts'
  }

  if (-not (Test-Path -LiteralPath $TargetFolder)) {
    New-Item -ItemType Directory -Path $TargetFolder -Force | Out-Null
  }

  $steamGamesIconPath = Join-Path $SteamPath 'steam\games'
  $WshShell = New-Object -ComObject WScript.Shell

  Get-ChildItem -Path $SourceFolder -Filter *.url | ForEach-Object {
    $urlFile = $_.FullName
    $lnkFile = Join-Path $TargetFolder ($_.BaseName + '.lnk')

    $content = Get-Content -LiteralPath $urlFile
    $url = ($content | Select-String '^URL=(.*)$').Matches.Groups[1].Value
    $iconFile = ($content | Select-String '^IconFile=(.*)$').Matches.Groups[1].Value

    $appId = ($url -replace 'steam://rungameid/', '')

    if (-not $iconFile -or -not (Test-Path -LiteralPath $iconFile)) {
      $possibleIcon = Join-Path $steamGamesIconPath "$appId.ico"
      if (Test-Path -LiteralPath $possibleIcon) {
        $iconFile = $possibleIcon
      }
    }

    $shortcut = $WshShell.CreateShortcut($lnkFile)
    $shortcut.TargetPath = Join-Path $SteamPath 'steam.exe'
    $shortcut.Arguments = "-applaunch $appId"
    if ($iconFile -and (Test-Path -LiteralPath $iconFile)) {
      $shortcut.IconLocation = $iconFile
    }
    $shortcut.Save()
  }

  Write-Host "변환 완료! $TargetFolder 폴더를 확인하세요."
}
