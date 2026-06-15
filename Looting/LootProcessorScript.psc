ScriptName PWAL:Looting:LootProcessorScript Extends Quest Hidden

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.0.4
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
	String sEffectLabel = "UnknownEffect"

	If akCandidates == None
		If akEffectContext != None
			sEffectLabel = akEffectContext.GetEffectDebugLabel()
		EndIf
		LogWarn("LootProcessor", sEffectLabel + " | ProcessCandidates aborted: candidate array is None.")
		Return 0
	EndIf

	If akEffectContext == None
		LogWarn("LootProcessor", "ProcessCandidates aborted: akEffectContext is None.")
		Return 0
	EndIf

	sEffectLabel = akEffectContext.GetEffectDebugLabel()
	LogDebug("LootProcessor", sEffectLabel + " | ProcessCandidates entered. CandidateCount=" + (akCandidates.Length as String))

	If akCandidates.Length <= 0
		LogDebug("LootProcessor", sEffectLabel + " | ProcessCandidates skipped: candidate array is empty.")
		Return 0
	EndIf

	If RuntimeManager == None
		LogError("LootProcessor", sEffectLabel + " | ProcessCandidates failed: RuntimeManager property is not filled.")
		Return 0
	EndIf

	If LootValidation == None
		LogError("LootProcessor", sEffectLabel + " | ProcessCandidates failed: LootValidation property is not filled.")
		Return 0
	EndIf

	If !RuntimeManager.CanRunLooting()
		LogDebug("LootProcessor", sEffectLabel + " | ProcessCandidates skipped: RuntimeManager denied looting.")
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

	LogDebug("LootProcessor", sEffectLabel + " | ProcessCandidates complete. Processed " + iProcessed + " candidate(s).")
	Return iProcessed
EndFunction

Bool Function ProcessSingleCandidate(ObjectReference akLoot, PWAL:Looting:LootEffectScript akEffectContext)
	ObjectReference akResolvedLoot
	String sEffectLabel = "UnknownEffect"
	Form akBaseObject = None
	ObjectReference akContainerRef = None
	Location akCurrentLocation = None

	If akLoot == None
		LogDebug("LootProcessor", sEffectLabel + " | ProcessSingleCandidate aborted: candidate ref is None.")
		Return false
	EndIf

	If akEffectContext == None
		LogDebug("LootProcessor", sEffectLabel + " | ProcessSingleCandidate aborted: akEffectContext is None.")
		Return false
	EndIf

	sEffectLabel = akEffectContext.GetEffectDebugLabel()
	akResolvedLoot = NormalizeCandidateRef(akLoot, akEffectContext)
	If akResolvedLoot == None
		LogDebug("LootProcessor", sEffectLabel + " | ProcessSingleCandidate aborted: normalized loot ref is None. original=" + akLoot)
		Return false
	EndIf

	akBaseObject = akResolvedLoot.GetBaseObject()
	akContainerRef = akResolvedLoot.GetContainer()
	akCurrentLocation = akResolvedLoot.GetCurrentLocation()
	LogDebug("LootProcessor", sEffectLabel + " | Candidate before validation: original=" + akLoot + " resolved=" + akResolvedLoot + " base=" + akBaseObject + " container=" + akContainerRef + " location=" + akCurrentLocation)

	If akEffectContext.IsNonLethalHarvestMode()
		LogDebug("LootProcessor", sEffectLabel + " | Routing candidate as non-lethal harvest: ref=" + akResolvedLoot + " base=" + akBaseObject)
		Return RouteNonLethalHarvest(akResolvedLoot, akEffectContext)
	EndIf

	If akEffectContext.IsCorpseMode()
		LogDebug("LootProcessor", sEffectLabel + " | Routing candidate as corpse: ref=" + akResolvedLoot + " base=" + akBaseObject)
		Return RouteCorpse(akResolvedLoot, akEffectContext)
	EndIf

	If !LootValidation.CanProcessLoot(akResolvedLoot, akEffectContext)
		Return false
	EndIf

	If akEffectContext.IsContainerMode() || akEffectContext.IsShipContainerMode()
		LogDebug("LootProcessor", sEffectLabel + " | Routing candidate as container: ref=" + akResolvedLoot + " base=" + akBaseObject)
		Return RouteContainer(akResolvedLoot, akEffectContext)
	EndIf

	If akEffectContext.IsActivatorMode()
		LogDebug("LootProcessor", sEffectLabel + " | Routing candidate as activator: ref=" + akResolvedLoot + " base=" + akBaseObject)
		Return RouteActivator(akResolvedLoot, akEffectContext)
	EndIf

	If akEffectContext.IsSpellActivationMode()
		LogDebug("LootProcessor", sEffectLabel + " | Routing candidate as spell activation: ref=" + akResolvedLoot + " base=" + akBaseObject)
		Return RouteSpellActivation(akResolvedLoot, akEffectContext)
	EndIf

	If !CanRouteAsLooseLoot(akResolvedLoot, akEffectContext)
		Return false
	EndIf

	LogDebug("LootProcessor", sEffectLabel + " | Routing candidate as loose loot: ref=" + akResolvedLoot + " base=" + akBaseObject)
	Return RouteLooseLoot(akResolvedLoot, akEffectContext)
EndFunction

; ==============================================================
; Route Handlers
; ==============================================================

Bool Function RouteContainer(ObjectReference akContainer, PWAL:Looting:LootEffectScript akEffectContext)
	Form akBase
	Container akBaseContainer
	String sEffectLabel = "UnknownEffect"

	If akContainer == None
		Return false
	EndIf

	If akEffectContext != None
		sEffectLabel = akEffectContext.GetEffectDebugLabel()
	EndIf

	akBase = akContainer.GetBaseObject()
	akBaseContainer = akBase as Container

	If akBaseContainer == None
		LogDebug("LootProcessor", sEffectLabel + " | RouteContainer rejected non-container base: ref=" + akContainer + " base=" + akBase)
		Return false
	EndIf

	If ContainerProcessor == None
		LogWarn("LootProcessor", "RouteContainer failed: ContainerProcessor property is not filled.")
		Return false
	EndIf

	ContainerProcessor.ProcessContainer(akContainer, akEffectContext)
	LogDebug("LootProcessor", sEffectLabel + " | Container routed: " + akContainer)
	Return true
EndFunction

Bool Function RouteCorpse(ObjectReference akCorpse, PWAL:Looting:LootEffectScript akEffectContext)
	Actor akCorpseActor

	If akCorpse == None || akEffectContext == None
		Return false
	EndIf

	akCorpseActor = akCorpse as Actor
	If akCorpseActor == None
		LogDebug("LootProcessor", "RouteCorpse skipped: candidate is not an Actor.")
		Return false
	EndIf

	If !akCorpseActor.IsDead()
		LogDebug("LootProcessor", "RouteCorpse skipped: actor is not dead.")
		Return false
	EndIf

	If LootValidation != None
		If !LootValidation.CanProcessLoot(akCorpse, akEffectContext)
			LogDebug("LootProcessor", "RouteCorpse skipped: LootValidation rejected corpse.")
			Return false
		EndIf
	EndIf

	If CorpseProcessor == None
		LogWarn("LootProcessor", "RouteCorpse failed: CorpseProcessor property is not filled.")
		Return false
	EndIf

	CorpseProcessor.ProcessCorpse(akCorpse, akEffectContext)
	LogDebug("LootProcessor", akEffectContext.GetEffectDebugLabel() + " | Corpse routed: " + akCorpse)
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

	If bProcessed
		LogDebug("LootProcessor", akEffectContext.GetEffectDebugLabel() + " | Nonlethal harvest routed: " + akTarget)
	Else
		LogDebug("LootProcessor", akEffectContext.GetEffectDebugLabel() + " | Nonlethal harvest not processed: " + akTarget)
	EndIf

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
	LogDebug("LootProcessor", akEffectContext.GetEffectDebugLabel() + " | Activator routed: " + akLoot)
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
	LogDebug("LootProcessor", akEffectContext.GetEffectDebugLabel() + " | Spell activation routed: " + akLoot)
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

	LogDebug("LootProcessor", akEffectContext.GetEffectDebugLabel() + " | LOOSE DEBUG BEFORE VALIDATION: ref=" + akLoot + " base=" + akBaseObject + " container=" + akContainingRef + " lootGroup=" + (akEffectContext.GetLootGroupCode() as String) + " activeList=" + akEffectContext.ActiveLootList)

	If akContainingRef != None
		LogDebug("LootProcessor", akEffectContext.GetEffectDebugLabel() + " | RouteLooseLoot rejected: candidate is inside a container/inventory: " + akLoot + " container=" + akContainingRef + " base=" + akBaseObject)
		Return false
	EndIf

	If akBaseObject == None
		LogDebug("LootProcessor", akEffectContext.GetEffectDebugLabel() + " | RouteLooseLoot rejected: base object is None: " + akLoot)
		Return false
	EndIf

	; Quest items must never be auto-looted.
	If akLoot.IsQuestItem()
		LogDebug("LootProcessor", akEffectContext.GetEffectDebugLabel() + " | RouteLooseLoot skipped quest item: " + akLoot)
		Return false
	EndIf

	iDestinationCode = DestinationResolver.ResolveDestinationCode(akEffectContext.GetLootGroupCode())
	LogDebug("LootProcessor", akEffectContext.GetEffectDebugLabel() + " | Resolved destination code " + (iDestinationCode as String) + " for loot group " + (akEffectContext.GetLootGroupCode() as String))

	akDestinationRef = DestinationResolver.ResolveDestinationRef(iDestinationCode)
	If akDestinationRef == None
		LogWarn("LootProcessor", "RouteLooseLoot failed: resolved destination ref is None.")
		Return false
	EndIf

	LogDebug("LootProcessor", akEffectContext.GetEffectDebugLabel() + " | LOOSE DEBUG ADD ATTEMPT: ref=" + akLoot + " base=" + akBaseObject + " dest=" + akDestinationRef)

	akDestinationRef.AddItem(akLoot as Form, 1, true)

	LogDebug("LootProcessor", akEffectContext.GetEffectDebugLabel() + " | Loose loot AddItem attempted by ref form: " + akLoot + " base=" + akBaseObject + " to " + akDestinationRef)
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
		LogDebug("LootProcessor", "Rejected loose-loot route: candidate is Actor ref: " + akLoot)
		Return false
	EndIf

	; Container and corpse effect profiles should route through their processors.
	If akEffectContext.IsContainerMode() || akEffectContext.IsShipContainerMode()
		LogDebug("LootProcessor", "Rejected loose-loot route: effect is container mode.")
		Return false
	EndIf

	If akEffectContext.IsCorpseMode()
		LogDebug("LootProcessor", "Rejected loose-loot route: effect is corpse mode.")
		Return false
	EndIf

	; Loose loot must be an actual placed/world ref, not an inventory pseudo-ref.
	ObjectReference akContainingRef = akLoot.GetContainer()
	If akContainingRef != None
		LogDebug("LootProcessor", "Rejected loose-loot route: candidate is inside a container/inventory: " + akLoot + " container=" + akContainingRef)
		Return false
	EndIf

	; Hard safety guards for framework/player refs.
	If akLoot == akEffectContext.GetPlayerRef()
		LogDebug("LootProcessor", "Rejected loose-loot route: candidate is PlayerRef.")
		Return false
	EndIf

	If akLoot == akEffectContext.GetPWALInventoryContainerRef()
		LogDebug("LootProcessor", "Rejected loose-loot route: candidate is PWAL inventory.")
		Return false
	EndIf

	If akLoot == akEffectContext.GetLodgeSafeRef()
		LogDebug("LootProcessor", "Rejected loose-loot route: candidate is Lodge Safe.")
		Return false
	EndIf

	Return true
EndFunction

ObjectReference Function NormalizeCandidateRef(ObjectReference akLoot, PWAL:Looting:LootEffectScript akEffectContext)
	ObjectReference akShipRef
	String sEffectLabel = "UnknownEffect"

	If akLoot == None
		Return None
	EndIf

	If akEffectContext == None
		Return akLoot
	EndIf

	sEffectLabel = akEffectContext.GetEffectDebugLabel()

	If !akEffectContext.IsShipContainerMode()
		Return akLoot
	EndIf

	If akEffectContext.SpaceshipInventoryContainer != None
		If akLoot.HasKeyword(akEffectContext.SpaceshipInventoryContainer)
			akShipRef = akLoot.GetCurrentShipRef() as ObjectReference
			If akShipRef != None
				LogDebug("LootProcessor", sEffectLabel + " | Ship container candidate normalized from " + akLoot + " to " + akShipRef)
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
