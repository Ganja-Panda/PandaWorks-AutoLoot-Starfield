ScriptName PWAL:Looting:LootValidationScript Extends Quest Hidden

; ==============================================================
; Pandworks Studios - PandaWork Auto Loot
; Author: Ganja Panda
; Version: 1.0.2
; Created: 04-10-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: LootValidationScript
; Type: Looting / Validation
; Purpose:
;   Central validation service for PWAL looting decisions.
;   Determines whether a loot reference is valid and allowed
;   for processing under current PWAL settings.
;
; Responsibilities:
;   - Validate whether loot may be processed
;   - Check protected source references
;   - Check owned-area looting rules
;   - Check stealing/ownership rules
;   - Check player availability
;   - Check object load/disable/delete state
;   - Identify corpse references
;   - Reject already-looted containers/corpses
;
; Non-Responsibilities:
;   - No ownership mutation
;   - No unlocking
;   - No transfer logic
;   - No destination resolution
; ==============================================================

; ==============================================================
; Properties
; ==============================================================

PWAL:Core:LoggerScript Property Logger Auto Const

Location Property CityNewAtlantisLodgeLocation Auto Const
LocationAlias Property PlayerShipInterior Auto Const Mandatory
Keyword Property LocTypeOutpost Auto Const
Keyword Property LocTypePlayerHouse Auto Const
ReferenceAlias Property PlayerShip Auto Const
ReferenceAlias Property HomeShip Auto Const
ReferenceAlias Property PlayerShipSpaceshipInventory Auto Const
LocationAlias Property HomeShipInteriorLocation Auto Const


; ==============================================================
; Public API
; ==============================================================

Bool Function CanProcessLoot(ObjectReference akLoot, PWAL:Looting:LootEffectScript akEffectContext)
	Actor akPlayerActor

	If akLoot == None
		Return false
	EndIf

	If akEffectContext == None
		Return false
	EndIf
	
	If IsBlockedPlayerInventoryRef(akLoot, akEffectContext)
		Return false
	EndIf

	If !IsLootLoaded(akLoot)
		Return false
	EndIf

	If !IsPlayerAvailable()
		Return false
	EndIf

	If IsActorOutsideCorpseOrHarvestMode(akLoot, akEffectContext)
		Return false
	EndIf

	If IsProtectedSourceRef(akLoot, akEffectContext)
		Return false
	EndIf

	If IsAlreadyLooted(akLoot, akEffectContext)
		Return false
	EndIf

	If IsInBlockedOwnedArea(akEffectContext)
		Return false
	EndIf

	If (akEffectContext.IsShipInteriorMode() || akEffectContext.IsShipContainerMode()) && !CanLootShipSpaceContent(akEffectContext)
		Return false
	EndIf

	akPlayerActor = akEffectContext.GetPlayerActor()
	If akPlayerActor != None
		If akPlayerActor.WouldBeStealing(akLoot) && !akEffectContext.CanSteal()
			Return false
		EndIf
	EndIf

	If IsPlayerStealing(akLoot, akEffectContext) && !akEffectContext.CanSteal()
		Return false
	EndIf

	Return true
EndFunction

Bool Function CanProcess(ObjectReference akLoot, ObjectReference akLooterRef, PWAL:Looting:LootEffectScript akEffectContext)
	Return CanProcessLoot(akLoot, akEffectContext)
EndFunction

; ==============================================================
; Validation Helpers
; ==============================================================

Bool Function IsBlockedPlayerInventoryRef(ObjectReference akLoot, PWAL:Looting:LootEffectScript akEffectContext)
	ObjectReference akPlayerRef
	ObjectReference akPWALInventoryRef

	If akLoot == None || akEffectContext == None
		Return false
	EndIf

	akPlayerRef = akEffectContext.GetPlayerRef()
	If akPlayerRef == None
		akPlayerRef = Game.GetPlayer()
	EndIf

	If akPlayerRef != None
		If akLoot == akPlayerRef
			Return true
		EndIf

		If akLoot.GetContainer() == akPlayerRef
			Return true
		EndIf
	EndIf

	akPWALInventoryRef = akEffectContext.GetPWALInventoryContainerRef()
	If akPWALInventoryRef != None
		If akLoot == akPWALInventoryRef
			Return true
		EndIf

		If akLoot.GetContainer() == akPWALInventoryRef
			Return true
		EndIf
	EndIf

	Return false
EndFunction

Bool Function IsPlayerShipProtectedSource(ObjectReference akLoot, PWAL:Looting:LootEffectScript akEffectContext)
	ObjectReference akPlayerShipRef
	ObjectReference akHomeShipRef
	ObjectReference akShipInventoryRef
	ObjectReference akCurrentShipRef

	If akLoot == None || akEffectContext == None
		Return false
	EndIf

	; This protection is only for the ship/space container scan path.
	; Do not let it block normal corpses, loose loot, or regular containers.
	If !akEffectContext.IsShipInteriorMode() && !akEffectContext.IsShipContainerMode()
		Return false
	EndIf

	If PlayerShip != None
		akPlayerShipRef = PlayerShip.GetReference()
	EndIf

	If HomeShip != None
		akHomeShipRef = HomeShip.GetReference()
	EndIf

	If PlayerShipSpaceshipInventory != None
		akShipInventoryRef = PlayerShipSpaceshipInventory.GetReference()
	EndIf

	; Direct cargo/inventory alias protection.
	If akShipInventoryRef != None
		If akLoot == akShipInventoryRef
			Return true
		EndIf
	EndIf

	; Cargo hold path may normalize directly to the player/home ship ref.
	If akPlayerShipRef != None
		If akLoot == akPlayerShipRef
			Return true
		EndIf
	EndIf

	If akHomeShipRef != None
		If akLoot == akHomeShipRef
			Return true
		EndIf
	EndIf

	; Ship-interior containers like Captain's Locker may resolve to their owning/current ship.
	akCurrentShipRef = akLoot.GetCurrentShipRef() as ObjectReference

	If akCurrentShipRef != None
		If akPlayerShipRef != None
			If akCurrentShipRef == akPlayerShipRef
				Return true
			EndIf
		EndIf

		If akHomeShipRef != None
			If akCurrentShipRef == akHomeShipRef
				Return true
			EndIf
		EndIf
	EndIf

	Return false
EndFunction

Bool Function IsActorOutsideCorpseOrHarvestMode(ObjectReference akLoot, PWAL:Looting:LootEffectScript akEffectContext)
	Actor akActor

	If akLoot == None || akEffectContext == None
		Return false
	EndIf

	akActor = akLoot as Actor
	If akActor == None
		Return false
	EndIf

	If akEffectContext.IsCorpseMode()
		Return false
	EndIf

	If akEffectContext.IsNonLethalHarvestMode()
		Return false
	EndIf

	If akEffectContext.IsContainerMode() || akEffectContext.IsShipInteriorMode() || akEffectContext.IsShipContainerMode()
		Return false
	EndIf

	Return true
EndFunction

Bool Function CanLootShipSpaceContent(PWAL:Looting:LootEffectScript akEffectContext)
	If akEffectContext == None
		Return false
	EndIf

	If akEffectContext.PWAL_GLOB_Settings_AllowLooting_Ships == None
		Return false
	EndIf

	Return akEffectContext.PWAL_GLOB_Settings_AllowLooting_Ships.GetValueInt() != 0
EndFunction

Bool Function IsQuestLoot(ObjectReference akLoot)
	If akLoot == None
		Return false
	EndIf

	Return akLoot.IsQuestItem()
EndFunction

Bool Function IsProtectedSourceRef(ObjectReference akLoot, PWAL:Looting:LootEffectScript akEffectContext)
	If akLoot == None || akEffectContext == None
		Return false
	EndIf

	If akLoot == akEffectContext.GetLodgeSafeRef()
		Return true
	EndIf

	If akLoot == akEffectContext.GetPWALInventoryContainerRef()
		Return true
	EndIf

	If IsPlayerShipProtectedSource(akLoot, akEffectContext)
		Return true
	EndIf

	Return false
EndFunction

Bool Function IsAlreadyLooted(ObjectReference akLoot, PWAL:Looting:LootEffectScript akEffectContext)
	Actor akActor
	Keyword akLootedKeyword

	If akLoot == None || akEffectContext == None
		Return false
	EndIf

	akActor = akLoot as Actor
	If akActor != None
		akLootedKeyword = akEffectContext.GetCorpseLootedKeyword()
	EndIf

	If akLootedKeyword == None
		Return false
	EndIf

	Return akLoot.HasKeyword(akLootedKeyword)
EndFunction

Bool Function IsInBlockedOwnedArea(PWAL:Looting:LootEffectScript akEffectContext)
	ObjectReference akPlayerRef
	Location akPlayerLocation

	If akEffectContext == None
		Return true
	EndIf

	akPlayerRef = akEffectContext.GetPlayerRef()
	If akPlayerRef == None
		Return true
	EndIf

	akPlayerLocation = akPlayerRef.GetCurrentLocation()
	If akPlayerLocation == None
		Return false
	EndIf

	; Player homes
	If LocTypePlayerHouse != None
		If akPlayerLocation.HasKeyword(LocTypePlayerHouse)
			If akEffectContext.PWAL_GLOB_Settings_AllowLooting_PlayerHomes == None
				Return true
			EndIf

			If akEffectContext.PWAL_GLOB_Settings_AllowLooting_PlayerHomes.GetValueInt() == 0
				Return true
			EndIf
		EndIf
	EndIf

	; Lodge
	If CityNewAtlantisLodgeLocation != None
		If akPlayerRef.IsInLocation(CityNewAtlantisLodgeLocation)
			If akEffectContext.PWAL_GLOB_Settings_AllowLooting_Lodge == None
				Return true
			EndIf

			If akEffectContext.PWAL_GLOB_Settings_AllowLooting_Lodge.GetValueInt() == 0
				Return true
			EndIf
		EndIf
	EndIf

	; Player outposts
	If LocTypeOutpost != None
		If akPlayerLocation.HasKeyword(LocTypeOutpost)
			If akEffectContext.PWAL_GLOB_Settings_AllowLooting_Outposts == None
				Return true
			EndIf

			If akEffectContext.PWAL_GLOB_Settings_AllowLooting_Outposts.GetValueInt() == 0
				Return true
			EndIf
		EndIf
	EndIf

	Return false
EndFunction

Bool Function IsOwned(ObjectReference akLoot, PWAL:Looting:LootEffectScript akEffectContext)
	Actor akPlayerActor

	If akLoot == None || akEffectContext == None
		Return false
	EndIf

	akPlayerActor = akEffectContext.GetPlayerActor()
	If akPlayerActor == None
		Return false
	EndIf

	Return akPlayerActor.WouldBeStealing(akLoot) || IsPlayerStealing(akLoot, akEffectContext) || akLoot.HasOwner()
EndFunction

Bool Function IsPlayerStealing(ObjectReference akLoot, PWAL:Looting:LootEffectScript akEffectContext)
	Faction akCurrentOwner

	If akLoot == None || akEffectContext == None
		Return false
	EndIf

	akCurrentOwner = akLoot.GetFactionOwner()

	If akCurrentOwner == None
		Return false
	EndIf

	If akEffectContext.PlayerFaction == None
		Return true
	EndIf

	Return akCurrentOwner != akEffectContext.PlayerFaction
EndFunction

Bool Function IsPlayerAvailable()
	Return Game.IsActivateControlsEnabled() || Game.IsLookingControlsEnabled()
EndFunction

Bool Function IsLootLoaded(ObjectReference akLoot)
	If akLoot == None
		Return false
	EndIf

	If !akLoot.IsBoundGameObjectAvailable()
		Return false
	EndIf

	Return akLoot.Is3DLoaded() && !akLoot.IsDisabled() && !akLoot.IsDeleted()
EndFunction

Bool Function IsCorpse(ObjectReference akLoot)
	Actor akActor = akLoot as Actor
	Return akActor != None
EndFunction

; ==============================================================
; Internal Logging Wrappers
; ==============================================================

Function LogInfo(String asSource, String asMessage)
	If Logger
		Logger.Info(asSource, asMessage)
	Else
		Debug.Trace("[PWAL][INFO][" + asSource + "] " + asMessage)
	EndIf
EndFunction

Function LogWarn(String asSource, String asMessage)
	If Logger
		Logger.Warn(asSource, asMessage)
	Else
		Debug.Trace("[PWAL][WARN][" + asSource + "] " + asMessage)
	EndIf
EndFunction

Function LogError(String asSource, String asMessage)
	If Logger
		Logger.Error(asSource, asMessage)
	Else
		Debug.Trace("[PWAL][ERROR][" + asSource + "] " + asMessage)
	EndIf
EndFunction

Function LogDebug(String asSource, String asMessage)
	If Logger
		Logger.DebugLog(asSource, asMessage)
	Else
		Debug.Trace("[PWAL][DEBUG][" + asSource + "] " + asMessage)
	EndIf
EndFunction
