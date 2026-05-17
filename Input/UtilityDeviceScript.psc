ScriptName PWAL:Input:UtilityDeviceScript Extends ObjectReference Const

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.00
; Created: 05-17-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: UtilityDevicePortableScript
; Type: Input / Portable Utility Terminal Device
; Purpose:
;   Opens the PandaWorks Utilities terminal when the portable
;   utility device is used from inventory.
;
; Responsibilities:
;   - Run from the placed utility-device reference
;   - Wait briefly for inventory/menu state to settle
;   - Activate the assigned utility terminal reference
;
; Non-Responsibilities:
;   - No MagicEffect scripting
;   - No alias scripting
;   - No transfer logic
;   - No inventory-management logic
;   - No terminal menu logic
;   - No loot scanning
; ==============================================================


; ==============================================================
; Properties
; ==============================================================

ObjectReference Property PWAL_TERM_UtilityDevice_Ref Auto Const Mandatory


; ==============================================================
; Events
; ==============================================================

Event OnEquipped(Actor akActor)
	Utility.Wait(0.1)
	PWAL_TERM_UtilityDevice_Ref.Activate(Game.GetPlayer() as ObjectReference, false)
EndEvent