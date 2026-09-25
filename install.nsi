; PWSHProfile NSIS installer
; Build with: makensis install.nsi

!ifndef APPNAME
  !define APPNAME "PWSHProfile"
!endif
!ifndef APPVERSION
  !define APPVERSION "1.0.2"
!endif
!define COMPANYNAME "PurewellBIZ"
!define INSTALLDIR "$DOCUMENTS\PowerShell\Modules\${APPNAME}\${APPVERSION}"

!ifndef OUTPUT_FILE
  !define OUTPUT_FILE "${APPNAME}-${APPVERSION}-setup.exe"
!endif

Name "${APPNAME}"
OutFile "${OUTPUT_FILE}"
InstallDir "${INSTALLDIR}"
RequestExecutionLevel user
SetCompress auto
BrandingText "${COMPANYNAME}"
Unicode True

VIProductVersion "${APPVERSION}.0"
VIAddVersionKey "ProductName" "${APPNAME}"
VIAddVersionKey "ProductVersion" "${APPVERSION}"
VIAddVersionKey "CompanyName" "${COMPANYNAME}"
VIAddVersionKey "FileDescription" "PowerShell utility module installer"
VIAddVersionKey "FileVersion" "${APPVERSION}"

!include "MUI2.nsh"

!define MUI_ABORTWARNING
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "Korean"
!insertmacro MUI_LANGUAGE "English"

Section "Main" SEC01
  SetOutPath "$INSTDIR"

  ; Copy module files from the source tree.
  File /r "src\*"

  ; Create the uninstaller inside the versioned module directory.
  WriteUninstaller "$INSTDIR\uninstall.exe"

  ; Register uninstall entry in the current user's registry.
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayName" "${APPNAME} PowerShell Module"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayVersion" "${APPVERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "Publisher" "${COMPANYNAME}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "UninstallString" "$INSTDIR\uninstall.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "InstallLocation" "$INSTDIR"
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "NoModify" 1
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "NoRepair" 1
SectionEnd

Section "Uninstall"
  Delete "$INSTDIR\uninstall.exe"
  RMDir /r "$INSTDIR"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"
SectionEnd
