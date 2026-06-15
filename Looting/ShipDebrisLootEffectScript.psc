ScriptName PWAL:Looting:ShipDebrisLootEffectScript Extends PWAL:Looting:LootEffectScript

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.0.2
; Created: 06-11-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: ShipDebrisLootEffectScript
; Type: Looting / Ship Debris Effect Adapter
; Purpose:
;   Handles ship-debris-specific in-space gating before handing
;   discovery and processing back to the standard PWAL loot framework.
;
; Responsibilities:
;   - Confirm the player ship is currently in space
;   - Log Bethesda's SQ_ShipDebris orbital keyword when available
;   - Run the configured ship-debris scan profile once the player ship is in space
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
		LogDebug("ShipDebris", GetEffectDebugLabel() + " | ShipDebris ExecuteLooting skipped: player ship is not in space.")
		Return
	EndIf

	LogDebug("ShipDebris", GetEffectDebugLabel() + " | ShipDebris gate passed. Calling Parent.ExecuteLooting().")
	Parent.ExecuteLooting()
	LogDebug("ShipDebris", GetEffectDebugLabel() + " | ShipDebris Parent.ExecuteLooting complete.")
EndFunction


Bool Function IsPlayerInShipDebrisOrbit()
	SpaceshipReference playerShipRef = None
	Location shipLoc = None
	Location playerLoc = None
	Actor playerActorRef = None
	Bool bInSpace = false

	LogDebug("ShipDebris", GetEffectDebugLabel() + " | IsPlayerInShipDebrisOrbit entered.")

	playerActorRef = Game.GetPlayer()
	LogDebug("ShipDebris", GetEffectDebugLabel() + " | player=" + playerActorRef)

	If playerActorRef == None
		LogWarn("ShipDebris", GetEffectDebugLabel() + " | IsPlayerInShipDebrisOrbit failed: player is None.")
		Return false
	EndIf

	playerShipRef = playerActorRef.GetCurrentShipRef() as SpaceshipReference
	LogDebug("ShipDebris", GetEffectDebugLabel() + " | playerShipRef=" + playerShipRef)

	If playerShipRef == None
		playerShipRef = GetPlayerHomeShipRef() as SpaceshipReference
		LogDebug("ShipDebris", GetEffectDebugLabel() + " | PlayerHomeShip fallback result=" + playerShipRef)
	EndIf

	If playerShipRef == None
		LogWarn("ShipDebris", GetEffectDebugLabel() + " | IsPlayerInShipDebrisOrbit failed: player ship is None.")
		Return false
	EndIf

	bInSpace = playerShipRef.IsInSpace()
	shipLoc = playerShipRef.GetCurrentLocation()
	playerLoc = playerActorRef.GetCurrentLocation()

	LogDebug("ShipDebris", GetEffectDebugLabel() + " | ship.IsInSpace=" + (bInSpace as String))
	LogDebug("ShipDebris", GetEffectDebugLabel() + " | ship.location=" + shipLoc)
	LogDebug("ShipDebris", GetEffectDebugLabel() + " | player.location=" + playerLoc)

	If SQ_ShipDebrisKeyword == None
		LogDebug("ShipDebris", GetEffectDebugLabel() + " | SQ_ShipDebrisKeyword is not filled; skipping encounter-keyword diagnostic.")
	ElseIf shipLoc == None
		LogDebug("ShipDebris", GetEffectDebugLabel() + " | ship.location is None; skipping SQ_ShipDebrisKeyword diagnostic.")
	Else
		LogDebug("ShipDebris", GetEffectDebugLabel() + " | ship.location.HasKeyword(SQ_ShipDebrisKeyword)=" + (shipLoc.HasKeyword(SQ_ShipDebrisKeyword) as String))
	EndIf

	If !bInSpace
		LogDebug("ShipDebris", GetEffectDebugLabel() + " | IsPlayerInShipDebrisOrbit failed: player ship is not in space.")
		Return false
	EndIf

	LogDebug("ShipDebris", GetEffectDebugLabel() + " | IsPlayerInShipDebrisOrbit result=true")
	Return true
EndFunction