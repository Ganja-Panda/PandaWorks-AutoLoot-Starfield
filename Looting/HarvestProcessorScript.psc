ScriptName PWAL:Looting:HarvestProcessorScript Extends Quest Hidden

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.00
; Created: 05-11-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: HarvestProcessorScript
; Type: Looting / Processor Service
; Purpose:
;   Handles harvest-style loot targets routed by LootProcessorScript.
;
; Responsibilities:
;   - Process nonlethal organic harvest targets
;   - Verify the vanilla Zoology nonlethal harvest condition
;   - Trigger the configured harvest spell
;   - Activate the harvest target after spell cast
;
; Non-Responsibilities:
;   - No scanning
;   - No timer lifecycle
;   - No destination routing
;   - No inventory transfer
;   - No category filtering
; ==============================================================

; ==============================================================
; Properties
; ==============================================================

Group FrameworkServices_AutoFill
	PWAL:Core:LoggerScript Property Logger Auto Const Mandatory
EndGroup

; ==============================================================
; Public API
; ==============================================================

Bool Function ProcessNonLethalHarvest(ObjectReference akTarget, PWAL:Looting:LootEffectScript akEffectContext)
	ObjectReference akPlayerRef
	Actor akPlayerActor
	Spell akHarvestSpell
	ConditionForm akHarvestCondition

	If akTarget == None
		LogDebug("HarvestProcessor", "ProcessNonLethalHarvest skipped: akTarget is None.")
		Return false
	EndIf

	If akEffectContext == None
		LogWarn("HarvestProcessor", "ProcessNonLethalHarvest failed: akEffectContext is None.")
		Return false
	EndIf

	If !Game.IsActivateControlsEnabled()
		LogDebug("HarvestProcessor", "ProcessNonLethalHarvest skipped: activate controls are disabled.")
		Return false
	EndIf

	If !IsHarvestTargetLoaded(akTarget)
		LogDebug("HarvestProcessor", "ProcessNonLethalHarvest skipped: target is not loaded or valid.")
		Return false
	EndIf

	akPlayerRef = akEffectContext.GetPlayerRef()
	akPlayerActor = akEffectContext.GetPlayerActor()

	If akPlayerRef == None
		LogWarn("HarvestProcessor", "ProcessNonLethalHarvest failed: player ref is None.")
		Return false
	EndIf

	If akPlayerActor == None
		LogWarn("HarvestProcessor", "ProcessNonLethalHarvest failed: player actor is None.")
		Return false
	EndIf

	akHarvestSpell = akEffectContext.ActiveLootSpell
	If akHarvestSpell == None
		LogWarn("HarvestProcessor", "ProcessNonLethalHarvest failed: ActiveLootSpell is None.")
		Return false
	EndIf

	akHarvestCondition = akEffectContext.Perk_CND_Zoology_NonLethalHarvest_Target
	If akHarvestCondition == None
		LogWarn("HarvestProcessor", "ProcessNonLethalHarvest failed: Perk_CND_Zoology_NonLethalHarvest_Target is None.")
		Return false
	EndIf

	If !akHarvestCondition.IsTrue(akTarget, akPlayerRef)
		LogDebug("HarvestProcessor", "ProcessNonLethalHarvest skipped: vanilla Zoology condition returned false.")
		Return false
	EndIf

	LogDebug("HarvestProcessor", "Nonlethal harvest target accepted: " + akTarget)

	akHarvestSpell.RemoteCast(akPlayerRef, akPlayerActor, akTarget)
	akTarget.Activate(akPlayerRef, false)

	LogDebug("HarvestProcessor", "Nonlethal harvest processed: " + akTarget)
	Return true
EndFunction

; ==============================================================
; Validation Helpers
; ==============================================================

Bool Function IsHarvestTargetLoaded(ObjectReference akTarget)
	If akTarget == None
		Return false
	EndIf

	If !akTarget.Is3DLoaded()
		Return false
	EndIf

	If akTarget.IsDisabled()
		Return false
	EndIf

	If akTarget.IsDeleted()
		Return false
	EndIf

	Return true
EndFunction

; ==============================================================
; Internal Logging Wrappers
; ==============================================================

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