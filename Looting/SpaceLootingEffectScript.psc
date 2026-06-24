ScriptName PWAL:Looting:SpaceLootingEffectScript Extends ActiveMagicEffect

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.0.0
; Created: 06-23-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: SpaceLootingEffectScript
; Type: Looting / Space Salvage Effect Adapter
; Purpose:
;   Drains one configured space salvage candidate inbox into the
;   player ship cargo hold through the selected processor path.
;
; Responsibilities:
;   - Own timer lifecycle for the space salvage effect instance
;   - Resolve the player ship cargo target once per processing pass
;   - Drain the configured candidate inbox
;   - Dispatch to the configured processor type
;   - Leave not-ready refs queued for retry
;
; Non-Responsibilities:
;   - No bridge submission logic
;   - No normal ground looting
;   - No scanner, validation, or unlock handling
;   - No destination routing
;   - No ShipDebris processing
; ==============================================================

; ==============================================================
; Properties
; ==============================================================

Group FrameworkServices
	PWAL:Core:LoggerScript Property Logger Auto Const Mandatory
	PWAL:Looting:AsteroidDepositProcessorScript Property AsteroidDepositProcessor Auto Const
	PWAL:Looting:SpaceCargoProcessorScript Property SpaceCargoProcessor Auto Const
EndGroup

Group SpaceSalvage_Config
	RefCollectionAlias Property CandidateInbox Auto Const Mandatory
	Int Property ProcessorType = 0 Auto Const
EndGroup

Group WorldState_References
	ReferenceAlias Property PlayerHomeShip Auto Const Mandatory
EndGroup

Group RuntimeState
	Int Property SpaceLootTimerID = 201 Auto
	Float Property SpaceLootTimerDelay = 0.5 Auto
	Bool Property bIsProcessing = false Auto Hidden
EndGroup

; ==============================================================
; Events
; ==============================================================

Event OnInit()
EndEvent

Event OnEffectStart(ObjectReference akTarget, Actor akCaster, MagicEffect akBaseEffect, Float afMagnitude, Float afDuration)
	Debug.Trace("[PWAL_SPACE] SpaceLootingEffect OnEffectStart entered: target=" + akTarget + " caster=" + akCaster)
	Debug.Trace("[PWAL_SPACE] SpaceLootingEffect ProcessorType=" + (ProcessorType as String))
	Debug.Trace("[PWAL_SPACE] SpaceLootingEffect CandidateInbox=" + CandidateInbox)
	Debug.Trace("[PWAL_SPACE] SpaceLootingEffect PlayerHomeShip alias=" + PlayerHomeShip)
	If PlayerHomeShip != None
		Debug.Trace("[PWAL_SPACE] SpaceLootingEffect PlayerHomeShip.GetRef()=" + PlayerHomeShip.GetRef())
	Else
		Debug.Trace("[PWAL_SPACE] SpaceLootingEffect PlayerHomeShip.GetRef() skipped: PlayerHomeShip alias is None")
	EndIf

	bIsProcessing = false

	CancelTimer(SpaceLootTimerID)
	Debug.Trace("[PWAL_SPACE] SpaceLootingEffect timer started: delay=" + (SpaceLootTimerDelay as String) + " timerID=" + (SpaceLootTimerID as String))
	StartTimer(SpaceLootTimerDelay, SpaceLootTimerID)
EndEvent

Event OnEffectFinish(ObjectReference akTarget, Actor akCaster, MagicEffect akBaseEffect, Float afMagnitude, Float afDuration)
	Debug.Trace("[PWAL_SPACE] SpaceLootingEffect OnEffectFinish entered: target=" + akTarget + " caster=" + akCaster)
	CancelTimer(SpaceLootTimerID)
	Debug.Trace("[PWAL_SPACE] SpaceLootingEffect timer cancelled: timerID=" + (SpaceLootTimerID as String))

	bIsProcessing = false
EndEvent

Event OnTimer(Int aiTimerID)
	Debug.Trace("[PWAL_SPACE] SpaceLootingEffect OnTimer fired: timerID=" + (aiTimerID as String) + " expectedTimerID=" + (SpaceLootTimerID as String))
	If aiTimerID != SpaceLootTimerID
		Return
	EndIf

	If bIsProcessing
		Debug.Trace("[PWAL_SPACE] SpaceLootingEffect processing skipped because already processing")
		CancelTimer(SpaceLootTimerID)
		StartTimer(SpaceLootTimerDelay, SpaceLootTimerID)
		Return
	EndIf

	bIsProcessing = true
	ProcessSpaceLootPass()
	bIsProcessing = false

	CancelTimer(SpaceLootTimerID)
	StartTimer(SpaceLootTimerDelay, SpaceLootTimerID)
EndEvent

; ==============================================================
; Processing
; ==============================================================

Function ProcessSpaceLootPass()
	ObjectReference akPlayerShipCargoTarget

	Debug.Trace("[PWAL_SPACE] SpaceLootingEffect ProcessSpaceLootPass entered")
	akPlayerShipCargoTarget = GetPlayerShipCargoTarget()
	Debug.Trace("[PWAL_SPACE] SpaceLootingEffect player ship cargo target from alias: target=" + akPlayerShipCargoTarget)
	If akPlayerShipCargoTarget == None
		LogWarn("SpaceLootingEffect", "ProcessSpaceLootPass aborted: player ship cargo target is None.")
		Debug.Trace("[PWAL_SPACE] SpaceLootingEffect ProcessSpaceLootPass aborted: player ship cargo target is None")
		Return
	EndIf

	DrainCandidateInbox(akPlayerShipCargoTarget)
EndFunction

Function DrainCandidateInbox(ObjectReference akPlayerShipCargoTarget)
	Int iIndex = 0
	Int iCount
	ObjectReference akCandidate
	Bool bProcessed

	If CandidateInbox == None
		LogWarn("SpaceLootingEffect", "DrainCandidateInbox skipped: CandidateInbox is None.")
		Debug.Trace("[PWAL_SPACE] SpaceLootingEffect CandidateInbox count skipped: CandidateInbox is None")
		Return
	EndIf

	If !HasValidProcessor()
		Debug.Trace("[PWAL_SPACE] SpaceLootingEffect DrainCandidateInbox skipped: invalid processor for ProcessorType=" + (ProcessorType as String))
		Return
	EndIf

	iCount = CandidateInbox.GetCount()
	Debug.Trace("[PWAL_SPACE] SpaceLootingEffect CandidateInbox count: inbox=" + CandidateInbox + " count=" + (iCount as String) + " processorType=" + (ProcessorType as String))

	While iIndex < iCount
		akCandidate = CandidateInbox.GetAt(iIndex)
		Debug.Trace("[PWAL_SPACE] SpaceLootingEffect candidate index/ref: index=" + (iIndex as String) + " ref=" + akCandidate)

		If akCandidate == None
			LogWarn("SpaceLootingEffect", "DrainCandidateInbox removed stale None candidate at index " + (iIndex as String))
			Debug.Trace("[PWAL_SPACE] SpaceLootingEffect stale None candidate handling: index=" + (iIndex as String) + " removing and rebuilding inbox")
			iCount = RemoveStaleCandidateAtIndex(iIndex)
		Else
			Debug.Trace("[PWAL_SPACE] SpaceLootingEffect processor dispatch path selected: ProcessorType=" + (ProcessorType as String) + " candidate=" + akCandidate)
			bProcessed = ProcessCandidate(akCandidate, akPlayerShipCargoTarget)
			Debug.Trace("[PWAL_SPACE] SpaceLootingEffect processor result: candidate=" + akCandidate + " result=" + (bProcessed as String))

			If bProcessed
				CandidateInbox.RemoveRef(akCandidate)
				Debug.Trace("[PWAL_SPACE] SpaceLootingEffect ref removed from CandidateInbox after success: candidate=" + akCandidate + " inbox=" + CandidateInbox)
				iCount -= 1
			Else
				Debug.Trace("[PWAL_SPACE] SpaceLootingEffect ref left queued after false result: candidate=" + akCandidate + " inbox=" + CandidateInbox)
				iIndex += 1
			EndIf
		EndIf
	EndWhile
EndFunction

Int Function RemoveStaleCandidateAtIndex(Int aiStaleIndex)
	ObjectReference[] akCandidates = CandidateInbox.GetArray()
	Int iIndex = 0

	CandidateInbox.RemoveAll()

	While iIndex < akCandidates.Length
		If iIndex != aiStaleIndex && akCandidates[iIndex] != None
			CandidateInbox.AddRef(akCandidates[iIndex])
		EndIf

		iIndex += 1
	EndWhile

	Return CandidateInbox.GetCount()
EndFunction

Bool Function HasValidProcessor()
	If ProcessorType == 1
		Debug.Trace("[PWAL_SPACE_AST] SpaceLootingEffect validating asteroid processor path: processor=" + AsteroidDepositProcessor)
		If AsteroidDepositProcessor == None
			LogWarn("SpaceLootingEffect", "ProcessorType 1 skipped: AsteroidDepositProcessor is None.")
			Debug.Trace("[PWAL_SPACE_AST] SpaceLootingEffect processor dispatch path unavailable: AsteroidDepositProcessor is None")
			Return false
		EndIf

		Return true
	EndIf

	If ProcessorType == 2
		Debug.Trace("[PWAL_SPACE_CARGO] SpaceLootingEffect validating space cargo processor path: processor=" + SpaceCargoProcessor)
		If SpaceCargoProcessor == None
			LogWarn("SpaceLootingEffect", "ProcessorType 2 skipped: SpaceCargoProcessor is None.")
			Debug.Trace("[PWAL_SPACE_CARGO] SpaceLootingEffect processor dispatch path unavailable: SpaceCargoProcessor is None")
			Return false
		EndIf

		Return true
	EndIf

	LogWarn("SpaceLootingEffect", "Invalid ProcessorType: " + (ProcessorType as String))
	Return false
EndFunction

Bool Function ProcessCandidate(ObjectReference akCandidate, ObjectReference akPlayerShipCargoTarget)
	If ProcessorType == 1
		Debug.Trace("[PWAL_SPACE_AST] SpaceLootingEffect dispatching asteroid processor: candidate=" + akCandidate + " target=" + akPlayerShipCargoTarget)
		Return AsteroidDepositProcessor.ProcessAsteroidDeposit(akCandidate, akPlayerShipCargoTarget)
	EndIf

	If ProcessorType == 2
		Debug.Trace("[PWAL_SPACE_CARGO] SpaceLootingEffect dispatching space cargo processor: candidate=" + akCandidate + " target=" + akPlayerShipCargoTarget)
		Return SpaceCargoProcessor.ProcessSpaceCargo(akCandidate, akPlayerShipCargoTarget)
	EndIf

	Return false
EndFunction

ObjectReference Function GetPlayerShipCargoTarget()
	If PlayerHomeShip == None
		Return None
	EndIf

	Return PlayerHomeShip.GetRef()
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
