ScriptName PWAL:Looting:ShipDebrisDetectorScript Extends Quest

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Script: ShipDebrisDetectorScript
; Type: Looting / Space Ship Debris Detection
; Purpose:
;   Detection-only experiment for hostile non-player ship debris.
;
; Responsibilities:
;   - Inspect current player ship combat targets
;   - Watch hostile non-player SpaceshipReference refs while alive
;   - Submit watched dead ship refs to the ship debris candidate inbox
;
; Non-Responsibilities:
;   - No item transfer
;   - No destination routing
;   - No ground looting scanner integration
;   - No orbit-location processing
; ==============================================================

Group Diagnostics
	PWAL:Core:LoggerScript Property Logger Auto Const
EndGroup

Group ShipDebrisDetection
	RefCollectionAlias Property PWAL_RCAL_ShipDebrisCandidateInbox Auto Const Mandatory
	RefCollectionAlias Property PWAL_RCAL_WatchedHostileShips Auto Const Mandatory
	ReferenceAlias Property PlayerShip Auto Const Mandatory
	ReferenceAlias Property HomeShip Auto Const
	Keyword Property PlayerShipKeyword Auto Const
	Keyword Property SQ_ShipDebrisProhibited Auto Const
	Float Property DetectionTimerInterval = 1.0 Auto Const
	Int Property DetectionTimerID = 301 Auto Const
EndGroup

Bool bDetectorRunning = False

Event OnQuestStarted()
	StartDetector()
EndEvent

Event OnQuestShutdown()
	StopDetector()
EndEvent

Event OnTimer(Int aiTimerID)
	If aiTimerID == DetectionTimerID
		RunDetectionPass()

		If bDetectorRunning
			StartTimer(DetectionTimerInterval, DetectionTimerID)
		EndIf
	EndIf
EndEvent

Event SpaceshipReference.OnDying(SpaceshipReference akSender, ObjectReference akKiller)
	HandleWatchedShipDeath(akSender, akKiller, "OnDying")
EndEvent

Event SpaceshipReference.OnDeath(SpaceshipReference akSender, ObjectReference akKiller)
	HandleWatchedShipDeath(akSender, akKiller, "OnDeath")
EndEvent

Function StartDetector()
	bDetectorRunning = True
	CancelTimer(DetectionTimerID)
	LogInfo("detector started interval=" + (DetectionTimerInterval as String))
	RunDetectionPass()
	StartTimer(DetectionTimerInterval, DetectionTimerID)
EndFunction

Function StopDetector()
	bDetectorRunning = False
	CancelTimer(DetectionTimerID)
	UnregisterWatchedShips()
	LogInfo("detector stopped")
EndFunction

Function RunDetectionPass()
	SpaceshipReference akPlayerShipRef = ResolvePlayerShipRef()

	If akPlayerShipRef == None
		Return
	EndIf

	If PWAL_RCAL_WatchedHostileShips == None
		LogWarn("scan skipped: WatchedHostileShips is None")
		Return
	EndIf

	SpaceshipReference[] akCombatTargets = akPlayerShipRef.GetAllCombatTargets()
	Int iIndex = 0

	While iIndex < akCombatTargets.Length
		TryWatchCombatTarget(akCombatTargets[iIndex], akPlayerShipRef)
		iIndex += 1
	EndWhile
EndFunction

Function TryWatchCombatTarget(SpaceshipReference akCandidate, SpaceshipReference akPlayerShipRef)
	If akCandidate == None
		Return
	EndIf

	If akPlayerShipRef == None
		Return
	EndIf

	If IsProtectedPlayerShip(akCandidate, akPlayerShipRef)
		Return
	EndIf

	If SQ_ShipDebrisProhibited != None
		If akCandidate.HasKeyword(SQ_ShipDebrisProhibited)
			Return
		EndIf
	EndIf

	If akCandidate.IsDead()
		Return
	EndIf

	If PWAL_RCAL_WatchedHostileShips.Find(akCandidate) >= 0
		Return
	EndIf

	Bool bHostileToPlayerShip = akCandidate.IsHostileToSpaceship(akPlayerShipRef)
	Bool bTargetingPlayerShip = akCandidate.GetCombatTarget() == akPlayerShipRef

	If !bHostileToPlayerShip
		If !bTargetingPlayerShip
			Return
		EndIf
	EndIf

	PWAL_RCAL_WatchedHostileShips.AddRef(akCandidate)
	RegisterForRemoteEvent(akCandidate, "OnDying")
	RegisterForRemoteEvent(akCandidate, "OnDeath")
	LogInfo("watching hostile ship=" + akCandidate + " hostile=" + (bHostileToPlayerShip as String) + " targetingPlayer=" + (bTargetingPlayerShip as String))
EndFunction

Function HandleWatchedShipDeath(SpaceshipReference akSender, ObjectReference akKiller, String asEventName)
	SpaceshipReference akPlayerShipRef = ResolvePlayerShipRef()

	If akSender == None
		Return
	EndIf

	If PWAL_RCAL_WatchedHostileShips == None
		Return
	EndIf

	If PWAL_RCAL_WatchedHostileShips.Find(akSender) < 0
		Return
	EndIf

	If IsProtectedPlayerShip(akSender, akPlayerShipRef)
		LogWarn(asEventName + " skipped protected ship=" + akSender)
		Return
	EndIf

	SubmitDeadShipCandidate(akSender, akKiller, asEventName)
EndFunction

Function SubmitDeadShipCandidate(SpaceshipReference akShipRef, ObjectReference akKiller, String asEventName)
	If PWAL_RCAL_ShipDebrisCandidateInbox == None
		LogWarn(asEventName + " submit skipped: ShipDebrisCandidateInbox is None ship=" + akShipRef)
		Return
	EndIf

	If PWAL_RCAL_ShipDebrisCandidateInbox.Find(akShipRef) >= 0
		Return
	EndIf

	PWAL_RCAL_ShipDebrisCandidateInbox.AddRef(akShipRef)
	LogInfo(asEventName + " submitted ship=" + akShipRef + " killer=" + akKiller + " isDead=" + (akShipRef.IsDead() as String) + " itemCount=" + (akShipRef.GetItemCount() as String))
EndFunction

SpaceshipReference Function ResolvePlayerShipRef()
	If PlayerShip == None
		Return None
	EndIf

	Return PlayerShip.GetRef() as SpaceshipReference
EndFunction

SpaceshipReference Function ResolveHomeShipRef()
	If HomeShip != None
		SpaceshipReference akHomeShipRef = HomeShip.GetRef() as SpaceshipReference

		If akHomeShipRef != None
			Return akHomeShipRef
		EndIf
	EndIf

	Return Game.GetPlayerHomeSpaceShip()
EndFunction

Bool Function IsProtectedPlayerShip(SpaceshipReference akCandidate, SpaceshipReference akPlayerShipRef)
	If akCandidate == None
		Return True
	EndIf

	If akPlayerShipRef != None
		If akCandidate == akPlayerShipRef
			Return True
		EndIf
	EndIf

	SpaceshipReference akHomeShipRef = ResolveHomeShipRef()
	If akHomeShipRef != None
		If akCandidate == akHomeShipRef
			Return True
		EndIf
	EndIf

	If PlayerShipKeyword != None
		If akCandidate.HasKeyword(PlayerShipKeyword)
			Return True
		EndIf
	EndIf

	Return IsPlayerOwnedShip(akCandidate)
EndFunction

Bool Function IsPlayerOwnedShip(SpaceshipReference akCandidate)
	SpaceshipReference[] akOwnedShips = Game.GetPlayerOwnedShips()
	Int iIndex = 0

	While iIndex < akOwnedShips.Length
		If akCandidate == akOwnedShips[iIndex]
			Return True
		EndIf

		iIndex += 1
	EndWhile

	Return False
EndFunction

Function UnregisterWatchedShips()
	If PWAL_RCAL_WatchedHostileShips == None
		Return
	EndIf

	ObjectReference[] akWatchedRefs = PWAL_RCAL_WatchedHostileShips.GetArray()
	Int iIndex = 0
	SpaceshipReference akWatchedShip

	While iIndex < akWatchedRefs.Length
		akWatchedShip = akWatchedRefs[iIndex] as SpaceshipReference

		If akWatchedShip != None
			UnregisterForRemoteEvent(akWatchedShip, "OnDying")
			UnregisterForRemoteEvent(akWatchedShip, "OnDeath")
		EndIf

		iIndex += 1
	EndWhile
EndFunction

Function LogInfo(String asMessage)
	If Logger != None
		Logger.Info("ShipDebrisDetector", "[PWAL_SPACE_SHIP] " + asMessage)
	EndIf
EndFunction

Function LogWarn(String asMessage)
	If Logger != None
		Logger.Warn("ShipDebrisDetector", "[PWAL_SPACE_SHIP] " + asMessage)
	EndIf
EndFunction

Function LogDebug(String asMessage)
	If Logger != None
		Logger.DebugLog("ShipDebrisDetector", "[PWAL_SPACE_SHIP] " + asMessage)
	EndIf
EndFunction
