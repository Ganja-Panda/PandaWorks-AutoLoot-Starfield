ScriptName PWAL:Looting:LootProcessorScript Extends Quest Hidden

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.0.3
; Created: 04-10-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: LootProcessorScript
; Type: Looting / Processor Service
; Purpose:
;   Routes scanned loot candidates into the correct PWAL handling
;   path based on the CK-configured LootEffectScript context.
;
; Responsibilities:
;   - Validate candidate refs through LootValidationScript
;   - Route containers to ContainerProcessorScript
;   - Route corpses to CorpseProcessorScript
;   - Handle activator path
;   - Handle spell activation path
;   - Handle direct loose-loot transfer path
;
; Non-Responsibilities:
;   - No scanning
;   - No unlock implementation
;   - No destination policy implementation
;   - No container/corpse deep processing
; ==============================================================

; ==============================================================
; Properties
; ==============================================================

Group FrameworkServices_AutoFill
	PWAL:Core:LoggerScript Property Logger Auto Const Mandatory
	PWAL:Core:RuntimeManagerScript Property RuntimeManager Auto Const Mandatory
	PWAL:Looting:LootValidationScript Property LootValidation Auto Const Mandatory
	PWAL:Looting:DestinationResolverScript Property DestinationResolver Auto Const Mandatory
	PWAL:Looting:ContainerProcessorScript Property ContainerProcessor Auto Const Mandatory
	PWAL:Looting:CorpseProcessorScript Property CorpseProcessor Auto Const Mandatory
	PWAL:Looting:HarvestProcessorScript Property HarvestProcessor Auto Const Mandatory
EndGroup

; ==============================================================
; Public API
; ==============================================================

Int Function ProcessCandidates(ObjectReference[] akCandidates, PWAL:Looting:LootEffectScript akEffectContext)
	Int iIndex
	Int iProcessed

	If akCandidates == None
		LogWarn("LootProcessor", "ProcessCandidates aborted: candidate array is None.")
		Return 0
	EndIf

	If akEffectContext == None
		LogWarn("LootProcessor", "ProcessCandidates aborted: akEffectContext is None.")
		Return 0
	EndIf

	If akCandidates.Length <= 0
		Return 0
	EndIf

	If RuntimeManager == None
		LogError("LootProcessor", "ProcessCandidates failed: RuntimeManager property is not filled.")
		Return 0
	EndIf

	If LootValidation == None
		LogError("LootProcessor", "ProcessCandidates failed: LootValidation property is not filled.")
		Return 0
	EndIf

	If !RuntimeManager.CanRunLooting()
		Return 0
	EndIf

	iIndex = 0
	iProcessed = 0

	While iIndex < akCandidates.Length
		If ProcessSingleCandidate(akCandidates[iIndex], akEffectContext)
			iProcessed += 1
		EndIf

		iIndex += 1
	EndWhile

	Return iProcessed
EndFunction

Bool Function ProcessSingleCandidate(ObjectReference akLoot, PWAL:Looting:LootEffectScript akEffectContext)
	ObjectReference akResolvedLoot

	If akLoot == None
		Return false
	EndIf

	If akEffectContext == None
		Return false
	EndIf

	akResolvedLoot = NormalizeCandidateRef(akLoot, akEffectContext)
	If akResolvedLoot == None
		Return false
	EndIf

	If akEffectContext.IsNonLethalHarvestMode()
		Return RouteNonLethalHarvest(akResolvedLoot, akEffectContext)
	EndIf

	If akEffectContext.IsCorpseMode()
		Return RouteCorpse(akResolvedLoot, akEffectContext)
	EndIf

	If !LootValidation.CanProcessLoot(akResolvedLoot, akEffectContext)
		Return false
	EndIf

	If akEffectContext.IsContainerMode() || akEffectContext.IsShipInteriorMode() || akEffectContext.IsShipContainerMode()
		Return RouteContainer(akResolvedLoot, akEffectContext)
	EndIf

	If akEffectContext.IsActivatorMode()
		Return RouteActivator(akResolvedLoot, akEffectContext)
	EndIf

	If akEffectContext.IsSpellActivationMode()
		Return RouteSpellActivation(akResolvedLoot, akEffectContext)
	EndIf

	If !CanRouteAsLooseLoot(akResolvedLoot, akEffectContext)
		Return false
	EndIf

	Return RouteLooseLoot(akResolvedLoot, akEffectContext)
EndFunction

; ==============================================================
; Route Handlers
; ==============================================================

Bool Function RouteContainer(ObjectReference akContainer, PWAL:Looting:LootEffectScript akEffectContext)
	If akContainer == None
		Return false
	EndIf

	If ContainerProcessor == None
		LogWarn("LootProcessor", "RouteContainer failed: ContainerProcessor property is not filled.")
		Return false
	EndIf

	ContainerProcessor.ProcessValidatedContainer(akContainer, akEffectContext)
	Return true
EndFunction

Bool Function RouteCorpse(ObjectReference akCorpse, PWAL:Looting:LootEffectScript akEffectContext)
	Actor akCorpseActor
	Keyword akLootedKeyword

	If akCorpse == None || akEffectContext == None
		Return false
	EndIf

	akCorpseActor = akCorpse as Actor
	If akCorpseActor == None
		Return false
	EndIf

	If !akCorpseActor.IsDead()
		Return false
	EndIf

	akLootedKeyword = akEffectContext.GetCorpseLootedKeyword()
	If akLootedKeyword != None
		If akCorpse.HasKeyword(akLootedKeyword)
			Return false
		EndIf
	EndIf

	If LootValidation != None
		If !LootValidation.CanProcessLoot(akCorpse, akEffectContext)
			Return false
		EndIf
	EndIf

	If CorpseProcessor == None
		LogWarn("LootProcessor", "RouteCorpse failed: CorpseProcessor property is not filled.")
		Return false
	EndIf

	CorpseProcessor.ProcessValidatedCorpse(akCorpse, akCorpseActor, akEffectContext)
	Return true
EndFunction

Bool Function RouteNonLethalHarvest(ObjectReference akTarget, PWAL:Looting:LootEffectScript akEffectContext)
	If akTarget == None
		Return false
	EndIf

	If HarvestProcessor == None
		LogWarn("LootProcessor", "RouteNonLethalHarvest failed: HarvestProcessor property is not filled.")
		Return false
	EndIf

	Bool bProcessed = HarvestProcessor.ProcessNonLethalHarvest(akTarget, akEffectContext)

	Return bProcessed
EndFunction

Bool Function RouteActivator(ObjectReference akLoot, PWAL:Looting:LootEffectScript akEffectContext)
	ObjectReference akPlayerRef

	If akLoot == None || akEffectContext == None
		Return false
	EndIf

	akPlayerRef = akEffectContext.GetPlayerRef()
	If akPlayerRef == None
		akPlayerRef = Game.GetPlayer()
	EndIf

	If akPlayerRef == None
		LogWarn("LootProcessor", "RouteActivator failed: PlayerRef resolved to None.")
		Return false
	EndIf

	akLoot.Activate(akPlayerRef, false)
	Return true
EndFunction

Bool Function RouteSpellActivation(ObjectReference akLoot, PWAL:Looting:LootEffectScript akEffectContext)
	Spell akLootSpell
	ObjectReference akPlayerRef
	Actor akPlayerActor

	If akLoot == None || akEffectContext == None
		Return false
	EndIf

	akLootSpell = akEffectContext.ActiveLootSpell
	If akLootSpell == None
		LogWarn("LootProcessor", "RouteSpellActivation failed: ActiveLootSpell is None.")
		Return false
	EndIf

	akPlayerRef = akEffectContext.GetPlayerRef()
	If akPlayerRef == None
		akPlayerRef = Game.GetPlayer()
	EndIf

	akPlayerActor = akPlayerRef as Actor

	If akPlayerRef == None || akPlayerActor == None
		LogWarn("LootProcessor", "RouteSpellActivation failed: player reference or actor is None.")
		Return false
	EndIf

	akLootSpell.RemoteCast(akPlayerRef, akPlayerActor, akLoot)
	Return true
EndFunction

Bool Function RouteLooseLoot(ObjectReference akLoot, PWAL:Looting:LootEffectScript akEffectContext)
	ObjectReference akDestinationRef
	ObjectReference akContainingRef
	Form akBaseObject
	Int iDestinationCode

	If akLoot == None
		Return false
	EndIf

	If akEffectContext == None
		LogWarn("LootProcessor", "RouteLooseLoot failed: akEffectContext is None.")
		Return false
	EndIf

	If DestinationResolver == None
		LogWarn("LootProcessor", "RouteLooseLoot failed: DestinationResolver property is not filled.")
		Return false
	EndIf

	; Loose loot must be an actual placed/world ref, not an inventory pseudo-ref.
	akContainingRef = akLoot.GetContainer()
	akBaseObject = akLoot.GetBaseObject()

	If akContainingRef != None
		Return false
	EndIf

	If akBaseObject == None
		Return false
	EndIf

	; Quest items must never be auto-looted.
	If akLoot.IsQuestItem()
		Return false
	EndIf

	iDestinationCode = DestinationResolver.ResolveDestinationCode(akEffectContext.GetLootGroupCode())

	akDestinationRef = DestinationResolver.ResolveDestinationRef(iDestinationCode)
	If akDestinationRef == None
		LogWarn("LootProcessor", "RouteLooseLoot failed: resolved destination ref is None.")
		Return false
	EndIf

	akDestinationRef.AddItem(akLoot as Form, 1, true)

	Return true
EndFunction

; ==============================================================
; Candidate Helpers
; ==============================================================

Bool Function CanRouteAsLooseLoot(ObjectReference akLoot, PWAL:Looting:LootEffectScript akEffectContext)
	If akLoot == None || akEffectContext == None
		Return false
	EndIf

	; Actors/corpses must never fall into loose-loot routing.
	Actor akActor = akLoot as Actor
	If akActor != None
		Return false
	EndIf

	; Container and corpse effect profiles should route through their processors.
	If akEffectContext.IsContainerMode() || akEffectContext.IsShipInteriorMode() || akEffectContext.IsShipContainerMode()
		Return false
	EndIf

	If akEffectContext.IsCorpseMode()
		Return false
	EndIf

	; Loose loot must be an actual placed/world ref, not an inventory pseudo-ref.
	ObjectReference akContainingRef = akLoot.GetContainer()
	If akContainingRef != None
		Return false
	EndIf

	; Hard safety guards for framework/player refs.
	If akLoot == akEffectContext.GetPlayerRef()
		Return false
	EndIf

	If akLoot == akEffectContext.GetPWALInventoryContainerRef()
		Return false
	EndIf

	If akLoot == akEffectContext.GetLodgeSafeRef()
		Return false
	EndIf

	Return true
EndFunction

ObjectReference Function NormalizeCandidateRef(ObjectReference akLoot, PWAL:Looting:LootEffectScript akEffectContext)
	ObjectReference akShipRef

	If akLoot == None
		Return None
	EndIf

	If akEffectContext == None
		Return akLoot
	EndIf

	If !akEffectContext.IsShipInteriorMode()
		Return akLoot
	EndIf

	If akEffectContext.SpaceshipInventoryContainer != None
		If akLoot.HasKeyword(akEffectContext.SpaceshipInventoryContainer)
			akShipRef = akLoot.GetCurrentShipRef() as ObjectReference
			If akShipRef != None
				Return akShipRef
			EndIf
		EndIf
	EndIf

	Return akLoot
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
