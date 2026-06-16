ScriptName PWAL:Looting:ShipDebrisBridgeScript Extends ObjectReference

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.0.0
; Created: 06-15-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: ShipDebrisBridgeScript
; Type: Looting / Space Loot Bridge
; Purpose:
;   Submits generated ship debris containers to the PWAL ship debris
;   candidate inbox so the active space looting effect can process them.
;
; Responsibilities:
;   - Run on generated ship debris container references
;   - Submit ready refs to the ship debris candidate inbox
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

RefCollectionAlias Property PWAL_RCAL_ShipDebrisCandidateInbox Auto Const
Int Property SHIP_DEBRIS_INBOX_TIMER_ID = 102 Auto Const

Int iSubmitAttempt = 0

Event OnInit()
	StartReadinessRetry()
EndEvent

Event OnLoad()
	StartReadinessRetry()
EndEvent

Event OnTimer(Int aiTimerID)
	If aiTimerID == SHIP_DEBRIS_INBOX_TIMER_ID
		ProcessReadinessAttempt()
	EndIf
EndEvent

Event OnUnload()
	CancelTimer(SHIP_DEBRIS_INBOX_TIMER_ID)

	If PWAL_RCAL_ShipDebrisCandidateInbox != None
		PWAL_RCAL_ShipDebrisCandidateInbox.RemoveRef(Self)
		Debug.Trace("[PWAL][DEBUG][ShipDebrisBridge] Removed ship debris candidate from inbox: " + Self)
	EndIf
EndEvent

Function StartReadinessRetry()
	iSubmitAttempt = 0
	CancelTimer(SHIP_DEBRIS_INBOX_TIMER_ID)
	StartTimer(0.5, SHIP_DEBRIS_INBOX_TIMER_ID)
EndFunction

Function ProcessReadinessAttempt()
	Bool bAlreadyInInbox = False
	Form akBase = GetBaseObject()
	Container akBaseContainer = akBase as Container

	If akBaseContainer == None
		Debug.Trace("[PWAL][WARN][ShipDebrisBridge] Readiness rejected non-container base: ref=" + Self + " base=" + akBase)
		Return
	EndIf

	Int iItemCount = GetItemCount()

	iSubmitAttempt += 1

	If PWAL_RCAL_ShipDebrisCandidateInbox == None
		Debug.Trace("[PWAL][WARN][ShipDebrisBridge] Readiness attempt=" + (iSubmitAttempt as String) + " ref=" + Self + " base=" + akBase + " itemCount=" + (iItemCount as String) + " alreadyInInbox=False inbox=None")

		If iSubmitAttempt < 5
			StartTimer(0.5, SHIP_DEBRIS_INBOX_TIMER_ID)
		EndIf

		Return
	EndIf

	bAlreadyInInbox = PWAL_RCAL_ShipDebrisCandidateInbox.Find(Self) >= 0
	Debug.Trace("[PWAL][DEBUG][ShipDebrisBridge] Readiness attempt=" + (iSubmitAttempt as String) + " ref=" + Self + " base=" + akBase + " itemCount=" + (iItemCount as String) + " alreadyInInbox=" + (bAlreadyInInbox as String))

	If bAlreadyInInbox
		Return
	EndIf

	If iItemCount > 0 || iSubmitAttempt >= 5
		PWAL_RCAL_ShipDebrisCandidateInbox.AddRef(Self)
		Debug.Trace("[PWAL][DEBUG][ShipDebrisBridge] Submitted ship debris candidate on attempt=" + (iSubmitAttempt as String) + ": " + Self)
		Return
	EndIf

	StartTimer(0.5, SHIP_DEBRIS_INBOX_TIMER_ID)
EndFunction
