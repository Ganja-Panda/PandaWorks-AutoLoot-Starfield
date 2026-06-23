ScriptName PWAL:Looting:SpaceCargoBridgeScript Extends ObjectReference

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.0.0
; Created: 06-15-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: SpaceCargoBridgeScript
; Type: Looting / Space Loot Bridge
; Purpose:
;   Submits generated space cargo containers to the PWAL space cargo
;   candidate inbox so the active space looting effect can process them.
;
; Responsibilities:
;   - Run on generated space cargo container references
;   - Submit ready refs to the space cargo candidate inbox
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

Int Property SPACE_CARGO_INBOX_TIMER_ID = 102 Auto Const
RefCollectionAlias Property PWAL_RCAL_SpaceCargoCandidateInbox Auto Const

Int iSubmitAttempt = 0

Event OnInit()
	StartReadinessRetry()
EndEvent

Event OnLoad()
	StartReadinessRetry()
EndEvent

Event OnTimer(Int aiTimerID)
	If aiTimerID == SPACE_CARGO_INBOX_TIMER_ID
		ProcessReadinessAttempt()
	EndIf
EndEvent

Event OnUnload()
	CancelTimer(SPACE_CARGO_INBOX_TIMER_ID)

	If PWAL_RCAL_SpaceCargoCandidateInbox != None
		PWAL_RCAL_SpaceCargoCandidateInbox.RemoveRef(Self)
	EndIf
EndEvent

Function StartReadinessRetry()
	iSubmitAttempt = 0
	CancelTimer(SPACE_CARGO_INBOX_TIMER_ID)
	StartTimer(0.5, SPACE_CARGO_INBOX_TIMER_ID)
EndFunction

Function ProcessReadinessAttempt()
	Bool bAlreadyInInbox = False
	Form akBase = GetBaseObject()
	Container akBaseContainer = akBase as Container

	If akBaseContainer == None
		Debug.Trace("[PWAL][WARN][SpaceCargoBridge] Readiness rejected non-container base: ref=" + Self + " base=" + akBase)
		Return
	EndIf

	Int iItemCount = GetItemCount()

	iSubmitAttempt += 1

	If PWAL_RCAL_SpaceCargoCandidateInbox == None
		Debug.Trace("[PWAL][WARN][SpaceCargoBridge] Readiness attempt=" + (iSubmitAttempt as String) + " ref=" + Self + " base=" + akBase + " itemCount=" + (iItemCount as String) + " alreadyInInbox=False inbox=None")

		If iSubmitAttempt < 5
			StartTimer(0.5, SPACE_CARGO_INBOX_TIMER_ID)
		EndIf

		Return
	EndIf

	bAlreadyInInbox = PWAL_RCAL_SpaceCargoCandidateInbox.Find(Self) >= 0

	If bAlreadyInInbox
		Return
	EndIf

	If iItemCount > 0 || iSubmitAttempt >= 5
		PWAL_RCAL_SpaceCargoCandidateInbox.AddRef(Self)
		Return
	EndIf

	StartTimer(0.5, SPACE_CARGO_INBOX_TIMER_ID)
EndFunction
