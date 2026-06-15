ScriptName PWAL:Looting:AsteroidDepositProcessorScript Extends Quest

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.0.0
; Created: 06-15-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: AsteroidDepositProcessorScript
; Type: Looting / Processor Service
; Purpose:
;   Transfers generated asteroid mineral/deposit inventory refs.
;
; Responsibilities:
;   - Accept generated asteroid deposit inventory refs
;   - Resolve the configured PWAL destination
;   - Transfer or remove the full deposit inventory
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

Bool Function ProcessAsteroidDeposit(ObjectReference akDeposit, PWAL:Looting:LootEffectScript akEffectContext)
	Int iDestinationCode
	Int iItemCountBefore
	Int iItemCountAfter
	ObjectReference akDestinationRef

	If akDeposit == None
		LogWarn("AsteroidDepositProcessor", "ProcessAsteroidDeposit failed: akDeposit is None.")
		Return false
	EndIf

	If akEffectContext == None
		LogWarn("AsteroidDepositProcessor", "ProcessAsteroidDeposit failed: akEffectContext is None.")
		Return false
	EndIf

	If DestinationResolver == None
		LogError("AsteroidDepositProcessor", "ProcessAsteroidDeposit failed: DestinationResolver property is not filled.")
		Return false
	EndIf

	iDestinationCode = DestinationResolver.ResolveDestinationCodeForEffect(akEffectContext.GetLootGroupCode(), akEffectContext)
	akDestinationRef = DestinationResolver.ResolveDestinationRef(iDestinationCode)

	If !DestinationResolver.IsVoidDestination(iDestinationCode) && akDestinationRef == None
		LogWarn("AsteroidDepositProcessor", "ProcessAsteroidDeposit failed: resolved destination ref is None. source=" + akDeposit + " destinationCode=" + (iDestinationCode as String))
		Return false
	EndIf

	iItemCountBefore = akDeposit.GetItemCount()
	If iItemCountBefore <= 0
		LogDebug("AsteroidDepositProcessor", "ProcessAsteroidDeposit deferred: source has no items yet. source=" + akDeposit)
		Return false
	EndIf

	LogDebug("AsteroidDepositProcessor", "Transfer begin: source=" + akDeposit + " destination=" + akDestinationRef + " destinationCode=" + (iDestinationCode as String) + " before=" + (iItemCountBefore as String))

	akDeposit.RemoveAllItems(akDestinationRef, false, false)

	iItemCountAfter = akDeposit.GetItemCount()
	LogDebug("AsteroidDepositProcessor", "Transfer complete: source=" + akDeposit + " destination=" + akDestinationRef + " destinationCode=" + (iDestinationCode as String) + " before=" + (iItemCountBefore as String) + " after=" + (iItemCountAfter as String))

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
