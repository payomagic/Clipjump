/*
Plugin management Routines
*/

pluginManagerGui:
	pluginManager_GUI()
	return

pluginManager_GUI(){
	static wt, ht
	static searchTerm, pluginMLV
	wt := 600 ;(A_ScreenWidth/2.5) - 14
	ht := 400
	DidDelete := 0

	Gui, PluginM:New
	Gui, Margin, 7, 7
	Gui, -MaximizeBox
	Gui, Font,, Consolas
	Gui, Add, Edit, % "x7 y7 w" wt " vsearchTerm gpluginMSearch", 
	Gui, Font,, Courier New
	Gui, Add, ListView, % "xp y+10 h" ht-40 " -LV0X10 vpluginMLV gpluginMLV -Multi w" wt, % TXT._name "|" TXT._tags "|" TXT._author "|hidden"
	Gui, PluginM:Default
	LV_ModifyCol(1, 5*wt/12) , LV_ModifyCol(2, 4*wt/12-4) , LV_ModifyCol(3, wt/4) , LV_ModifyCol(4, 0)
	updatePluginList()
	Gui, Font
	; The menu
	Menu, plMenu, Add, % TXT._run, plugin_Run
	Menu, plMenu, Add
	Menu, plMenu, Add, % TXT.plg_edit, plugin_edit
	Menu, plMenu, Add, % TXT.plg_properties, plugin_showprops
	Menu, plMenu, Add, % TXT.HST_m_del, plugin_delete
	Menu, plMenu, Default, % TXT._run

	Gui, Add, StatusBar
	Gui, pluginM:Show, % "w" wt+14 " h" ht+30, % PROGNAME " " TXT.PLG__name
	; the Hotkeys
	Hotkey, IfWinActive, % PROGNAME " " TXT.PLG__name
	hkZ("^f", "pluginSearchfocus")
	hkZ("!d", "pluginSearchfocus")
	Hotkey, If
	Hotkey, If, IsPlugListViewActive()
	hkZ("Enter", "plugin_Run")
	hkZ("F2", "plugin_edit")
	hkZ("!Enter", "plugin_showprops")
	hkZ("Del", "plugin_delete")
	Hotkey, If
	return

pluginMLV:
	if A_GuiEvent = DoubleClick
		gosub plugin_Run
	return

pluginSearchfocus:
	GuiControl, pluginM:focus, searchTerm
	GuiControl, pluginM:focus, Edit1
	return

plugin_Run:
	Gui, pluginM:Default
	gosub plugin_getSelected
	filepath := PLUGINS["<>"][dirNum]["plugin_path"]
	SB_SetText(TXT.PLG_sb_running " - " plugin_displayname)
	API.runPlugin(filepath)
	Gui, pluginM:Default 	; set it def again incase gui was changed
	SB_SetText(TXT.PLG_sb_exit " - " plugin_displayname)
	return

plugin_edit:
	gosub plugin_getSelected
	Run % ini_defEditor " """ "plugins\" PLUGINS["<>"][dirNum]["plugin_path"] """"
	return

plugin_showprops:
	gosub plugin_getSelected
	disText := ""
	for key,value in PLUGINS["<>"][dirNum]
		if key not in #,`*,silent,previewable
			disText .= key "  -  " value "`n"
	guiMsgbox(plugin_displayname " " TXT._properties, disText, "pluginM")
	EmptyMem()
	return

plugin_delete:
	gosub plugin_getSelected
	MsgBox, 52, Plugin Delete, % TXT.PLG_delmsg "`n" plugin_displayname
	IfMsgBox, Yes
	{
		FileDelete, % plugPath := "plugins\" PLUGINS["<>"][dirNum]["Plugin_path"]
		FileRemoveDir, % Substr(plugPath,1,-4) ".lib", 1 	;remove .ahk and put .lib
		LV_Delete(valSelected)
		Gui, pluginM:Default
		SB_SetText(TXT.PLG_sb_deleted " - " plugin_displayname)
		DidDelete := 1
	}
	return

plugin_getSelected:
	Gui, pluginM:Default
	if LV_GetNext() = 0
		valSelected := selected_row
	else valSelected := LV_GetNext()
	LV_GetText(dirNum, valSelected, 4) , plugin_displayname := PLUGINS["<>"][dirNum]["name"]
	return

pluginMSearch:
	Gui, pluginM:Submit, Nohide
	updatePluginList(searchTerm)
	return

pluginMGuiContextMenu:
	Gui, pluginM:Default
	if (A_GuiControl != "pluginMLV") or (LV_GetNext() = 0)
		return
	selected_row := LV_GetNext()
	Menu, plMenu, Show, %A_Guix%, %A_guiy%
	return

pluginMGuiEscape:
pluginMGuiClose:
	GUi, pluginM: Destroy
	Menu, plmenu, DeleteAll
	if DidDelete {
		MsgBox, 52, Warning, % TXT.PLG_restartmsg
		IfMsgBox, Yes
			gosub reload
	} 
	EmptyMem()
	return

}

updatePluginList(searchTerm="") {
	Gui, PluginM:Default
	LV_Delete()

	for k,v in PLUGINS
	{
		if k in external,pformat,`<`>
			continue
		if !updatePluginList_validate(searchTerm,v)
			continue
		LV_Add("", v.name, v.tags, v.author, v["#"])
	}
	for k,v in PLUGINS.external
	{
		if !updatePluginList_validate(searchTerm,v)
			continue
		LV_Add("", v.name, v.tags, v.author, v["#"])
	}
	for k,v in PLUGINS.pformat
	{
		if !updatePluginList_validate(searchTerm,v)
			continue
		LV_Add("", v.name, v.tags, v.author, v["#"])
	}
}

updatePluginList_validate(searchTerm, v){
	return SuperInstr(v.name " " v.tags " " v.author , Trim(searchTerm), 1)
}

;////////////////////////////////////////////////////////////////////////////////////////////////////////////
;------------------------------------------------------ END OF GUI FUNCTIONS --------------------------------

updatePluginIncludes() {
	FileDelete, plugins\_registry.ahk
	loop, plugins\*.ahk
	{
		if Instr(A_LoopFileName, "external.") = 1
			continue
		st .= "#Include, %A_ScriptDir%\plugins\" A_LoopFileName "`n"
	}
	FileAppend, % st, plugins\_registry.ahk
}

;-------------------------------------------------------------------------------------------------------------
;Loads Plugins into the Obj
;-------------------------------------------------------------------------------------------------------------

loadPlugins() {
	PLUGINS.pformat := {} , PLUGINS.external := {} , PLUGINS["<>"] := {}	; init 2nd level objects
	loop, plugins\*.ahk
	{
		if A_LoopFileName = _registry.ahk
			continue
		; read plugin dets
		FileRead, ov, % A_LoopFileFullPath
		p:=1 , detobj := {}
		while p2:=RegExMatch(ov, "im)^;@Plugin-.*$", o, p) {
			ps := Substr(o, Instr(o,"-")+1) , pname := Substr(ps, 1, Instr(ps," ")-1) , ptext := Substr(ps, Instr(ps, " ")+1)
			p := p2+Strlen(o) , detobj[pname] .= ptext
		}

		filename := Substr(A_LoopFileName, 1, -4) , c := 0
		loop, parse, filename,`.
			name%A_index% := A_LoopField , c++
		detobj["#"] := A_index		; add unique number of <> realtive directory
		detobj["name"] := detobj.name ? detobj.name : Substr(A_LoopFileName,1,-4) 	; add the Name of plugin
		detobj["Plugin_path"] := A_LoopFileName
		; and * stores the path of plugin
		if c>1
		{
			if name1 = external
				detobj["*"] := "plugins\external." name2 ".ahk" , PLUGINS["external"][name2] := detobj.Clone() 
				, PLUGINS["<>"][A_index] := detobj.Clone()
			else if name1 = pformat
				detobj["*"] := "plugin_pformat_" name2 , PLUGINS["pformat"][name2] := detobj.Clone() 
				, PLUGINS["<>"][A_index] := detobj.Clone()
		}
		else detobj["*"] := "plugin_" name1 , PLUGINS[name1] := detobj.Clone() , PLUGINS["<>"][A_Index] := detobj.Clone()
	}
	; -- set def pformat
	set_pformat()
}

;///////////////////////// MORE LOW END GUI FUNCTIONS ///////////////////////////////////////////////////////////////////

IsPlugListViewActive(){
	return IsActive("SysListView321", "classnn") && IsActive(PROGNAME " " TXT.PLG__name, "window") && ctrlRef==""
}
#If IsPlugListViewActive()
#If