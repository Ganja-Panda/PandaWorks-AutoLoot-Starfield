ScriptName PWAL:Looting:AsteroidDepositBridgeScript Extends ObjectReference

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.0.0
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

Bool bKeywordAdded = False

Event OnInit()
	AddAsteroidDepositKeyword()
EndEvent

Event OnLoad()
	AddAsteroidDepositKeyword()
EndEvent

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