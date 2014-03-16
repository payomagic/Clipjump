﻿;#########################
;LESS CHANGEABLE LABES AND FUNCTIONS
;#########################

; Used Labels

settings:
	gui_Settings()
	return
	
history:
	gui_History()
	return

channelGUI:
	channelGUI()
	return

classTool:
	classManager()
	return

main:
	aboutGUI()
	return

exit:
	routines_Exit()
	ExitApp
	return

Tooltip_setFont(font_options="", font_face=""){
;sets font for a tooltip
	if (font_options) or (font_face)
	{
		loop, parse, font_face, |
			Gui, TTfont:Font, %font_options%, %A_LoopField%
		Gui, TTfont:Add, Text, hwnd_hwnd, `.
		SendMessage, 0x31, 0, 0,, ahk_id %_hwnd%
		Gui, TTfont: Destroy
		font := ErrorLevel
		SendMessage, 0x30, %font%, 1, %ctrl%, ahk_class tooltips_class32
	}
}

;BeepAt()
;SoundBeep function
BeepAt(value, freq, duration=150){
	if value
		SoundBeep, % freq, % duration
}

;EmptyMem()
;	Emtpties free memory

EmptyMem(){
	return, dllcall("psapi.dll\EmptyWorkingSet", "UInt", -1)
}

FoolGUI(switch=1){

	if !switch
	{
		Gui, foolgui:Destroy
		return
	}

	Gui, foolgui: -Caption +E0x80000 +LastFound +OwnDialogs +Owner +AlwaysOnTop
	Gui, foolgui: Show, NA, foolgui
	WinActivate, foolgui
}

;Checks and makes sure Clipboard is available
;Use 0 as the param when for calling the function, the aim is only to free clipboard and not get its contents
MakeClipboardAvailable(doreturn=1){

	while !temp
	{
		temp := DllCall("OpenClipboard", "int", "")
		sleep 10
	}
	DllCall("CloseClipboard")
	return doreturn ? Clipboard : ""
}

;type=1
;	returns Text
;type=0
;	returns data types
GetClipboardFormat(type=1){		;Thanks nnnik
	Critical, On

 	DllCall("OpenClipboard", "int", "")
 	while c := DllCall("EnumClipboardFormats","Int",c?c:0)
		x .= "," c
	DllCall("CloseClipboard")

	if type=1
  		if Instr(x, ",1") and Instr(x, ",13")
    		return "[" TXT.TIP_text "]"
 		else If Instr(x, ",15")
    		return "[" TXT.TIP_file_folder "]"
    	else
    		return ""
    else
    	return x
}

;GetFile()
;	Gets file path of selected item in Explorer

GetFile(hwnd=""){
	hwnd := hwnd ? hwnd : WinExist("A")
	WinGetClass class, ahk_id %hwnd%
	if (class="CabinetWClass" or class="ExploreWClass")
	{
		try for window in ComObjCreate("Shell.Application").Windows
				if (window.hwnd==hwnd)
    				sel := window.Document.SelectedItems
    	for item in sel
			ToReturn .= item.path "`n"
    }
    else
    	Toreturn := Copytovar(4)

	return Trim(ToReturn,"`n")
}

;GetFolder()
;	Gets folder path of active window in Explorer

GetFolder()
{
	WinGetClass,var,A
	If var in CabinetWClass,ExplorerWClass,Progman
	{
		IfEqual,var,Progman
			v := A_Desktop
		else
		{
			winGetText,Fullpath,A
			loop,parse,Fullpath,`r`n
			{
				IfInString,A_LoopField,:\
				{
					StringGetPos,pos,A_Loopfield,:\,L
					Stringtrimleft,v,A_loopfield,(pos - 1)
					break
				}
			}
		}
	return v
	}
	else
	{
		return Copytovar(2, "!{sc020}^{sc02e}{Esc}") 			;!d^c
	}
}

;BrowserRun()
;	Runs a web-site in default browser safely.

BrowserRun(site){
RegRead, OutputVar, HKCR, http\shell\open\command 
IfNotEqual, Outputvar
{
	StringReplace, OutputVar, OutputVar,"
	SplitPath, OutputVar,,OutDir,,OutNameNoExt, OutDrive
	run,% OutDir . "\" . OutNameNoExt . ".exe" . " """ . site . """"
}
else
	run,% "iexplore.exe" . " """ . site . """"	;internet explorer
}

;hkZ()
;	Hotkey command function

hkZ(HotKey, Label, Status=1) {
	if Hotkey !=
	{
		try
			Hotkey,% HotKey,% Label,% Status ? "On" : "Off"
		catch {
			t := ""
			loop, parse, hotkey
				if A_LoopField is alpha
					t .= "vk" GetVKList(A_LoopField)[1]
				else t .= A_LoopField
			Hotkey, % t,% Label,% (Status ? "On" : "Off") " UseErrorLevel"
			if ErrorLevel = 2
				MsgBox, 16, Clipjump Warning, It looks like the hotkey %t% doesn't exist ? `nRefer to troubleshooting page in help file.
		}
	}
}

;Gdip_SetImagetoClipboard()
;	Sets some Image to Clipboard

Gdip_SetImagetoClipboard( pImage ){
	;Sets some Image file to Clipboard
	PToken := Gdip_Startup()
	pBitmap := Gdip_CreateBitmapFromFile(pImage)
	Gdip_SetBitmaptoClipboard(pBitmap)
	Gdip_DisposeImage( pBitmap )
	Gdip_Shutdown( PToken)
}

;Gdip_CaptureClipboard()
;	Captures Clipboard to file

Gdip_CaptureClipboard(file, quality){
	PToken := Gdip_Startup()
	pBitmap := Gdip_CreateBitmapFromClipboard()
	Gdip_SaveBitmaptoFile(pBitmap, file, quality)
	Gdip_DisposeImage( pBitmap )
	Gdip_Shutdown( PToken)
}

; Gdip_Getdimensions()

Gdip_getLengths(img, byref width, byref height) {

	GDIPToken := Gdip_Startup()
	pBM := Gdip_CreateBitmapFromFile( img )
	width := Gdip_GetImageWidth( pBM )
	height := Gdip_GetImageHeight( pBM )
	Gdip_DisposeImage( pBM )
	Gdip_Shutdown( GDIPToken )
}

;	Flexible Active entity analyzer

IsActive(what, oftype="classnn", ispattern=false){
	if oftype = classnn
		ControlGetFocus, O, A
	else if oftype = window
		WinGetActiveTitle, O

	if ispattern
		return Instr(O, what) ? 1 : 0
	else
		return ( O == what ) ? 1 : 0
}

;Taken from Miscellaneous Functions by Avi Aryan
getParams(sum){
	static a := 1
	while sum>0
		loop
		{
			a*=2
			if (a>sum)
			{
				a/=2,p.=Round(a)" ",sum-=a,a:=1
				break
			}
		}
	return Substr(p,1,-1)
}

autoTooltip(Text, Time, which=1){
	ToolTip, % Text, , , % which
	SetTimer,% "Tooltipoff" which ,% Time
}

TooltipOff:
TooltipOff1:
TooltipOff2:
TooltipOff3:
TooltipOff4:
TooltipOff5:
TooltipOff6:
TooltipOff7:
TooltipOff8:
TooltipOff9:
TooltipOff10:
	SetTimer, % A_ThisLabel, Off
	ToolTip,,,, % ( Substr(A_ThisLabel, 0) == "f" ) ? 1 : RegExReplace(A_ThisLabel, "TooltipOff")
	return


keyblocker:
	return

simplePaste: 		; simple lable to paste CURRENT content on cb.
	Send ^{vk56}
	return

shortcutblocker_settings:
	ControlGetFocus, temp, A
	GuiControl, settings:,% temp,% A_ThisHotkey
	return

IsHotkeyControlActive(){
	return IsActive("msctls_hotkey", "classnn", true)
}

getQuant(str, what){
	StringReplace, str, str,% what,% what, UseErrorLevel
	return ErrorLevel
}

;Used for Debugging
debugTip(text, tooltipno=20){
	Tooltip, % text,,, % tooltipno
}

fillwithSpaces(text, limit=35){
	loop % limit-Strlen(text)
		r .= A_space
	return text r
}

/*
SuperInstr()
	Returns min/max position for a | separated values of Needle(s)
	
	return_min = true  ; return minimum position
	return_max = false ; return maximum position

*/
SuperInstr(Hay, Needles, return_min=true, Case=false, Startpoint=1, Occurrence=1){
	
	pos := return_min*Strlen(Hay)
	Needles := Rtrim(Needles, " ")
	
	if return_min
	{
		loop, parse, Needles, %A_space%
			if ( pos > (var := Instr(Hay, A_LoopField, Case, startpoint, Occurrence)) )
				pos := var
	}
	else
	{
		if Needles=
			return Strlen(Hay)
		loop, parse, Needles, %A_space%
			if ( (var := Instr(Hay, A_LoopField, Case, startpoint, Occurrence)) > pos )
				pos := var
	}
	return pos
}

/*
Compare Versions
*/

IsLatestRelease(prog_ver, cur_ver, exclude_keys="b|a") {

	if RegExMatch(prog_ver, "(" exclude_keys ")")
		return 1

	StringSplit, prog_ver_array, prog_ver,`.
	StringSplit, cur_ver_array, cur_ver  ,`.

	Loop % cur_ver_array0
		if !( prog_ver_array%A_index% >= cur_ver_array%A_index% )
			return 0
	return 1
}

;get width and heights of controls
getControlInfo(type="button", text="", ret="w", fontsize="", fontmore=""){
	static test
	Gui, wasteGUI:New
	Gui, wasteGUI:Font, % fontsize, % fontmore
	Gui, wasteGUI:Add, % type, vtest, % text
	GuiControlGet, test, wasteGUI:pos
	Gui, wasteGUI:Destroy
	if ret=w
		return testw
	if ret=h
		return testh
}

;GUI Message Box to allow selection
guiMsgBox(title, text, owner="" ,isEditable=0, wait=0, w="", h=""){
	static thebox
	wf := getControlInfo("edit", text, "w", "s9", "Lucida Console")
	hf := getControlInfo("edit", text, "h", "s9", "Lucida Console")
	w := !w ? (wf > A_ScreenWidth/1.5 ? A_ScreenWidth/1.5 : wf+20) : w 	;+10 for scl bar
	h := !h ? (hf > A_ScreenHeight ? A_ScreenHeight : hf+65) : h 		;+10 for margin, +more for the button

	Gui, guiMsgBox:New
	Gui, guiMsgBox:+Owner%owner%
	Gui, -MaximizeBox
	Gui, Font, s9, Lucida Console
	Gui, Add, Edit, % "x5 y5 w" w-10 " h" h-35 (isEditable ? " -" : " +") "Readonly vthebox +multi -Border", % text
	Gui, Add, button, % "x" w/2-20 " w40 y+5", OK
	GuiControl, Focus, button1
	Gui, guiMsgBox:Show, % "w" w " h" h, % title
	if wait
		while GuiEnds
			sleep 100
	return thebox

guiMsgBoxButtonOK:
guiMsgBoxGuiClose:
guiMsgBoxGuiEscape:
	Gui, guiMsgBox:Submit, nohide
	Gui, guiMsgBox:Destroy
	GuiEnds := 1
	return

}

;inputbox function for use with customizer...
inputBox(title, text){
	Inputbox, o, % title, % text
	return o
}

; Code by deo http://www.autohotkey.com/board/topic/74348-send-command-when-switching-to-russian-input-language/#entry474543

GetVKList( letter )
{
	SetFormat, Integer, Hex
	vk_list := Array()
	for i, hkl in KeyboardLayoutList()
	{
		retVK := DllCall("VkKeyScanExW","UShort",Asc(letter),"Ptr",hkl,"Short")
		if (retVK = -1)
			continue
		vk := retVK & 0xFF
		StringTrimLeft,vk,vk,2
		if !instr(_list,"|" vk "|")
		{
			_list .= "|" vk "|"
			vk_list.insert(vk)
		}
	}
	SetFormat, Integer, D
	return vk_list
}

KeyboardLayoutList()
{
	hkl_num := 20
	VarSetCapacity(hHkls,hkl_num*A_PtrSize,0)
	num := DllCall("GetKeyboardLayoutList","Uint",hkl_num,"Ptr",&hHkls)
	hkl_list := Array()
	loop,% num
		hkl_list.Insert(NumGet(hHkls,(A_index-1)*A_PtrSize,"UPtr"))
	hHkls =
	return hkl_list
}

; !Code by deo