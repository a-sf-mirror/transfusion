; NSIS 2.0 installer script for Transfusion
; The Transfusion Project - http://www.planetblood.com/qblood/
;
; By Mathieu Olivier <elric@planetblood.com>
; Last update: 07/21/2004

; UPDATE ME  :)
!define TFSRCDIR "D:\Jeux\Transfusion"
!define TFVERSION "1.1beta3"

; The name of the installer
Name "Transfusion"

; The file to write
OutFile "transfusion-${TFVERSION}-win32.exe"

; License page
LicenseText "This installer will install Transfusion. Please, read the license below."
LicenseData ${TFSRCDIR}\GPL.txt


; The default installation directory
InstallDir $PROGRAMFILES\Transfusion

; Registry key to check for directory (so if you install again, it will overwrite the old one automatically)
InstallDirRegKey HKLM SOFTWARE\Transfusion "Install_Dir"

; The text to prompt the user to enter a directory
ComponentText "This will install Transfusion on your computer. Select which optional things you want installed."

; The text to prompt the user to enter a directory
DirText "Choose a directory to install in to:"

; Icons
Icon installer.ico
CheckBitmap checks.bmp


; The onInit function
Function .onInit
  InitPluginsDir
  SetOutPath $PLUGINSDIR
  File /oname=spltmp.bmp "splash.bmp"
  File /oname=spltmp.wav "splash.wav"

  splash::show 2000 $PLUGINSDIR\spltmp
  Pop $0 ; $0 has '1' if the user closed the splash screen early,
	 ; '0' if everything closed normal, and '-1' if some error occured.
FunctionEnd


; The various install types
InstType "Full"
InstType "Minimal"


; The essential files
Section "Base files (required)"
  SectionIn RO

  ; Root directory
  SetOutPath $INSTDIR
  File "${TFSRCDIR}\GPL.txt"
  File "${TFSRCDIR}\transfusion.exe"
  File "${TFSRCDIR}\*.dll"

  ; Data directory
  SetOutPath $INSTDIR\basetf
  File "${TFSRCDIR}\basetf\*.pk3"
  File "${TFSRCDIR}\basetf\maps.cfg"

  ; Write a few informations into the registry
  WriteRegStr HKLM SOFTWARE\Transfusion "Install_Dir" "$INSTDIR"
  WriteRegStr HKLM SOFTWARE\Transfusion "Version" "${TFVERSION}"

  ; Write the uninstall keys for Windows
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Transfusion" "DisplayName" "Transfusion ${TFVERSION} (remove only)"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Transfusion" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteUninstaller "uninstall.exe"
SectionEnd


; Optional section
Section "Start Menu Shortcuts"
  SectionIn 1

  CreateDirectory "$SMPROGRAMS\Transfusion"

  SetOutPath $INSTDIR
  CreateShortCut "$SMPROGRAMS\Transfusion\Transfusion.lnk" "$INSTDIR\transfusion.exe"
  CreateShortCut "$SMPROGRAMS\Transfusion\Uninstall.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0
  CreateShortCut "$SMPROGRAMS\Transfusion\License.lnk" "$INSTDIR\GPL.txt" ""
SectionEnd


; Uninstall stuff
UninstallText "This will uninstall Transfusion. Hit next to continue."

; Special uninstall section.
Section "Uninstall"
  ; Remove registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Transfusion"
  DeleteRegKey HKLM SOFTWARE\Transfusion

  ; Remove files and directories (including the uninstaller)
  RMDir /r "$INSTDIR"

  ; Remove shortcuts, if any.
  RMDir "$SMPROGRAMS\Transfusion"
SectionEnd
