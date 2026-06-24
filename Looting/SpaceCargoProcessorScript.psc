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

	Debug.Trace("[PWAL_SPACE_CARGO] SpaceCargoProcessor ProcessSpaceCargo entered")
	Debug.Trace("[PWAL_SPACE_CARGO] SpaceCargoProcessor source ref: source=" + akCargo)
	Debug.Trace("[PWAL_SPACE_CARGO] SpaceCargoProcessor player ship cargo target: target=" + akPlayerShipCargoTarget)

	If akCargo == None
		LogWarn("SpaceCargoProcessor", "ProcessSpaceCargo failed: akCargo is None.")
		Debug.Trace("[PWAL_SPACE_CARGO] SpaceCargoProcessor return false reason: source ref is None")
		Return false
	EndIf

	If akPlayerShipCargoTarget == None
		LogWarn("SpaceCargoProcessor", "ProcessSpaceCargo failed: akPlayerShipCargoTarget is None.")
		Debug.Trace("[PWAL_SPACE_CARGO] SpaceCargoProcessor return false reason: player ship cargo target is None")
		Return false
	EndIf

	iItemCountBefore = akCargo.GetItemCount()
	Debug.Trace("[PWAL_SPACE_CARGO] SpaceCargoProcessor source item count before transfer: source=" + akCargo + " itemCount=" + (iItemCountBefore as String))
	If iItemCountBefore <= 0
		LogDebug("SpaceCargoProcessor", "ProcessSpaceCargo deferred: source has no items yet. source=" + akCargo)
		Debug.Trace("[PWAL_SPACE_CARGO] SpaceCargoProcessor return false reason: source has no items before transfer")
		Return false
	EndIf

	LogDebug("SpaceCargoProcessor", "Transfer begin: source=" + akCargo + " destination=" + akPlayerShipCargoTarget + " before=" + (iItemCountBefore as String))

	Debug.Trace("[PWAL_SPACE_CARGO] SpaceCargoProcessor RemoveAllItems call about to run: source=" + akCargo + " target=" + akPlayerShipCargoTarget + " before=" + (iItemCountBefore as String))
	akCargo.RemoveAllItems(akPlayerShipCargoTarget, false, false)

	iItemCountAfter = akCargo.GetItemCount()
	Debug.Trace("[PWAL_SPACE_CARGO] SpaceCargoProcessor source item count after transfer: source=" + akCargo + " itemCount=" + (iItemCountAfter as String))
	LogDebug("SpaceCargoProcessor", "Transfer complete: source=" + akCargo + " destination=" + akPlayerShipCargoTarget + " before=" + (iItemCountBefore as String) + " after=" + (iItemCountAfter as String))

	bResult = iItemCountAfter <= 0
	Debug.Trace("[PWAL_SPACE_CARGO] SpaceCargoProcessor return " + (bResult as String) + " reason: sourceAfter=" + (iItemCountAfter as String))
	Return bResult
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
