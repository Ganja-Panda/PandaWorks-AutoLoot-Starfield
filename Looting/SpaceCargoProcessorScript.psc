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
;   - Resolve the configured PWAL destination
;   - Transfer or remove the full cargo inventory
;   - Report transfer diagnostics
;
; Non-Responsibilities:
;   - No scanning
;   - No validation
;   - No normal container processing
;   - No category filtering
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

Bool Function ProcessSpaceCargo(ObjectReference akCargo, PWAL:Looting:LootEffectScript akEffectContext)
	Int iDestinationCode
	Int iItemCountBefore
	Int iItemCountAfter
	ObjectReference akDestinationRef

	If akCargo == None
		LogWarn("SpaceCargoProcessor", "ProcessSpaceCargo failed: akCargo is None.")
		Return false
	EndIf

	If akEffectContext == None
		LogWarn("SpaceCargoProcessor", "ProcessSpaceCargo failed: akEffectContext is None.")
		Return false
	EndIf

	If DestinationResolver == None
		LogError("SpaceCargoProcessor", "ProcessSpaceCargo failed: DestinationResolver property is not filled.")
		Return false
	EndIf

	iDestinationCode = DestinationResolver.ResolveDestinationCodeForEffect(akEffectContext.GetLootGroupCode(), akEffectContext)
	akDestinationRef = DestinationResolver.ResolveDestinationRef(iDestinationCode)

	If !DestinationResolver.IsVoidDestination(iDestinationCode) && akDestinationRef == None
		LogWarn("SpaceCargoProcessor", "ProcessSpaceCargo failed: resolved destination ref is None. source=" + akCargo + " destinationCode=" + (iDestinationCode as String))
		Return false
	EndIf

	iItemCountBefore = akCargo.GetItemCount()
	If iItemCountBefore <= 0
		LogDebug("SpaceCargoProcessor", "ProcessSpaceCargo deferred: source has no items yet. source=" + akCargo)
		Return false
	EndIf

	LogDebug("SpaceCargoProcessor", "Transfer begin: source=" + akCargo + " destination=" + akDestinationRef + " destinationCode=" + (iDestinationCode as String) + " before=" + (iItemCountBefore as String))

	akCargo.RemoveAllItems(akDestinationRef, false, false)

	iItemCountAfter = akCargo.GetItemCount()
	LogDebug("SpaceCargoProcessor", "Transfer complete: source=" + akCargo + " destination=" + akDestinationRef + " destinationCode=" + (iDestinationCode as String) + " before=" + (iItemCountBefore as String) + " after=" + (iItemCountAfter as String))

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
