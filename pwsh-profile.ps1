#!/usr/bin/env pwsh

# 예쁜 프롬프트 출력을 위한 스타쉽: https://starship.rs/
$ENV:STARSHIP_CONFIG = "$HOME\.config\starship.toml"
Invoke-Expression (&starship init powershell)

# 스케쥴러에 등록하기
# 명령어: pwsh.exe
# 인수: -ExecutionPolicy Bypass -Command ". $PROFILE; <함수이름>"

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
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$FolderPath = (Get-Item .).FullName
    )

    process {
        $iniPath = Join-Path $FolderPath "desktop.ini"

        Write-Host "--------------------------------------------------" -ForegroundColor Cyan
        Write-Host "대상 폴더: $FolderPath" -ForegroundColor Yellow

        if (-not (Test-Path $iniPath -PathType Leaf)) {
            Write-Host "해당 폴더에 desktop.ini 파일이 존재하지 않습니다. (정상)" -ForegroundColor Green
            return
        }

        Write-Host "기존 복구 대상 파일 발견. 안전하게 백업 및 정제 작업을 시작합니다..." -ForegroundColor Gray

        # 1. 속성 일시 해제 (읽기전용, 시스템, 숨김 해제해야 파일 읽기/쓰기가 안정적임)
        $originalAttributes = (Get-Item $iniPath -Force).Attributes
        Set-ItemProperty -Path $iniPath -Name Attributes -Value "Normal" -ErrorAction SilentlyContinue

        # 2. 파일 내용 읽기 (인코딩을 명시하지 않고 원시 텍스트로 가져옴)
        $rawLines = Get-Content -Path $iniPath -Raw -ErrorAction SilentlyContinue

        if ([string]::IsNullOrWhiteSpace($rawLines)) {
            Write-Host "⚠ 파일이 비어있거나 손상이 심합니다. 기본값으로 전환합니다." -ForegroundColor Yellow
            $cleanedContent = "[.ShellClassInfo]`r`nLocalizedResourceName=@%SystemRoot%\system32\windows.storage.dll,-21798`r`nIconResource=%SystemRoot%\system32\imageres.dll,-184"
        }
        else {
            # 3. 핵심: 맨 앞의 쓰레기 바이트 및 비정상 제어문자 정제
            # 대괄호([)로 시작하는 섹션 헤더 앞의 모든 깨진 문자를 날려버립니다.
            if ($rawLines -match '(?s)(\[\.ShellClassInfo\].*)') {
                $cleanedContent = $Matches[1].Trim()
                Write-Host "✔ 오염된 헤더를 제거하고 기존 폴더 설정 내용을 살려냈습니다." -ForegroundColor Green
            }
            else {
                # 만약 [.ShellClassInfo] 구조가 없다면 일반 텍스트 정제 진행
                $cleanedContent = $rawLines -replace '[^\x20-\x7E\xAC00-\xD7A3\s\[\]\=\,\-\.\_\@\%\\]', ''
                $cleanedContent = $cleanedContent.Trim()
                Write-Host "✔ 알 수 없는 포맷의 파일입니다. 텍스트 정제만 진행했습니다." -ForegroundColor Yellow
            }
        }

        # 4. 백업 파일 생성 (안전을 위해 기존 파일은 .bak로 보관)
        Copy-Item -Path $iniPath -Destination "$iniPath.bak" -Force -ErrorAction SilentlyContinue
        Write-Host "기존 원본은 'desktop.ini.bak'로 안전하게 백업되었습니다." -ForegroundColor Gray

        # 5. 윈도우 표준 UTF-16 LE(BOM 포함)로 파일 다시 쓰기
        # 파일 내용을 확실히 밀어버리기 위해 강제 생성합니다.
        Out-File -FilePath $iniPath -InputObject $cleanedContent -Encoding Unicode -Force

        # 6. 원상복구 및 필수 속성(Hidden + System) 강제 재부여
        # 기존에 있던 속성을 존중하되, 탐색기 작동에 필수인 Hidden과 System은 반드시 결합합니다.
        $file = Get-Item $iniPath -Force
        $file.Attributes = [System.IO.FileAttributes]::Hidden -bor [System.IO.FileAttributes]::System

        Write-Host "✔ desktop.ini 정제 완료! 속성이 재설정되었습니다." -ForegroundColor Green
        Write-Host "--------------------------------------------------" -ForegroundColor Cyan
    }
}
