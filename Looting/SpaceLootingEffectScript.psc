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
; ==============================================================

; ==============================================================
; Properties
; ==============================================================

Group FrameworkServices
	PWAL:Core:LoggerScript Property Logger Auto Const Mandatory
	PWAL:Looting:AsteroidDepositProcessorScript Property AsteroidDepositProcessor Auto Const
	PWAL:Looting:SpaceCargoProcessorScript Property SpaceCargoProcessor Auto Const
	PWAL:Looting:ShipDebrisProcessorScript Property ShipDebrisProcessor Auto Const
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
	Int Property FailedCandidateRetryLimit = 5 Auto
	Bool Property bIsProcessing = false Auto Hidden
EndGroup

ObjectReference[] akFailedCandidates
Int[] iFailedCandidateCounts
Bool bLoggedMissingPlayerHomeShipAlias
Bool bLoggedMissingPlayerHomeShipRef
Bool bLoggedMissingPlayerShipCargoTarget
Bool bLoggedMissingShipDebrisProcessor

; ==============================================================
; Events
; ==============================================================

Event OnInit()
EndEvent

Event OnEffectStart(ObjectReference akTarget, Actor akCaster, MagicEffect akBaseEffect, Float afMagnitude, Float afDuration)
	bIsProcessing = false
	ClearFailedCandidateRetries()

	CancelTimer(SpaceLootTimerID)
	StartTimer(SpaceLootTimerDelay, SpaceLootTimerID)
EndEvent

Event OnEffectFinish(ObjectReference akTarget, Actor akCaster, MagicEffect akBaseEffect, Float afMagnitude, Float afDuration)
	CancelTimer(SpaceLootTimerID)

	bIsProcessing = false
	ClearFailedCandidateRetries()
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
		If !bLoggedMissingPlayerShipCargoTarget
			LogWarn("SpaceLootingEffect", "ProcessSpaceLootPass aborted: player ship cargo target is None.")
			bLoggedMissingPlayerShipCargoTarget = true
		EndIf

		Return
	EndIf

	bLoggedMissingPlayerShipCargoTarget = false
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
				ClearFailedCandidateRetry(akCandidate)
				CandidateInbox.RemoveRef(akCandidate)
				iCount -= 1
			Else
				If ShouldDropFailedCandidate(akCandidate)
					LogWarn("SpaceLootingEffect", "DrainCandidateInbox removed failed candidate after retry cap: processorType=" + (ProcessorType as String) + " candidate=" + akCandidate)
					ClearFailedCandidateRetry(akCandidate)
					CandidateInbox.RemoveRef(akCandidate)
					iCount -= 1
				Else
					iIndex += 1
				EndIf
			EndIf
		EndIf
	EndWhile
EndFunction

Bool Function ShouldDropFailedCandidate(ObjectReference akCandidate)
	Int iRetryCount = IncrementFailedCandidateRetry(akCandidate)

	If FailedCandidateRetryLimit <= 0
		Return false
	EndIf

	Return iRetryCount >= FailedCandidateRetryLimit
EndFunction

Int Function IncrementFailedCandidateRetry(ObjectReference akCandidate)
	Int iIndex = FindFailedCandidateRetryIndex(akCandidate)
	Int iRetryCount

	If akCandidate == None
		Return 0
	EndIf

	If iIndex >= 0
		iRetryCount = iFailedCandidateCounts[iIndex] + 1
		iFailedCandidateCounts[iIndex] = iRetryCount
		Return iRetryCount
	EndIf

	AddFailedCandidateRetry(akCandidate)
	Return 1
EndFunction

Int Function FindFailedCandidateRetryIndex(ObjectReference akCandidate)
	Int iIndex = 0

	If akFailedCandidates == None
		Return -1
	EndIf

	While iIndex < akFailedCandidates.Length
		If akFailedCandidates[iIndex] == akCandidate
			Return iIndex
		EndIf

		iIndex += 1
	EndWhile

	Return -1
EndFunction

Function AddFailedCandidateRetry(ObjectReference akCandidate)
	Int iOldLength = 0
	Int iIndex = 0
	ObjectReference[] akNewFailedCandidates
	Int[] iNewFailedCandidateCounts

	If akCandidate == None
		Return
	EndIf

	If akFailedCandidates != None
		iOldLength = akFailedCandidates.Length
	EndIf

	akNewFailedCandidates = new ObjectReference[iOldLength + 1]
	iNewFailedCandidateCounts = new Int[iOldLength + 1]

	While iIndex < iOldLength
		akNewFailedCandidates[iIndex] = akFailedCandidates[iIndex]
		iNewFailedCandidateCounts[iIndex] = iFailedCandidateCounts[iIndex]
		iIndex += 1
	EndWhile

	akNewFailedCandidates[iOldLength] = akCandidate
	iNewFailedCandidateCounts[iOldLength] = 1

	akFailedCandidates = akNewFailedCandidates
	iFailedCandidateCounts = iNewFailedCandidateCounts
EndFunction

Function ClearFailedCandidateRetry(ObjectReference akCandidate)
	Int iOldLength
	Int iNewLength
	Int iIndex = 0
	Int iNewIndex = 0
	ObjectReference[] akNewFailedCandidates
	Int[] iNewFailedCandidateCounts

	If akCandidate == None
		Return
	EndIf

	If akFailedCandidates == None
		Return
	EndIf

	iOldLength = akFailedCandidates.Length

	If FindFailedCandidateRetryIndex(akCandidate) < 0
		Return
	EndIf

	iNewLength = iOldLength - 1

	If iNewLength <= 0
		ClearFailedCandidateRetries()
		Return
	EndIf

	akNewFailedCandidates = new ObjectReference[iNewLength]
	iNewFailedCandidateCounts = new Int[iNewLength]

	While iIndex < iOldLength
		If akFailedCandidates[iIndex] != akCandidate
			akNewFailedCandidates[iNewIndex] = akFailedCandidates[iIndex]
			iNewFailedCandidateCounts[iNewIndex] = iFailedCandidateCounts[iIndex]
			iNewIndex += 1
		EndIf

		iIndex += 1
	EndWhile

	akFailedCandidates = akNewFailedCandidates
	iFailedCandidateCounts = iNewFailedCandidateCounts
EndFunction

Function ClearFailedCandidateRetries()
	akFailedCandidates = new ObjectReference[0]
	iFailedCandidateCounts = new Int[0]
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

	If ProcessorType == 3
		If ShipDebrisProcessor == None
			If !bLoggedMissingShipDebrisProcessor
				LogWarn("SpaceLootingEffect", "ProcessorType 3 skipped: ShipDebrisProcessor is None.")
				bLoggedMissingShipDebrisProcessor = true
			EndIf

			Return false
		EndIf

		bLoggedMissingShipDebrisProcessor = false
		Return true
	EndIf

	LogWarn("SpaceLootingEffect", "Invalid ProcessorType: " + (ProcessorType as String))
	Return false
EndFunction

Bool Function ProcessCandidate(ObjectReference akCandidate, ObjectReference akPlayerShipCargoTarget)
	SpaceshipReference akCandidateShip

	If ProcessorType == 1
		Return AsteroidDepositProcessor.ProcessAsteroidDeposit(akCandidate, akPlayerShipCargoTarget)
	EndIf

	If ProcessorType == 2
		Return SpaceCargoProcessor.ProcessSpaceCargo(akCandidate, akPlayerShipCargoTarget)
	EndIf

	If ProcessorType == 3
		akCandidateShip = akCandidate as SpaceshipReference
		If akCandidateShip == None
			Return false
		EndIf

		Return ShipDebrisProcessor.ProcessShipDebris(akCandidateShip, akPlayerShipCargoTarget)
	EndIf

	Return false
EndFunction

ObjectReference Function GetPlayerShipCargoTarget()
	ObjectReference akPlayerShipRef

	If PlayerHomeShip == None
		If !bLoggedMissingPlayerHomeShipAlias
			LogWarn("SpaceLootingEffect", "GetPlayerShipCargoTarget failed: PlayerHomeShip alias is None.")
			bLoggedMissingPlayerHomeShipAlias = true
		EndIf

		Return None
	EndIf

	bLoggedMissingPlayerHomeShipAlias = false

	akPlayerShipRef = PlayerHomeShip.GetRef()
	If akPlayerShipRef == None
		If !bLoggedMissingPlayerHomeShipRef
			LogWarn("SpaceLootingEffect", "GetPlayerShipCargoTarget failed: PlayerHomeShip alias returned None.")
			bLoggedMissingPlayerHomeShipRef = true
		EndIf
	Else
		bLoggedMissingPlayerHomeShipRef = false
	EndIf

	Return akPlayerShipRef
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
