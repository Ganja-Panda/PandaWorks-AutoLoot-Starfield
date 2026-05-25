ScriptName PWAL:Input:CorpseDestinationMenuScript Extends TerminalMenu Hidden

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.00
; Created: 05-25-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: CorpseDestinationMenuScript
; Type: Input / Terminal Menu Controller
; Purpose:
;   Dedicated terminal controller for the main Loot Destinations
;   page. Handles the corpse destination setting directly while
;   leaving loose loot/category destinations to the standard
;   DestinationMenuScript pages.
;
; Responsibilities:
;   - Refresh the corpse destination token on menu enter
;   - Cycle the existing corpse destination global
;   - Keep the main destination page free of SendAll behavior
;   - Allow the Loose Loot Destinations row to remain submenu-only
;   - Always provide valid destination replacement messages
;
; Non-Responsibilities:
;   - No loot scanning
;   - No runtime destination resolving
;   - No item movement
;   - No install/update logic
;   - No loose loot/category destination handling
;   - No SendAll handling
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
	GlobalVariable Property PWAL_GLOB_Settings_Dest_Corpses Auto Const Mandatory
EndGroup

Group DisplayMessages
	Message Property PWAL_MSG_Dest_Player Auto Const Mandatory
	Message Property PWAL_MSG_Dest_PandaWorks Auto Const Mandatory
	Message Property PWAL_MSG_Dest_PlayerShip Auto Const Mandatory
	Message Property PWAL_MSG_Dest_LodgeSafe Auto Const Mandatory
	Message Property PWAL_MSG_Dest_Void Auto Const Mandatory
EndGroup

Group RuntimeConfig
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

	RefreshCorpseToken(akTerminalRef)
EndEvent

Event OnTerminalMenuItemRun(Int auiMenuItemID, TerminalMenu akTerminalBase, ObjectReference akTerminalRef)
	If akTerminalBase != CurrentTerminalMenu
		Return
	EndIf

	; ID 0 is the Loose Loot submenu. Ignore it.
	If auiMenuItemID != 1
		Return
	EndIf

	If PWAL_GLOB_Settings_Dest_Corpses == None
		LogWarn("CorpseDestinationMenu", "Corpse destination global is not filled.")
		Return
	EndIf

	Int iCurrentValue = NormalizeDestinationValue(PWAL_GLOB_Settings_Dest_Corpses.GetValueInt())
	Int iNewValue = GetNextDestinationValue(iCurrentValue)

	PWAL_GLOB_Settings_Dest_Corpses.SetValueInt(iNewValue)
	RefreshCorpseToken(akTerminalRef)
EndEvent

; ==============================================================
; Token Display
; ==============================================================

Function RefreshCorpseToken(ObjectReference akTerminalRef)
	If akTerminalRef == None
		Return
	EndIf

	If PWAL_GLOB_Settings_Dest_Corpses == None
		Return
	EndIf

	Message akReplacementMessage = GetDestinationMessage(PWAL_GLOB_Settings_Dest_Corpses.GetValueInt())
	akTerminalRef.AddTextReplacementData("State1", akReplacementMessage as Form)
EndFunction

Message Function GetDestinationMessage(Int aiValue)
	Int iValue = NormalizeDestinationValue(aiValue)

	If iValue == DEST_LODGE_SAFE
		Return PWAL_MSG_Dest_LodgeSafe
	ElseIf iValue == DEST_PANDAWORKS
		Return PWAL_MSG_Dest_PandaWorks
	ElseIf iValue == DEST_PLAYER
		Return PWAL_MSG_Dest_Player
	ElseIf iValue == DEST_PLAYER_SHIP
		Return PWAL_MSG_Dest_PlayerShip
	ElseIf iValue == DEST_VOID
		Return PWAL_MSG_Dest_Void
	EndIf

	Return PWAL_MSG_Dest_Player
EndFunction

; ==============================================================
; Destination Helpers
; ==============================================================

Int Function NormalizeDestinationValue(Int aiValue)
	If aiValue == DEST_PLAYER
		Return DEST_PLAYER
	EndIf

	If aiValue == DEST_PANDAWORKS
		Return DEST_PANDAWORKS
	EndIf

	If aiValue == DEST_PLAYER_SHIP
		Return DEST_PLAYER_SHIP
	EndIf

	If aiValue == DEST_LODGE_SAFE
		Return DEST_LODGE_SAFE
	EndIf

	If aiValue == DEST_VOID
		Return DEST_VOID
	EndIf

	Return DEST_LODGE_SAFE
EndFunction

Int Function GetNextDestinationValue(Int aiCurrentValue)
	If aiCurrentValue == DEST_LODGE_SAFE
		Return DEST_PANDAWORKS
	ElseIf aiCurrentValue == DEST_PANDAWORKS
		Return DEST_PLAYER
	ElseIf aiCurrentValue == DEST_PLAYER
		Return DEST_PLAYER_SHIP
	ElseIf aiCurrentValue == DEST_PLAYER_SHIP
		Return DEST_VOID
	EndIf

	Return DEST_LODGE_SAFE
EndFunction

; ==============================================================
; Internal Logging Wrappers
; ==============================================================

Function LogWarn(String asSource, String asMessage)
	If Logger
		Logger.Warn(asSource, asMessage)
	Else
		Debug.Trace("[PWAL][WARN][" + asSource + "] " + asMessage)
	EndIf
EndFunction