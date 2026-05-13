ScriptName PWAL:Input:ToggleMenuScript Extends TerminalMenu Hidden

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.00
; Created: 04-10-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: ToggleMenuScript
; Type: Input / Terminal Menu Controller
; Purpose:
;   Generic terminal controller for PWAL toggle-based menu pages.
;   Handles menus backed by an ordered FormList of GlobalVariables
;   using the ToggleAll / State# token pattern.
;
; Responsibilities:
;   - Refresh ToggleAll and State# token displays on menu enter
;   - Toggle individual State# globals
;   - Toggle all child globals from the ToggleAll row
;   - Keep ToggleAll synchronized with child states
;   - Always provide valid On/Off replacement messages
;   - Ignore submenu/navigation rows safely
;
; Non-Responsibilities:
;   - No loot scanning
;   - No destination routing
;   - No item movement
;   - No install/update logic
;   - No direct submenu navigation handling
; ==============================================================

; ==============================================================
; Properties
; ==============================================================

Group FrameworkServices
	PWAL:Core:LoggerScript Property Logger Auto Const
EndGroup

Group Terminal
	TerminalMenu Property CurrentTerminalMenu Auto Const Mandatory
EndGroup

Group MenuData
	FormList Property MenuGlobals Auto Const Mandatory
EndGroup

Group DisplayMessages
	Message Property PWAL_MSG_Menu_On Auto Const Mandatory
	Message Property PWAL_MSG_Menu_Off Auto Const Mandatory
EndGroup

Group RuntimeConfig
	Int Property VALUE_OFF = 0 Auto Const
	Int Property VALUE_ON = 1 Auto Const
EndGroup

; ==============================================================
; Events
; ==============================================================

Event OnTerminalMenuEnter(TerminalMenu akTerminalBase, ObjectReference akTerminalRef)
	If akTerminalBase != CurrentTerminalMenu
		Return
	EndIf

	LogDebug("ToggleMenu", "OnTerminalMenuEnter triggered.")
	RefreshAllTokens(akTerminalRef)
EndEvent

Event OnTerminalMenuItemRun(Int auiMenuItemID, TerminalMenu akTerminalBase, ObjectReference akTerminalRef)
	If akTerminalBase != CurrentTerminalMenu
		Return
	EndIf

	If !HasValidMenuGlobals()
		Return
	EndIf

	If !IsMappedMenuItem(auiMenuItemID)
		LogDebug("ToggleMenu", "Ignoring unmapped menu item ID: " + auiMenuItemID)
		Return
	EndIf

	GlobalVariable akClickedGlobal = GetMenuGlobal(auiMenuItemID)

	If akClickedGlobal == None
		LogWarn("ToggleMenu", "MenuGlobals[" + auiMenuItemID + "] is not a GlobalVariable.")
		Return
	EndIf

	If auiMenuItemID == 0
		LogDebug("ToggleMenu", "ToggleAll selected.")
		RunToggleAll(akClickedGlobal)
	Else
		LogDebug("ToggleMenu", "State" + auiMenuItemID + " selected.")
		RunSingleToggle(akClickedGlobal)
		SyncToggleAllFromChildren()
	EndIf

	RefreshAllTokens(akTerminalRef)
EndEvent

; ==============================================================
; Core Execution
; ==============================================================

Function RunToggleAll(GlobalVariable akToggleAllGlobal)
	Int iNewValue = ToggleBoolGlobal(akToggleAllGlobal)

	Int iIndex = 1
	Int iCount = MenuGlobals.GetSize()

	While iIndex < iCount
		GlobalVariable akChildGlobal = GetMenuGlobal(iIndex)

		If akChildGlobal != None
			akChildGlobal.SetValueInt(iNewValue)
		EndIf

		iIndex += 1
	EndWhile
EndFunction

Function RunSingleToggle(GlobalVariable akSettingGlobal)
	ToggleBoolGlobal(akSettingGlobal)
EndFunction

Int Function ToggleBoolGlobal(GlobalVariable akGlobal)
	If akGlobal == None
		Return VALUE_OFF
	EndIf

	Int iCurrentValue = akGlobal.GetValueInt()
	Int iNewValue = VALUE_ON

	If iCurrentValue > 0
		iNewValue = VALUE_OFF
	EndIf

	akGlobal.SetValueInt(iNewValue)
	Return iNewValue
EndFunction

Function SyncToggleAllFromChildren()
	If !HasValidMenuGlobals()
		Return
	EndIf

	If MenuGlobals.GetSize() <= 1
		Return
	EndIf

	GlobalVariable akToggleAllGlobal = GetMenuGlobal(0)

	If akToggleAllGlobal == None
		Return
	EndIf

	Bool bAllEnabled = true
	Int iIndex = 1
	Int iCount = MenuGlobals.GetSize()

	While iIndex < iCount
		GlobalVariable akChildGlobal = GetMenuGlobal(iIndex)

		If akChildGlobal != None
			If akChildGlobal.GetValueInt() <= 0
				bAllEnabled = false
			EndIf
		EndIf

		iIndex += 1
	EndWhile

	If bAllEnabled
		akToggleAllGlobal.SetValueInt(VALUE_ON)
	Else
		akToggleAllGlobal.SetValueInt(VALUE_OFF)
	EndIf
EndFunction

; ==============================================================
; Token Display
; ==============================================================

Function RefreshAllTokens(ObjectReference akTerminalRef)
	If akTerminalRef == None
		LogWarn("ToggleMenu", "RefreshAllTokens failed: terminal ref is None.")
		Return
	EndIf

	If !HasValidMenuGlobals()
		Return
	EndIf

	Int iIndex = 0
	Int iCount = MenuGlobals.GetSize()

	While iIndex < iCount
		RefreshToken(iIndex, akTerminalRef)
		iIndex += 1
	EndWhile
EndFunction

Function RefreshToken(Int aiIndex, ObjectReference akTerminalRef)
	If akTerminalRef == None
		Return
	EndIf

	GlobalVariable akSettingGlobal = GetMenuGlobal(aiIndex)

	If akSettingGlobal == None
		LogWarn("ToggleMenu", "RefreshToken skipped: MenuGlobals[" + aiIndex + "] is not a GlobalVariable.")
		Return
	EndIf

	Message akReplacementMessage = GetToggleMessage(akSettingGlobal.GetValueInt())
	String sTokenName = GetTokenName(aiIndex)

	akTerminalRef.AddTextReplacementData(sTokenName, akReplacementMessage as Form)
	LogDebug("ToggleMenu", "Token refreshed: " + sTokenName)
EndFunction

Message Function GetToggleMessage(Int aiValue)
	If aiValue > 0
		Return PWAL_MSG_Menu_On
	EndIf

	Return PWAL_MSG_Menu_Off
EndFunction

String Function GetTokenName(Int aiIndex)
	If aiIndex == 0
		Return "ToggleAll"
	EndIf

	Return "State" + (aiIndex as String)
EndFunction

; ==============================================================
; Validation Helpers
; ==============================================================

Bool Function HasValidMenuGlobals()
	If MenuGlobals == None
		LogError("ToggleMenu", "MenuGlobals property is not filled.")
		Return false
	EndIf

	If MenuGlobals.GetSize() <= 0
		LogWarn("ToggleMenu", "MenuGlobals is empty.")
		Return false
	EndIf

	Return true
EndFunction

Bool Function IsMappedMenuItem(Int aiMenuItemID)
	If MenuGlobals == None
		Return false
	EndIf

	If aiMenuItemID < 0
		Return false
	EndIf

	If aiMenuItemID >= MenuGlobals.GetSize()
		Return false
	EndIf

	Return true
EndFunction

GlobalVariable Function GetMenuGlobal(Int aiIndex)
	If MenuGlobals == None
		Return None
	EndIf

	If aiIndex < 0
		Return None
	EndIf

	If aiIndex >= MenuGlobals.GetSize()
		Return None
	EndIf

	Return MenuGlobals.GetAt(aiIndex) as GlobalVariable
EndFunction

; ==============================================================
; Internal Logging Wrappers
; ==============================================================

Function LogInfo(String asSource, String asMessage)
	If Logger
		Logger.Info(asSource, asMessage)
	Else
		Debug.Trace("[PWAL][INFO][" + asSource + "] " + asMessage)
	EndIf
EndFunction

Function LogWarn(String asSource, String asMessage)
	If Logger
		Logger.Warn(asSource, asMessage)
	Else
		Debug.Trace("[PWAL][WARN][" + asSource + "] " + asMessage)
	EndIf
EndFunction

Function LogError(String asSource, String asMessage)
	If Logger
		Logger.Error(asSource, asMessage)
	Else
		Debug.Trace("[PWAL][ERROR][" + asSource + "] " + asMessage)
	EndIf
EndFunction

Function LogDebug(String asSource, String asMessage)
	If Logger
		Logger.DebugLog(asSource, asMessage)
	Else
		Debug.Trace("[PWAL][DEBUG][" + asSource + "] " + asMessage)
	EndIf
EndFunction