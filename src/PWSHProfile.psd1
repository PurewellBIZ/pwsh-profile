#
# 모듈 'PWSHProfile'의 모듈 매니페스트
#
# 생성자: NeoGenius
#
# 생성 날짜: 2026-09-25
#

@{

# 이 매니페스트와 연결된 스크립트 모듈 또는 이진 모듈 파일입니다.
RootModule = 'PWSHProfile.psm1'

# 이 모듈의 버전 번호입니다.
ModuleVersion = '1.0.1'

# 지원되는 PSEditions
# CompatiblePSEditions = @()

# 이 모듈을 고유하게 식별하는 데 사용하는 ID
GUID = 'ae864dcf-543e-440b-98cb-cd3bbe3ce285'

# 이 모듈의 작성자
Author = 'NeoGenius'

# 이 모듈의 회사 또는 공급업체
CompanyName = 'PurewellBIZ'

# 이 모듈의 저작권 문구
Copyright = '(c) 2026 PurewellBIZ'

# 이 모듈에서 제공하는 기능에 대한 설명
Description = 'PowerShell 프로필 함수 모듈입니다. Functions 디렉터리의 보조 스크립트를 지연 로드합니다.'

# 이 모듈에 필요한 PowerShell 엔진의 최소 버전
PowerShellVersion = '7.0'

# 이 모듈에 필요한 PowerShell 호스트의 이름
# PowerShellHostName = ''

# 이 모듈에 필요한 PowerShell 호스트의 최소 버전
# PowerShellHostVersion = ''

# 이 모듈에 필요한 Microsoft .NET Framework의 최소 버전입니다. 이 필수 구성 요소는 PowerShell 데스크톱 버전에만 유효합니다.
# DotNetFrameworkVersion = ''

# 이 모듈에 필요한 CLR(공용 언어 런타임)의 최소 버전입니다. 이 필수 구성 요소는 PowerShell 데스크톱 버전에만 유효합니다.
# ClrVersion = ''

# 이 모듈에 필요한 프로세서 아키텍처(None, X86, Amd64)
# ProcessorArchitecture = ''

# 이 모듈을 가져오기 전에 전역 환경으로 가져와야 하는 모듈
# RequiredModules = @()

# 이 모듈을 가져오기 전에 로드해야 하는 어셈블리
# RequiredAssemblies = @()

# 이 모듈을 가져오기 전에 호출자의 환경에서 실행되는 스크립트 파일(.ps1)입니다.
# ScriptsToProcess = @()

# 이 모듈을 가져올 때 로드할 형식 파일(.ps1xml)
# TypesToProcess = @()

# 이 모듈을 가져올 때 로드할 서식 파일(.ps1xml)
# FormatsToProcess = @()

# RootModule/ModuleToProcess에 지정된 모듈의 중첩 모듈로 가져올 모듈
# NestedModules = @()

# 이 모듈에서 내보낼 함수입니다. 최상의 성능을 위해 와일드카드를 사용하지 말고, 항목을 삭제하지 마세요. 내보낼 함수가 없으면 빈 배열을 사용하세요.
FunctionsToExport = 'Sync-Profile', 'Clear-Trash', 'Clear-AllHistory', 'New-Symlink', 
               'Get-WakeArmedDevices', 'Get-LastWakeEvent', 'Enable-WakeOnDevice', 
               'Disable-WakeOnDevice', 'Reset-DesktopIni', 'ConvertTo-ICO', 
               'New-IconLibrary', 'Repair-SteamShortcuts'

# 이 모듈에서 내보낼 cmdlet입니다. 최상의 성능을 위해 와일드카드를 사용하지 말고, 항목을 삭제하지 마세요. 내보낼 cmdlet이 없으면 빈 배열을 사용하세요.
CmdletsToExport = @()

# 이 모듈에서 내보낼 변수
# VariablesToExport = @()

# 이 모듈에서 내보낼 별칭입니다. 최상의 성능을 위해 와일드카드를 사용하지 말고, 항목을 삭제하지 마세요. 내보낼 별칭이 없으면 빈 배열을 사용하세요.
AliasesToExport = '*'

# 이 모듈에서 내보낼 DSC 리소스
# DscResourcesToExport = @()

# 이 모듈과 함께 패키지된 모든 모듈 목록
# ModuleList = @()

# 이 모듈과 함께 패키지된 모든 파일 목록
FileList = 'PWSHProfile.psm1', 'PWSHProfile.psd1'

# RootModule/ModuleToProcess에 지정된 모듈에 전달할 프라이빗 데이터입니다. 여기에는 PowerShell에서 사용하는 추가 모듈 메타데이터가 있는 PSData 해시 테이블도 포함될 수 있습니다.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'PowerShell','Profile','Functions'

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/PurewellBIZ/pwsh-profile/blob/main/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/PurewellBIZ/pwsh-profile'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = ''

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

 } # End of PrivateData hashtable

# 이 모듈의 HelpInfo URI
# HelpInfoURI = ''

# 이 모듈에서 내보낸 명령의 기본 접두사입니다. Import-Module -Prefix를 사용하여 기본 접두사를 재정의하세요.
# DefaultCommandPrefix = ''

}

