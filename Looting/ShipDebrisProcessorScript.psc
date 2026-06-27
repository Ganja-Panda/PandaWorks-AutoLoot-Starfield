ScriptName PWAL:Looting:ShipDebrisProcessorScript Extends Quest

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.0.0
; Created: 06-27-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: ShipDebrisProcessorScript
; Type: Looting / Processor Service
; Purpose:
;   Transfers destroyed hostile ship inventory refs.
;
; Responsibilities:
;   - Accept destroyed ship refs submitted by the ship debris detector
;   - Accept the player ship cargo transfer target
;   - Transfer the full ship inventory
;   - Report transfer diagnostics
;
; Non-Responsibilities:
;   - No scanning
;   - No validation
;   - No hostility checks
;   - No ref cleanup, disabling, deletion, or unregistering
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

Bool Function ProcessShipDebris(SpaceshipReference akShipRef, ObjectReference akPlayerShipCargoTarget)
	Int iItemCountBefore
	Int iItemCountAfter
	Bool bResult

	If akShipRef == None
		LogWarn("ShipDebrisProcessor", "ProcessShipDebris failed: akShipRef is None.")
		Return false
	EndIf

	If akPlayerShipCargoTarget == None
		LogWarn("ShipDebrisProcessor", "ProcessShipDebris failed: akPlayerShipCargoTarget is None.")
		Return false
	EndIf

	If !akShipRef.IsBoundGameObjectAvailable()
		Return false
	EndIf

	If !akShipRef.IsDead()
		Return false
	EndIf

	iItemCountBefore = akShipRef.GetItemCount()
	If iItemCountBefore <= 0
		Return false
	EndIf

	akShipRef.RemoveAllItems(akPlayerShipCargoTarget, false, true)

	iItemCountAfter = akShipRef.GetItemCount()

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
