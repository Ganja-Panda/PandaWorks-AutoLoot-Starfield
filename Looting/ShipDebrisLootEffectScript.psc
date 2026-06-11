ScriptName PWAL:Looting:ShipDebrisLootEffectScript Extends PWAL:Looting:LootEffectScript

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.0.0
; Created: 06-11-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: ShipDebrisLootEffectScript
; Type: Looting / Ship Debris Effect Adapter
; Purpose:
;   Handles ship-debris-specific orbital gating before handing
;   discovery and processing back to the standard PWAL loot framework.
;
; Responsibilities:
;   - Confirm the player is in a valid ship-debris orbit
;   - Check Bethesda's SQ_ShipDebris orbital keyword when available
;   - Run the configured ship-debris scan profile
;   - Delegate scanning, validation, processing, and routing to PWAL
;
; Non-Responsibilities:
;   - No direct inventory transfer
;   - No asteroid deposit keyword bridging
;   - No destination policy ownership
;   - No container filtering logic
;   - No ship-kill event handling
;   - No direct ship cargo routing
; ==============================================================

Group ShipDebris_Mandatory
	Keyword Property SQ_ShipDebrisKeyword Auto Const Mandatory
EndGroup


Function ExecuteLooting()
	If !IsPlayerInShipDebrisOrbit()
		LogDebug("ShipDebris", "ExecuteLooting skipped: player is not in a ship-debris orbit.")
		Return
	EndIf

	Parent.ExecuteLooting()
EndFunction


Bool Function IsPlayerInShipDebrisOrbit()
	SpaceshipReference playerShipRef = None
	Location currentLocation = None

	playerShipRef = Game.GetPlayer().GetCurrentShipRef() as SpaceshipReference

	If playerShipRef == None
		playerShipRef = GetPlayerHomeShipRef() as SpaceshipReference
	EndIf

	If playerShipRef == None
		LogDebug("ShipDebris", "IsPlayerInShipDebrisOrbit failed: no player ship ref.")
		Return false
	EndIf

	If !playerShipRef.IsInSpace()
		LogDebug("ShipDebris", "IsPlayerInShipDebrisOrbit failed: player ship is not in space.")
		Return false
	EndIf

	If SQ_ShipDebrisKeyword == None
		LogWarn("ShipDebris", "IsPlayerInShipDebrisOrbit failed: SQ_ShipDebrisKeyword is not filled.")
		Return false
	EndIf

	currentLocation = playerShipRef.GetCurrentLocation()

	If currentLocation == None
		LogDebug("ShipDebris", "IsPlayerInShipDebrisOrbit failed: current location is None.")
		Return false
	EndIf

	If currentLocation.HasKeyword(SQ_ShipDebrisKeyword)
		Return true
	EndIf

	Return false
EndFunction