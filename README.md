# PWSH-Profile

윈도우 + PowerShell 용 유틸리티 스크립트.

## 주요 구성

- `STARSHIP_CONFIG` 환경 변수를 설정하고 Starship 프롬프트를 초기화합니다.
- 스케줄러에서 직접 호출할 수 있는 관리 함수들을 정의합니다.

## 설치

```pwsh
pwsh -ExecutionPolicy ByPass -c "irm https://raw.githubusercontent.com/PurewellBIZ/pwsh-profile/main/install.ps1 | iex"
```

## 제공되는 함수

### `Clear-Trash`

휴지통을 강제로 비우고 `Clear-AllHistory`를 호출하여 PowerShell 기록도 함께 삭제합니다.

### `Clear-AllHistory`

PowerShell 히스토리, `PSReadLine` 히스토리 파일, 그리고 Windows 탐색기 `TypedPaths` 레지스트리 항목을 제거합니다.

### `New-Symlink`

심볼릭 링크를 생성합니다.

```powershell
New-Symlink -source <원본경로> -target <링크경로>
```

### `Get-WakeArmedDevices`

현재 대기 모드 해제가 활성화된 장치 목록을 조회합니다.

### `Get-LastWakeEvent`

마지막으로 대기 모드 해제를 발생시킨 장치 또는 이벤트를 조회합니다.

### `Set-EnableWakeOnDevice`

지정된 장치에서 대기 모드 해제를 활성화합니다.

### `Set-DisableWakeOnDevice`

지정된 장치 또는 `all` 인수로 모든 장치의 대기 모드 해제를 비활성화합니다.

### `Reset-DesktopIni`

지정된 폴더의 `desktop.ini` 파일을 안전하게 백업하고 정제한 뒤, Windows 탐색기에서 올바르게 동작하는 형식으로 재작성합니다.

## 예약 작업으로 사용하기

PowerShell 스케줄러에서 이 프로필을 불러와 함수를 실행하려면 다음과 같이 설정할 수 있습니다.

- 명령어: `pwsh.exe`
- 인수: `-ExecutionPolicy Bypass -Command ". $PROFILE; <함수이름>"`

예:

```powershell
pwsh.exe -ExecutionPolicy Bypass -Command ". $PROFILE; Clear-Trash"
```
