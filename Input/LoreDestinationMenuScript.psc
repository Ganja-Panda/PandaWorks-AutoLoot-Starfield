ScriptName PWAL:Input:LoreDestinationMenuScript Extends TerminalMenu Hidden

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.00
; Created: 04-10-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: LoreDestinationMenuScript
; Type: Input / Terminal Menu Controller
; Purpose:
;   Handles the single-row Lore/DataSlates destination menu page.
;   Cycles the DataSlates destination override global and refreshes
;   the Lore terminal replacement token.
;
; Responsibilities:
;   - Refresh the Lore destination token on menu enter
;   - Cycle the DataSlates destination override global
;   - Preserve resolver contract where 0 means use default destination
;   - Always provide a valid destination replacement message
;   - Ignore unmapped menu rows safely
;
; Non-Responsibilities:
;   - No SendAll logic
;   - No bulk destination routing
;   - No loot scanning
;   - No runtime destination resolving
;   - No item movement
;   - No install/update logic
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

Group DestinationGlobal
	GlobalVariable Property PWAL_GLOB_Settings_Dest_BOOK_Dataslates Auto Const Mandatory
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

	LogDebug("LoreDestinationMenu", "OnTerminalMenuEnter triggered.")
	RefreshLoreToken(akTerminalRef)
EndEvent

Event OnTerminalMenuItemRun(Int auiMenuItemID, TerminalMenu akTerminalBase, ObjectReference akTerminalRef)
	If akTerminalBase != CurrentTerminalMenu
		Return
	EndIf

	If auiMenuItemID != 0
		LogDebug("LoreDestinationMenu", "Ignoring unmapped menu item ID: " + auiMenuItemID)
		Return
	EndIf

	If !HasValidLoreDestinationGlobal()
		Return
	EndIf

	LogDebug("LoreDestinationMenu", "Lore destination selected.")

	CycleLoreDestination()
	RefreshLoreToken(akTerminalRef)
EndEvent

; ==============================================================
; Core Execution
; ==============================================================

Function CycleLoreDestination()
	If !HasValidLoreDestinationGlobal()
		Return
	EndIf

	Int iCurrentValue = NormalizeDestinationValue(PWAL_GLOB_Settings_Dest_BOOK_Dataslates.GetValueInt())
	Int iNewValue = iCurrentValue + 1

	If iNewValue > DEST_VOID
		iNewValue = DEST_DEFAULT
	EndIf

	If iNewValue < DEST_DEFAULT
		iNewValue = DEST_DEFAULT
	EndIf

	PWAL_GLOB_Settings_Dest_BOOK_Dataslates.SetValueInt(iNewValue)

	LogDebug("LoreDestinationMenu", "DataSlates destination changed from " + iCurrentValue + " to " + iNewValue)
EndFunction

; ==============================================================
; Token Display
; ==============================================================

Function RefreshLoreToken(ObjectReference akTerminalRef)
	If akTerminalRef == None
		LogWarn("LoreDestinationMenu", "RefreshLoreToken failed: terminal ref is None.")
		Return
	EndIf

	If !HasValidLoreDestinationGlobal()
		Return
	EndIf

	Message akReplacementMessage = GetDestinationMessage(PWAL_GLOB_Settings_Dest_BOOK_Dataslates.GetValueInt())

	akTerminalRef.AddTextReplacementData("Lore", akReplacementMessage as Form)

	LogDebug("LoreDestinationMenu", "Token refreshed: Lore")
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

Bool Function HasValidLoreDestinationGlobal()
	If PWAL_GLOB_Settings_Dest_BOOK_Dataslates == None
		LogError("LoreDestinationMenu", "PWAL_GLOB_Settings_Dest_BOOK_Dataslates property is not filled.")
		Return false
	EndIf

	Return true
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