ScriptName PWAL:System:CommandServicesScript Extends Quest Hidden

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.00
; Created: 04-10-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: CommandServicesScript
; Type: System / Command Service
; Purpose:
;   Central backend service for PWAL player-facing commands.
;   Provides a stable command API for terminal input scripts,
;   aid-device input scripts, and the Daemon hotkey bridge.
;
; Responsibilities:
;   - Open configured PWAL inventory destinations
;   - Toggle global looting state
;   - Execute known transfer commands
;   - Validate runtime references before use
;   - Keep input scripts and hotkey wrappers thin
;
; Non-Responsibilities:
;   - No CGF wrapper implementation
;   - No terminal token handling
;   - No loot scanning
;   - No loot classification
;   - No destination code resolution
;   - No install/update logic
; ==============================================================

; ==============================================================
; Properties
; ==============================================================

Group FrameworkServices
	PWAL:Core:LoggerScript Property Logger Auto Const
EndGroup

Group WorldState_References
	ObjectReference Property PlayerRef Auto Const Mandatory
	ObjectReference Property LodgeSafeRef Auto Const Mandatory
	ObjectReference Property PWAL_INV_REF Auto Const Mandatory
	ReferenceAlias Property PlayerHomeShip Auto Const Mandatory
EndGroup

Group Terminal_References
	ObjectReference Property PWAL_TERM_REF Auto Const
EndGroup

Group UtilityGlobals_AutoFill
	GlobalVariable Property PWAL_GLOB_Utilities_Toggle_Looting Auto Const Mandatory
EndGroup

Group TransferLists_Optional
	FormList Property PWAL_FLST_Script_Resources Auto Const
	FormList Property PWAL_FLST_Script_Valuables Auto Const
EndGroup

; ==============================================================
; Public Command API
; ==============================================================

Bool Function OpenTerminal()
	LogDebug("CommandServices", "OpenTerminal requested.")

	ObjectReference akPlayerRef = GetPlayerRef()

	If akPlayerRef == None
		LogError("CommandServices", "OpenTerminal failed: no player ref available.")
		Return false
	EndIf

	If PWAL_TERM_REF == None
		LogWarn("CommandServices", "OpenTerminal failed: PWAL_TERM_REF property is not filled.")
		Return false
	EndIf

	PWAL_TERM_REF.Activate(akPlayerRef, false)
	Return true
EndFunction

Bool Function ToggleLooting()
	LogDebug("CommandServices", "ToggleLooting requested.")

	If PWAL_GLOB_Utilities_Toggle_Looting == None
		LogError("CommandServices", "ToggleLooting failed: PWAL_GLOB_Utilities_Toggle_Looting property is not filled.")
		Return false
	EndIf

	If PWAL_GLOB_Utilities_Toggle_Looting.GetValueInt() > 0
		PWAL_GLOB_Utilities_Toggle_Looting.SetValueInt(0)
	Else
		PWAL_GLOB_Utilities_Toggle_Looting.SetValueInt(1)
	EndIf

	LogDebug("CommandServices", "Looting toggle is now " + (PWAL_GLOB_Utilities_Toggle_Looting.GetValueInt() as String))
	Return true
EndFunction

Bool Function OpenPandaWorksInventory()
	LogDebug("CommandServices", "OpenPandaWorksInventory requested.")

	If PWAL_INV_REF == None
		LogError("CommandServices", "OpenPandaWorksInventory failed: PWAL_INV_REF property is not filled.")
		Return false
	EndIf

	Actor akInventoryActor = PWAL_INV_REF as Actor

	If akInventoryActor != None
		akInventoryActor.OpenInventory(true, None, false)
		Return true
	EndIf

	ObjectReference akPlayerRef = GetPlayerRef()

	If akPlayerRef == None
		LogError("CommandServices", "OpenPandaWorksInventory failed: no player ref available.")
		Return false
	EndIf

	PWAL_INV_REF.Activate(akPlayerRef, false)
	Return true
EndFunction

Bool Function OpenLodgeSafe()
	LogDebug("CommandServices", "OpenLodgeSafe requested.")

	ObjectReference akPlayerRef = GetPlayerRef()

	If akPlayerRef == None
		LogError("CommandServices", "OpenLodgeSafe failed: no player ref available.")
		Return false
	EndIf

	If LodgeSafeRef == None
		LogError("CommandServices", "OpenLodgeSafe failed: LodgeSafeRef property is not filled.")
		Return false
	EndIf

	LodgeSafeRef.Activate(akPlayerRef, false)
	Return true
EndFunction

Bool Function OpenShipCargo()
	LogDebug("CommandServices", "OpenShipCargo requested.")

	ObjectReference akShipRef = GetPlayerHomeShipRef()

	If akShipRef == None
		LogWarn("CommandServices", "OpenShipCargo failed: PlayerHomeShip alias is unavailable.")
		Return false
	EndIf

	SpaceshipReference akShipRefTyped = akShipRef as SpaceshipReference

	If akShipRefTyped == None
		LogWarn("CommandServices", "OpenShipCargo failed: PlayerHomeShip ref is not a SpaceshipReference.")
		Return false
	EndIf

	akShipRefTyped.OpenInventory()
	Return true
EndFunction

; ==============================================================
; Public Transfer API
; ==============================================================

Bool Function TransferPandaWorksToShip()
	LogDebug("CommandServices", "TransferPandaWorksToShip requested.")

	ObjectReference akShipRef = GetPlayerHomeShipRef()

	If akShipRef == None
		LogWarn("CommandServices", "TransferPandaWorksToShip failed: ship is unavailable.")
		Return false
	EndIf

	Return TransferAllItems(PWAL_INV_REF, akShipRef, "PandaWorksInventory", "ShipCargo")
EndFunction

Bool Function TransferResourcesToShip()
	LogDebug("CommandServices", "TransferResourcesToShip requested.")

	ObjectReference akShipRef = GetPlayerHomeShipRef()

	If akShipRef == None
		LogWarn("CommandServices", "TransferResourcesToShip failed: ship is unavailable.")
		Return false
	EndIf

	Return TransferFormListItems(PWAL_INV_REF, akShipRef, PWAL_FLST_Script_Resources, "PandaWorksInventory", "ShipCargo", "Resources")
EndFunction

Bool Function TransferPandaWorksToLodgeSafe()
	LogDebug("CommandServices", "TransferPandaWorksToLodgeSafe requested.")

	Return TransferAllItems(PWAL_INV_REF, LodgeSafeRef, "PandaWorksInventory", "LodgeSafe")
EndFunction

Bool Function TransferValuablesToPlayer()
	LogDebug("CommandServices", "TransferValuablesToPlayer requested.")

	ObjectReference akPlayerRef = GetPlayerRef()

	If akPlayerRef == None
		LogError("CommandServices", "TransferValuablesToPlayer failed: no player ref available.")
		Return false
	EndIf

	Bool bMovedAnything = false

	If TransferFormListItems(PWAL_INV_REF, akPlayerRef, PWAL_FLST_Script_Valuables, "PandaWorksInventory", "Player", "Valuables")
		bMovedAnything = true
	EndIf

	ObjectReference akShipRef = GetPlayerHomeShipRef()

	If TransferFormListItems(akShipRef, akPlayerRef, PWAL_FLST_Script_Valuables, "ShipCargo", "Player", "Valuables")
		bMovedAnything = true
	EndIf

	Return bMovedAnything
EndFunction

Bool Function TransferShipToPandaWorks()
	LogDebug("CommandServices", "TransferShipToPandaWorks requested.")

	ObjectReference akShipRef = GetPlayerHomeShipRef()

	If akShipRef == None
		LogWarn("CommandServices", "TransferShipToPandaWorks failed: ship is unavailable.")
		Return false
	EndIf

	Return TransferAllItems(akShipRef, PWAL_INV_REF, "ShipCargo", "PandaWorksInventory")
EndFunction

; ==============================================================
; Transfer Helpers
; ==============================================================

Bool Function TransferAllItems(ObjectReference akSourceRef, ObjectReference akDestinationRef, String asSourceLabel, String asDestinationLabel)
	If akSourceRef == None
		LogWarn("CommandServices", "TransferAllItems failed: source ref is None for " + asSourceLabel)
		Return false
	EndIf

	If akDestinationRef == None
		LogWarn("CommandServices", "TransferAllItems failed: destination ref is None for " + asDestinationLabel)
		Return false
	EndIf

	If akSourceRef == akDestinationRef
		LogWarn("CommandServices", "TransferAllItems skipped: source and destination are the same ref.")
		Return false
	EndIf

	akSourceRef.RemoveAllItems(akDestinationRef, true, true)

	LogDebug("CommandServices", "TransferAllItems complete: " + asSourceLabel + " -> " + asDestinationLabel)
	Return true
EndFunction

Bool Function TransferFormListItems(ObjectReference akSourceRef, ObjectReference akDestinationRef, FormList akTransferList, String asSourceLabel, String asDestinationLabel, String asTransferLabel)
	If akSourceRef == None
		LogWarn("CommandServices", "TransferFormListItems failed: source ref is None for " + asSourceLabel)
		Return false
	EndIf

	If akDestinationRef == None
		LogWarn("CommandServices", "TransferFormListItems failed: destination ref is None for " + asDestinationLabel)
		Return false
	EndIf

	If akSourceRef == akDestinationRef
		LogWarn("CommandServices", "TransferFormListItems skipped: source and destination are the same ref.")
		Return false
	EndIf

	If akTransferList == None
		LogWarn("CommandServices", "TransferFormListItems failed: transfer list is None for " + asTransferLabel)
		Return false
	EndIf

	If akTransferList.GetSize() <= 0
		LogWarn("CommandServices", "TransferFormListItems failed: transfer list is empty for " + asTransferLabel)
		Return false
	EndIf

	akSourceRef.RemoveItem(akTransferList as Form, -1, true, akDestinationRef)

	LogDebug("CommandServices", "TransferFormListItems complete: " + asTransferLabel + " | " + asSourceLabel + " -> " + asDestinationLabel)
	Return true
EndFunction

; ==============================================================
; Legacy Compatibility Aliases
; ==============================================================

Bool Function MoveAllToShip()
	Return TransferPandaWorksToShip()
EndFunction

Bool Function MoveResourcesToShip()
	Return TransferResourcesToShip()
EndFunction

Bool Function MoveInventoryToLodgeSafe()
	Return TransferPandaWorksToLodgeSafe()
EndFunction

Bool Function MoveValuablesToPlayer()
	Return TransferValuablesToPlayer()
EndFunction

Bool Function MoveAllFromShipToPandaWorks()
	Return TransferShipToPandaWorks()
EndFunction

; ==============================================================
; Reference Helpers
; ==============================================================

ObjectReference Function GetPlayerRef()
	If PlayerRef != None
		Return PlayerRef
	EndIf

	Return Game.GetPlayer()
EndFunction

ObjectReference Function GetPlayerHomeShipRef()
	If PlayerHomeShip == None
		Return None
	EndIf

	Return PlayerHomeShip.GetRef()
EndFunction

Bool Function HasPlayerHomeShip()
	Return GetPlayerHomeShipRef() != None
EndFunction

Bool Function HasLodgeSafe()
	Return LodgeSafeRef != None
EndFunction

Bool Function HasPandaWorksInventory()
	Return PWAL_INV_REF != None
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