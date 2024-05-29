; Documentation: https://nsis.sourceforge.io/Docs/Chapter4.html

;--------------------------------
;Include Modern UI

  !include "MUI2.nsh"

;--------------------------------
;General

  ;Name and file
  Name "Update Me Example"
  OutFile "..\build\${VERSION}"
  Unicode True

  ; Icon
  !define MUI_ICON "icon.ico"

  ;Default installation folder
  InstallDir "$APPDATA\cc.feedme\update_me_example"
  
  ;Get installation folder from registry if available
  InstallDirRegKey HKCU "Software\cc.feedme" ""

  ;Request application privileges for Windows Vista
  RequestExecutionLevel admin

;--------------------------------
;Interface Settings

  !define MUI_ABORTWARNING

;--------------------------------
;Pages

  !insertmacro MUI_PAGE_INSTFILES
  !insertmacro MUI_UNPAGE_INSTFILES
  !define MUI_FINISHPAGE_RUN "$INSTDIR\update_me_example.exe"
  !insertmacro MUI_PAGE_FINISH
  
;--------------------------------
;Languages
 
  !insertmacro MUI_LANGUAGE "English"

;--------------------------------
;Installer Sections

Section "Install" SecInstall
  SetOutPath "$INSTDIR"
  
  ; /x exclude a file/folder
  ; /r recursive include all files
  File /r "..\build\windows\runner\Release\*"
  File "icon.ico"
  File /r "dependencies\*"

  ExecWait '"$INSTDIR\VC_redist.x64.exe" /SILENT /norestart'
  
  ; Store installation folder
  WriteRegStr HKCU "Software\cc.feedme" "" $INSTDIR

  ; Register uninstaller to Control Panel's Add/Remove programs
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\UpdateMeExample" "DisplayName" "Update Me Example"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\UpdateMeExample" "DisplayIcon" '"$INSTDIR\icon.ico"'
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\UpdateMeExample" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\UpdateMeExample" "QuietUninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\UpdateMeExample" "InstallLocation " '"$INSTDIR"'
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\UpdateMeExample" "Publisher" "FeedMe POS Sdn Bhd"

  ; Create desktop shortcut
  CreateShortcut "$DESKTOP\Update Me Example.lnk" "$INSTDIR\update_me_example.exe"

  ; Create uninstaller
  WriteUninstaller "$INSTDIR\uninstall.exe"

SectionEnd

;--------------------------------
;Uninstaller Section

Section "Uninstall"
  RMDir /r "$INSTDIR" 

  Delete "$DESKTOP\Update Me Example.lnk"

  DeleteRegKey /ifempty HKCU "Software\cc.feedme"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\UpdateMeExample"

SectionEnd  