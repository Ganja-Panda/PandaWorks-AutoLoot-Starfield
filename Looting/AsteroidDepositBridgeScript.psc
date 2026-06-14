ScriptName PWAL:Looting:AsteroidDepositBridgeScript Extends ObjectReference

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.0.1
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
RefCollectionAlias Property PWAL_RCAL_AsteroidCanidateInbox Auto Const
Int Property ASTEROID_INBOX_TIMER_ID = 101 Auto Const

Bool bKeywordAdded = False

Event OnInit()
	AddAsteroidDepositKeyword()
	StartTimer(0.5, ASTEROID_INBOX_TIMER_ID)
EndEvent

Event OnLoad()
	AddAsteroidDepositKeyword()
	StartTimer(0.5, ASTEROID_INBOX_TIMER_ID)
EndEvent

Event OnTimer(Int aiTimerID)
	If aiTimerID == ASTEROID_INBOX_TIMER_ID
		SubmitCandidate()
	EndIf
EndEvent

Event OnUnload()
	If PWAL_RCAL_AsteroidCanidateInbox != None
		PWAL_RCAL_AsteroidCanidateInbox.RemoveRef(Self)
		Debug.Trace("[PWAL][DEBUG][AsteroidBridge] Removed asteroid candidate from inbox: " + Self)
	EndIf
EndEvent

Function SubmitCandidate()
	If PWAL_RCAL_AsteroidCanidateInbox == None
		Debug.Trace("[PWAL][WARN][AsteroidBridge] PWAL_RCAL_AsteroidCanidateInbox is None.")
		Return
	EndIf

	If PWAL_RCAL_AsteroidCanidateInbox.Find(Self) < 0
		PWAL_RCAL_AsteroidCanidateInbox.AddRef(Self)
		Debug.Trace("[PWAL][DEBUG][AsteroidBridge] Submitted asteroid candidate: " + Self)
	Else
		Debug.Trace("[PWAL][DEBUG][AsteroidBridge] Asteroid candidate already in inbox: " + Self)
	EndIf
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