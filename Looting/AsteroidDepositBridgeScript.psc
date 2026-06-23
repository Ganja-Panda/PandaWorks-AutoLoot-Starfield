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
;   Marks generated asteroid deposit containers so the PWAL space
;   loot scanner can discover them through the normal framework path.
;
; Responsibilities:
;   - Run on generated asteroid deposit container references
;   - Add the PWAL asteroid-deposit detection keyword
;   - Avoid direct inventory transfer
;   - Avoid destination routing
;   - Exit after the deposit has been marked
;
; Non-Responsibilities:
;   - No scanning
;   - No validation
;   - No unlock handling
;   - No item transfer
;   - No destination policy ownership
;   - No direct ship cargo routing
; ==============================================================

Keyword Property PWAL_KYWD_AsteroidDeposit Auto Const Mandatory
RefCollectionAlias Property PWAL_RCAL_AsteroidCandidateInbox Auto Const
Int Property ASTEROID_INBOX_TIMER_ID = 101 Auto Const

Bool bKeywordAdded = False
Int iSubmitAttempt = 0

Event OnInit()
	AddAsteroidDepositKeyword()
	StartReadinessRetry()
EndEvent

Event OnLoad()
	AddAsteroidDepositKeyword()
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
		Debug.Trace("[PWAL][DEBUG][AsteroidBridge] Removed asteroid candidate from inbox: " + Self)
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
	Debug.Trace("[PWAL][DEBUG][AsteroidBridge] Readiness attempt=" + (iSubmitAttempt as String) + " ref=" + Self + " base=" + akBase + " itemCount=" + (iItemCount as String) + " alreadyInInbox=" + (bAlreadyInInbox as String))

	If bAlreadyInInbox
		Return
	EndIf

	If iItemCount > 0 || iSubmitAttempt >= 5
		PWAL_RCAL_AsteroidCandidateInbox.AddRef(Self)
		Debug.Trace("[PWAL][DEBUG][AsteroidBridge] Submitted asteroid candidate on attempt=" + (iSubmitAttempt as String) + ": " + Self)
		Return
	EndIf

	StartTimer(0.5, ASTEROID_INBOX_TIMER_ID)
EndFunction

Function AddAsteroidDepositKeyword()
	If bKeywordAdded
		Return
	EndIf

	If PWAL_KYWD_AsteroidDeposit == None
		Return
	EndIf

	If !HasKeyword(PWAL_KYWD_AsteroidDeposit)
		AddKeyword(PWAL_KYWD_AsteroidDeposit)
	EndIf

	bKeywordAdded = True
EndFunction