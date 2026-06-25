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
;   - Accept the player ship cargo transfer target
;   - Transfer the full deposit inventory
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
	PWAL:Core:LoggerScript Property Logger Auto Const Mandatory
EndGroup

; ==============================================================
; Public API
; ==============================================================

Bool Function ProcessAsteroidDeposit(ObjectReference akDeposit, ObjectReference akPlayerShipCargoTarget)
	Int iItemCountBefore
	Int iItemCountAfter
	Bool bResult

	If akDeposit == None
		LogWarn("AsteroidDepositProcessor", "ProcessAsteroidDeposit failed: akDeposit is None.")
		Return false
	EndIf

	If akPlayerShipCargoTarget == None
		LogWarn("AsteroidDepositProcessor", "ProcessAsteroidDeposit failed: akPlayerShipCargoTarget is None.")
		Return false
	EndIf

	iItemCountBefore = akDeposit.GetItemCount()
	If iItemCountBefore <= 0
		LogDebug("AsteroidDepositProcessor", "ProcessAsteroidDeposit deferred: source has no items yet. source=" + akDeposit)
		Return false
	EndIf

	LogDebug("AsteroidDepositProcessor", "Transfer begin: source=" + akDeposit + " destination=" + akPlayerShipCargoTarget + " before=" + (iItemCountBefore as String))

	akDeposit.RemoveAllItems(akPlayerShipCargoTarget, false, false)

	iItemCountAfter = akDeposit.GetItemCount()
	LogDebug("AsteroidDepositProcessor", "Transfer complete: source=" + akDeposit + " destination=" + akPlayerShipCargoTarget + " before=" + (iItemCountBefore as String) + " after=" + (iItemCountAfter as String))

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
