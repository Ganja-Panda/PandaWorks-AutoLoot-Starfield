ScriptName PWAL:Looting:LootEffectScript Extends ActiveMagicEffect Hidden

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.00
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
EndGroup

Group EffectProfile_Mandatory
	Perk Property ActivePerk Auto Const Mandatory
	FormList Property ActiveLootList Auto Const Mandatory
EndGroup

Group EffectProfile_Optional
	Spell Property ActiveLootSpell Auto Const
EndGroup

Group EffectBehavior_Method
	Bool Property bIsActivator = false Auto
	Bool Property bIsContainer = false Auto
	Bool Property bLootDeadActor = false Auto
	Bool Property bIsActivatedBySpell = false Auto
	Bool Property bIsContainerSpace = false Auto
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
	Keyword Property PWAL_KYWD_Corpse_Looted Auto Const Mandatory
EndGroup

Group WorldState_Forms_AutoFill
	Keyword Property SpaceshipInventoryContainer Auto Const
	Armor Property PWAL_ARMO_Skin_NOTPLAYABLE Auto Const Mandatory
	Armor Property PWAL_ARMO_Skin_Dusty_NOTPLAYABLE Auto Const Mandatory
	Armor Property PWAL_ARMO_Skin_Frozen_NOTPLAYABLE Auto Const Mandatory
	FormList Property PWAL_FLST_Script_HumanRaces Auto Const Mandatory
	GlobalVariable Property PWAL_GLOB_Utilities_Toggle_Logging Auto Const Mandatory
EndGroup

Group RuntimeState
	Int Property LootTimerID = 1 Auto
	Float Property lootTimerDelay = 0.5 Auto 
	Bool Property bIsLooting = false Auto Hidden
	Bool Property bAllowStealing = false Auto
	Bool Property bStealingIsHostile = false Auto
	Bool Property bTakeAll = false Auto
	Bool Property bTakeAllContainer = false Auto
	Bool Property bTakeAllCorpse = false Auto
	Float Property initialTimerJitter = 4.0 Auto
	ObjectReference Property theLooterRef Auto 
EndGroup

; ==============================================================
; Events
; ==============================================================

Event OnInit()
	LogDebug("LootEffect", "OnInit triggered.")
EndEvent

Event OnEffectStart(ObjectReference akTarget, Actor akCaster, MagicEffect akBaseEffect, Float afMagnitude, Float afDuration)
	LogDebug("LootEffect", "OnEffectStart triggered.")

	RefreshRuntimeSettings()
	theLooterRef = ResolveLooterRef()
	bIsLooting = false

	CancelTimer(LootTimerID)
	StartTimer(lootTimerDelay, LootTimerID)
EndEvent

Event OnEffectFinish(ObjectReference akTarget, Actor akCaster, MagicEffect akBaseEffect, Float afMagnitude, Float afDuration)
	LogDebug("LootEffect", "OnEffectFinish triggered.")

	CancelTimer(LootTimerID)

	bIsLooting = false
	theLooterRef = None
EndEvent

Event OnTimer(Int aiTimerID)
	If aiTimerID != LootTimerID
		Return
	EndIf

	If bIsLooting
		LogDebug("LootEffect", "OnTimer skipped: looting already in progress.")
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
	If RuntimeManager == None
		LogError("LootEffect", "ExecuteLooting failed: RuntimeManager property is not filled.")
		Return
	EndIf

	If LootScanner == None
		LogError("LootEffect", "ExecuteLooting failed: LootScanner property is not filled.")
		Return
	EndIf

	If LootProcessor == None
		LogError("LootEffect", "ExecuteLooting failed: LootProcessor property is not filled.")
		Return
	EndIf

	If ActiveLootList == None
		LogWarn("LootEffect", "ExecuteLooting aborted: ActiveLootList is None.")
		Return
	EndIf

	If ActiveLootList.GetSize() <= 0
		LogDebug("LootEffect", "ExecuteLooting skipped: ActiveLootList is empty.")
		Return
	EndIf

	If !RuntimeManager.CanRunLooting()
		LogDebug("LootEffect", "ExecuteLooting skipped: RuntimeManager denied looting.")
		Return
	EndIf

	RefreshRuntimeSettings()
	theLooterRef = ResolveLooterRef()

	ObjectReference[] akCandidates = LootScanner.Scan(Self)

	If akCandidates == None
		LogDebug("LootEffect", "ExecuteLooting complete: scanner returned None.")
		Return
	EndIf

	If akCandidates.Length <= 0
		LogDebug("LootEffect", "ExecuteLooting complete: scanner returned zero candidates.")
		Return
	EndIf

	LogDebug("LootEffect", "ExecuteLooting forwarding " + akCandidates.Length + " candidates to LootProcessor.")
	LootProcessor.ProcessCandidates(akCandidates, Self)
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
; Effect Context Helpers
; ==============================================================

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
	Return bIsContainerSpace
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
	If bIsContainerSpace
		Return Game.GetGameSettingFloat("fMaxShipTransferDistance")
	EndIf

	If PWAL_GLOB_Settings_Radius_Internal == None
		LogWarn("LootEffect", "GetRadius fallback: PWAL_GLOB_Settings_Radius_Internal is not filled.")
		Return 0.0
	EndIf

	Return PWAL_GLOB_Settings_Radius_Internal.GetValue()
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
	Return PWAL_KYWD_Corpse_Looted
EndFunction

Bool Function IsHumanRace(Actor akActor)
	If akActor == None
		Return false
	EndIf

	If PWAL_FLST_Script_HumanRaces == None
		LogWarn("LootEffect", "IsHumanRace fallback: PWAL_FLST_Script_HumanCorpseRaces is not filled.")
		Return false
	EndIf

	Race akRace = akActor.GetRace()
	if akRace == None
		Return false
	EndIf
	
	Return PWAL_FLST_Script_HumanRaces.HasForm(akRace)
EndFunction

; ==============================================================
; Utility Helpers
; ==============================================================

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