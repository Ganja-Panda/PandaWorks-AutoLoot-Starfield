ScriptName PWAL:Looting:DestroyedShipWatchAliasScript Extends ReferenceAlias

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.0.0
; Created: 06-18-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: DestroyedShipWatchAliasScript
; Type: Looting / Destroyed Ship Watch Alias Bridge
; Purpose:
;   Copies CK-filtered live hostile spaceship alias references into
;   the destroyed ship watch inbox for later PWAL effect processing.
;
; Responsibilities:
;   - Run on a quest ReferenceAlias filled by CK conditions
;   - Submit the filled alias reference to the destroyed ship watch inbox
;   - Avoid direct inventory transfer
;   - Avoid destination routing
;
; Non-Responsibilities:
;   - No ObjectReference attachment
;   - No keyword filtering
;   - No hostility filtering
;   - No dead-state checks
;   - No item transfer
;   - No destination policy ownership
; ==============================================================

RefCollectionAlias Property PWAL_RCAL_DestroyedShipWatchInbox Auto Const Mandatory
PWAL:Core:LoggerScript Property Logger Auto

Event OnAliasInit()
	RegisterAliasShip("OnAliasInit")
EndEvent

Event OnInit()
	RegisterAliasShip("OnInit")
EndEvent

Event OnLoad()
	RegisterAliasShip("OnLoad")
EndEvent

Function RegisterAliasShip(String asEventName = "Unknown")
	ObjectReference akRef = GetReference()

	If akRef == None
		LogDebug("DestroyedShipWatchAlias", "RegisterAliasShip skipped: alias reference is None. event=" + asEventName)
		Return
	EndIf

	If PWAL_RCAL_DestroyedShipWatchInbox == None
		LogWarn("DestroyedShipWatchAlias", "RegisterAliasShip failed: PWAL_RCAL_DestroyedShipWatchInbox property is not filled. event=" + asEventName + " source=" + akRef)
		Return
	EndIf

	PWAL_RCAL_DestroyedShipWatchInbox.AddRef(akRef)
	LogDebug("DestroyedShipWatchAlias", "Registered destroyed ship watch alias ref: event=" + asEventName + " source=" + akRef)
EndFunction

Function LogWarn(String asSource, String asMessage)
	If Logger
		Logger.Warn(asSource, asMessage)
	Else
		Debug.Trace("[PWAL][WARN][" + asSource + "] " + asMessage)
	EndIf
EndFunction

Function LogDebug(String asSource, String asMessage)
	If Logger
		Logger.DebugLog(asSource, asMessage)
	Else
		Debug.Trace("[PWAL][DEBUG][" + asSource + "] " + asMessage)
	EndIf
EndFunction