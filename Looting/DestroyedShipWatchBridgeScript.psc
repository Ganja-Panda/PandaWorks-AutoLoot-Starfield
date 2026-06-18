ScriptName PWAL:Looting:DestroyedShipWatchBridgeScript Extends ObjectReference

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.0.0
; Created: 06-18-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: DestroyedShipWatchBridgeScript
; Type: Looting / Destroyed Ship Watch Bridge
; Purpose:
;   Registers live hostile spaceship references into the destroyed
;   ship watch inbox so the active PWAL effect can process them later.
;
; Responsibilities:
;   - Run on live spaceship references
;   - Filter player ships and non-spaceship refs
;   - Submit hostile ship refs to the destroyed ship watch inbox
;   - Avoid direct inventory transfer
;   - Avoid destination routing
;
; Non-Responsibilities:
;   - No scanning
;   - No validation
;   - No unlock handling
;   - No item transfer
;   - No destination policy ownership
; ==============================================================

RefCollectionAlias Property PWAL_RCAL_DestroyedShipWatchInbox Auto Const Mandatory
Keyword Property SpaceshipKeyword Auto Const
Keyword Property PlayerShipKeyword Auto Const
Actor Property PlayerRef Auto Const
PWAL:Core:LoggerScript Property Logger Auto

Event OnInit()
	RegisterShipForWatch()
EndEvent

Event OnLoad()
	RegisterShipForWatch()
EndEvent

Function RegisterShipForWatch()
	SpaceshipReference shipRef = Self as SpaceshipReference

	If shipRef == None
		LogDebug("DestroyedShipWatchBridge", "RegisterShipForWatch rejected non-ship ref: source=" + Self + " baseObject=" + GetBaseObject())
		Return
	EndIf

	If PlayerShipKeyword != None && shipRef.HasKeyword(PlayerShipKeyword)
		LogDebug("DestroyedShipWatchBridge", "RegisterShipForWatch rejected player ship: source=" + shipRef)
		Return
	EndIf

	If SpaceshipKeyword != None && !shipRef.HasKeyword(SpaceshipKeyword)
		LogDebug("DestroyedShipWatchBridge", "RegisterShipForWatch rejected ship without SpaceshipKeyword: source=" + shipRef)
		Return
	EndIf

	If PlayerRef != None && shipRef.GetActorFactionReaction(PlayerRef) != 1
		LogDebug("DestroyedShipWatchBridge", "RegisterShipForWatch rejected non-hostile ship: source=" + shipRef + " player=" + PlayerRef + " reaction=" + (shipRef.GetActorFactionReaction(PlayerRef) as String))
		Return
	EndIf

	If PWAL_RCAL_DestroyedShipWatchInbox == None
		LogWarn("DestroyedShipWatchBridge", "RegisterShipForWatch failed: PWAL_RCAL_DestroyedShipWatchInbox property is not filled. source=" + shipRef)
		Return
	EndIf

	PWAL_RCAL_DestroyedShipWatchInbox.AddRef(shipRef)
	LogDebug("DestroyedShipWatchBridge", "Registered destroyed ship watch candidate: source=" + shipRef)
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
