ScriptName PWAL:Looting:DestroyedShipWatchCollectionScript Extends RefCollectionAlias

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.0.0
; Created: 06-19-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: DestroyedShipWatchCollectionScript
; Type: Looting / RefCollectionAlias Diagnostics
; Purpose:
;   Provides lightweight diagnostics for the destroyed ship watch inbox.
;
; Responsibilities:
;   - Run on PWAL_RCAL_DestroyedShipWatchInbox
;   - Report collection script initialization
;
; Non-Responsibilities:
;   - No manual AddRef behavior
;   - No manual RemoveRef behavior
;   - No inventory transfer
;   - No destination routing
;   - No scanning
;   - No keyword filtering
;   - No mode flags
; ==============================================================

; ==============================================================
; Properties
; ==============================================================

PWAL:Core:LoggerScript Property Logger Auto

; ==============================================================
; Events
; ==============================================================

Event OnInit()
	LogDebug("DestroyedShipWatchCollection", "Destroyed ship watch collection script initialized." + Self)
EndEvent

; ==============================================================
; Internal Logging Wrappers
; ==============================================================

Function LogDebug(String asSource, String asMessage)
	If Logger
		Logger.DebugLog(asSource, asMessage)
	Else
		Debug.Trace("[PWAL][DEBUG][" + asSource + "] " + asMessage)
	EndIf
EndFunction
