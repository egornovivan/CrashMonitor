#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=crashmonitor.ico
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Res_SaveSource=y
#AutoIt3Wrapper_Add_Constants=n
#AutoIt3Wrapper_AU3Check_Stop_OnWarning=y
#AutoIt3Wrapper_Run_Tidy=y
#AutoIt3Wrapper_Run_Au3Stripper=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
; *** Start added by AutoIt3Wrapper ***
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <File.au3>
#include <GUIConstantsEx.au3>
#include <Memory.au3>
#include <Process.au3>
#include <ProcessConstants.au3>
#include <StaticConstants.au3>
#include <WinAPI.au3>
#include <WindowsConstants.au3>
#include <WinAPILocale.au3>
; *** End added by AutoIt3Wrapper ***
Opt("TrayAutoPause", 0)
Opt("TrayIconHide", 1)



Local $extensions[] = ["*.log", "*.txt", "*.ini", "*.inf", "*.cfg", "*.dll"]
$tempdir = @TempDir & "\crashmonitor"
$scriptdir = @ScriptDir
$crashmonitorlog = $scriptdir & "\crashmonitor.log"
$tempfile = $scriptdir & "\temp.flv"
$ffmpegfile = $scriptdir & "\ffmpeg.exe"

$lang = 0
$lang = _WinAPI_EnumUILanguages($MUI_LANGUAGE_NAME)
If (IsArray($lang)) Then
	While Not ($lang[0] == 0)
		If (StringRegExp($lang[$lang[0]], "^(ru)", 0, 1)) Then
			ExitLoop
		Else
			$lang[0] -= 1
		EndIf
	WEnd
	If ($lang[0] == 0) Then
		$lang = "en"
	Else
		$lang = "ru"
	EndIf
Else
	$lang = "en"
EndIf

If ($lang == "ru") Then
	$text0 = "У вас осталось менее 1GB свободного места на диске, пожалуйста освободите несколько гигабайт."
	$text1 = "Приложение аварийно завершилось с ошибкой:"
	$text2 = "Хотите сформировать отчет для отправки разработчикам?"
	$text3 = "Пожалуйста расскажите что происходило в игре за несколько секунд до краша"
	$text4 = "Пожалуйста, передайте этот архив разработчикам мода или разработчикам sfall"
Else
	$text0 = "You have less than 1GB of free disk space, please free up a few gigabytes."
	$text1 = "The application crashed with an error:"
	$text2 = "Want to generate a report to send to developers?"
	$text3 = "Please tell us what happened in the game a few seconds before the crash"
	$text4 = "Please transfer this archive to the developers of this mod or the developers of sfall"
EndIf



$drivespacefree = Round(DriveSpaceFree($scriptdir))
If (($drivespacefree < 1024) And ($drivespacefree > 0)) Then
	Sleep(2000)
	MsgBox(262192, "Free Disk Space", $text0)
EndIf

$files = 0
$files = _FileListToArray($scriptdir, "*_crash.txt", 1, 1)
If (IsArray($files)) Then
	While Not ($files[0] == 0)
		If (StringRegExp($files[$files[0]], "^.*[0-9]{14}\_crash\.txt$", 0, 1)) Then
			If Not (FileExists(StringRegExpReplace($files[$files[0]], "\_crash\.txt$", ".7z"))) Then
				If Not (FileExists(StringRegExpReplace($files[$files[0]], "\_crash\.txt$", ""))) Then
					FileDelete($files[$files[0]])
				EndIf
			EndIf
			$files[0] -= 1
		Else
			$files[0] -= 1
		EndIf
	WEnd
EndIf



If ($CmdLine[0] > 0) Then
	If ($CmdLine[1] == 0) Then
		Opt("WinTitleMatchMode", -1)
		$hwnd = WinWait("[TITLE:Fallout II; CLASS:GNW95 Class]", "", 15)
		Opt("WinTitleMatchMode", 1)
	Else
		$hwnd = HWnd(Ptr($CmdLine[1]))
	EndIf
Else
	Opt("WinTitleMatchMode", -1)
	$hwnd = WinWait("[TITLE:Fallout II; CLASS:GNW95 Class]", "", 15)
	Opt("WinTitleMatchMode", 1)
EndIf
If ($hwnd == 0) Then
	Exit
EndIf

If ($CmdLine[0] > 1) Then
	If ($CmdLine[2] == 0) Then
		$dumpprocess = False
	Else
		$dumpprocess = True
	EndIf
Else
	$dumpprocess = False
EndIf

If ($CmdLine[0] > 2) Then
	$dumptype = _DWORD(Ptr($CmdLine[3]))
Else
	$dumptype = _DWORD(Ptr("0x00000000"))
EndIf

If (FileExists($ffmpegfile)) Then
	$videorecord = True
	$title = WinGetTitle($hwnd)
	If ($title == "") Then
		$videorecord = False
	Else
		$hfile = FileOpen($tempfile, 26)
		FileClose($hfile)
		_WinAPI_SetFileAttributes($tempfile, $FILE_ATTRIBUTE_TEMPORARY)
		$ffpid = Run('cmd /c ""' & $ffmpegfile & '" -y -f gdigrab -framerate 30 -t 300 -i title="' & $title & '" -f flv - > temp.flv"', $scriptdir, @SW_HIDE)
	EndIf
Else
	$videorecord = False
EndIf

$pid = WinGetProcess($hwnd)
If ($pid == -1) Then
	Exit
EndIf
$exe = 0
$processlist = 0
$processlist = ProcessList()
If (IsArray($processlist)) Then
	While Not ($processlist[0][0] == 0)
		If ($processlist[$processlist[0][0]][1] == $pid) Then
			$exe = $processlist[$processlist[0][0]][0]
			ExitLoop
		EndIf
		$processlist[0][0] -= 1
	WEnd
Else
	Exit
EndIf
If ($exe == 0) Then
	Exit
EndIf

$gamedir1 = _WinAPI_GetProcessFileName($pid)
$gamedir2 = StringRegExpReplace($scriptdir, "^(.*)(?:[\/\\]{1}[^\/\\]*)$", "\1") & "\" & $exe
If ($gamedir1 == $gamedir2) Then
	If (FileExists($gamedir1) And FileExists($gamedir2)) Then
		$gamedir = StringRegExpReplace($scriptdir, "^(.*)(?:[\/\\]{1}[^\/\\]*)$", "\1")
	Else
		Exit
	EndIf
ElseIf (FileExists($gamedir2)) Then
	$gamedir = StringRegExpReplace($gamedir2, "^(.*)(?:[\/\\]{1}[^\/\\]*)$", "\1")
ElseIf (FileExists($gamedir1)) Then
	$gamedir = StringRegExpReplace($gamedir1, "^(.*)(?:[\/\\]{1}[^\/\\]*)$", "\1")
Else
	Exit
EndIf
$savesdir = $gamedir & "\data\savegame"

While 1
	If (WinExists($hwnd)) Then
		$hwnde = 0
		$crash = ""
	Else
		If (WinExists($hwnd)) Then
			$hwnde = 0
			$crash = ""
		Else
			If (ProcessExists($pid)) Then
				$hwnd = 0
				$hwnde = 0
				$crash = "The window is gone, but the process still exists."
			Else
				ExitLoop
			EndIf
		EndIf
	EndIf
	If ($videorecord) Then
		If Not (ProcessExists($ffpid)) Then
			_WinAPI_SetFileAttributes($tempfile, $FILE_ATTRIBUTE_TEMPORARY)
			$ffpid = Run('cmd /c ""' & $ffmpegfile & '" -y -f gdigrab -framerate 30 -t 300 -i title="' & $title & '" -f flv - > temp.flv"', $scriptdir, @SW_HIDE)
		EndIf
	EndIf
	$hwndarray = 0
	$hwndarray = _WinAPI_EnumProcessWindows($pid, True)
	If (IsArray($hwndarray)) Then
		While Not ($hwndarray[0][0] == 0)
			If ($hwndarray[$hwndarray[0][0]][0] == $hwnd) Then
				;If (_WinAPI_IsHungAppWindow($hwndarray[$hwndarray[0][0]][0])) Then
				;	$hwnde = $hwndarray[$hwndarray[0][0]][0]
				;	$crash = "The window is frozen/hung."
				;EndIf
				$hwndarray[0][0] -= 1
			Else
				If ($hwndarray[$hwndarray[0][0]][1] == "#32770") Then
					If Not (WinGetTitle($hwndarray[$hwndarray[0][0]][0]) == "") Then
						If (WinGetProcess($hwndarray[$hwndarray[0][0]][0]) == $pid) Then
							$hwnde = $hwndarray[$hwndarray[0][0]][0]
							$crash = WinGetText($hwnde)
							ExitLoop
						EndIf
					EndIf
				EndIf
				$hwndarray[0][0] -= 1
			EndIf
		WEnd
	EndIf
	If ($hwnd == 0) Then
		If ($hwnde == 0) Then
			If (ProcessWaitClose($pid, 5)) Then
				ExitLoop
			EndIf
		EndIf
	EndIf
	If Not ($crash == "") Then
		If Not ($hwnde == 0) Then
			If ($hwnde == $hwnd) Then
				WinSetOnTop($hwnde, "", 0)
			Else
				WinSetOnTop($hwnd, "", 0)
				WinSetOnTop($hwnde, "", 0)
			EndIf
		EndIf
		$crashreport = @YEAR & @MON & @MDAY & @HOUR & @MIN & @SEC
		$crashreportdir = $scriptdir & "\" & $crashreport
		$dumpfile = $crashreportdir & "\" & $crashreport & ".dmp"
		If Not (DirCreate($crashreportdir)) Then
			_error_log($crashmonitorlog, $crashreport, $crash, 'DirCreate($crashreportdir)')
		EndIf
		$hfile = FileOpen($crashreportdir & "\" & $crashreport & "_crash.txt", 521)
		If Not ($hfile == -1) Then
			FileWrite($hfile, $crash)
			FileClose($hfile)
		EndIf
		If ($videorecord) Then
			$childarray = 0
			$childarray = _WinAPI_EnumChildProcess($ffpid)
			If (IsArray($childarray)) Then
				While Not ($childarray[0][0] == 0)
					If ($childarray[$childarray[0][0]][1] == "ffmpeg.exe") Then
						ProcessClose($childarray[$childarray[0][0]][0])
						ExitLoop
					EndIf
					$childarray[0][0] -= 1
				WEnd
			EndIf
		EndIf
		If Not (MsgBox(262436, "Crashreport", $text1 & @CRLF & "-------------------------------------------------------------------------------" & @CRLF & StringRegExpReplace($crash, "^((?s)[OoОо]{1}[KkКк]{1}\R+)", "", 1) & @CRLF & "-------------------------------------------------------------------------------" & @CRLF & @CRLF & $text2) == 6) Then
			If Not ($hwnde == 0) Then
				WinClose($hwnde)
				If Not (WinWaitClose($hwnde, "", 5)) Then
					_error_log($crashmonitorlog, $crashreport, $crash, 'WinWaitClose($hwnde, "", 5)')
					WinKill($hwnde)
				EndIf
			EndIf
			FileMove($crashreportdir & "\" & $crashreport & "_crash.txt", $crashreportdir & "_crash.txt", 9)
			DirRemove($crashreportdir, 1)
			ContinueLoop
		EndIf
		ProgressOn("Please, wait", "Please, wait")
		If Not ($hwnde == 0) Then
			If ($hwnde == $hwnd) Then
				WinSetState($hwnde, "", @SW_MINIMIZE)
			Else
				WinSetState($hwnd, "", @SW_MINIMIZE)
				WinSetState($hwnde, "", @SW_MINIMIZE)
			EndIf
		EndIf
		If ($dumpprocess And FileExists($crashreportdir) And ProcessExists($pid)) Then
			$hprocess = 0
			$hprocess = _WinAPI_OpenProcess($PROCESS_ALL_ACCESS, 0, $pid, True)
			If Not ($hprocess == 0) Then
				$hfile = 0
				$hfile = _WinAPI_CreateFile($dumpfile, 1)
				If Not ($hfile == 0) Then
					$minidumpcall = DllCall("dbghelp.dll", "bool", "MiniDumpWriteDump", "handle", $hprocess, "dword", $pid, "handle", $hfile, "dword", $dumptype, "dword", 0, "dword", 0, "dword", 0)
					If (IsArray($minidumpcall)) Then
						If ($minidumpcall[0] == 1) Then
							_WinAPI_CloseHandle($hfile)
							_WinAPI_CloseHandle($hprocess)
						Else
							_error_log($crashmonitorlog, $crashreport, $crash, '$minidumpcall = DllCall')
						EndIf
					Else
						_error_log($crashmonitorlog, $crashreport, $crash, 'IsArray($minidumpcall)')
					EndIf
				Else
					_error_log($crashmonitorlog, $crashreport, $crash, '_WinAPI_CreateFile')
				EndIf
			Else
				_error_log($crashmonitorlog, $crashreport, $crash, '_WinAPI_OpenProcess')
			EndIf
		EndIf
		ProgressSet(50)
		If Not ($hwnde == 0) Then
			WinClose($hwnde)
			If Not (WinWaitClose($hwnde, "", 5)) Then
				_error_log($crashmonitorlog, $crashreport, $crash, 'WinWaitClose($hwnde, "", 5)')
				WinKill($hwnde)
			EndIf
		EndIf
		If ($videorecord) Then
			$ffpid = Run('cmd /c ""' & $ffmpegfile & '" -sseof -10 -i temp.flv ' & $crashreport & '.flv"', $scriptdir, @SW_HIDE)
			If (ProcessWaitClose($ffpid, 10)) Then
				FileMove($crashreportdir & ".flv", $crashreportdir & "\" & $crashreport & ".flv", 9)
			EndIf
		EndIf
		ProgressOff()
		#Region ### START Koda GUI section ###
		$Form1 = GUICreate("Report", 641, 481, -1, -1, -1, BitOR($WS_EX_TOPMOST, $WS_EX_WINDOWEDGE))
		$Edit1 = GUICtrlCreateEdit("", 0, 60, 640, 360)
		$Button1 = GUICtrlCreateButton("Done", 283, 436, 75, 25)
		$Label1 = GUICtrlCreateLabel($text3, 0, 0, 640, 60, BitOR($SS_CENTER, $SS_CENTERIMAGE))
		GUISetState(@SW_SHOW)
		GUICtrlSetState($Edit1, $GUI_FOCUS)
		#EndRegion ### END Koda GUI section ###
		While 1
			$nMsg = GUIGetMsg()
			Switch $nMsg
				Case $GUI_EVENT_CLOSE, $Button1
					$report = GUICtrlRead($Edit1)
					GUIDelete($Form1)
					ExitLoop
			EndSwitch
		WEnd
		$hfile = FileOpen($crashreportdir & "\" & $crashreport & "_report.txt", 521)
		If Not ($hfile == -1) Then
			FileWrite($hfile, "`" & $report & "`")
			FileClose($hfile)
		EndIf
		$files = 0
		$files = _FileListToArray($crashreportdir, "*.txt", 1, 0)
		If (IsArray($files)) Then
			While Not ($files[0] == 0)
				FileCopy($crashreportdir & "\" & $files[$files[0]], $scriptdir & "\" & $files[$files[0]])
				$files[0] -= 1
			WEnd
		EndIf
		If (FileExists($savesdir)) Then
			DirCreate($crashreportdir & "\SAVEGAME")
			If (FileExists($savesdir & "\slotdat.ini")) Then
				If (FileCopy($savesdir & "\slotdat.ini", $crashreportdir & "\SAVEGAME\slotdat.ini", 9)) Then
					FileSetTime($crashreportdir & "\SAVEGAME\slotdat.ini", FileGetTime($savesdir & "\slotdat.ini", 0, 1))
				EndIf
				$slotdatarray = IniReadSection($crashreportdir & "\SAVEGAME\slotdat.ini", "POSITION")
				If (IsArray($slotdatarray)) Then
					$slotdatarray = $slotdatarray[1][1] + $slotdatarray[2][1]
					If ($slotdatarray > 9) Then
						$slotdatarray = "SLOT" & $slotdatarray
					Else
						$slotdatarray = "SLOT0" & $slotdatarray
					EndIf
					If (FileExists($savesdir & "\" & $slotdatarray)) Then
						If (DirCopy($savesdir & "\" & $slotdatarray, $crashreportdir & "\SAVEGAME\" & $slotdatarray, 1)) Then
							FileSetTime($crashreportdir & "\SAVEGAME\" & $slotdatarray, FileGetTime($savesdir & "\" & $slotdatarray, 0, 1))
						EndIf
					EndIf
				EndIf
			EndIf
			$saves = 0
			$saves = _FileListToArray($savesdir, "slot*", 2, 0)
			If (IsArray($saves)) Then
				$savestime = $saves
				While Not ($savestime[0] == 0)
					$savestime[$savestime[0]] = FileGetTime($savesdir & "\" & $savestime[$savestime[0]], 0, 1)
					$savestime[0] -= 1
				WEnd
				For $i = 1 To 10
					$maxindex = _ArrayMaxIndex($savestime, 1)
					If Not ($maxindex == 0 Or $maxindex == -1) Then
						If (DirCopy($savesdir & "\" & $saves[$maxindex], $crashreportdir & "\SAVEGAME\" & $saves[$maxindex], 1)) Then
							FileSetTime($crashreportdir & "\SAVEGAME\" & $saves[$maxindex], $savestime[$maxindex])
						EndIf
						$savestime[$maxindex] = -1
					EndIf
				Next
			EndIf
		EndIf
		$hfile = FileOpen($gamedir & "\debug.log", 9)
		If Not ($hfile == -1) Then
			FileWrite($hfile, @CRLF & $crashreport & @CRLF & $crash & @CRLF)
			FileClose($hfile)
		EndIf
		For $i In $extensions
			$files = 0
			$files = _FileListToArray($gamedir, $i, 1, 0)
			If (IsArray($files)) Then
				While Not ($files[0] == 0)
					If (FileCopy($gamedir & "\" & $files[$files[0]], $crashreportdir & "\" & $files[$files[0]])) Then
						FileSetTime($crashreportdir & "\" & $files[$files[0]], FileGetTime($gamedir & "\" & $files[$files[0]], 0, 1))
					EndIf
					$files[0] -= 1
				WEnd
			EndIf
		Next
		If (($hwnd == 0) And ($hwnde == 0)) Then
			If (ProcessExists($pid)) Then
				If (ProcessClose($pid)) Then
					ExitLoop
				Else
					Exit
				EndIf
			Else
				ExitLoop
			EndIf
		EndIf
	EndIf
	Sleep(1000)
WEnd

If ($videorecord) Then
	$childarray = 0
	$childarray = _WinAPI_EnumChildProcess($ffpid)
	If (IsArray($childarray)) Then
		While Not ($childarray[0][0] == 0)
			If ($childarray[$childarray[0][0]][1] == "ffmpeg.exe") Then
				ProcessClose($childarray[$childarray[0][0]][0])
				ExitLoop
			EndIf
			$childarray[0][0] -= 1
		WEnd
	EndIf
EndIf

$dirs = 0
$dirs = _FileListToArray($scriptdir, "*", 2, 0)
If (IsArray($dirs)) Then
	While Not ($dirs[0] == 0)
		If (StringRegExp($dirs[$dirs[0]], "^([0-9]{14})$", 0, 1)) Then
			ExitLoop
		Else
			$dirs[0] -= 1
		EndIf
	WEnd
	If Not ($dirs[0] == 0) Then
		ProgressOn("Please, wait", "Please, wait")
		DirRemove($tempdir, 1)
		DirCreate($tempdir)
		FileInstall(".\7za.exe", $tempdir & "\7za.exe", 1)
		FileInstall(".\7za.dll", $tempdir & "\7za.dll", 1)
		FileInstall(".\7zxa.dll", $tempdir & "\7zxa.dll", 1)
		If (FileExists($tempdir & "\7za.exe") And FileExists($tempdir & "\7za.dll") And FileExists($tempdir & "\7zxa.dll")) Then
			ProgressSet(50)
			While Not ($dirs[0] == 0)
				If (StringRegExp($dirs[$dirs[0]], "^([0-9]{14})$", 0, 1)) Then
					$crashreportdir = $scriptdir & "\" & $dirs[$dirs[0]]
					If Not (FileExists($crashreportdir & "_crash.txt")) Then
						If (FileExists($crashreportdir & "\" & $dirs[$dirs[0]] & "_crash.txt")) Then
							FileCopy($crashreportdir & "\" & $dirs[$dirs[0]] & "_crash.txt", $crashreportdir & "_crash.txt", 9)
						Else
							If (FileExists($crashreportdir & "\" & $dirs[$dirs[0]] & ".dmp")) Then
								$hfile = FileOpen($crashreportdir & "\" & $dirs[$dirs[0]] & "_crash.txt", 521)
								If Not ($hfile == -1) Then
									FileWrite($hfile, @CRLF & "Unknown" & @CRLF)
									FileClose($hfile)
								EndIf
								FileCopy($crashreportdir & "\" & $dirs[$dirs[0]] & "_crash.txt", $crashreportdir & "_crash.txt", 9)
							Else
								DirRemove($crashreportdir, 1)
								$dirs[0] -= 1
								ContinueLoop
							EndIf
						EndIf
					EndIf
					If Not (FileExists($crashreportdir & "_report.txt")) Then
						If (FileExists($crashreportdir & "\" & $dirs[$dirs[0]] & "_report.txt")) Then
							FileCopy($crashreportdir & "\" & $dirs[$dirs[0]] & "_report.txt", $crashreportdir & "_report.txt", 9)
						Else
							$hfile = FileOpen($crashreportdir & "\" & $dirs[$dirs[0]] & "_report.txt", 521)
							If Not ($hfile == -1) Then
								FileWrite($hfile, "``")
								FileClose($hfile)
							EndIf
							FileCopy($crashreportdir & "\" & $dirs[$dirs[0]] & "_report.txt", $crashreportdir & "_report.txt", 9)
						EndIf
					EndIf
					If (FileExists($crashmonitorlog)) Then
						FileCopy($crashmonitorlog, $crashreportdir & "\crashmonitor.log", 9)
					EndIf
					If (FileExists($crashreportdir & ".7z")) Then
						FileDelete($crashreportdir & ".7z")
					EndIf
					If Not (RunWait('"' & $tempdir & '\7za.exe" a "' & $crashreportdir & '.7z" "' & $crashreportdir & '"', $scriptdir, @SW_HIDE)) Then
						If (FileExists($crashreportdir & ".7z")) Then
							DirRemove($crashreportdir, 1)
						Else
							_error_log($crashmonitorlog, $dirs[$dirs[0]], "7za", 'FileExists($crashreportdir & ".7z")')
						EndIf
					Else
						_error_log($crashmonitorlog, $dirs[$dirs[0]], "7za", 'RunWait')
					EndIf
					$dirs[0] -= 1
				Else
					$dirs[0] -= 1
				EndIf
			WEnd
		Else
			_error_log($crashmonitorlog, $dirs[$dirs[0]], "7za", 'FileExists($tempdir & "\7za.exe")')
		EndIf
		DirRemove($tempdir, 1)
		ProgressOff()
		$files = 0
		$files = _FileListToArray($scriptdir, "*.7z", 1, 1)
		If (IsArray($files)) Then
			While Not ($files[0] == 0)
				If (StringRegExp($files[$files[0]], "^.*[0-9]{14}\.7z$", 0, 1)) Then
					$idbutton = MsgBox(262192, "Crashreport is ready", $text4 & @CRLF & @CRLF & $files[$files[0]])
					If ($idbutton == 1) Then
						ShellExecute($scriptdir)
					EndIf
					ExitLoop
				Else
					$files[0] -= 1
				EndIf
			WEnd
		EndIf
	EndIf
EndIf



Exit



Func _error_log($a, $b, $c, $d)
	Local $thfile = FileOpen($a, 9)
	FileWrite($thfile, "__________" & @CRLF & $b & @CRLF & $c & @CRLF & $d & @CRLF & "__________")
	FileClose($thfile)
EndFunc   ;==>_error_log

Func _DWORD($a)
	Local $tDWORD = DllStructCreate("DWORD")
	DllStructSetData($tDWORD, 1, $a)
	Return DllStructGetData($tDWORD, 1)
EndFunc   ;==>_DWORD


