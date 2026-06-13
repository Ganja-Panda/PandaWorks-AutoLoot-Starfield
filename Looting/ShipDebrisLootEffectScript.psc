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
	LogDebug("ShipDebris", GetEffectDebugLabel() + " | ShipDebris ExecuteLooting entered.")

	If !IsPlayerInShipDebrisOrbit()
		LogDebug("ShipDebris", GetEffectDebugLabel() + " | ShipDebris ExecuteLooting skipped: player is not in a ship-debris orbit.")
		Return
	EndIf

	LogDebug("ShipDebris", GetEffectDebugLabel() + " | ShipDebris gate passed. Calling Parent.ExecuteLooting().")
	Parent.ExecuteLooting()
	LogDebug("ShipDebris", GetEffectDebugLabel() + " | ShipDebris Parent.ExecuteLooting complete.")
EndFunction


Bool Function IsPlayerInShipDebrisOrbit()
	SpaceshipReference playerShipRef = None
	Location currentLocation = None
	Bool bHasKeyword = false
	ObjectReference akPlayerRef = None

	LogDebug("ShipDebris", GetEffectDebugLabel() + " | IsPlayerInShipDebrisOrbit entered.")

	akPlayerRef = Game.GetPlayer()
	LogDebug("ShipDebris", GetEffectDebugLabel() + " | Game.GetPlayer result=" + akPlayerRef)

	playerShipRef = akPlayerRef.GetCurrentShipRef() as SpaceshipReference
	LogDebug("ShipDebris", GetEffectDebugLabel() + " | GetCurrentShipRef result=" + playerShipRef)

	If playerShipRef == None
		playerShipRef = GetPlayerHomeShipRef() as SpaceshipReference
		LogDebug("ShipDebris", GetEffectDebugLabel() + " | PlayerHomeShip fallback result=" + playerShipRef)
	EndIf

	If playerShipRef == None
		LogDebug("ShipDebris", GetEffectDebugLabel() + " | Player ship ref is None.")
		Return false
	EndIf

	LogDebug("ShipDebris", GetEffectDebugLabel() + " | ship.IsInSpace=" + (playerShipRef.IsInSpace() as String))
	If !playerShipRef.IsInSpace()
		LogDebug("ShipDebris", GetEffectDebugLabel() + " | IsPlayerInShipDebrisOrbit failed: player ship is not in space.")
		Return false
	EndIf

	If SQ_ShipDebrisKeyword == None
		LogWarn("ShipDebris", GetEffectDebugLabel() + " | IsPlayerInShipDebrisOrbit failed: SQ_ShipDebrisKeyword is not filled.")
		Return false
	EndIf

	currentLocation = playerShipRef.GetCurrentLocation()
	LogDebug("ShipDebris", GetEffectDebugLabel() + " | currentLocation=" + currentLocation)

	If currentLocation == None
		LogDebug("ShipDebris", GetEffectDebugLabel() + " | IsPlayerInShipDebrisOrbit failed: current location is None.")
		Return false
	EndIf

	bHasKeyword = currentLocation.HasKeyword(SQ_ShipDebrisKeyword)
	LogDebug("ShipDebris", GetEffectDebugLabel() + " | currentLocation.HasKeyword(SQ_ShipDebrisKeyword)=" + (bHasKeyword as String))

	If bHasKeyword
		LogDebug("ShipDebris", GetEffectDebugLabel() + " | IsPlayerInShipDebrisOrbit result=true")
		Return true
	EndIf

	LogDebug("ShipDebris", GetEffectDebugLabel() + " | IsPlayerInShipDebrisOrbit result=false")
	Return false
EndFunction