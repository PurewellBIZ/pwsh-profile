#!/usr/bin/env pwsh

# 예쁜 프롬프트 출력을 위한 스타쉽: https://starship.rs/
$ENV:STARSHIP_CONFIG = "$HOME\.config\starship.toml"
Invoke-Expression (&starship init powershell)

$PWSHLibraryPath = Join-Path $PSScriptRoot "Functions"

# 모듈 로드 예시:
# Import-Module PWSHProfile
# Get-Command -Module PWSHProfile

# 환경설정 다시 불러오기
function Sync-Profile {
  . $PROFILE
  Write-Host "PowerShell 프로필을 다시 불러왔습니다." -ForegroundColor Green
}

# 휴지통을 비우고 PowerShell 기록을 모두 지웁니다.
function Clear-Trash {
  Clear-RecycleBin -Force

  Clear-AllHistory
}

# PowerShell 세션 기록, PSReadLine 기록, 그리고 Explorer Typed Paths를 삭제합니다.
function Clear-AllHistory {
  [CmdletBinding()]
  param()

  process {
    Clear-History

    if (!(Get-Module PSReadLine)) {
      Import-Module PSReadLine -ErrorAction SilentlyContinue
    }

    if (Get-Command Clear-HistoryHandler -ErrorAction SilentlyContinue) {
      Clear-HistoryHandler
    }
    else {
      $historyPath = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"

      try {
        $historyPath = [Microsoft.PowerShell.PSConsoleReadLine]::GetHistorySavePath()
      }
      catch {
        # GetHistorySavePath 메서드가 없는 경우 기본 경로를 사용
      }

      if (Test-Path $historyPath) {
        Clear-Content $historyPath
      }
    }

    $typedPathsKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths'
    if (Test-Path $typedPathsKey) {
      $typedPathProps = (Get-ItemProperty -Path $typedPathsKey).PSObject.Properties |
      Where-Object { $_.Name -notin 'PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider' }

      foreach ($prop in $typedPathProps) {
        Remove-ItemProperty -Path $typedPathsKey -Name $prop.Name -ErrorAction SilentlyContinue
      }
    }
  }
}

# 심볼릭 링크를 생성합니다.
function New-Symlink {
  param (
    [string]$source,
    [string]$target
  )
  New-Item -ItemType SymbolicLink -Path $target -Target $source
}

# 현재 대기 모드 해제 허용 장치 목록을 조회합니다.
function Get-WakeArmedDevices {
  $output = & powercfg -devicequery wake_armed 2>&1

  $devices = $output |
  Where-Object {
    $_ -and $_.Trim().Length -gt 0 -and
    -not ($_.Trim() -match '^(없음|없습니다|No devices|no devices|There are no|가 없습니다|항목이 없습니다|목록이 없습니다)$')
  } |
  ForEach-Object { $_.Trim() }

  if ($devices.Count -gt 0) {
    return $devices
  }

  return @()
}

# 마지막에 대기 모드 해제를 발생시킨 이벤트를 조회합니다.
function Get-LastWakeEvent {
  $output = & powercfg -lastwake 2>&1

  if ($output -match 'Wake Source:\s*(.+)') {
    return $Matches[1].Trim()
  }

  return @()
}

# 지정된 장치에서 대기 모드 해제를 활성화합니다.
function Set-EnableWakeOnDevice {
  param(
    [string]$deviceName
  )
  sudo powercfg -deviceenablewake $deviceName
}

# 지정된 장치 또는 모든 Wake-armed 장치에서 대기 모드 해제를 비활성화합니다.
function Set-DisableWakeOnDevice {
  param(
    [string]$deviceName
  )

  if ([string]::IsNullOrWhiteSpace($deviceName)) {
    Write-Host "디바이스 이름은 필수입니다. 'all'을 사용하여 모든 대기 모드 해제 장치를 비활성화할 수 있습니다."
    return
  }

  if ($deviceName.Trim().ToLower() -eq 'all') {
    $devices = Get-WakeArmedDevices
    if (-not $devices) {
      Write-Host "현재 대기 모드 해제를 활성화한 장치가 없습니다."
      return
    }

    foreach ($device in $devices) {
      Write-Host "대기 모드 해제 가능 권한을 비활성화 하였습니다: $device"
      sudo powercfg -devicedisablewake $device
    }

    return
  }

  sudo powercfg -devicedisablewake $deviceName
}

# desktop.ini 파일을 백업하고 정제한 뒤 Windows 탐색기 호환 형식으로 재설정합니다.
function Reset-DesktopIni {
  $folderManipulateScript = Join-Path $PWSHLibraryPath "FolderManipulate.ps1"
  if (-not (Test-Path -Path $folderManipulateScript -PathType Leaf)) {
    Write-Error "FolderManipulate.ps1 파일을 찾을 수 없습니다: $folderManipulateScript"
    return
  }

  . $folderManipulateScript
  Reset-DesktopIni @args
}

# 아이콘/이미지 관련 유틸리티는 필요할 때만 지연 로드합니다.
function ConvertTo-ICO {
  $iconManipulateScript = Join-Path $PWSHLibraryPath "IconManipulate.ps1"
  if (-not (Test-Path -Path $iconManipulateScript -PathType Leaf)) {
    Write-Error "IconManipulate.ps1 파일을 찾을 수 없습니다: $iconManipulateScript"
    return
  }

  . $iconManipulateScript
  ConvertTo-ICO @args
}

function New-IconLibrary {
  $iconManipulateScript = Join-Path $PWSHLibraryPath "IconManipulate.ps1"
  if (-not (Test-Path -Path $iconManipulateScript -PathType Leaf)) {
    Write-Error "IconManipulate.ps1 파일을 찾을 수 없습니다: $iconManipulateScript"
    return
  }

  . $iconManipulateScript
  New-IconLibrary @args
}

function New-IconLibrary {
  $iconManipulateScript = Join-Path $PWSHLibraryPath "IconManipulate.ps1"
  if (-not (Test-Path -Path $iconManipulateScript -PathType Leaf)) {
    Write-Error "IconManipulate.ps1 파일을 찾을 수 없습니다: $iconManipulateScript"
    return
  }

  . $iconManipulateScript
  New-IconLibrary @args
}

function Repair-SteamShortcuts {
  [CmdletBinding()]
  param(
    [string]$SourceFolder = [Environment]::GetFolderPath('Desktop'),
    [string]$TargetFolder,
    [string]$SteamPath = 'C:\Program Files (x86)\Steam'
  )

  $steamManipulateScript = Join-Path $PWSHLibraryPath "SteamManipulate.ps1"
  if (-not (Test-Path -Path $steamManipulateScript -PathType Leaf)) {
    Write-Error "SteamManipulate.ps1 파일을 찾을 수 없습니다: $steamManipulateScript"
    return
  }

  . $steamManipulateScript
  Repair-SteamShortcuts -SourceFolder $SourceFolder -TargetFolder $TargetFolder -SteamPath $SteamPath
}
