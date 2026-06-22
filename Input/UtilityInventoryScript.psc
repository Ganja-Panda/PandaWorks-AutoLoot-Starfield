ScriptName PWAL:Input:UtilityInventoryScript Extends TerminalMenu Hidden

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.00
; Created: 05-17-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: UtilityInventoryScript
; Type: Input / Terminal Menu Controller
; Purpose:
;   Handles the PWAL Utilities > Inventories terminal page.
;   Routes inventory open menu actions into CommandServices.
;
; Responsibilities:
;   - Open Lodge Safe from the Inventories utility menu
;   - Open PandaWorks Inventory from the Inventories utility menu
;   - Open Home Ship Cargo from the Inventories utility menu
;   - Show unavailable message when backend command fails
;   - Ignore unmapped menu rows safely
;
; Non-Responsibilities:
;   - No transfer implementation
;   - No loot scanning
;   - No destination resolving
;   - No inventory backend logic
;   - No terminal token handling
; ==============================================================

; ==============================================================
; Properties
; ==============================================================

Group FrameworkServices
	PWAL:Core:LoggerScript Property Logger Auto Const
	PWAL:System:CommandServicesScript Property CommandServices Auto Const Mandatory
EndGroup

Group Terminal
	TerminalMenu Property CurrentTerminalMenu Auto Const Mandatory
EndGroup

Group DisplayMessages
	Message Property PWAL_MSG_Utilities_Unavailable Auto Const
EndGroup

; ==============================================================
; Menu Item IDs
;
; PWAL_TMLM_Utilities_Inventories
; ID 0 = Lodge Safe
; ID 1 = PandaWorks
; ID 2 = Cargo Hold
; ==============================================================

Int Property ITEM_LODGE_SAFE = 0 Auto Const
Int Property ITEM_PANDAWORKS = 1 Auto Const
Int Property ITEM_CARGO_HOLD = 2 Auto Const

; ==============================================================
; Events
; ==============================================================

Event OnTerminalMenuEnter(TerminalMenu akTerminalBase, ObjectReference akTerminalRef)
	If akTerminalBase != CurrentTerminalMenu
		Return
	EndIf

EndEvent

Event OnTerminalMenuItemRun(Int auiMenuItemID, TerminalMenu akTerminalBase, ObjectReference akTerminalRef)
	If akTerminalBase != CurrentTerminalMenu
		Return
	EndIf

	If auiMenuItemID == ITEM_LODGE_SAFE
		RunOpenLodgeSafe()
	ElseIf auiMenuItemID == ITEM_PANDAWORKS
		RunOpenPandaWorksInventory()
	ElseIf auiMenuItemID == ITEM_CARGO_HOLD
		RunOpenShipCargo()
	EndIf
EndEvent

; ==============================================================
; Core Execution
; ==============================================================

Function RunOpenLodgeSafe()
	If CommandServices == None
		LogError("UtilityInventory", "RunOpenLodgeSafe failed: CommandServices property is not filled.")
		ShowMessage(PWAL_MSG_Utilities_Unavailable)
		Return
	EndIf

	Bool bSuccess = CommandServices.OpenLodgeSafe()

	If !bSuccess
		LogWarn("UtilityInventory", "OpenLodgeSafe returned false.")
		ShowMessage(PWAL_MSG_Utilities_Unavailable)
	EndIf
EndFunction

Function RunOpenPandaWorksInventory()
	If CommandServices == None
		LogError("UtilityInventory", "RunOpenPandaWorksInventory failed: CommandServices property is not filled.")
		ShowMessage(PWAL_MSG_Utilities_Unavailable)
		Return
	EndIf

	Bool bSuccess = CommandServices.OpenPandaWorksInventory()

	If !bSuccess
		LogWarn("UtilityInventory", "OpenPandaWorksInventory returned false.")
		ShowMessage(PWAL_MSG_Utilities_Unavailable)
	EndIf
EndFunction

Function RunOpenShipCargo()
	If CommandServices == None
		LogError("UtilityInventory", "RunOpenShipCargo failed: CommandServices property is not filled.")
		ShowMessage(PWAL_MSG_Utilities_Unavailable)
		Return
	EndIf

	Bool bSuccess = CommandServices.OpenShipCargo()

	If !bSuccess
		LogWarn("UtilityInventory", "OpenShipCargo returned false.")
		ShowMessage(PWAL_MSG_Utilities_Unavailable)
	EndIf
EndFunction

; ==============================================================
; Utility Helpers
; ==============================================================

Function ShowMessage(Message akMessage)
	If akMessage != None
		akMessage.Show()
	EndIf
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
