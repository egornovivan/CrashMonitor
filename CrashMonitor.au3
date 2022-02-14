#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=CrashMonitor.ico
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseUpx=y
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
#include <APILocaleConstants.au3>
#include <AutoItConstants.au3>
#include <FileConstants.au3>
#include <GUIConstantsEx.au3>
#include <MsgBoxConstants.au3>
#include <StaticConstants.au3>
#include <StructureConstants.au3>
#include <WindowsConstants.au3>
#include <Crypt.au3>
#include <File.au3>
#include <ScreenCapture.au3>
#include <WinAPI.au3>
#include <WinAPILocale.au3>
; *** End added by AutoIt3Wrapper ***



Const $sYandexToken = ""
Const $sGitHubToken = ""
Const $sGitHubOwner = "egornovivan"
Const $sGitHubRepo = "CrashMonitor"
Const $sVerCrashMonitor = "v2.11"
Const $sMd5CrashMonitorDumpExe = "02a0efba35521896c1107a00e3014ae0"
Const $sUrlCrashMonitorDumpExe = "https://github.com/" & $sGitHubOwner & "/" & $sGitHubRepo & "/releases/download/" & $sVerCrashMonitor & "/CrashMonitorDump.exe"
Const $sMd5CrashMonitorReportExe = "95bd0bc005eb86ed5208e8498f2cf5c6"
Const $sUrlCrashMonitorReportExe = "https://github.com/" & $sGitHubOwner & "/" & $sGitHubRepo & "/releases/download/" & $sVerCrashMonitor & "/CrashMonitorReport.exe"

Const $sDirTemp = @TempDir & "\CrashMonitor"
Const $sDirScript = @ScriptDir
Const $sFile7zaExe = $sDirTemp & "\7za.exe"
Const $sFile7zaDll = $sDirTemp & "\7za.dll"
Const $sFile7zxaDll = $sDirTemp & "\7zxa.dll"
Const $sFileCrashMonitorLog = $sDirScript & "\CrashMonitor.log"
Const $sFileTempFlv = $sDirScript & "\temp.flv"
Const $sFileFfmpegExe = $sDirScript & "\ffmpeg.exe"
Const $sFileCrashMonitorDumpDmp = $sDirScript & "\CrashMonitorDump.dmp"
Const $sFileCrashMonitorDumpExe = $sDirScript & "\CrashMonitorDump.exe"
Const $sFileCrashMonitorReportExe = $sDirScript & "\CrashMonitorReport.exe"

Global $hWndGame = 0
Global $bWndGameFullscreen = False
Global $bMiniDump = False
Global $iDumpType = 0
Global $bWndGameCapture = False, $iPIDFfmpegExe = 0, $aEnumChildProcess = 0, $sTitleGame = ""
Global $bWndGameScreenshot = False, $aiWndGameRect = 0, $hCDC = 0, $hDDC = 0, $hBMP = 0
Global $iPIDGame = -1, $hFileOpen = -1, $hDLL = -1
Global $iDriveSpaceFree = 0, $hWndCrash = 0
Global $sTextCrash = "", $sTextReport = ""
Global $sTimestamp = "", $sDirCrashReport = "", $sDirCrashReportSaves = "", $sFileCrash = "", $sFileReport = "", $sFileDump = "", $sFileMd5 = "", $sFileJpg = ""
Global $hForm1 = 0, $idEdit1 = 0, $idButton1 = 0, $idLabel1 = 0, $nMsg = 0
Global $asEnumUILanguages = 0, $asFileListToArray = 0, $aProcessList = 0, $aEnumProcessWindows = 0, $aIniReadSection = 0, $asFileGetTime = 0

Global $sText0 = "You have less than 1GB of free disk space, please free up a few gigabytes."
Global $sText1 = "The application crashed with an error:"
Global $sText2 = "Want to generate a report to send to developers?"
Global $sText3 = "Please tell us what happened in the game a few seconds before the crash"
Global $sText4 = "For some reason, the report could not be sent. Please transfer this archive to the developers of "
Global $sText5 = "mod"
Global $sText6 = "The report is ready to be sent. Would you like to send it to the developers? (Will be sent ≈"

$asEnumUILanguages = _WinAPI_EnumUILanguages($MUI_LANGUAGE_NAME)
If (IsArray($asEnumUILanguages)) Then
	While Not ($asEnumUILanguages[0] == 0)
		If (StringRegExp($asEnumUILanguages[$asEnumUILanguages[0]], "^ru")) Then
			$sText0 = "У вас осталось менее 1GB свободного места на диске, пожалуйста освободите несколько гигабайт."
			$sText1 = "Приложение аварийно завершилось с ошибкой:"
			$sText2 = "Хотите сформировать отчет для отправки разработчикам?"
			$sText3 = "Пожалуйста расскажите что происходило в игре за несколько секунд до краша"
			$sText4 = "По какой то причине не удалось отправить отчет. Пожалуйста передайте этот архив разработчикам "
			$sText5 = "мода"
			$sText6 = "Отчет готов к отправке. Хотите его отправить разработчикам? (Будет отправлено ≈"
			ExitLoop
		EndIf
		$asEnumUILanguages[0] -= 1
	WEnd
EndIf
$asEnumUILanguages = 0

$asFileListToArray = _FileListToArray($sDirScript, "*_crash.txt", $FLTA_FILES, True)
If (IsArray($asFileListToArray)) Then
	While Not ($asFileListToArray[0] == 0)
		If (StringRegExp($asFileListToArray[$asFileListToArray[0]], "^.*[0-9]{8}\_[0-9]{6}\_crash\.txt$")) Then
			If Not (FileExists(StringRegExpReplace($asFileListToArray[$asFileListToArray[0]], "\_crash\.txt$", ".7z"))) Then
				If Not (FileExists(StringRegExpReplace($asFileListToArray[$asFileListToArray[0]], "\_crash\.txt$", ""))) Then
					FileDelete($asFileListToArray[$asFileListToArray[0]])
				EndIf
			EndIf
		EndIf
		$asFileListToArray[0] -= 1
	WEnd
EndIf
$asFileListToArray = 0

If ($CmdLine[0] > 0) Then
	If ($CmdLine[1] == 0) Then
		$hWndGame = WinWait("[CLASS:GNW95 Class]", "", 5)
	Else
		$hWndGame = HWnd(Ptr($CmdLine[1]))
	EndIf
Else
	$hWndGame = WinWait("[CLASS:GNW95 Class]", "", 5)
EndIf
If ($hWndGame == 0) Then
	Exit
EndIf

If ($CmdLine[0] > 1) Then
	If ($CmdLine[2] == 0) Then
		$bWndGameFullscreen = False
	Else
		$bWndGameFullscreen = True
	EndIf
Else
	$bWndGameFullscreen = False
EndIf

If ($CmdLine[0] > 2) Then
	If ($CmdLine[3] == 0) Then
		$bMiniDump = False
	Else
		$bMiniDump = True
	EndIf
Else
	$bMiniDump = False
EndIf

If ($CmdLine[0] > 3) Then
	$iDumpType = Ptr($CmdLine[4])
Else
	$iDumpType = Ptr("0x00000000")
EndIf

$iPIDGame = WinGetProcess($hWndGame)
If ($iPIDGame == -1) Then
	Exit
EndIf

$aProcessList = ProcessList()
If (IsArray($aProcessList)) Then
	While Not ($aProcessList[0][0] == 0)
		If ($aProcessList[$aProcessList[0][0]][1] == $iPIDGame) Then
			ExitLoop
		EndIf
		$aProcessList[0][0] -= 1
	WEnd
	Const $sFileGame = StringRegExpReplace($sDirScript, "^(.*)(?:[\/\\]{1}[^\/\\]*)$", "\1") & "\" & $aProcessList[$aProcessList[0][0]][0]
Else
	Exit
EndIf
$aProcessList = 0

If (FileExists($sFileGame)) Then
	Const $sDirGame = StringRegExpReplace($sFileGame, "^(.*)(?:[\/\\]{1}[^\/\\]*)$", "\1")
Else
	Exit
EndIf

If (FileExists($sDirGame)) Then
	Const $sDirSaves = $sDirGame & "\data\savegame"
Else
	Exit
EndIf

$iDriveSpaceFree = Round(DriveSpaceFree($sDirScript))
If ($iDriveSpaceFree < 1024 And $iDriveSpaceFree > 0) Then
	Sleep(2000)
	WinSetOnTop($hWndGame, "", $WINDOWS_NOONTOP)
	If ($bWndGameFullscreen) Then
		WinSetState($hWndGame, "", @SW_MINIMIZE)
	EndIf
	MsgBox($MB_TOPMOST + $MB_ICONWARNING, "DriveSpaceFree", $sText0)
EndIf
$iDriveSpaceFree = 0

If (FileExists($sFileFfmpegExe)) Then
	$bWndGameCapture = True
	$sTitleGame = WinGetTitle($hWndGame)
	If ($sTitleGame == "") Then
		$bWndGameCapture = False
	Else
		$hFileOpen = FileOpen($sFileTempFlv, $FO_BINARY + $FO_CREATEPATH + $FO_OVERWRITE)
		FileClose($hFileOpen)
		$hFileOpen = -1
		FileSetAttrib($sFileTempFlv, "+T")
		$iPIDFfmpegExe = Run('cmd /c ""' & $sFileFfmpegExe & '" -y -f gdigrab -framerate 30 -t 300 -i title="' & $sTitleGame & '" -f flv - > temp.flv"', $sDirScript, @SW_HIDE)
	EndIf
	$sTitleGame = ""
Else
	$bWndGameCapture = False
EndIf

If Not ($bWndGameFullscreen) Then
	$bWndGameScreenshot = True
	$aiWndGameRect = _WndGameRect($hWndGame)
	If (IsArray($aiWndGameRect)) Then
		_ScreenCapture_SetJPGQuality(90)
		$hDDC = _WinAPI_GetDC($hWndGame)
		$hCDC = _WinAPI_CreateCompatibleDC($hDDC)
		$hBMP = _WinAPI_CreateCompatibleBitmap($hDDC, $aiWndGameRect[0], $aiWndGameRect[1])
		_WinAPI_SelectObject($hCDC, $hBMP)
		$hDLL = DllOpen("gdi32.dll")
		If ($hDLL == -1) Then
			$bWndGameScreenshot = False
		EndIf
	Else
		$bWndGameScreenshot = False
	EndIf
Else
	$bWndGameScreenshot = False
EndIf



While 1
	If WinActive($hWndGame) Then
		If $bWndGameScreenshot Then
			If WinActive($hWndGame) Then DllCall($hDLL, "bool", "BitBlt", "handle", $hCDC, "int", 0, "int", 0, "int", $aiWndGameRect[0], "int", $aiWndGameRect[1], "handle", $hDDC, "int", $aiWndGameRect[2], "int", $aiWndGameRect[3], "dword", $SRCCOPY)
			If @error Then $bWndGameScreenshot = False
		EndIf
		If $bWndGameCapture Then
			If Not ProcessExists($iPIDFfmpegExe) Then
				$bWndGameCapture = True
				$sTitleGame = WinGetTitle($hWndGame)
				If $sTitleGame == "" Then
					$bWndGameCapture = False
				Else
					$hFileOpen = FileOpen($sFileTempFlv, $FO_BINARY + $FO_CREATEPATH + $FO_OVERWRITE)
					FileClose($hFileOpen)
					$hFileOpen = -1
					FileSetAttrib($sFileTempFlv, "+T")
					$iPIDFfmpegExe = Run('cmd /c ""' & $sFileFfmpegExe & '" -y -f gdigrab -framerate 30 -t 300 -i title="' & $sTitleGame & '" -f flv - > temp.flv"', $sDirScript, @SW_HIDE)
				EndIf
				$sTitleGame = ""
			EndIf
		EndIf
	Else
		If (WinExists($hWndGame)) Then
			$hWndCrash = 0
			$sTextCrash = ""
		Else
			If (WinExists($hWndGame)) Then
				$hWndCrash = 0
				$sTextCrash = ""
			Else
				If (ProcessExists($iPIDGame)) Then
					$hWndGame = 0
					$hWndCrash = 0
					$sTextCrash = "The window is gone, but the process still exists."
				Else
					$hWndGame = 0
					$hWndCrash = 0
					$sTextCrash = ""
					$iPIDGame = -1
					ExitLoop
				EndIf
			EndIf
		EndIf
		$aEnumProcessWindows = _WinAPI_EnumProcessWindows($iPIDGame, True)
		If (IsArray($aEnumProcessWindows)) Then
			While Not ($aEnumProcessWindows[0][0] == 0)
				If ($aEnumProcessWindows[$aEnumProcessWindows[0][0]][1] == "#32770") Then
					If Not (WinGetTitle($aEnumProcessWindows[$aEnumProcessWindows[0][0]][0]) == "") Then
						If (WinGetProcess($aEnumProcessWindows[$aEnumProcessWindows[0][0]][0]) == $iPIDGame) Then
							$hWndCrash = $aEnumProcessWindows[$aEnumProcessWindows[0][0]][0]
							$sTextCrash = WinGetText($hWndCrash)
							ExitLoop
						EndIf
					EndIf
				EndIf
				$aEnumProcessWindows[0][0] -= 1
			WEnd
		EndIf
		$aEnumProcessWindows = 0
		If ($hWndGame == 0) Then
			If ($hWndCrash == 0) Then
				If (ProcessWaitClose($iPIDGame, 5)) Then
					$sTextCrash = ""
					$iPIDGame = -1
					ExitLoop
				EndIf
			EndIf
		EndIf
		If Not ($sTextCrash == "") Then
			If Not ($hWndCrash == 0) Then
				WinSetOnTop($hWndCrash, "", $WINDOWS_NOONTOP)
				WinSetState($hWndCrash, "", @SW_MINIMIZE)
			EndIf
			If Not ($hWndGame == 0) Then
				WinSetOnTop($hWndGame, "", $WINDOWS_NOONTOP)
				If ($bWndGameFullscreen) Then
					WinSetState($hWndGame, "", @SW_MINIMIZE)
				EndIf
			EndIf
			$sTimestamp = @YEAR & @MON & @MDAY & "_" & @HOUR & @MIN & @SEC
			$sDirCrashReport = $sDirScript & "\" & $sTimestamp
			$sDirCrashReportSaves = $sDirCrashReport & "\SAVEGAME"
			$sFileCrash = $sDirCrashReport & "\" & $sTimestamp & "_crash.txt"
			$sFileReport = $sDirCrashReport & "\" & $sTimestamp & "_report.txt"
			$sFileDump = $sDirCrashReport & "\" & $sTimestamp & ".dmp"
			$sFileMd5 = $sDirCrashReport & "\" & $sTimestamp & ".md5"
			$sFileJpg = $sDirCrashReport & "\" & $sTimestamp & ".jpg"
			DirCreate($sDirCrashReport)
			$hFileOpen = FileOpen($sFileCrash, $FO_ANSI + $FO_CREATEPATH + $FO_APPEND)
			If Not ($hFileOpen == -1) Then
				FileWrite($hFileOpen, $sTextCrash)
				FileClose($hFileOpen)
			EndIf
			$hFileOpen = -1
			If ($bWndGameCapture) Then
				$aEnumChildProcess = _WinAPI_EnumChildProcess($iPIDFfmpegExe)
				If (IsArray($aEnumChildProcess)) Then
					While Not ($aEnumChildProcess[0][0] == 0)
						If ($aEnumChildProcess[$aEnumChildProcess[0][0]][1] == "ffmpeg.exe") Then
							If (ProcessClose($aEnumChildProcess[$aEnumChildProcess[0][0]][0])) Then
								$iPIDFfmpegExe = 0
							EndIf
							ExitLoop
						EndIf
						$aEnumChildProcess[0][0] -= 1
					WEnd
				EndIf
				$aEnumChildProcess = 0
			EndIf
			If Not (MsgBox($MB_TOPMOST + $MB_DEFBUTTON2 + $MB_ICONQUESTION + $MB_YESNO, "Crash", $sText1 & @CRLF & "-------------------------------------------------------------------------------" & @CRLF & StringRegExpReplace($sTextCrash, "^((?s)[OoОо]{1}[KkКк]{1}\R+)", "", 1) & @CRLF & "-------------------------------------------------------------------------------" & @CRLF & @CRLF & $sText2) == $IDYES) Then
				If Not ($hWndCrash == 0) Then
					If (WinExists($hWndCrash)) Then
						If (WinClose($hWndCrash)) Then
							If Not (WinWaitClose($hWndCrash, "", 5)) Then
								WinKill($hWndCrash)
							EndIf
						EndIf
					EndIf
				EndIf
				FileMove($sFileCrash, $sDirCrashReport & "_crash.txt", $FC_CREATEPATH + $FC_OVERWRITE)
				DirRemove($sDirCrashReport, $DIR_REMOVE)
				ContinueLoop
			EndIf
			ProgressOn("Please, wait", "Please, wait")
			If Not ($hWndCrash == 0) Then
				WinSetOnTop($hWndCrash, "", $WINDOWS_NOONTOP)
				WinSetState($hWndCrash, "", @SW_MINIMIZE)
			EndIf
			If Not ($hWndGame == 0) Then
				WinSetOnTop($hWndGame, "", $WINDOWS_NOONTOP)
				WinSetState($hWndGame, "", @SW_MINIMIZE)
			EndIf
			If ($bMiniDump And FileExists($sDirCrashReport) And ProcessExists($iPIDGame)) Then
				If Not (FileExists($sFileCrashMonitorDumpExe)) Then
					InetGet($sUrlCrashMonitorDumpExe, $sFileCrashMonitorDumpExe)
				EndIf
				If Not (StringLower(Hex(_Crypt_HashFile($sFileCrashMonitorDumpExe, $CALG_MD5))) == $sMd5CrashMonitorDumpExe) Then
					InetGet($sUrlCrashMonitorDumpExe, $sFileCrashMonitorDumpExe)
				EndIf
				ProgressSet(50)
				If (FileExists($sFileCrashMonitorDumpExe)) Then
					If (StringLower(Hex(_Crypt_HashFile($sFileCrashMonitorDumpExe, $CALG_MD5))) == $sMd5CrashMonitorDumpExe) Then
						If (ProcessExists($iPIDGame)) Then
							If (RunWait('"' & $sFileCrashMonitorDumpExe & '" "' & $iPIDGame & '" "' & $iDumpType & '"', $sDirScript, @SW_HIDE)) Then
								FileDelete($sFileCrashMonitorDumpDmp)
							Else
								FileMove($sFileCrashMonitorDumpDmp, $sFileDump, $FC_CREATEPATH + $FC_OVERWRITE)
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
			ProgressSet(50)
			If ($bWndGameScreenshot) Then
				DllClose($hDLL)
				_WinAPI_ReleaseDC($hWndGame, $hDDC)
				_WinAPI_DeleteDC($hCDC)
				_ScreenCapture_SaveImage($sFileJpg, $hBMP, True)
			EndIf
			If Not ($hWndCrash == 0) Then
				If (WinExists($hWndCrash)) Then
					If (WinClose($hWndCrash)) Then
						If Not (WinWaitClose($hWndCrash, "", 5)) Then
							WinKill($hWndCrash)
						EndIf
					EndIf
				EndIf
			EndIf
			If ($bWndGameCapture) Then
				$iPIDFfmpegExe = Run('cmd /c ""' & $sFileFfmpegExe & '" -sseof -10 -i temp.flv ' & $sTimestamp & '.flv"', $sDirScript, @SW_HIDE)
				If (ProcessWaitClose($iPIDFfmpegExe, 10)) Then
					FileMove($sDirCrashReport & ".flv", $sDirCrashReport & "\" & $sTimestamp & ".flv", $FC_CREATEPATH + $FC_OVERWRITE)
				EndIf
				$iPIDFfmpegExe = 0
			EndIf
			ProgressOff()
			#Region ### START Koda GUI section ###
			$hForm1 = GUICreate("Report", 641, 481, -1, -1, -1, BitOR($WS_EX_TOPMOST, $WS_EX_WINDOWEDGE))
			$idEdit1 = GUICtrlCreateEdit("", 0, 60, 640, 360)
			$idButton1 = GUICtrlCreateButton("Done", 283, 436, 75, 25)
			$idLabel1 = GUICtrlCreateLabel($sText3, 0, 0, 640, 60, BitOR($SS_CENTER, $SS_CENTERIMAGE))
			GUISetState(@SW_SHOW)
			GUICtrlSetState($idEdit1, $GUI_FOCUS)
			#EndRegion ### END Koda GUI section ###
			While 1
				$nMsg = GUIGetMsg()
				Switch $nMsg
					Case $GUI_EVENT_CLOSE, $idButton1
						$sTextReport = GUICtrlRead($idEdit1)
						GUIDelete($hForm1)
						ExitLoop
				EndSwitch
			WEnd
			ProgressOn("Please, wait", "Please, wait")
			If (ProcessExists($iPIDGame)) Then
				If (ProcessClose($iPIDGame)) Then
					$iPIDGame = -1
				EndIf
			EndIf
			$hFileOpen = FileOpen($sFileReport, $FO_ANSI + $FO_CREATEPATH + $FO_APPEND)
			If Not ($hFileOpen == -1) Then
				FileWrite($hFileOpen, "`" & @UserName & "@" & @ComputerName & @CRLF & $sTextReport & "`")
				FileClose($hFileOpen)
			EndIf
			$hFileOpen = -1
			$asFileListToArray = _FileListToArray($sDirCrashReport, "*.txt", $FLTA_FILES, False)
			If (IsArray($asFileListToArray)) Then
				While Not ($asFileListToArray[0] == 0)
					FileCopy($sDirCrashReport & "\" & $asFileListToArray[$asFileListToArray[0]], $sDirScript & "\" & $asFileListToArray[$asFileListToArray[0]], $FC_CREATEPATH + $FC_OVERWRITE)
					$asFileListToArray[0] -= 1
				WEnd
			EndIf
			$asFileListToArray = 0
			If (FileExists($sDirSaves)) Then
				DirCreate($sDirCrashReportSaves)
				If (FileExists($sDirSaves & "\slotdat.ini")) Then
					If (FileCopy($sDirSaves & "\slotdat.ini", $sDirCrashReportSaves & "\slotdat.ini", $FC_CREATEPATH + $FC_OVERWRITE)) Then
						FileSetTime($sDirCrashReportSaves & "\slotdat.ini", FileGetTime($sDirSaves & "\slotdat.ini", $FT_MODIFIED, $FT_STRING))
						$aIniReadSection = IniReadSection($sDirCrashReportSaves & "\slotdat.ini", "POSITION")
						If (IsArray($aIniReadSection)) Then
							$aIniReadSection = $aIniReadSection[1][1] + $aIniReadSection[2][1]
							If ($aIniReadSection > 9) Then
								$aIniReadSection = "SLOT" & $aIniReadSection
							Else
								$aIniReadSection = "SLOT0" & $aIniReadSection
							EndIf
							If (FileExists($sDirSaves & "\" & $aIniReadSection)) Then
								If (DirCopy($sDirSaves & "\" & $aIniReadSection, $sDirCrashReportSaves & "\" & $aIniReadSection, $FC_OVERWRITE)) Then
									FileSetTime($sDirCrashReportSaves & "\" & $aIniReadSection, FileGetTime($sDirSaves & "\" & $aIniReadSection, $FT_MODIFIED, $FT_STRING))
								EndIf
							EndIf
						EndIf
						$aIniReadSection = 0
					EndIf
				EndIf
				$asFileListToArray = _FileListToArray($sDirSaves, "slot*", $FLTA_FOLDERS, False)
				If (IsArray($asFileListToArray)) Then
					$asFileGetTime = $asFileListToArray
					While Not ($asFileGetTime[0] == 0)
						$asFileGetTime[$asFileGetTime[0]] = FileGetTime($sDirSaves & "\" & $asFileGetTime[$asFileGetTime[0]], $FT_MODIFIED, $FT_STRING)
						$asFileGetTime[0] -= 1
					WEnd
					For $i = 1 To 10
						$asFileGetTime[0] = _ArrayMaxIndex($asFileGetTime, 1)
						If Not ($asFileGetTime[0] == 0 Or $asFileGetTime[0] == -1) Then
							If (DirCopy($sDirSaves & "\" & $asFileListToArray[$asFileGetTime[0]], $sDirCrashReportSaves & "\" & $asFileListToArray[$asFileGetTime[0]], $FC_OVERWRITE)) Then
								FileSetTime($sDirCrashReportSaves & "\" & $asFileListToArray[$asFileGetTime[0]], $asFileGetTime[$asFileGetTime[0]])
							EndIf
							$asFileGetTime[$asFileGetTime[0]] = -1
							$asFileGetTime[0] = 0
						EndIf
					Next
					$asFileGetTime = 0
				EndIf
				$asFileListToArray = 0
			EndIf
			$hFileOpen = FileOpen($sDirGame & "\debug.log", $FO_CREATEPATH + $FO_APPEND)
			If Not ($hFileOpen == -1) Then
				FileWrite($hFileOpen, @CRLF & $sTimestamp & @CRLF & $sTextCrash & @CRLF)
				FileClose($hFileOpen)
			EndIf
			$hFileOpen = -1
			ProgressSet(50)
			$asFileListToArray = _FileListToArrayRec($sDirGame & "\", "*.cfg;*.inf;*.ini;*.log;*.txt;*.dll", $FLTAR_FILES, $FLTAR_NORECUR, $FLTAR_SORT, $FLTAR_RELPATH)
			If (IsArray($asFileListToArray)) Then
				While Not ($asFileListToArray[0] == 0)
					If (FileCopy($sDirGame & "\" & $asFileListToArray[$asFileListToArray[0]], $sDirCrashReport & "\" & $asFileListToArray[$asFileListToArray[0]], $FC_CREATEPATH + $FC_OVERWRITE)) Then
						FileSetTime($sDirCrashReport & "\" & $asFileListToArray[$asFileListToArray[0]], FileGetTime($sDirGame & "\" & $asFileListToArray[$asFileListToArray[0]], $FT_MODIFIED, $FT_STRING))
					EndIf
					$asFileListToArray[0] -= 1
				WEnd
			EndIf
			$asFileListToArray = 0
			If (FileExists($sDirCrashReport & "\ddraw.ini")) Then
				$aIniReadSection = StringRegExpReplace(StringRegExpReplace(IniRead($sDirCrashReport & "\ddraw.ini", "Scripts", "IniConfigFolder", "mods"), "^(\\|\.\\|\.\.\\|\/|\.\/|\.\.\/)", ""), "^([^\/\\]*)(?:.*)$", "\1")
				If ($aIniReadSection == "") Then
					$aIniReadSection = "mods"
				EndIf
				If (FileExists($sDirGame & "\" & $aIniReadSection)) Then
					$asFileListToArray = _FileListToArrayRec($sDirGame & "\" & $aIniReadSection & "\", "*.cfg;*.inf;*.ini;*.log;*.txt;*.dll", $FLTAR_FILES, $FLTAR_RECUR, $FLTAR_SORT, $FLTAR_RELPATH)
					If (IsArray($asFileListToArray)) Then
						While Not ($asFileListToArray[0] == 0)
							If (FileCopy($sDirGame & "\" & $aIniReadSection & "\" & $asFileListToArray[$asFileListToArray[0]], $sDirCrashReport & "\" & $aIniReadSection & "\" & $asFileListToArray[$asFileListToArray[0]], $FC_CREATEPATH + $FC_OVERWRITE)) Then
								FileSetTime($sDirCrashReport & "\" & $aIniReadSection & "\" & $asFileListToArray[$asFileListToArray[0]], FileGetTime($sDirGame & "\" & $aIniReadSection & "\" & $asFileListToArray[$asFileListToArray[0]], $FT_MODIFIED, $FT_STRING))
							EndIf
							$asFileListToArray[0] -= 1
						WEnd
					EndIf
					$asFileListToArray = 0
				EndIf
				$aIniReadSection = 0
			EndIf
			$hFileOpen = FileOpen($sFileMd5, $FO_ANSI + $FO_CREATEPATH + $FO_APPEND)
			If Not ($hFileOpen == -1) Then
				$asFileListToArray = _FileListToArrayRec($sDirGame & "\", "*||crashreport;savegame;text", $FLTAR_FILES, $FLTAR_RECUR, $FLTAR_SORT, $FLTAR_RELPATH)
				If (IsArray($asFileListToArray)) Then
					If ($asFileListToArray[0] >= 5000) Then
						FileWriteLine($hFileOpen, "Attention Plyushkin!")
					Else
						While Not ($asFileListToArray[0] == 0)
							FileWriteLine($hFileOpen, StringLower(Hex(_Crypt_HashFile($sDirGame & "\" & $asFileListToArray[$asFileListToArray[0]], $CALG_MD5))) & " *" & $asFileListToArray[$asFileListToArray[0]])
							$asFileListToArray[0] -= 1
						WEnd
					EndIf
				EndIf
				$asFileListToArray = 0
				FileClose($hFileOpen)
			EndIf
			$hFileOpen = -1
			ProgressOff()
			If (ProcessExists($iPIDGame)) Then
				If (ProcessClose($iPIDGame)) Then
					$iPIDGame = -1
					ExitLoop
				Else
					Exit
				EndIf
			Else
				$iPIDGame = -1
				ExitLoop
			EndIf
		EndIf
		Sleep(1000)
	EndIf
	Sleep(500)
WEnd



If ($bWndGameCapture) Then
	$aEnumChildProcess = _WinAPI_EnumChildProcess($iPIDFfmpegExe)
	If (IsArray($aEnumChildProcess)) Then
		While Not ($aEnumChildProcess[0][0] == 0)
			If ($aEnumChildProcess[$aEnumChildProcess[0][0]][1] == "ffmpeg.exe") Then
				If (ProcessClose($aEnumChildProcess[$aEnumChildProcess[0][0]][0])) Then
					$iPIDFfmpegExe = 0
				EndIf
				ExitLoop
			EndIf
			$aEnumChildProcess[0][0] -= 1
		WEnd
	EndIf
	$aEnumChildProcess = 0
EndIf

$asFileListToArray = _FileListToArray($sDirScript, "*", $FLTA_FOLDERS, False)
If (IsArray($asFileListToArray)) Then
	While Not ($asFileListToArray[0] == 0)
		If (StringRegExp($asFileListToArray[$asFileListToArray[0]], "^[0-9]{8}\_[0-9]{6}$")) Then
			ExitLoop
		EndIf
		$asFileListToArray[0] -= 1
	WEnd
	If Not ($asFileListToArray[0] == 0) Then
		ProgressOn("Please, wait", "Please, wait")
		DirRemove($sDirTemp, $DIR_REMOVE)
		DirCreate($sDirTemp)
		FileInstall(".\7za.exe", $sFile7zaExe, $FC_OVERWRITE)
		FileInstall(".\7za.dll", $sFile7zaDll, $FC_OVERWRITE)
		FileInstall(".\7zxa.dll", $sFile7zxaDll, $FC_OVERWRITE)
		If (FileExists($sFile7zaExe) And FileExists($sFile7zaDll) And FileExists($sFile7zxaDll)) Then
			ProgressSet(50)
			While Not ($asFileListToArray[0] == 0)
				If (StringRegExp($asFileListToArray[$asFileListToArray[0]], "^[0-9]{8}\_[0-9]{6}$")) Then
					$sDirCrashReport = $sDirScript & "\" & $asFileListToArray[$asFileListToArray[0]]
					If Not (FileExists($sDirCrashReport & "_crash.txt")) Then
						If (FileExists($sDirCrashReport & "\" & $asFileListToArray[$asFileListToArray[0]] & "_crash.txt")) Then
							FileCopy($sDirCrashReport & "\" & $asFileListToArray[$asFileListToArray[0]] & "_crash.txt", $sDirCrashReport & "_crash.txt", $FC_CREATEPATH + $FC_OVERWRITE)
						Else
							If (FileExists($sDirCrashReport & "\" & $asFileListToArray[$asFileListToArray[0]] & ".dmp")) Then
								$hFileOpen = FileOpen($sDirCrashReport & "\" & $asFileListToArray[$asFileListToArray[0]] & "_crash.txt", $FO_ANSI + $FO_CREATEPATH + $FO_APPEND)
								If Not ($hFileOpen == -1) Then
									FileWrite($hFileOpen, @CRLF & "UnknownCrash" & @CRLF)
									FileClose($hFileOpen)
								EndIf
								$hFileOpen = -1
								FileCopy($sDirCrashReport & "\" & $asFileListToArray[$asFileListToArray[0]] & "_crash.txt", $sDirCrashReport & "_crash.txt", $FC_CREATEPATH + $FC_OVERWRITE)
							Else
								DirRemove($sDirCrashReport, $DIR_REMOVE)
								$asFileListToArray[0] -= 1
								ContinueLoop
							EndIf
						EndIf
					EndIf
					If Not (FileExists($sDirCrashReport & "_report.txt")) Then
						If (FileExists($sDirCrashReport & "\" & $asFileListToArray[$asFileListToArray[0]] & "_report.txt")) Then
							FileCopy($sDirCrashReport & "\" & $asFileListToArray[$asFileListToArray[0]] & "_report.txt", $sDirCrashReport & "_report.txt", $FC_CREATEPATH + $FC_OVERWRITE)
						Else
							$hFileOpen = FileOpen($sDirCrashReport & "\" & $asFileListToArray[$asFileListToArray[0]] & "_report.txt", $FO_ANSI + $FO_CREATEPATH + $FO_APPEND)
							If Not ($hFileOpen == -1) Then
								FileWrite($hFileOpen, "`" & @UserName & "@" & @ComputerName & @CRLF & "`")
								FileClose($hFileOpen)
							EndIf
							$hFileOpen = -1
							FileCopy($sDirCrashReport & "\" & $asFileListToArray[$asFileListToArray[0]] & "_report.txt", $sDirCrashReport & "_report.txt", $FC_CREATEPATH + $FC_OVERWRITE)
						EndIf
					EndIf
					If (FileExists($sFileCrashMonitorLog)) Then
						FileCopy($sFileCrashMonitorLog, $sDirCrashReport & "\CrashMonitor.log", $FC_CREATEPATH + $FC_OVERWRITE)
					EndIf
					If (FileExists($sDirCrashReport & ".7z")) Then
						FileDelete($sDirCrashReport & ".7z")
					EndIf
					If Not (RunWait('"' & $sFile7zaExe & '" a "' & $sDirCrashReport & '.7z" "' & $sDirCrashReport & '"', $sDirScript, @SW_HIDE)) Then
						If (FileExists($sDirCrashReport & ".7z")) Then
							DirRemove($sDirCrashReport, $DIR_REMOVE)
						EndIf
					EndIf
				EndIf
				$asFileListToArray[0] -= 1
			WEnd
		EndIf
		DirRemove($sDirTemp, $DIR_REMOVE)
		ProgressOff()
	EndIf
EndIf
$asFileListToArray = 0

$asFileListToArray = _FileListToArray($sDirScript, "*.7z", $FLTA_FILES, True)
If (IsArray($asFileListToArray)) Then
	While Not ($asFileListToArray[0] == 0)
		If (StringRegExp($asFileListToArray[$asFileListToArray[0]], "^.*[0-9]{8}\_[0-9]{6}\.7z$")) Then
			If Not (StringRegExp(@OSVersion, "^WIN_2000$")) Then
				If (MsgBox($MB_TOPMOST + $MB_DEFBUTTON2 + $MB_ICONQUESTION + $MB_YESNO, "CrashReport is ready", $sText6 & Ceiling(FileGetSize($asFileListToArray[$asFileListToArray[0]]) / 1048576) & "MB)" & @CRLF & @CRLF & $asFileListToArray[$asFileListToArray[0]]) == $IDYES) Then
					ProgressOn("Please, wait", "Please, wait")
					If Not (FileExists($sFileCrashMonitorReportExe)) Then
						InetGet($sUrlCrashMonitorReportExe, $sFileCrashMonitorReportExe)
					EndIf
					If Not (StringLower(Hex(_Crypt_HashFile($sFileCrashMonitorReportExe, $CALG_MD5))) == $sMd5CrashMonitorReportExe) Then
						InetGet($sUrlCrashMonitorReportExe, $sFileCrashMonitorReportExe)
					EndIf
					ProgressSet(50)
					If (FileExists($sFileCrashMonitorReportExe)) Then
						If (StringLower(Hex(_Crypt_HashFile($sFileCrashMonitorReportExe, $CALG_MD5))) == $sMd5CrashMonitorReportExe) Then
							If Not (RunWait('"' & $sFileCrashMonitorReportExe & '" --ytoken="' & $sYandexToken & '" --gtoken="' & $sGitHubToken & '" --file="' & $asFileListToArray[$asFileListToArray[0]] & '" --md5="' & StringLower(Hex(_Crypt_HashFile($asFileListToArray[$asFileListToArray[0]], $CALG_MD5))) & '" --owner="' & $sGitHubOwner & '" --repo="' & $sGitHubRepo & '" --ver="' & $sVerCrashMonitor & '"', $sDirScript, @SW_HIDE)) Then
								FileDelete($asFileListToArray[$asFileListToArray[0]])
								FileDelete(StringRegExpReplace($asFileListToArray[$asFileListToArray[0]], "\.7z$", "_crash.txt"))
								FileDelete(StringRegExpReplace($asFileListToArray[$asFileListToArray[0]], "\.7z$", "_report.txt"))
								$asFileListToArray[0] -= 1
								ProgressOff()
								ContinueLoop
							EndIf
						EndIf
					EndIf
					ProgressOff()
				Else
					ExitLoop
				EndIf
			EndIf
			If (FileExists(StringRegExpReplace($asFileListToArray[$asFileListToArray[0]], "\.7z$", "_crash.txt"))) Then
				If (StringRegExp(FileRead(StringRegExpReplace($asFileListToArray[$asFileListToArray[0]], "\.7z$", "_crash.txt")), "(UnknownCrash|[0-9A-Fa-f]{8})")) Then
					$sText5 = "sfall"
				EndIf
			EndIf
			If (MsgBox($MB_TOPMOST + $MB_ICONWARNING, "CrashReport is ready", $sText4 & $sText5 & @CRLF & @CRLF & $asFileListToArray[$asFileListToArray[0]]) == $IDOK) Then
				ShellExecute($sDirScript)
				ExitLoop
			EndIf
		EndIf
		$asFileListToArray[0] -= 1
	WEnd
EndIf
$asFileListToArray = 0



Exit



Func _WndGameRect($hWnd, $iLeft = 0, $iTop = 0, $iRight = 0, $iBottom = 0)
	If Not IsHWnd($hWnd) Then $hWnd = WinGetHandle($hWnd)
	Local $tRECT = DllStructCreate($tagRECT)
	; needed to get rect when Aero theme is active : Thanks Kafu, Zedna
	Local Const $DWMWA_EXTENDED_FRAME_BOUNDS = 9
	Local $bRet = DllCall("dwmapi.dll", "long", "DwmGetWindowAttribute", "hwnd", $hWnd, "dword", $DWMWA_EXTENDED_FRAME_BOUNDS, "struct*", $tRECT, "dword", DllStructGetSize($tRECT))
	If (@error Or $bRet[0] Or (Abs(DllStructGetData($tRECT, "Left")) + Abs(DllStructGetData($tRECT, "Top")) + _
			Abs(DllStructGetData($tRECT, "Right")) + Abs(DllStructGetData($tRECT, "Bottom"))) = 0) Then
		$tRECT = _WinAPI_GetWindowRect($hWnd)
		If @error Then Return SetError(@error + 10, @extended, False)
	EndIf

	$iLeft = DllStructGetData($tRECT, "Left")
	$iTop = DllStructGetData($tRECT, "Top")
	$iRight = DllStructGetData($tRECT, "Right")
	$iBottom = DllStructGetData($tRECT, "Bottom")

	Local $iW = ($iRight - $iLeft) + 1
	Local $iH = ($iBottom - $iTop) + 1
	Local $aiRect = [$iW, $iH, 0, 0]
	Return $aiRect
EndFunc   ;==>_WndGameRect

Func _error_log($a, $b, $c, $d)
	Local $hfile = FileOpen($a, 9)
	FileWrite($hfile, "__________" & @CRLF & $b & @CRLF & $c & @CRLF & $d & @CRLF & "__________")
	FileClose($hfile)
EndFunc   ;==>_error_log


