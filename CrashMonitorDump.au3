#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=CrashMonitor.ico
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_AU3Check_Stop_OnWarning=y
#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#AutoIt3Wrapper_Run_Tidy=y
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/pe /so /sf /sv /rm
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
AutoItSetOption("MustDeclareVars", 1)
AutoItSetOption("TrayAutoPause", 0)
AutoItSetOption("TrayIconHide", 1)
; *** Start added by AutoIt3Wrapper ***
#include <FileConstants.au3>
#include <ProcessConstants.au3>
#include <SecurityConstants.au3>
#include <WinAPI.au3>
; *** End added by AutoIt3Wrapper ***



Const $sDirScript = @ScriptDir
Const $sFileDump = $sDirScript & "\CrashMonitorDump.dmp"

If ($CmdLine[0] > 0) Then
	Global $iPIDGame = ProcessExists($CmdLine[1])
	If $iPIDGame == 0 Then Exit (1)
Else
	Exit (2)
EndIf

If ($CmdLine[0] > 1) Then
	Global $tDumpType = DllStructCreate("dword")
	DllStructSetData($tDumpType, 1, Ptr($CmdLine[2]))
Else
	Exit (3)
EndIf



Global $hSetPrivilege = _Security__OpenProcessToken(_WinAPI_GetCurrentProcess(), $TOKEN_ALL_ACCESS)
If (@error == 0 And $hSetPrivilege <> 0) Then
	If (_Security__SetPrivilege($hSetPrivilege, $SE_DEBUG_NAME, True)) Then
		Global $hOpenProcess = _WinAPI_OpenProcess($PROCESS_ALL_ACCESS, 0, $iPIDGame, True)
		If (@error == 0 And $hOpenProcess <> 0) Then
			Global $hCreateFile = _WinAPI_CreateFile($sFileDump, $FC_OVERWRITE)
			If (@error == 0 And $hCreateFile <> 0) Then
				If (_Security__SetPrivilege($hSetPrivilege, $SE_DEBUG_NAME, True)) Then
					Global $aMiniDump = DllCall("dbghelp.dll", "bool", "MiniDumpWriteDump", "handle", $hOpenProcess, "dword", $iPIDGame, "handle", $hCreateFile, "dword", DllStructGetData($tDumpType, 1), "dword", 0, "dword", 0, "dword", 0)
					If (@error == 0 And IsArray($aMiniDump)) Then
						If ($aMiniDump[0] == 1) Then
							_WinAPI_CloseHandle($hCreateFile)
							_WinAPI_CloseHandle($hOpenProcess)
							_WinAPI_CloseHandle($hSetPrivilege)
						Else
							Exit (4)
						EndIf
					Else
						Exit (5)
					EndIf
				Else
					Exit (6)
				EndIf
			Else
				Exit (7)
			EndIf
		Else
			Exit (8)
		EndIf
	Else
		Exit (9)
	EndIf
Else
	Exit (10)
EndIf



Exit


