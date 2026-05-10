ScriptName PWAL:Looting:LootValidationScript Extends Quest Hidden

; ==============================================================
; Pandworks Studios - PandaWork Auto Loot
; Author: Ganja Panda
; Version: 1.00
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
;   - Block quest items
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

LocationAlias Property LodgeLocation Auto Const
LocationAlias Property playerShipInterior Auto Const Mandatory
Keyword Property LocTypeOutpost Auto Const
Keyword Property LocTypePlayerHouse Auto Const


; ==============================================================
; Public API
; ==============================================================

Bool Function CanProcessLoot(ObjectReference akLoot, PWAL:Looting:LootEffectScript akEffectContext)
	Actor akPlayerActor

	LogDebug("LootValidation", "CanProcessLoot called.")

	If akLoot == None
		LogDebug("LootValidation", "Rejected: loot reference is None.")
		Return false
	EndIf

	If akEffectContext == None
		LogDebug("LootValidation", "Rejected: effect context is None.")
		Return false
	EndIf

	If !IsLootLoaded(akLoot)
		LogDebug("LootValidation", "Rejected: loot is not loaded or is disabled/deleted.")
		Return false
	EndIf

	If IsQuestLoot(akLoot)
		LogDebug("LootValidation", "Rejected: loot is marked as a quest item.")
		Return false
	EndIf

	If !IsPlayerAvailable()
		LogDebug("LootValidation", "Rejected: player is not available.")
		Return false
	EndIf

	If IsProtectedSourceRef(akLoot, akEffectContext)
		LogDebug("LootValidation", "Rejected: protected source reference.")
		Return false
	EndIf

	If IsAlreadyLooted(akLoot, akEffectContext)
		LogDebug("LootValidation", "Rejected: target is already marked as looted.")
		Return false
	EndIf

	If IsInBlockedOwnedArea(akEffectContext)
		LogDebug("LootValidation", "Rejected: blocked owned area.")
		Return false
	EndIf

	If akEffectContext.IsShipContainerMode() && !CanLootShipSpaceContent(akEffectContext)
		LogDebug("LootValidation", "Rejected: ship looting is disabled.")
		Return false
	EndIf

	akPlayerActor = akEffectContext.GetPlayerActor()
	If akPlayerActor != None
		If akPlayerActor.WouldBeStealing(akLoot) && !akEffectContext.CanSteal()
			LogDebug("LootValidation", "Rejected: WouldBeStealing and stealing is not allowed.")
			Return false
		EndIf
	EndIf

	If IsPlayerStealing(akLoot, akEffectContext) && !akEffectContext.CanSteal()
		LogDebug("LootValidation", "Rejected: IsPlayerStealing and stealing is not allowed.")
		Return false
	EndIf

	If !akEffectContext.IsContainerMode() && !akEffectContext.IsCorpseMode()
		If akLoot.GetContainer() != None
			LogDebug("LootValidation", "Rejected: loot still belongs to a live container reference.")
			Return false
		EndIf
	EndIf

	LogDebug("LootValidation", "Accepted: loot passed validation.")
	Return true
EndFunction

Bool Function CanProcess(ObjectReference akLoot, ObjectReference akLooterRef, PWAL:Looting:LootEffectScript akEffectContext)
	Return CanProcessLoot(akLoot, akEffectContext)
EndFunction

; ==============================================================
; Validation Helpers
; ==============================================================

Bool Function CanLootShipSpaceContent(PWAL:Looting:LootEffectScript akEffectContext)
	If akEffectContext == None
		Return false
	EndIf

	If akEffectContext.PWAL_GLOB_Settings_AllowLooting_Ships == None
		LogDebug("LootValidation", "CanLootShipSpaceContent: AllowLooting_Ships global missing. Defaulting to false.")
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

	; PWAL_CONT_Inventory_Reference is the  Ganja Panda's inventory container.
	; It is not a protected home-ship source ref.
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
	Else
		akLootedKeyword = akEffectContext.GetContainerLootedKeyword()
	EndIf

	If akLootedKeyword == None
		Return false
	EndIf

	Return akLoot.HasKeyword(akLootedKeyword)
EndFunction

Bool Function IsInBlockedOwnedArea(PWAL:Looting:LootEffectScript akEffectContext)
	ObjectReference akPlayerRef
	Location akPlayerLocation
	Location akLodgeLocation

	If akEffectContext == None
		Return true
	EndIf

	akPlayerRef = akEffectContext.GetPlayerRef()
	If akPlayerRef == None
		LogDebug("LootValidation", "IsInBlockedOwnedArea: PlayerRef is None. Treating as blocked.")
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
				LogDebug("LootValidation", "Blocked: player home looting global missing.")
				Return true
			EndIf

			If akEffectContext.PWAL_GLOB_Settings_AllowLooting_PlayerHomes.GetValueInt() == 0
				LogDebug("LootValidation", "Blocked: player home looting is disabled.")
				Return true
			EndIf
		EndIf
	EndIf

	; Lodge
	If LodgeLocation != None
		akLodgeLocation = LodgeLocation.GetLocation()

		If akLodgeLocation != None
			If akPlayerRef.IsInLocation(akLodgeLocation)
				If akEffectContext.PWAL_GLOB_Settings_AllowLooting_Lodge == None
					LogDebug("LootValidation", "Blocked: lodge looting global missing.")
					Return true
				EndIf

				If akEffectContext.PWAL_GLOB_Settings_AllowLooting_Lodge.GetValueInt() == 0
					LogDebug("LootValidation", "Blocked: lodge looting is disabled.")
					Return true
				EndIf
			EndIf
		EndIf
	EndIf

	; Player outposts
	If LocTypeOutpost != None
		If akPlayerLocation.HasKeyword(LocTypeOutpost)
			If akEffectContext.PWAL_GLOB_Settings_AllowLooting_Outposts == None
				LogDebug("LootValidation", "Blocked: outpost looting global missing.")
				Return true
			EndIf

			If akEffectContext.PWAL_GLOB_Settings_AllowLooting_Outposts.GetValueInt() == 0
				LogDebug("LootValidation", "Blocked: outpost looting is disabled.")
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