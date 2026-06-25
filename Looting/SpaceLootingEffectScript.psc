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
	bIsProcessing = false

	CancelTimer(SpaceLootTimerID)
	StartTimer(SpaceLootTimerDelay, SpaceLootTimerID)
EndEvent

Event OnEffectFinish(ObjectReference akTarget, Actor akCaster, MagicEffect akBaseEffect, Float afMagnitude, Float afDuration)
	CancelTimer(SpaceLootTimerID)

	bIsProcessing = false
EndEvent

Event OnTimer(Int aiTimerID)
	If aiTimerID != SpaceLootTimerID
		Return
	EndIf

	If bIsProcessing
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

	akPlayerShipCargoTarget = GetPlayerShipCargoTarget()
	If akPlayerShipCargoTarget == None
		LogWarn("SpaceLootingEffect", "ProcessSpaceLootPass aborted: player ship cargo target is None.")
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
		Return
	EndIf

	If !HasValidProcessor()
		Return
	EndIf

	iCount = CandidateInbox.GetCount()

	While iIndex < iCount
		akCandidate = CandidateInbox.GetAt(iIndex)

		If akCandidate == None
			LogWarn("SpaceLootingEffect", "DrainCandidateInbox removed stale None candidate at index " + (iIndex as String))
			iCount = RemoveStaleCandidateAtIndex(iIndex)
		Else
			bProcessed = ProcessCandidate(akCandidate, akPlayerShipCargoTarget)

			If bProcessed
				CandidateInbox.RemoveRef(akCandidate)
				iCount -= 1
			Else
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
		If AsteroidDepositProcessor == None
			LogWarn("SpaceLootingEffect", "ProcessorType 1 skipped: AsteroidDepositProcessor is None.")
			Return false
		EndIf

		Return true
	EndIf

	If ProcessorType == 2
		If SpaceCargoProcessor == None
			LogWarn("SpaceLootingEffect", "ProcessorType 2 skipped: SpaceCargoProcessor is None.")
			Return false
		EndIf

		Return true
	EndIf

	LogWarn("SpaceLootingEffect", "Invalid ProcessorType: " + (ProcessorType as String))
	Return false
EndFunction

Bool Function ProcessCandidate(ObjectReference akCandidate, ObjectReference akPlayerShipCargoTarget)
	If ProcessorType == 1
		Return AsteroidDepositProcessor.ProcessAsteroidDeposit(akCandidate, akPlayerShipCargoTarget)
	EndIf

	If ProcessorType == 2
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
