ScriptName PWAL:Input:DestinationMenuScript Extends TerminalMenu Hidden

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.00
; Created: 04-10-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: DestinationMenuScript
; Type: Input / Terminal Menu Controller
; Purpose:
;   Generic terminal controller for PWAL destination menu pages.
;   Handles menus backed by an ordered FormList of destination
;   GlobalVariables using the SendAll / State# token pattern.
;
; Responsibilities:
;   - Refresh SendAll and State# destination tokens on menu enter
;   - Cycle individual destination globals
;   - Apply SendAll destination values to child destination globals
;   - Preserve resolver contract where 0 means use default destination
;   - Always provide valid destination replacement messages
;   - Ignore submenu/navigation rows safely
;
; Non-Responsibilities:
;   - No loot scanning
;   - No runtime destination resolving
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
	FormList Property DestinationGlobals Auto Const Mandatory
EndGroup

Group DisplayMessages
	Message Property PWAL_MSG_Dest_Default Auto Const Mandatory
	Message Property PWAL_MSG_Dest_Player Auto Const Mandatory
	Message Property PWAL_MSG_Dest_PandaWorks Auto Const Mandatory
	Message Property PWAL_MSG_Dest_PlayerShip Auto Const Mandatory
	Message Property PWAL_MSG_Dest_LodgeSafe Auto Const Mandatory
	Message Property PWAL_MSG_Dest_Void Auto Const Mandatory
EndGroup

Group RuntimeConfig
	Int Property DEST_DEFAULT = 0 Auto Const
	Int Property DEST_PLAYER = 1 Auto Const
	Int Property DEST_PANDAWORKS = 2 Auto Const
	Int Property DEST_PLAYER_SHIP = 3 Auto Const
	Int Property DEST_LODGE_SAFE = 4 Auto Const
	Int Property DEST_VOID = 5 Auto Const
EndGroup

; ==============================================================
; Events
; ==============================================================

Event OnTerminalMenuEnter(TerminalMenu akTerminalBase, ObjectReference akTerminalRef)
	If akTerminalBase != CurrentTerminalMenu
		Return
	EndIf

	LogDebug("DestinationMenu", "OnTerminalMenuEnter triggered.")
	RefreshAllTokens(akTerminalRef)
EndEvent

Event OnTerminalMenuItemRun(Int auiMenuItemID, TerminalMenu akTerminalBase, ObjectReference akTerminalRef)
	If akTerminalBase != CurrentTerminalMenu
		Return
	EndIf

	If !HasValidDestinationGlobals()
		Return
	EndIf

	If !IsMappedMenuItem(auiMenuItemID)
		LogDebug("DestinationMenu", "Ignoring unmapped menu item ID: " + auiMenuItemID)
		Return
	EndIf

	GlobalVariable akClickedGlobal = GetDestinationGlobal(auiMenuItemID)

	If akClickedGlobal == None
		LogWarn("DestinationMenu", "DestinationGlobals[" + auiMenuItemID + "] is not a GlobalVariable.")
		Return
	EndIf

	If auiMenuItemID == 0
		LogDebug("DestinationMenu", "SendAll selected.")
		RunSendAll(akClickedGlobal)
	Else
		LogDebug("DestinationMenu", "State" + auiMenuItemID + " selected.")
		RunSingleDestination(akClickedGlobal)
	EndIf

	RefreshAllTokens(akTerminalRef)
EndEvent

; ==============================================================
; Core Execution
; ==============================================================

Function RunSendAll(GlobalVariable akSendAllGlobal)
	Int iNewValue = CycleDestinationGlobal(akSendAllGlobal)

	Int iIndex = 1
	Int iCount = DestinationGlobals.GetSize()

	While iIndex < iCount
		GlobalVariable akChildGlobal = GetDestinationGlobal(iIndex)

		If akChildGlobal != None
			akChildGlobal.SetValueInt(iNewValue)
		EndIf

		iIndex += 1
	EndWhile
EndFunction

Function RunSingleDestination(GlobalVariable akDestinationGlobal)
	CycleDestinationGlobal(akDestinationGlobal)
EndFunction

Int Function CycleDestinationGlobal(GlobalVariable akGlobal)
	If akGlobal == None
		Return DEST_DEFAULT
	EndIf

	Int iCurrentValue = NormalizeDestinationValue(akGlobal.GetValueInt())
	Int iNewValue = iCurrentValue + 1

	If iNewValue > DEST_VOID
		iNewValue = DEST_DEFAULT
	EndIf

	If iNewValue < DEST_DEFAULT
		iNewValue = DEST_DEFAULT
	EndIf

	akGlobal.SetValueInt(iNewValue)
	Return iNewValue
EndFunction

; ==============================================================
; Token Display
; ==============================================================

Function RefreshAllTokens(ObjectReference akTerminalRef)
	If akTerminalRef == None
		LogWarn("DestinationMenu", "RefreshAllTokens failed: terminal ref is None.")
		Return
	EndIf

	If !HasValidDestinationGlobals()
		Return
	EndIf

	Int iIndex = 0
	Int iCount = DestinationGlobals.GetSize()

	While iIndex < iCount
		RefreshToken(iIndex, akTerminalRef)
		iIndex += 1
	EndWhile
EndFunction

Function RefreshToken(Int aiIndex, ObjectReference akTerminalRef)
	If akTerminalRef == None
		Return
	EndIf

	GlobalVariable akDestinationGlobal = GetDestinationGlobal(aiIndex)

	If akDestinationGlobal == None
		LogWarn("DestinationMenu", "RefreshToken skipped: DestinationGlobals[" + aiIndex + "] is not a GlobalVariable.")
		Return
	EndIf

	Message akReplacementMessage = GetDestinationMessage(akDestinationGlobal.GetValueInt())
	String sTokenName = GetTokenName(aiIndex)

	akTerminalRef.AddTextReplacementData(sTokenName, akReplacementMessage as Form)
	LogDebug("DestinationMenu", "Token refreshed: " + sTokenName)
EndFunction

Message Function GetDestinationMessage(Int aiValue)
	Int iValue = NormalizeDestinationValue(aiValue)

	If iValue == DEST_DEFAULT
		Return PWAL_MSG_Dest_Default
	ElseIf iValue == DEST_PLAYER
		Return PWAL_MSG_Dest_Player
	ElseIf iValue == DEST_PANDAWORKS
		Return PWAL_MSG_Dest_PandaWorks
	ElseIf iValue == DEST_PLAYER_SHIP
		Return PWAL_MSG_Dest_PlayerShip
	ElseIf iValue == DEST_LODGE_SAFE
		Return PWAL_MSG_Dest_LodgeSafe
	ElseIf iValue == DEST_VOID
		Return PWAL_MSG_Dest_Void
	EndIf

	Return PWAL_MSG_Dest_Default
EndFunction

String Function GetTokenName(Int aiIndex)
	If aiIndex == 0
		Return "SendAll"
	EndIf

	Return "State" + (aiIndex as String)
EndFunction

; ==============================================================
; Destination Helpers
; ==============================================================

Int Function NormalizeDestinationValue(Int aiValue)
	If aiValue < DEST_DEFAULT
		Return DEST_DEFAULT
	EndIf

	If aiValue > DEST_VOID
		Return DEST_DEFAULT
	EndIf

	Return aiValue
EndFunction

; ==============================================================
; Validation Helpers
; ==============================================================

Bool Function HasValidDestinationGlobals()
	If DestinationGlobals == None
		LogError("DestinationMenu", "DestinationGlobals property is not filled.")
		Return false
	EndIf

	If DestinationGlobals.GetSize() <= 0
		LogWarn("DestinationMenu", "DestinationGlobals is empty.")
		Return false
	EndIf

	Return true
EndFunction

Bool Function IsMappedMenuItem(Int aiMenuItemID)
	If DestinationGlobals == None
		Return false
	EndIf

	If aiMenuItemID < 0
		Return false
	EndIf

	If aiMenuItemID >= DestinationGlobals.GetSize()
		Return false
	EndIf

	Return true
EndFunction

GlobalVariable Function GetDestinationGlobal(Int aiIndex)
	If DestinationGlobals == None
		Return None
	EndIf

	If aiIndex < 0
		Return None
	EndIf

	If aiIndex >= DestinationGlobals.GetSize()
		Return None
	EndIf

	Return DestinationGlobals.GetAt(aiIndex) as GlobalVariable
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