ScriptName PWAL:Looting:SpaceLootProcessorScript Extends Quest

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.0.0
; Created: 06-15-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: SpaceLootProcessorScript
; Type: Looting / Processor Service
; Purpose:
;   Transfers lootable space inventory refs.
;
; Responsibilities:
;   - Accept lootable space inventory refs
;   - Resolve PWAL destination through DestinationResolver
;   - Transfer or remove the full space-loot inventory
;   - Report transfer diagnostics
;
; Non-Responsibilities:
;   - No scanning
;   - No validation
;   - No normal container processing
;   - No category filtering
;   - No RefCollectionAlias insertion/discovery
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

Bool Function ProcessSpaceLoot(ObjectReference akLootRef, PWAL:Looting:LootEffectScript akEffectContext)
	Int iDestinationCode
	Int iItemCountBefore
	Int iItemCountAfter
	ObjectReference akDestinationRef

	If akLootRef == None
		LogWarn("SpaceLootProcessor", "ProcessSpaceLoot failed: akLootRef is None.")
		Return false
	EndIf

	If akEffectContext == None
		LogWarn("SpaceLootProcessor", "ProcessSpaceLoot failed: akEffectContext is None.")
		Return false
	EndIf

	If DestinationResolver == None
		LogError("SpaceLootProcessor", "ProcessSpaceLoot failed: DestinationResolver property is not filled.")
		Return false
	EndIf

	If akEffectContext.IsAsteroidDepositMode()
		iDestinationCode = DestinationResolver.ResolveDestinationCode(akEffectContext.GetLootGroupCode())
	Else
		iDestinationCode = DestinationResolver.ResolveDestinationCodeForEffect(akEffectContext.GetLootGroupCode(), akEffectContext)
	EndIf
	akDestinationRef = DestinationResolver.ResolveDestinationRef(iDestinationCode)

	If !DestinationResolver.IsVoidDestination(iDestinationCode) && akDestinationRef == None
		LogWarn("SpaceLootProcessor", "ProcessSpaceLoot failed: resolved destination ref is None. source=" + akLootRef + " destinationCode=" + (iDestinationCode as String))
		Return false
	EndIf

	iItemCountBefore = akLootRef.GetItemCount()
	If iItemCountBefore <= 0
		LogDebug("SpaceLootProcessor", "ProcessSpaceLoot deferred: source has no items yet. source=" + akLootRef)
		Return false
	EndIf

	LogDebug("SpaceLootProcessor", "Transfer begin: source=" + akLootRef + " destination=" + akDestinationRef + " destinationCode=" + (iDestinationCode as String) + " before=" + (iItemCountBefore as String))

	akLootRef.RemoveAllItems(akDestinationRef, false, false)

	iItemCountAfter = akLootRef.GetItemCount()
	LogDebug("SpaceLootProcessor", "Transfer complete: source=" + akLootRef + " destination=" + akDestinationRef + " destinationCode=" + (iDestinationCode as String) + " before=" + (iItemCountBefore as String) + " after=" + (iItemCountAfter as String))

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
