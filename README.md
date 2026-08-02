# PWSH-Profile

Windows와 PowerShell용 유틸리티 스크립트다.

## 주요 구성

- 스케줄러에서 직접 호출할 관리 함수를 정의한다.

## 설치

```pwsh
pwsh -ExecutionPolicy ByPass -c "irm https://raw.githubusercontent.com/PurewellBIZ/pwsh-profile/main/install.ps1 | iex"
```

설치 후에는 Documents\PowerShell\Modules\PWSHProfile\<버전> 위치에 모듈을 배치한다. 새 세션에서 Import-Module PWSHProfile를 실행하거나 PowerShell 자동 로딩으로 함수를 바로 사용한다.

소스 코드 구조는 다음과 같다.

- install.ps1 : 설치 스크립트
- src/PWSHProfile.psm1 : 모듈 본문
- src/PWSHProfile.psd1 : 모듈 매니페스트
- src/Functions/ : 보조 구현 스크립트

## 제공되는 함수

### Clear-Trash

휴지통을 강제로 비우고 Clear-AllHistory를 호출해 PowerShell 기록도 함께 삭제한다.

### Clear-AllHistory

PowerShell 히스토리, PSReadLine 히스토리 파일, Windows 탐색기 TypedPaths 레지스트리 항목을 제거한다.

### New-Symlink

심볼릭 링크를 생성한다.

```powershell
New-Symlink -source <원본경로> -target <링크경로>
```

### Get-WakeArmedDevices

현재 대기 모드 해제 기능이 활성화된 장치 목록을 조회한다.

### Get-LastWakeEvent

마지막으로 대기 모드 해제를 발생시킨 장치나 이벤트를 조회한다.

### Set-EnableWakeOnDevice

지정한 장치에서 대기 모드 해제를 활성화한다.

### Set-DisableWakeOnDevice

지정한 장치나 all 인수로 모든 장치의 대기 모드 해제를 비활성화한다.

### Reset-DesktopIni

지정한 폴더의 desktop.ini 파일을 안전하게 백업하고 정제한 뒤, Windows 탐색기에서 올바르게 동작하는 형식으로 재작성한다.

### ConvertTo-ICO

이미지 파일을 .ico로 변환한다. ImageMagick의 magick 또는 convert 명령이 설치되어 있어야 하며, ConvertTo-Ico 별칭으로도 호출할 수 있다.

```powershell
ConvertTo-ICO -InputPath .\icon.png -OutputPath .\icon.ico
```

### New-IconLibrary

폴더 안의 .ico 파일을 이름순(ABC순)으로 정렬해 하나의 리소스 전용 DLL로 묶는다. 정렬된 목록의 첫 번째 아이콘이 DLL의 기본 아이콘(인덱스 0)이 되며, dotnet SDK만 있으면 동작한다(오프라인 환경에서도 사용 가능).

자주 쓰는 기능이 아니라 [src/Functions/IconManipulate.ps1](src/Functions/IconManipulate.ps1)로 분리했다. 프로필 로드 시 함께 불러와서 ConvertTo-ICO와 New-IconLibrary를 바로 사용한다.

```powershell
New-IconLibrary -IconFolder .\icons -OutputDllPath .\icon.dll -Force
```

- -Force : 출력 경로에 dll이 이미 있어도 덮어쓴다(없으면 기본적으로 오류가 발생한다).
- -ForceRebuildTool : 내부적으로 사용하는 리소스 빌더 도구(%LOCALAPPDATA%\IconLibraryTool에 캐시됨)를 강제로 다시 빌드한다.

## 예약 작업으로 사용하기

PowerShell 스케줄러에서 이 프로필을 불러와 함수를 실행하려면 다음처럼 설정한다.

- 명령어: pwsh.exe
- 인수: -ExecutionPolicy Bypass -Command ". $PROFILE; <함수이름>"

예:

```powershell
pwsh.exe -ExecutionPolicy Bypass -Command ". $PROFILE; Clear-Trash"
```
