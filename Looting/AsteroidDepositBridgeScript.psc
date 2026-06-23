ScriptName PWAL:Looting:AsteroidDepositBridgeScript Extends ObjectReference

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.0.2
; Created: 06-11-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: AsteroidDepositBridgeScript
; Type: Looting / Space Loot Bridge
; Purpose:
;   Submits generated asteroid deposit containers to the PWAL asteroid
;   candidate inbox so the active space looting effect can process them.
;
; Responsibilities:
;   - Run on generated asteroid deposit container references
;   - Submit ready refs to the asteroid candidate inbox
;   - Avoid direct inventory transfer
;   - Avoid destination routing
;
; Non-Responsibilities:
;   - No scanning
;   - No validation
;   - No unlock handling
;   - No item transfer
;   - No destination policy ownership
;   - No direct ship cargo routing
; ==============================================================

RefCollectionAlias Property PWAL_RCAL_AsteroidCandidateInbox Auto Const
Int Property ASTEROID_INBOX_TIMER_ID = 101 Auto Const

Int iSubmitAttempt = 0

Event OnInit()
	StartReadinessRetry()
EndEvent

Event OnLoad()
	StartReadinessRetry()
EndEvent

Event OnTimer(Int aiTimerID)
	If aiTimerID == ASTEROID_INBOX_TIMER_ID
		ProcessReadinessAttempt()
	EndIf
EndEvent

Event OnUnload()
	CancelTimer(ASTEROID_INBOX_TIMER_ID)

	If PWAL_RCAL_AsteroidCandidateInbox != None
		PWAL_RCAL_AsteroidCandidateInbox.RemoveRef(Self)
	EndIf
EndEvent

Function StartReadinessRetry()
	iSubmitAttempt = 0
	CancelTimer(ASTEROID_INBOX_TIMER_ID)
	StartTimer(0.5, ASTEROID_INBOX_TIMER_ID)
EndFunction

Function ProcessReadinessAttempt()
	Bool bAlreadyInInbox = False
	Form akBase = GetBaseObject()
	Container akBaseContainer = akBase as Container

	If akBaseContainer == None
		Debug.Trace("[PWAL][WARN][AsteroidBridge] Readiness rejected non-container base: ref=" + Self + " base=" + akBase)
		Return
	EndIf

	Int iItemCount = GetItemCount()

	iSubmitAttempt += 1

	If PWAL_RCAL_AsteroidCandidateInbox == None
		Debug.Trace("[PWAL][WARN][AsteroidBridge] Readiness attempt=" + (iSubmitAttempt as String) + " ref=" + Self + " base=" + akBase + " itemCount=" + (iItemCount as String) + " alreadyInInbox=False inbox=None")

		If iSubmitAttempt < 5
			StartTimer(0.5, ASTEROID_INBOX_TIMER_ID)
		EndIf

		Return
	EndIf

	bAlreadyInInbox = PWAL_RCAL_AsteroidCandidateInbox.Find(Self) >= 0

	If bAlreadyInInbox
		Return
	EndIf

	If iItemCount > 0 || iSubmitAttempt >= 5
		PWAL_RCAL_AsteroidCandidateInbox.AddRef(Self)
		Return
	EndIf

	StartTimer(0.5, ASTEROID_INBOX_TIMER_ID)
EndFunction
