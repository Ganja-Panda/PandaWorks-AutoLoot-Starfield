ScriptName PWAL:Looting:SpaceLootBridgeScript Extends ObjectReference

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.0.2
; Created: 06-11-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: SpaceLootBridgeScript
; Type: Looting / Space Loot Bridge
; Purpose:
;   Submits ready generated space-loot inventory/container refs
;   through the normal framework inbox path.
;
; Responsibilities:
;   - Run on generated space-loot inventory/container references
;   - Submit ready space-loot refs to the shared candidate inbox
;   - Avoid direct inventory transfer
;   - Avoid destination routing
;
; Non-Responsibilities:
;   - No scanning
;   - No validation
;   - No keyword tagging
;   - No unlock handling
;   - No item transfer
;   - No destination policy ownership
;   - No direct ship cargo routing
; ==============================================================

RefCollectionAlias Property SpaceLootCandidateInbox Auto Const
Int Property SPACE_LOOT_INBOX_TIMER_ID = 101 Auto Const

Int iSubmitAttempt = 0

Event OnInit()
	StartReadinessRetry()
EndEvent

Event OnLoad()
	StartReadinessRetry()
EndEvent

Event OnTimer(Int aiTimerID)
	If aiTimerID == SPACE_LOOT_INBOX_TIMER_ID
		ProcessReadinessAttempt()
	EndIf
EndEvent

Event OnUnload()
	CancelTimer(SPACE_LOOT_INBOX_TIMER_ID)

	If SpaceLootCandidateInbox != None
		SpaceLootCandidateInbox.RemoveRef(Self)
		Debug.Trace("[PWAL][DEBUG][SpaceLootBridge] Removed space-loot candidate from inbox: " + Self)
	EndIf
EndEvent

Function StartReadinessRetry()
	iSubmitAttempt = 0
	CancelTimer(SPACE_LOOT_INBOX_TIMER_ID)
	StartTimer(0.5, SPACE_LOOT_INBOX_TIMER_ID)
EndFunction

Function ProcessReadinessAttempt()
	Bool bAlreadyInInbox = False
	Form akBase = GetBaseObject()
	Container akBaseContainer = akBase as Container

	If akBaseContainer == None
		Debug.Trace("[PWAL][WARN][SpaceLootBridge] Readiness rejected non-container base: ref=" + Self + " base=" + akBase)
		Return
	EndIf

	Int iItemCount = GetItemCount()

	iSubmitAttempt += 1

	If SpaceLootCandidateInbox == None
		Debug.Trace("[PWAL][WARN][SpaceLootBridge] Readiness attempt=" + (iSubmitAttempt as String) + " ref=" + Self + " base=" + akBase + " itemCount=" + (iItemCount as String) + " alreadyInInbox=False inbox=None")

		If iSubmitAttempt < 5
			StartTimer(0.5, SPACE_LOOT_INBOX_TIMER_ID)
		EndIf

		Return
	EndIf

	bAlreadyInInbox = SpaceLootCandidateInbox.Find(Self) >= 0
	Debug.Trace("[PWAL][DEBUG][SpaceLootBridge] Readiness attempt=" + (iSubmitAttempt as String) + " ref=" + Self + " base=" + akBase + " itemCount=" + (iItemCount as String) + " alreadyInInbox=" + (bAlreadyInInbox as String))

	If bAlreadyInInbox
		Return
	EndIf

	If iItemCount > 0 || iSubmitAttempt >= 5
		SpaceLootCandidateInbox.AddRef(Self)
		Debug.Trace("[PWAL][DEBUG][SpaceLootBridge] Submitted space-loot candidate on attempt=" + (iSubmitAttempt as String) + ": " + Self)
		Return
	EndIf

	StartTimer(0.5, SPACE_LOOT_INBOX_TIMER_ID)
EndFunction
