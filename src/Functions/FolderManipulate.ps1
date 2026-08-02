#!/usr/bin/env pwsh
# 폴더 관련 유틸리티를 모아둔 스크립트입니다.
# 필요하면 직접 불러와도 됩니다: . "$PWSHLibraryPath\FolderManipulate.ps1"


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
