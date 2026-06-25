ScriptName PWAL:Looting:SpaceCargoProcessorScript Extends Quest

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.0.0
; Created: 06-15-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: SpaceCargoProcessorScript
; Type: Looting / Processor Service
; Purpose:
;   Transfers generated space cargo inventory refs.
;
; Responsibilities:
;   - Accept generated space cargo inventory refs
;   - Accept the player ship cargo transfer target
;   - Transfer the full cargo inventory
;   - Report transfer diagnostics
;
; Non-Responsibilities:
;   - No scanning
;   - No validation
;   - No normal container processing
;   - No category filtering
;   - No destination resolution
; ==============================================================

; ==============================================================
; Properties
; ==============================================================

Group FrameworkServices
	PWAL:Core:LoggerScript Property Logger Auto
EndGroup

; ==============================================================
; Public API
; ==============================================================

Bool Function ProcessSpaceCargo(ObjectReference akCargo, ObjectReference akPlayerShipCargoTarget)
	Int iItemCountBefore
	Int iItemCountAfter
	Bool bResult

	If akCargo == None
		LogWarn("SpaceCargoProcessor", "ProcessSpaceCargo failed: akCargo is None.")
		Return false
	EndIf

	If akPlayerShipCargoTarget == None
		LogWarn("SpaceCargoProcessor", "ProcessSpaceCargo failed: akPlayerShipCargoTarget is None.")
		Return false
	EndIf

	iItemCountBefore = akCargo.GetItemCount()
	If iItemCountBefore <= 0
		LogDebug("SpaceCargoProcessor", "ProcessSpaceCargo deferred: source has no items yet. source=" + akCargo)
		Return false
	EndIf

	LogDebug("SpaceCargoProcessor", "Transfer begin: source=" + akCargo + " destination=" + akPlayerShipCargoTarget + " before=" + (iItemCountBefore as String))

	akCargo.RemoveAllItems(akPlayerShipCargoTarget, false, false)

	iItemCountAfter = akCargo.GetItemCount()
	LogDebug("SpaceCargoProcessor", "Transfer complete: source=" + akCargo + " destination=" + akPlayerShipCargoTarget + " before=" + (iItemCountBefore as String) + " after=" + (iItemCountAfter as String))

	bResult = iItemCountAfter <= 0
	Return bResult
EndFunction

; ==============================================================
; Internal Logging Wrappers
; ==============================================================

Function LogWarn(String asSource, String asMessage)
	If Logger
		Logger.Warn(asSource, asMessage)
	EndIf
EndFunction

Function LogError(String asSource, String asMessage)
	If Logger
		Logger.Error(asSource, asMessage)
	EndIf
EndFunction

Function LogDebug(String asSource, String asMessage)
	If Logger
		Logger.DebugLog(asSource, asMessage)
	EndIf
EndFunction
