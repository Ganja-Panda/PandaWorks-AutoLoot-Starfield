ScriptName PWAL:Input:UtilityTransferMenuScript Extends TerminalMenu Hidden

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.00
; Created: 04-10-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: UtilityTransferMenuScript
; Type: Input / Terminal Menu Controller
; Purpose:
;   Handles the PWAL Utilities Transfer terminal submenu.
;   Routes player-selected transfer commands into the framework
;   command/service layer.
;
; Responsibilities:
;   - Route All to Ship transfer action
;   - Route PandaWorks to Lodge Safe transfer action
;   - Route Valuables to Player transfer action
;   - Route optional Resources to Ship transfer action
;   - Show success/failure utility messages when available
;   - Ignore unmapped menu rows safely
;
; Non-Responsibilities:
;   - No direct inventory transfer implementation
;   - No loot scanning
;   - No destination resolving
;   - No install/update logic
;   - No terminal token management
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

Group UtilityMessages
	Message Property PWAL_MSG_Utilities_MoveItemsToShip Auto Const
	Message Property PWAL_MSG_Utilities_MoveItemsToLodge Auto Const
	Message Property PWAL_MSG_ValuablesToPlayer Auto Const
	Message Property PWAL_MSG_ResourcesToShip Auto Const
	Message Property PWAL_MSG_Utilities_NoItems Auto Const
	Message Property PWAL_MSG_Utilities_Unavailable Auto Const
EndGroup

; ==============================================================
; Events
; ==============================================================

Event OnTerminalMenuItemRun(Int auiMenuItemID, TerminalMenu akTerminalBase, ObjectReference akTerminalRef)
	If akTerminalBase != CurrentTerminalMenu
		Return
	EndIf

	If CommandServices == None
		LogError("UtilityTransferMenu", "OnTerminalMenuItemRun failed: CommandServices property is not filled.")
		ShowMessage(PWAL_MSG_Utilities_Unavailable)
		Return
	EndIf

	If auiMenuItemID == 0
		RunMoveAllToShip()
	ElseIf auiMenuItemID == 1
		RunMovePandaWorksToLodgeSafe()
	ElseIf auiMenuItemID == 2
		RunMoveValuablesToPlayer()
	ElseIf auiMenuItemID == 3
		RunMoveResourcesToShip()
	Else
		LogDebug("UtilityTransferMenu", "Ignoring unmapped menu item ID: " + (auiMenuItemID as String))
	EndIf
EndEvent

; ==============================================================
; Core Execution
; ==============================================================

Function RunMoveAllToShip()
	LogDebug("UtilityTransferMenu", "RunMoveAllToShip triggered.")

	Bool bMovedAnything = CommandServices.TransferPandaWorksToShip()

	If bMovedAnything
		ShowMessage(PWAL_MSG_Utilities_MoveItemsToShip)
	Else
		ShowMessage(PWAL_MSG_Utilities_NoItems)
	EndIf
EndFunction

Function RunMovePandaWorksToLodgeSafe()
	LogDebug("UtilityTransferMenu", "RunMovePandaWorksToLodgeSafe triggered.")

	Bool bMovedAnything = CommandServices.TransferPandaWorksToLodgeSafe()

	If bMovedAnything
		ShowMessage(PWAL_MSG_Utilities_MoveItemsToLodge)
	Else
		ShowMessage(PWAL_MSG_Utilities_NoItems)
	EndIf
EndFunction

Function RunMoveValuablesToPlayer()
	LogDebug("UtilityTransferMenu", "RunMoveValuablesToPlayer triggered.")

	Bool bMovedAnything = CommandServices.TransferValuablesToPlayer()

	If bMovedAnything
		ShowMessage(PWAL_MSG_ValuablesToPlayer)
	Else
		ShowMessage(PWAL_MSG_Utilities_NoItems)
	EndIf
EndFunction

Function RunMoveResourcesToShip()
	LogDebug("UtilityTransferMenu", "RunMoveResourcesToShip triggered.")

	Bool bMovedAnything = CommandServices.TransferResourcesToShip()

	If bMovedAnything
		ShowMessage(PWAL_MSG_ResourcesToShip)
	Else
		ShowMessage(PWAL_MSG_Utilities_NoItems)
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