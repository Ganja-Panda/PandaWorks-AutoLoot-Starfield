ScriptName PWAL:System:CommandServicesScript Extends Quest Hidden

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.0.1
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
	PWAL:Core:RuntimeManagerScript Property RuntimeManager Auto Const
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
	GlobalVariable Property PWAL_GLOB_Utilities_Toggle_Logging Auto Const Mandatory
EndGroup

Group TransferLists_Optional
	FormList Property PWAL_FLST_Script_Resources Auto Const
	FormList Property PWAL_FLST_Script_Valuables Auto Const
EndGroup

Group CommandMessages
	Message Property PWAL_MSG_Looting_Enabled Auto Const
	Message Property PWAL_MSG_Looting_Disabled Auto Const
	Message Property PWAL_MSG_Logging_Enabled Auto Const
	Message Property PWAL_MSG_Logging_Disabled Auto Const
	Message Property PWAL_MSG_Utilities_MoveItemsToShip Auto Const
	Message Property PWAL_MSG_Utilities_MoveItemsToLodge Auto Const
	Message Property PWAL_MSG_Utilities_MoveItemsToPandaWorks Auto Const
	Message Property PWAL_MSG_ResourcesToShip Auto Const
	Message Property PWAL_MSG_ValuablesToPlayer Auto Const
	Message Property PWAL_MSG_Utilities_NoItems Auto Const
	Message Property PWAL_MSG_Utilities_Unavailable Auto Const
EndGroup

Bool bLoggedMissingRuntimeManager

; ==============================================================
; Static Accessor
; ==============================================================

PWAL:System:CommandServicesScript Function GetScript() Global
	Quest akQuest = Game.GetFormFromFile(0x040009E1, "PandaWorks AutoLoot.esm") as Quest
	Return akQuest as PWAL:System:CommandServicesScript
EndFunction

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

	If !CanRunCommand("ToggleLooting")
		Return false
	EndIf

	If PWAL_GLOB_Utilities_Toggle_Looting == None
		LogError("CommandServices", "ToggleLooting failed: PWAL_GLOB_Utilities_Toggle_Looting property is not filled.")
		ShowCommandMessage(PWAL_MSG_Utilities_Unavailable, "ToggleLooting unavailable: looting toggle message property is not filled.")
		Return false
	EndIf

	If PWAL_GLOB_Utilities_Toggle_Looting.GetValueInt() > 0
		PWAL_GLOB_Utilities_Toggle_Looting.SetValueInt(0)
		ShowCommandMessage(PWAL_MSG_Looting_Disabled, "Looting disabled.")
	Else
		PWAL_GLOB_Utilities_Toggle_Looting.SetValueInt(1)
		ShowCommandMessage(PWAL_MSG_Looting_Enabled, "Looting enabled.")
	EndIf

	LogDebug("CommandServices", "Looting toggle is now " + (PWAL_GLOB_Utilities_Toggle_Looting.GetValueInt() as String))
	Return true
EndFunction

Bool Function ToggleLogging()
	LogDebug("CommandServices", "ToggleLogging requested.")

	If PWAL_GLOB_Utilities_Toggle_Logging == None
		LogError("CommandServices", "ToggleLogging failed: PWAL_GLOB_Utilities_Toggle_Logging property is not filled.")
		ShowCommandMessage(PWAL_MSG_Utilities_Unavailable, "ToggleLogging unavailable: logging toggle message property is not filled.")
		Return false
	EndIf

	If PWAL_GLOB_Utilities_Toggle_Logging.GetValueInt() > 0
		PWAL_GLOB_Utilities_Toggle_Logging.SetValueInt(0)
		ShowCommandMessage(PWAL_MSG_Logging_Disabled, "Logging disabled.")
	Else
		PWAL_GLOB_Utilities_Toggle_Logging.SetValueInt(1)
		ShowCommandMessage(PWAL_MSG_Logging_Enabled, "Logging enabled.")
	EndIf

	LogDebug("CommandServices", "Logging toggle is now " + (PWAL_GLOB_Utilities_Toggle_Logging.GetValueInt() as String))
	Return true
EndFunction

Bool Function OpenPandaWorksInventory()
	LogDebug("CommandServices", "OpenPandaWorksInventory requested.")

	If !CanRunCommand("OpenPandaWorksInventory")
		Return false
	EndIf

	If PWAL_INV_REF == None
		LogError("CommandServices", "OpenPandaWorksInventory failed: PWAL_INV_REF property is not filled.")
		ShowCommandMessage(PWAL_MSG_Utilities_Unavailable, "OpenPandaWorksInventory unavailable: PWAL_INV_REF property is not filled.")
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
		ShowCommandMessage(PWAL_MSG_Utilities_Unavailable, "OpenPandaWorksInventory unavailable: no player ref available.")
		Return false
	EndIf

	PWAL_INV_REF.Activate(akPlayerRef, false)
	Return true
EndFunction

Bool Function OpenLodgeSafe()
	LogDebug("CommandServices", "OpenLodgeSafe requested.")

	If !CanRunCommand("OpenLodgeSafe")
		Return false
	EndIf

	ObjectReference akPlayerRef = GetPlayerRef()

	If akPlayerRef == None
		LogError("CommandServices", "OpenLodgeSafe failed: no player ref available.")
		ShowCommandMessage(PWAL_MSG_Utilities_Unavailable, "OpenLodgeSafe unavailable: no player ref available.")
		Return false
	EndIf

	If LodgeSafeRef == None
		LogError("CommandServices", "OpenLodgeSafe failed: LodgeSafeRef property is not filled.")
		ShowCommandMessage(PWAL_MSG_Utilities_Unavailable, "OpenLodgeSafe unavailable: LodgeSafeRef property is not filled.")
		Return false
	EndIf

	LodgeSafeRef.Activate(akPlayerRef, false)
	Return true
EndFunction

Bool Function OpenShipCargo()
	LogDebug("CommandServices", "OpenShipCargo requested.")

	If !CanRunCommand("OpenShipCargo")
		Return false
	EndIf

	ObjectReference akShipRef = GetPlayerHomeShipRef()

	If akShipRef == None
		LogWarn("CommandServices", "OpenShipCargo failed: PlayerHomeShip alias is unavailable.")
		ShowCommandMessage(PWAL_MSG_Utilities_Unavailable, "OpenShipCargo unavailable: PlayerHomeShip alias is unavailable.")
		Return false
	EndIf

	SpaceshipReference akShipRefTyped = akShipRef as SpaceshipReference

	If akShipRefTyped == None
		LogWarn("CommandServices", "OpenShipCargo failed: PlayerHomeShip ref is not a SpaceshipReference.")
		ShowCommandMessage(PWAL_MSG_Utilities_Unavailable, "OpenShipCargo unavailable: PlayerHomeShip ref is not a SpaceshipReference.")
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
	Bool bResult

	If !CanRunCommand("TransferPandaWorksToShip")
		Return false
	EndIf

	ObjectReference akShipRef = GetPlayerHomeShipRef()

	If akShipRef == None
		LogWarn("CommandServices", "TransferPandaWorksToShip failed: ship is unavailable.")
		ShowCommandMessage(PWAL_MSG_Utilities_Unavailable, "TransferPandaWorksToShip unavailable: ship is unavailable.")
		Return false
	EndIf

	If PWAL_INV_REF == None
		LogWarn("CommandServices", "TransferPandaWorksToShip failed: PandaWorks inventory is unavailable.")
		ShowCommandMessage(PWAL_MSG_Utilities_Unavailable, "TransferPandaWorksToShip unavailable: PandaWorks inventory is unavailable.")
		Return false
	EndIf

	If PWAL_INV_REF.GetItemCount() <= 0
		ShowCommandMessage(PWAL_MSG_Utilities_NoItems, "TransferPandaWorksToShip skipped: PandaWorks inventory is empty.")
		Return false
	EndIf

	bResult = TransferAllItems(PWAL_INV_REF, akShipRef, "PandaWorksInventory", "ShipCargo")
	If bResult
		ShowCommandMessage(PWAL_MSG_Utilities_MoveItemsToShip, "TransferPandaWorksToShip completed.")
	Else
		ShowCommandMessage(PWAL_MSG_Utilities_Unavailable, "TransferPandaWorksToShip unavailable.")
	EndIf

	Return bResult
EndFunction

Bool Function TransferResourcesToShip()
	LogDebug("CommandServices", "TransferResourcesToShip requested.")
	Bool bResult

	If !CanRunCommand("TransferResourcesToShip")
		Return false
	EndIf

	ObjectReference akShipRef = GetPlayerHomeShipRef()

	If akShipRef == None
		LogWarn("CommandServices", "TransferResourcesToShip failed: ship is unavailable.")
		ShowCommandMessage(PWAL_MSG_Utilities_Unavailable, "TransferResourcesToShip unavailable: ship is unavailable.")
		Return false
	EndIf

	If PWAL_INV_REF == None
		LogWarn("CommandServices", "TransferResourcesToShip failed: PandaWorks inventory is unavailable.")
		ShowCommandMessage(PWAL_MSG_Utilities_Unavailable, "TransferResourcesToShip unavailable: PandaWorks inventory is unavailable.")
		Return false
	EndIf

	If PWAL_FLST_Script_Resources == None
		LogWarn("CommandServices", "TransferResourcesToShip failed: resources transfer list is unavailable.")
		ShowCommandMessage(PWAL_MSG_Utilities_Unavailable, "TransferResourcesToShip unavailable: resources transfer list is unavailable.")
		Return false
	EndIf

	If PWAL_INV_REF.GetItemCount(PWAL_FLST_Script_Resources as Form) <= 0
		ShowCommandMessage(PWAL_MSG_Utilities_NoItems, "TransferResourcesToShip skipped: no resources available.")
		Return false
	EndIf

	bResult = TransferFormListItems(PWAL_INV_REF, akShipRef, PWAL_FLST_Script_Resources, "PandaWorksInventory", "ShipCargo", "Resources")
	If bResult
		ShowCommandMessage(PWAL_MSG_ResourcesToShip, "TransferResourcesToShip completed.")
	Else
		ShowCommandMessage(PWAL_MSG_Utilities_Unavailable, "TransferResourcesToShip unavailable.")
	EndIf

	Return bResult
EndFunction

Bool Function TransferPandaWorksToLodgeSafe()
	LogDebug("CommandServices", "TransferPandaWorksToLodgeSafe requested.")
	Bool bResult

	If !CanRunCommand("TransferPandaWorksToLodgeSafe")
		Return false
	EndIf

	If PWAL_INV_REF == None
		LogWarn("CommandServices", "TransferPandaWorksToLodgeSafe failed: PandaWorks inventory is unavailable.")
		ShowCommandMessage(PWAL_MSG_Utilities_Unavailable, "TransferPandaWorksToLodgeSafe unavailable: PandaWorks inventory is unavailable.")
		Return false
	EndIf

	If LodgeSafeRef == None
		LogWarn("CommandServices", "TransferPandaWorksToLodgeSafe failed: Lodge Safe is unavailable.")
		ShowCommandMessage(PWAL_MSG_Utilities_Unavailable, "TransferPandaWorksToLodgeSafe unavailable: Lodge Safe is unavailable.")
		Return false
	EndIf

	If PWAL_INV_REF.GetItemCount() <= 0
		ShowCommandMessage(PWAL_MSG_Utilities_NoItems, "TransferPandaWorksToLodgeSafe skipped: PandaWorks inventory is empty.")
		Return false
	EndIf

	bResult = TransferAllItems(PWAL_INV_REF, LodgeSafeRef, "PandaWorksInventory", "LodgeSafe")
	If bResult
		ShowCommandMessage(PWAL_MSG_Utilities_MoveItemsToLodge, "TransferPandaWorksToLodgeSafe completed.")
	Else
		ShowCommandMessage(PWAL_MSG_Utilities_Unavailable, "TransferPandaWorksToLodgeSafe unavailable.")
	EndIf

	Return bResult
EndFunction

Bool Function TransferValuablesToPlayer()
	LogDebug("CommandServices", "TransferValuablesToPlayer requested.")

	If !CanRunCommand("TransferValuablesToPlayer")
		Return false
	EndIf

	ObjectReference akPlayerRef = GetPlayerRef()

	If akPlayerRef == None
		LogError("CommandServices", "TransferValuablesToPlayer failed: no player ref available.")
		ShowCommandMessage(PWAL_MSG_Utilities_Unavailable, "TransferValuablesToPlayer unavailable: no player ref available.")
		Return false
	EndIf

	If PWAL_FLST_Script_Valuables == None
		LogWarn("CommandServices", "TransferValuablesToPlayer failed: valuables transfer list is unavailable.")
		ShowCommandMessage(PWAL_MSG_Utilities_Unavailable, "TransferValuablesToPlayer unavailable: valuables transfer list is unavailable.")
		Return false
	EndIf

	Bool bMovedAnything = false
	ObjectReference akShipRef = GetPlayerHomeShipRef()
	Bool bHasPandaWorksValuables = false
	Bool bHasShipValuables = false

	If PWAL_INV_REF != None
		bHasPandaWorksValuables = PWAL_INV_REF.GetItemCount(PWAL_FLST_Script_Valuables as Form) > 0
	EndIf

	If akShipRef != None
		bHasShipValuables = akShipRef.GetItemCount(PWAL_FLST_Script_Valuables as Form) > 0
	EndIf

	If !bHasPandaWorksValuables && !bHasShipValuables
		ShowCommandMessage(PWAL_MSG_Utilities_NoItems, "TransferValuablesToPlayer skipped: no valuables available.")
		Return false
	EndIf

	If TransferFormListItems(PWAL_INV_REF, akPlayerRef, PWAL_FLST_Script_Valuables, "PandaWorksInventory", "Player", "Valuables")
		bMovedAnything = true
	EndIf

	If TransferFormListItems(akShipRef, akPlayerRef, PWAL_FLST_Script_Valuables, "ShipCargo", "Player", "Valuables")
		bMovedAnything = true
	EndIf

	If bMovedAnything
		ShowCommandMessage(PWAL_MSG_ValuablesToPlayer, "TransferValuablesToPlayer completed.")
	Else
		ShowCommandMessage(PWAL_MSG_Utilities_Unavailable, "TransferValuablesToPlayer unavailable.")
	EndIf

	Return bMovedAnything
EndFunction

Bool Function TransferShipToPandaWorks()
	LogDebug("CommandServices", "TransferShipToPandaWorks requested.")
	Bool bResult

	If !CanRunCommand("TransferShipToPandaWorks")
		Return false
	EndIf

	ObjectReference akShipRef = GetPlayerHomeShipRef()

	If akShipRef == None
		LogWarn("CommandServices", "TransferShipToPandaWorks failed: ship is unavailable.")
		ShowCommandMessage(PWAL_MSG_Utilities_Unavailable, "TransferShipToPandaWorks unavailable: ship is unavailable.")
		Return false
	EndIf

	If PWAL_INV_REF == None
		LogWarn("CommandServices", "TransferShipToPandaWorks failed: PandaWorks inventory is unavailable.")
		ShowCommandMessage(PWAL_MSG_Utilities_Unavailable, "TransferShipToPandaWorks unavailable: PandaWorks inventory is unavailable.")
		Return false
	EndIf

	If akShipRef.GetItemCount() <= 0
		ShowCommandMessage(PWAL_MSG_Utilities_NoItems, "TransferShipToPandaWorks skipped: ship cargo is empty.")
		Return false
	EndIf

	bResult = TransferAllItems(akShipRef, PWAL_INV_REF, "ShipCargo", "PandaWorksInventory")
	If bResult
		ShowCommandMessage(PWAL_MSG_Utilities_MoveItemsToPandaWorks, "TransferShipToPandaWorks completed.")
	Else
		ShowCommandMessage(PWAL_MSG_Utilities_Unavailable, "TransferShipToPandaWorks unavailable.")
	EndIf

	Return bResult
EndFunction

; ==============================================================
; Transfer Helpers
; ==============================================================

Bool Function TransferAllItems(ObjectReference akSourceRef, ObjectReference akDestinationRef, String asSourceLabel, String asDestinationLabel)
	Int iItemCountBefore
	Int iItemCountAfter

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

	iItemCountBefore = akSourceRef.GetItemCount()
	If iItemCountBefore <= 0
		LogDebug("CommandServices", "TransferAllItems skipped: source is empty for " + asSourceLabel)
		Return false
	EndIf

	; abKeepOwnership = false, abRemoveQuestItems = true
	akSourceRef.RemoveAllItems(akDestinationRef, false, true)

	iItemCountAfter = akSourceRef.GetItemCount()
	If iItemCountAfter < iItemCountBefore
		LogDebug("CommandServices", "TransferAllItems complete: " + asSourceLabel + " -> " + asDestinationLabel)
		Return true
	EndIf

	LogWarn("CommandServices", "TransferAllItems failed: source count did not decrease for " + asSourceLabel)
	Return false
EndFunction

Bool Function TransferFormListItems(ObjectReference akSourceRef, ObjectReference akDestinationRef, FormList akTransferList, String asSourceLabel, String asDestinationLabel, String asTransferLabel)
	Form akTransferForm
	Int iItemCountBefore
	Int iItemCountAfter

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

	akTransferForm = akTransferList as Form
	If akTransferForm == None
		LogWarn("CommandServices", "TransferFormListItems failed: transfer list is not a Form for " + asTransferLabel)
		Return false
	EndIf

	iItemCountBefore = akSourceRef.GetItemCount(akTransferForm)
	If iItemCountBefore <= 0
		LogDebug("CommandServices", "TransferFormListItems skipped: no matching items for " + asTransferLabel)
		Return false
	EndIf

	akSourceRef.RemoveItem(akTransferForm, -1, true, akDestinationRef)

	iItemCountAfter = akSourceRef.GetItemCount(akTransferForm)
	If iItemCountAfter < iItemCountBefore
		LogDebug("CommandServices", "TransferFormListItems complete: " + asTransferLabel + " | " + asSourceLabel + " -> " + asDestinationLabel)
		Return true
	EndIf

	LogWarn("CommandServices", "TransferFormListItems failed: source count did not decrease for " + asTransferLabel)
	Return false
EndFunction

; ==============================================================
; PandaWorks Public Command Aliases
; ==============================================================

Bool Function OpenPandaWorks()
	Return OpenPandaWorksInventory()
EndFunction

Bool Function SendPandaWorksToShip()
	Return TransferPandaWorksToShip()
EndFunction

Bool Function SendResourcesToShip()
	Return TransferResourcesToShip()
EndFunction

Bool Function SendPandaWorksToLodge()
	Return TransferPandaWorksToLodgeSafe()
EndFunction

Bool Function SendValuablesToPlayer()
	Return TransferValuablesToPlayer()
EndFunction

Bool Function SendCargoHoldToPandaWorks()
	Return TransferShipToPandaWorks()
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

Bool Function CanRunCommand(String asCommandName)
	If RuntimeManager == None
		If !bLoggedMissingRuntimeManager
			LogWarn("CommandServices", asCommandName + " allowed without RuntimeManager gate.")
			bLoggedMissingRuntimeManager = true
		EndIf

		Return true
	EndIf

	bLoggedMissingRuntimeManager = false

	If !RuntimeManager.CanRunLooting()
		LogWarn("CommandServices", asCommandName + " blocked: runtime is not ready.")
		ShowCommandMessage(PWAL_MSG_Utilities_Unavailable, asCommandName + " unavailable: runtime is not ready.")
		Return false
	EndIf

	Return true
EndFunction

Function ShowCommandMessage(Message akMessage, String asFallbackLog)
	If akMessage != None
		akMessage.Show()
	Else
		LogWarn("CommandServices", asFallbackLog)
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
