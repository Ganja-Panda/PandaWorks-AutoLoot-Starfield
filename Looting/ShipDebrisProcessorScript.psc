ScriptName PWAL:Looting:ShipDebrisProcessorScript Extends Quest

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.0.0
; Created: 06-15-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: ShipDebrisProcessorScript
; Type: Looting / Processor Service
; Purpose:
;   Transfers inventory from watched destroyed SpaceshipReference refs.
;
; Responsibilities:
;   - Accept watched destroyed SpaceshipReference refs
;   - Resolve the configured PWAL destination
;   - Transfer or remove the full destroyed ship inventory
;   - Report transfer diagnostics
;
; Non-Responsibilities:
;   - No scanning
;   - No validation
;   - No normal container processing
;   - No category filtering
;   - No visual SMOD/MSTT debris processing
;   - No physical cargo/fuel module CONT processing
;   - Physical space cargo containers belong to SpaceCargoProcessorScript
; ==============================================================

; ==============================================================
; Properties
; ==============================================================

Group FrameworkServices
	PWAL:Core:LoggerScript Property Logger Auto
	PWAL:Looting:DestinationResolverScript Property DestinationResolver Auto Const Mandatory
EndGroup

; ==============================================================
; Public API
; ==============================================================

Bool Function ProcessShipDebris(ObjectReference akDebris, PWAL:Looting:LootEffectScript akEffectContext)
	Int iDestinationCode
	Int iItemCountBefore
	Int iItemCountAfter
	ObjectReference akDestinationRef

	If akDebris == None
		LogWarn("ShipDebrisProcessor", "ProcessShipDebris failed: akDebris is None.")
		Return true
	EndIf

	SpaceshipReference shipRef = akDebris as SpaceshipReference

	If akEffectContext == None
		LogWarn("ShipDebrisProcessor", "ProcessShipDebris failed: akEffectContext is None.")
		Return false
	EndIf

	If DestinationResolver == None
		LogError("ShipDebrisProcessor", "ProcessShipDebris failed: DestinationResolver property is not filled.")
		Return false
	EndIf

	If shipRef == None
		LogWarn("ShipDebrisProcessor", "ProcessShipDebris rejected non-ship candidate. source=" + akDebris + " baseObject=" + akDebris.GetBaseObject())
		Return true
	EndIf

	If !shipRef.IsDead()
		LogDebug("ShipDebrisProcessor", "ProcessShipDebris deferred: ship is still alive. source=" + shipRef)
		Return false
	EndIf

	iItemCountBefore = shipRef.GetItemCount()
	If iItemCountBefore <= 0
		LogDebug("ShipDebrisProcessor", "ProcessShipDebris deferred: dead ship has no inventory yet. source=" + shipRef)
		Return false
	EndIf

	iDestinationCode = DestinationResolver.ResolveDestinationCodeForEffect(akEffectContext.GetLootGroupCode(), akEffectContext)
	akDestinationRef = DestinationResolver.ResolveDestinationRef(iDestinationCode)

	If !DestinationResolver.IsVoidDestination(iDestinationCode) && akDestinationRef == None
		LogWarn("ShipDebrisProcessor", "ProcessShipDebris failed: resolved destination ref is None. source=" + shipRef + " destinationCode=" + (iDestinationCode as String))
		Return false
	EndIf

	LogDebug("ShipDebrisProcessor", "Destroyed ship transfer begin: source=" + shipRef + " destination=" + akDestinationRef + " destinationCode=" + (iDestinationCode as String) + " before=" + (iItemCountBefore as String))

	shipRef.RemoveAllItems(akDestinationRef, false, false)

	iItemCountAfter = shipRef.GetItemCount()
	LogDebug("ShipDebrisProcessor", "Destroyed ship transfer complete: source=" + shipRef + " destination=" + akDestinationRef + " destinationCode=" + (iDestinationCode as String) + " before=" + (iItemCountBefore as String) + " after=" + (iItemCountAfter as String))

	Return true
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
