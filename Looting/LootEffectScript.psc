ScriptName PWAL:Looting:LootEffectScript Extends ActiveMagicEffect Hidden

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.0.4
; Created: 04-10-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: LootEffectScript
; Type: Looting / Effect Adapter
; Purpose:
;   Thin ActiveMagicEffect adapter for PWAL looting effects.
;   Owns timer lifecycle, local reentry protection, and effect-
;   specific metadata, then hands real work off to framework
;   services.
;
; Responsibilities:
;   - Own timer lifecycle for this effect instance
;   - Guard against local reentry
;   - Expose effect-specific configuration metadata
;   - Ask runtime manager whether looting may execute
;   - Invoke scanner and processor services
;
; Non-Responsibilities:
;   - No scanning implementation
;   - No validation implementation
;   - No unlock handling
;   - No destination routing implementation
;   - No corpse/container transfer logic
; ==============================================================

; ==============================================================
; Properties
; ==============================================================
Group FrameworkServices
	PWAL:Core:LoggerScript Property Logger Auto Const Mandatory
	PWAL:Core:RuntimeManagerScript Property RuntimeManager Auto Const Mandatory
	PWAL:Looting:LootScannerScript Property LootScanner Auto Const Mandatory
	PWAL:Looting:LootProcessorScript Property LootProcessor Auto Const Mandatory
	RefCollectionAlias Property PWAL_RCAL_AsteroidCandidateInbox Auto Const
	RefCollectionAlias Property PWAL_RCAL_ShipDebrisCandidateInbox Auto Const
	RefCollectionAlias Property PWAL_RCAL_SpaceCargoCandidateInbox Auto Const
EndGroup

Group EffectProfile_Mandatory
	Perk Property ActivePerk Auto Const Mandatory
	FormList Property ActiveLootList Auto Const Mandatory
EndGroup

Group EffectProfile_Optional
	Spell Property ActiveLootSpell Auto Const
	Int Property iLootGroupCode = 0 Auto Const
	Formlist Property PWAL_FLST_System_Loot_GroupCodes Auto Const
EndGroup

Group EffectBehavior_Method
	Bool Property bIsActivator = false Auto
	Bool Property bIsContainer = false Auto
	Bool Property bLootDeadActor = false Auto
	Bool Property bIsActivatedBySpell = false Auto
	Bool Property bIsContainerSpace = false Auto
	Bool Property bIsAsteroidDeposit = false Auto Const
	Bool Property bIsShipInterior = false Auto Const
	Bool Property bIsSpaceCargo = false Auto Const
	Bool Property bIsShipDebris = false Auto Const
	Bool Property bIsNonLethalHarvest = false Auto
EndGroup

Group EffectBehavior_FormFilter
	Bool Property bIsKeyword = false Auto
	Bool Property bIsMultipleKeyword = false Auto
EndGroup

Group WorldState_References
	ObjectReference Property PlayerRef Auto Const Mandatory
	ObjectReference Property LodgeSafeRef Auto Const Mandatory
	ObjectReference Property PWAL_INV_REF Auto Const Mandatory
	ReferenceAlias Property PlayerHomeShip Auto Const Mandatory
EndGroup

Group Settings_Looting_AutoFill
	GlobalVariable Property PWAL_GLOB_Settings_AllowLooting_Lodge Auto Const
	GlobalVariable Property PWAL_GLOB_Settings_AllowLooting_Outposts Auto Const
	GlobalVariable Property PWAL_GLOB_Settings_AllowLooting_PlayerHomes Auto Const
	GlobalVariable Property PWAL_GLOB_Settings_AllowLooting_Ships Auto Const
	GlobalVariable Property PWAL_GLOB_Settings_Container_TakeAll Auto Const
	GlobalVariable Property PWAL_GLOB_Settings_Corpses_TakeAll Auto Const
	GlobalVariable Property PWAL_GLOB_Settings_Corpses_Remove Auto Const
	GlobalVariable Property PWAL_GLOB_Settings_Radius_City Auto Const
	GlobalVariable Property PWAL_GLOB_Settings_Radius_Internal Auto Const
	GlobalVariable Property PWAL_GLOB_Settings_Radius_Wilderness Auto Const
	GlobalVariable Property PWAL_GLOB_Settings_Stealing_Allowed Auto Const
	GlobalVariable Property PWAL_GLOB_Settings_Stealing_IsHostile Auto Const
EndGroup

Group Settings_Unlocking_AutoFill
	GlobalVariable Property PWAL_GLOB_Settings_Unlock_Auto Auto Const
	GlobalVariable Property PWAL_GLOB_Settings_Unlock_SkillCheck Auto Const
	GlobalVariable Property LockLevel_Advanced Auto Const
	GlobalVariable Property LockLevel_Expert Auto Const
	GlobalVariable Property LockLevel_Inaccessible Auto Const
	GlobalVariable Property LockLevel_Master Auto Const
	GlobalVariable Property LockLevel_Novice Auto Const
	GlobalVariable Property LockLevel_RequiresKey Auto Const
	Faction Property PlayerFaction Auto Const
	ConditionForm Property PWAL_PERK_CND_LockCheck_Advanced Auto Const
	ConditionForm Property PWAL_PERK_CND_LockCheck_Expert Auto Const
	ConditionForm Property PWAL_PERK_CND_LockCheck_Master Auto Const
	MiscObject Property Digipick Auto Const
EndGroup

Group System_Lists_AutoFill
	FormList Property PWAL_FLST_System_Looting_Globals Auto Const
	FormList Property PWAL_FLST_System_Looting_Lists Auto Const
EndGroup

Group WorldState_Tracking_AutoFill
	Keyword Property PWAL_KYWD_CorpseLooted Auto Const Mandatory
EndGroup

Group WorldState_Forms_AutoFill
	Keyword Property SpaceshipInventoryContainer Auto Const
	Armor Property PWAL_ARMO_Skin_NOTPLAYABLE Auto Const Mandatory
	Armor Property PWAL_ARMO_Skin_Dusty_NOTPLAYABLE Auto Const Mandatory
	Armor Property PWAL_ARMO_Skin_Frozen_NOTPLAYABLE Auto Const Mandatory
	FormList Property PWAL_FLST_Script_Races_Human Auto Const Mandatory
	FormList Property PWAL_FLST_Script_Corpses Auto Const Mandatory
	FormList Property PWAL_FLST_Script_Corpses_Dusty Auto Const Mandatory
	FormList Property PWAL_FLST_Script_Corpses_Frozen Auto Const Mandatory
	FormList Property PWAL_FLST_Script_Locations_Cities Auto Const Mandatory
	GlobalVariable Property PWAL_GLOB_Utilities_Toggle_Logging Auto Const Mandatory
	ConditionForm Property Perk_CND_Zoology_NonLethalHarvest_Target Auto Const Mandatory
EndGroup

Group RuntimeState
	Int Property LootTimerID = 1 Auto
	String Property sEffectDebugName = "" Auto Const
	Float Property lootTimerDelay = 0.5 Auto 
	Bool Property bIsLooting = false Auto Hidden
	Bool Property bAllowStealing = false Auto
	Bool Property bStealingIsHostile = false Auto
	Bool Property bTakeAll = false Auto
	Bool Property bTakeAllContainer = false Auto
	Bool Property bTakeAllCorpse = false Auto
	FormList[] Property CachedLootingLists Auto Hidden
	Int[] Property CachedLootGroupCodes Auto Hidden
	Int Property CachedLootingListCount = 0 Auto Hidden
	Bool Property bLootingListCacheReady = false Auto Hidden
	Float Property initialTimerJitter = 4.0 Auto
	ObjectReference Property theLooterRef Auto 
EndGroup

; ==============================================================
; Events
; ==============================================================

Event OnInit()
	LogDebug("LootEffect", GetEffectDebugLabel() + " | OnInit triggered.")
EndEvent

Event OnEffectStart(ObjectReference akTarget, Actor akCaster, MagicEffect akBaseEffect, Float afMagnitude, Float afDuration)
	LogDebug("LootEffect", GetEffectDebugLabel() + " | OnEffectStart triggered.")
	LogEffectProfile("OnEffectStart")

	RefreshRuntimeSettings()
	EnsureLootingListCacheReady()
	theLooterRef = ResolveLooterRef()
	bIsLooting = false

	CancelTimer(LootTimerID)
	StartTimer(lootTimerDelay, LootTimerID)
EndEvent

Event OnEffectFinish(ObjectReference akTarget, Actor akCaster, MagicEffect akBaseEffect, Float afMagnitude, Float afDuration)
	LogDebug("LootEffect", GetEffectDebugLabel() + " | OnEffectFinish triggered.")

	CancelTimer(LootTimerID)

	bIsLooting = false
	theLooterRef = None
	ClearLootingListCache()
EndEvent

Event OnTimer(Int aiTimerID)
	If aiTimerID != LootTimerID
		Return
	EndIf

	LogDebug("LootEffect", GetEffectDebugLabel() + " | OnTimer fired. aiTimerID=" + (aiTimerID as String))

	If bIsLooting
		LogDebug("LootEffect", GetEffectDebugLabel() + " | OnTimer skipped: looting already in progress.")
		CancelTimer(LootTimerID)
		StartTimer(lootTimerDelay, LootTimerID)
		Return
	EndIf

	bIsLooting = true
	ExecuteLooting()
	bIsLooting = false

	CancelTimer(LootTimerID)
	StartTimer(lootTimerDelay, LootTimerID)
EndEvent

; ==============================================================
; Core Execution
; ==============================================================

Function ExecuteLooting()
	LogDebug("LootEffect", GetEffectDebugLabel() + " | ExecuteLooting entered.")

	If RuntimeManager == None
		LogError("LootEffect", GetEffectDebugLabel() + " | ExecuteLooting aborted: RuntimeManager property is not filled.")
		Return
	EndIf

	If LootScanner == None
		LogError("LootEffect", GetEffectDebugLabel() + " | ExecuteLooting aborted: LootScanner property is not filled.")
		Return
	EndIf

	If LootProcessor == None
		LogError("LootEffect", GetEffectDebugLabel() + " | ExecuteLooting aborted: LootProcessor property is not filled.")
		Return
	EndIf

	If ActiveLootList == None
		LogWarn("LootEffect", GetEffectDebugLabel() + " | ExecuteLooting aborted: ActiveLootList is None.")
		Return
	EndIf

	If !RuntimeManager.CanRunLooting()
		LogDebug("LootEffect", GetEffectDebugLabel() + " | ExecuteLooting aborted: RuntimeManager denied looting.")
		Return
	EndIf

	RefreshRuntimeSettings()
	EnsureLootingListCacheReady()
	theLooterRef = ResolveLooterRef()

	Bool bScannerProcessed = False
	If ActiveLootList.GetSize() > 0
		Int iProcessed = LootScanner.Scan(Self)
		If iProcessed > 0
			bScannerProcessed = True
			LogDebug("LootEffect", GetEffectDebugLabel() + " | ExecuteLooting complete. Scanner processed " + (iProcessed as String) + " candidate(s).")
		EndIf
	Else
		LogDebug("LootEffect", GetEffectDebugLabel() + " | ExecuteLooting scanner skipped: ActiveLootList is empty.")
	EndIf

	Bool bAsteroidProcessed = ProcessAsteroidCandidates()
	Bool bShipDebrisProcessed = ProcessShipDebrisCandidates()
	Bool bSpaceCargoProcessed = ProcessSpaceCargoCandidates()

	If !bScannerProcessed && !bAsteroidProcessed && !bShipDebrisProcessed && !bSpaceCargoProcessed
		LogDebug("LootEffect", GetEffectDebugLabel() + " | ExecuteLooting complete: scanner/asteroid/ship debris/space cargo inbox processed zero candidates.")
	EndIf
EndFunction

Bool Function ProcessAsteroidCandidates()
	If PWAL_RCAL_AsteroidCandidateInbox == None
		Return False
	EndIf

	ObjectReference[] candidates = PWAL_RCAL_AsteroidCandidateInbox.GetArray()

	If candidates == None || candidates.Length <= 0
		Return False
	EndIf

	LogDebug("LootEffect", GetEffectDebugLabel() + " | Asteroid candidate inbox count=" + (candidates.Length as String))

	If LootProcessor == None
		LogWarn("LootEffect", GetEffectDebugLabel() + " | Cannot process asteroid candidates: LootProcessor is None.")
		Return False
	EndIf

	ObjectReference[] singleCandidate = new ObjectReference[1]
	Int iIndex = 0
	Int iProcessed = 0
	Int iCandidateProcessed

	While iIndex < candidates.Length
		If candidates[iIndex] == None
			LogDebug("LootEffect", GetEffectDebugLabel() + " | Ignored None asteroid candidate at index=" + (iIndex as String))
		Else
			singleCandidate[0] = candidates[iIndex]
			iCandidateProcessed = LootProcessor.ProcessCandidates(singleCandidate, Self)

			If iCandidateProcessed > 0
				PWAL_RCAL_AsteroidCandidateInbox.RemoveRef(candidates[iIndex])
				iProcessed += iCandidateProcessed
				LogDebug("LootEffect", GetEffectDebugLabel() + " | Asteroid candidate processed and removed from inbox: " + candidates[iIndex])
			Else
				LogDebug("LootEffect", GetEffectDebugLabel() + " | Asteroid candidate retained in inbox for retry: " + candidates[iIndex])
			EndIf
		EndIf

		iIndex += 1
	EndWhile

	LogDebug("LootEffect", GetEffectDebugLabel() + " | Asteroid candidate processing complete. Processed=" + (iProcessed as String))

	Return iProcessed > 0
EndFunction

Bool Function ProcessShipDebrisCandidates()
	If PWAL_RCAL_ShipDebrisCandidateInbox == None
		Return False
	EndIf

	ObjectReference[] candidates = PWAL_RCAL_ShipDebrisCandidateInbox.GetArray()

	If candidates == None || candidates.Length <= 0
		Return False
	EndIf

	LogDebug("LootEffect", GetEffectDebugLabel() + " | Destroyed ship watch inbox count=" + (candidates.Length as String))

	If LootProcessor == None
		LogWarn("LootEffect", GetEffectDebugLabel() + " | Cannot process ship debris candidates: LootProcessor is None.")
		Return False
	EndIf

	Int iIndex = 0
	Int iProcessed = 0
	Bool bCandidateProcessed

	While iIndex < candidates.Length
		If candidates[iIndex] == None
			LogDebug("LootEffect", GetEffectDebugLabel() + " | Ignored None ship debris candidate at index=" + (iIndex as String))
		Else
			bCandidateProcessed = LootProcessor.RouteShipDebris(candidates[iIndex], Self)

			If bCandidateProcessed
				PWAL_RCAL_ShipDebrisCandidateInbox.RemoveRef(candidates[iIndex])
				iProcessed += 1
				LogDebug("LootEffect", GetEffectDebugLabel() + " | Destroyed ship candidate processed and removed from inbox: " + candidates[iIndex])
			Else
				LogDebug("LootEffect", GetEffectDebugLabel() + " | Destroyed ship candidate retained in inbox for retry: " + candidates[iIndex])
			EndIf
		EndIf

		iIndex += 1
	EndWhile

	LogDebug("LootEffect", GetEffectDebugLabel() + " | Destroyed ship candidate processing complete. Processed=" + (iProcessed as String))

	Return iProcessed > 0
EndFunction

Bool Function ProcessSpaceCargoCandidates()
	If PWAL_RCAL_SpaceCargoCandidateInbox == None
		Return False
	EndIf

	ObjectReference[] candidates = PWAL_RCAL_SpaceCargoCandidateInbox.GetArray()

	If candidates == None || candidates.Length <= 0
		Return False
	EndIf

	LogDebug("LootEffect", GetEffectDebugLabel() + " | Space cargo candidate inbox count=" + (candidates.Length as String))

	If LootProcessor == None
		LogWarn("LootEffect", GetEffectDebugLabel() + " | Cannot process space cargo candidates: LootProcessor is None.")
		Return False
	EndIf

	Int iIndex = 0
	Int iProcessed = 0
	Bool bCandidateProcessed

	While iIndex < candidates.Length
		If candidates[iIndex] == None
			LogDebug("LootEffect", GetEffectDebugLabel() + " | Ignored None space cargo candidate at index=" + (iIndex as String))
		Else
			bCandidateProcessed = LootProcessor.RouteSpaceCargo(candidates[iIndex], Self)

			If bCandidateProcessed
				PWAL_RCAL_SpaceCargoCandidateInbox.RemoveRef(candidates[iIndex])
				iProcessed += 1
				LogDebug("LootEffect", GetEffectDebugLabel() + " | Space cargo candidate processed and removed from inbox: " + candidates[iIndex])
			Else
				LogDebug("LootEffect", GetEffectDebugLabel() + " | Space cargo candidate retained in inbox for retry: " + candidates[iIndex])
			EndIf
		EndIf

		iIndex += 1
	EndWhile

	LogDebug("LootEffect", GetEffectDebugLabel() + " | Space cargo candidate processing complete. Processed=" + (iProcessed as String))

	Return iProcessed > 0
EndFunction

; ==============================================================
; Runtime Setting Cache
; ==============================================================

Function RefreshRuntimeSettings()
	bAllowStealing = GetGlobalBool(PWAL_GLOB_Settings_Stealing_Allowed)
	bStealingIsHostile = GetGlobalBool(PWAL_GLOB_Settings_Stealing_IsHostile)
	bTakeAllContainer = GetGlobalBool(PWAL_GLOB_Settings_Container_TakeAll)
	bTakeAllCorpse = GetGlobalBool(PWAL_GLOB_Settings_Corpses_TakeAll)
EndFunction

; ==============================================================
; Looting Registry Cache
; ==============================================================

Function ClearLootingListCache()
	CachedLootingLists = None
	CachedLootGroupCodes = None
	CachedLootingListCount = 0
	bLootingListCacheReady = false
EndFunction


Function EnsureLootingListCacheReady()
	If !bLootingListCacheReady
		LogDebug("LootEffect", GetEffectDebugLabel() + " | Rebuilding looting list cache: cache is not ready.")
		RefreshLootingListCache()
	EndIf
EndFunction


Function RefreshLootingListCache()
	FormList akLootingLists
	FormList akLootingGlobals
	FormList akLootGroupCodes
	FormList akCurrentList
	GlobalVariable akCurrentGlobal
	GlobalVariable akCurrentLootGroupCodeGlobal
	Int iListSize
	Int iGlobalSize
	Int iCodeSize
	Int iMaxSize
	Int iIndex
	Int iWriteIndex

	ClearLootingListCache()

	akLootingLists = PWAL_FLST_System_Looting_Lists
	akLootingGlobals = PWAL_FLST_System_Looting_Globals
	akLootGroupCodes = PWAL_FLST_System_Loot_GroupCodes

	If akLootingLists == None || akLootingGlobals == None || akLootGroupCodes == None
		LogWarn("LootEffect", GetEffectDebugLabel() + " | RefreshLootingListCache aborted: one or more system looting lists are None.")
		Return
	EndIf

	iListSize = akLootingLists.GetSize()
	iGlobalSize = akLootingGlobals.GetSize()
	iCodeSize = akLootGroupCodes.GetSize()

	iMaxSize = iListSize

	If iGlobalSize < iMaxSize
		iMaxSize = iGlobalSize
	EndIf

	If iCodeSize < iMaxSize
		iMaxSize = iCodeSize
	EndIf

	If iMaxSize <= 0
		LogDebug("LootEffect", GetEffectDebugLabel() + " | RefreshLootingListCache skipped: no looting registry entries configured.")
		Return
	EndIf

	If iMaxSize < iListSize || iMaxSize < iGlobalSize || iMaxSize < iCodeSize
		LogWarn("LootEffect", GetEffectDebugLabel() + " | RefreshLootingListCache detected mismatched paired list sizes. Lists=" + (iListSize as String) + " Globals=" + (iGlobalSize as String) + " Codes=" + (iCodeSize as String) + " Using=" + (iMaxSize as String))
	EndIf

	CachedLootingLists = new FormList[iMaxSize]
	CachedLootGroupCodes = new Int[iMaxSize]

	iIndex = 0
	iWriteIndex = 0

	While iIndex < iMaxSize
		akCurrentList = akLootingLists.GetAt(iIndex) as FormList
		akCurrentGlobal = akLootingGlobals.GetAt(iIndex) as GlobalVariable
		akCurrentLootGroupCodeGlobal = akLootGroupCodes.GetAt(iIndex) as GlobalVariable

		If akCurrentList != None && akCurrentGlobal != None && akCurrentLootGroupCodeGlobal != None
			If akCurrentGlobal.GetValueInt() > 0
				CachedLootingLists[iWriteIndex] = akCurrentList
				CachedLootGroupCodes[iWriteIndex] = akCurrentLootGroupCodeGlobal.GetValueInt()
				iWriteIndex += 1
			EndIf
		EndIf

		iIndex += 1
	EndWhile

	CachedLootingListCount = iWriteIndex
	bLootingListCacheReady = true

	; LogDebug("LootEffect", "RefreshLootingListCache complete. EnabledGroups=" + (CachedLootingListCount as String))
EndFunction


Int Function GetCachedLootingListCount()
	Return CachedLootingListCount
EndFunction


FormList Function GetCachedLootingList(Int aiIndex)
	If CachedLootingLists == None
		Return None
	EndIf

	If aiIndex < 0 || aiIndex >= CachedLootingListCount
		Return None
	EndIf

	Return CachedLootingLists[aiIndex]
EndFunction


Int Function GetCachedLootGroupCode(Int aiIndex)
	If CachedLootGroupCodes == None
		Return 0
	EndIf

	If aiIndex < 0 || aiIndex >= CachedLootingListCount
		Return 0
	EndIf

	Return CachedLootGroupCodes[aiIndex]
EndFunction

Bool Function IsLootingListCacheReady()
	Return bLootingListCacheReady
EndFunction

; ==============================================================
; Effect Context Helpers
; ==============================================================

String Function GetEffectDebugLabel()
	If sEffectDebugName != ""
		Return sEffectDebugName + " | TimerID=" + (LootTimerID as String)
	EndIf

	Return "UnnamedEffect | TimerID=" + (LootTimerID as String)
EndFunction

Int Function GetLootGroupCode()
	Return iLootGroupCode
EndFunction

Bool Function IsNonLethalHarvestMode()
	Return bIsNonLethalHarvest
EndFunction

Bool Function IsContainerMode()
	Return bIsContainer
EndFunction

Bool Function IsCorpseMode()
	Return bLootDeadActor
EndFunction

Bool Function IsActivatorMode()
	Return bIsActivator
EndFunction

Bool Function IsSpellActivationMode()
	Return bIsActivatedBySpell
EndFunction

Bool Function IsShipContainerMode()
	Return bIsShipInterior
EndFunction

Bool Function IsAsteroidDepositMode()
	Return bIsAsteroidDeposit
EndFunction

Bool Function IsShipInteriorMode()
	Return bIsShipInterior
EndFunction

Bool Function IsSpaceCargoMode()
	Return bIsSpaceCargo
EndFunction

Bool Function IsShipDebrisMode()
	Return bIsShipDebris
EndFunction

Bool Function UsesKeywordScan()
	Return bIsKeyword
EndFunction

Bool Function UsesMultipleKeywordScan()
	Return bIsMultipleKeyword
EndFunction

Bool Function CanSteal()
	Return bAllowStealing
EndFunction

Bool Function IsStealingHostile()
	Return bStealingIsHostile
EndFunction

Bool Function TakeAllContainers()
	Return bTakeAllContainer
EndFunction

Bool Function TakeAllCorpses()
	Return bTakeAllCorpse
EndFunction

Bool Function CanAutoUnlock()
	Return GetGlobalBool(PWAL_GLOB_Settings_Unlock_Auto)
EndFunction

Bool Function UseAutoUnlockSkillCheck()
	Return GetGlobalBool(PWAL_GLOB_Settings_Unlock_SkillCheck)
EndFunction

Bool Function RemoveCorpsesEnabled()
	Return GetGlobalBool(PWAL_GLOB_Settings_Corpses_Remove)
EndFunction

Float Function GetRadius()
	If bIsSpaceCargo || bIsShipDebris
		Float fShipDistance = Game.GetGameSettingFloat("fMaxShipTransferDistance")

		If fShipDistance > 0.0
			Return fShipDistance
		EndIf

		LogWarn("LootEffect", GetEffectDebugLabel() + " | GetRadius fallback: fMaxShipTransferDistance returned invalid value.")
		Return 0.0
	EndIf

	If PWAL_GLOB_Settings_Radius_Internal == None
		LogWarn("LootEffect", GetEffectDebugLabel() + " | GetRadius fallback: PWAL_GLOB_Settings_Radius_Internal is not filled.")
		Return 0.0
	EndIf

	If PWAL_GLOB_Settings_Radius_City == None
		LogWarn("LootEffect", GetEffectDebugLabel() + " | GetRadius fallback: PWAL_GLOB_Settings_Radius_City is not filled.")
		Return 0.0
	EndIf

	If PWAL_GLOB_Settings_Radius_Wilderness == None
		LogWarn("LootEffect", GetEffectDebugLabel() + " | GetRadius fallback: PWAL_GLOB_Settings_Radius_Wilderness is not filled.")
		Return 0.0
	EndIf

	ObjectReference akRef = theLooterRef

	If akRef == None
		akRef = GetPlayerRef()
	EndIf

	If akRef == None
		LogWarn("LootEffect", GetEffectDebugLabel() + " | GetRadius fallback: no looter/player ref available. Using internal radius.")
		Return PWAL_GLOB_Settings_Radius_Internal.GetValue()
	EndIf

	If akRef.IsInInterior()
		Return PWAL_GLOB_Settings_Radius_Internal.GetValue()
	EndIf

	Location akLocation = akRef.GetCurrentLocation()

	If IsCityLocation(akLocation)
		Return PWAL_GLOB_Settings_Radius_City.GetValue()
	EndIf

	Return PWAL_GLOB_Settings_Radius_Wilderness.GetValue()
EndFunction


Bool Function IsCityLocation(Location akLocation)
	If akLocation == None
		Return false
	EndIf

	If PWAL_FLST_Script_Locations_Cities == None
		LogDebug("LootEffect", GetEffectDebugLabel() + " | IsCityLocation fallback: PWAL_FLST_Script_Locations_Cities is not filled.")
		Return false
	EndIf

	Return PWAL_FLST_Script_Locations_Cities.HasForm(akLocation)
EndFunction

ObjectReference Function ResolveLooterRef()
	; Ship looting is still unresolved, so keep this conservative for now.
	Return GetPlayerRef()
EndFunction

ObjectReference Function GetPlayerRef()
	If PlayerRef != None
		Return PlayerRef
	EndIf

	Return Game.GetPlayer()
EndFunction

Actor Function GetPlayerActor()
	Return GetPlayerRef() as Actor
EndFunction

ObjectReference Function GetPlayerHomeShipRef()
	If PlayerHomeShip != None
		Return PlayerHomeShip.GetReference()
	EndIf

	Return None
EndFunction

ObjectReference Function GetPWALInventoryContainerRef()
	Return PWAL_INV_REF
EndFunction

ObjectReference Function GetLodgeSafeRef()
	Return LodgeSafeRef
EndFunction

Keyword Function GetCorpseLootedKeyword()
	Return PWAL_KYWD_CorpseLooted
EndFunction

Bool Function IsHumanRace(Actor akActor)
	If akActor == None
		Return false
	EndIf

	If PWAL_FLST_Script_Races_Human == None
		LogWarn("LootEffect", GetEffectDebugLabel() + " | IsHumanRace fallback: PWAL_FLST_Script_Races_Human is not filled.")
		Return false
	EndIf

	Race akRace = akActor.GetRace()
	if akRace == None
		Return false
	EndIf
	
	Return PWAL_FLST_Script_Races_Human.HasForm(akRace)
EndFunction

; ==============================================================
; Utility Helpers
; ==============================================================

Function LogEffectProfile(String asReason)
	LogDebug("LootEffect", GetEffectDebugLabel() + " | Profile dump requested by " + asReason)
	LogDebug("LootEffect", GetEffectDebugLabel() + " | Profile | ActivePerk=" + ActivePerk)
	LogDebug("LootEffect", GetEffectDebugLabel() + " | Profile | ActiveLootList=" + ActiveLootList)
	LogDebug("LootEffect", GetEffectDebugLabel() + " | Profile | ActiveLootSpell=" + ActiveLootSpell)
	LogDebug("LootEffect", GetEffectDebugLabel() + " | Profile | iLootGroupCode=" + (iLootGroupCode as String))
	LogDebug("LootEffect", GetEffectDebugLabel() + " | Profile | bIsActivator=" + (bIsActivator as String))
	LogDebug("LootEffect", GetEffectDebugLabel() + " | Profile | bIsContainer=" + (bIsContainer as String))
	LogDebug("LootEffect", GetEffectDebugLabel() + " | Profile | bIsAsteroidDeposit=" + (bIsAsteroidDeposit as String))
	LogDebug("LootEffect", GetEffectDebugLabel() + " | Profile | bIsShipInterior=" + (bIsShipInterior as String))
	LogDebug("LootEffect", GetEffectDebugLabel() + " | Profile | bIsSpaceCargo=" + (bIsSpaceCargo as String))
	LogDebug("LootEffect", GetEffectDebugLabel() + " | Profile | bIsShipDebris=" + (bIsShipDebris as String))
	LogDebug("LootEffect", GetEffectDebugLabel() + " | Profile | bLootDeadActor=" + (bLootDeadActor as String))
	LogDebug("LootEffect", GetEffectDebugLabel() + " | Profile | bIsActivatedBySpell=" + (bIsActivatedBySpell as String))
	LogDebug("LootEffect", GetEffectDebugLabel() + " | Profile | bIsContainerSpace=" + (bIsContainerSpace as String))
	LogDebug("LootEffect", GetEffectDebugLabel() + " | Profile | bIsNonLethalHarvest=" + (bIsNonLethalHarvest as String))
	LogDebug("LootEffect", GetEffectDebugLabel() + " | Profile | bIsKeyword=" + (bIsKeyword as String))
	LogDebug("LootEffect", GetEffectDebugLabel() + " | Profile | bIsMultipleKeyword=" + (bIsMultipleKeyword as String))
EndFunction

Bool Function GetGlobalBool(GlobalVariable akGlobal)
	If akGlobal == None
		Return false
	EndIf

	Return akGlobal.GetValueInt() > 0
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
