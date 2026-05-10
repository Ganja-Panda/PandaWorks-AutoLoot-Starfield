ScriptName PWAL:Looting:LootProcessorScript Extends Quest Hidden

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.00
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
		LogDebug("LootProcessor", "ProcessCandidates skipped: candidate array is empty.")
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
		LogDebug("LootProcessor", "ProcessCandidates skipped: RuntimeManager denied looting.")
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

	LogDebug("LootProcessor", "ProcessCandidates complete. Processed " + iProcessed + " candidate(s).")
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
		LogDebug("LootProcessor", "ProcessSingleCandidate skipped: normalized loot ref is None.")
		Return false
	EndIf

	If !LootValidation.CanProcessLoot(akResolvedLoot, akEffectContext)
		LogDebug("LootProcessor", "Candidate rejected by LootValidation: " + akResolvedLoot)
		Return false
	EndIf

	If akEffectContext.IsCorpseMode()
		Return RouteCorpse(akResolvedLoot, akEffectContext)
	EndIf

	If akEffectContext.IsContainerMode() || akEffectContext.IsShipContainerMode()
		Return RouteContainer(akResolvedLoot, akEffectContext)
	EndIf

	If akEffectContext.IsActivatorMode()
		Return RouteActivator(akResolvedLoot, akEffectContext)
	EndIf

	If akEffectContext.IsSpellActivationMode()
		Return RouteSpellActivation(akResolvedLoot, akEffectContext)
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

	ContainerProcessor.ProcessContainer(akContainer, akEffectContext)
	LogDebug("LootProcessor", "Container routed: " + akContainer)
	Return true
EndFunction

Bool Function RouteCorpse(ObjectReference akCorpse, PWAL:Looting:LootEffectScript akEffectContext)
	Actor akCorpseActor

	If akCorpse == None
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

	If CorpseProcessor == None
		LogWarn("LootProcessor", "RouteCorpse failed: CorpseProcessor property is not filled.")
		Return false
	EndIf

	CorpseProcessor.ProcessCorpse(akCorpse, akEffectContext)
	LogDebug("LootProcessor", "Corpse routed: " + akCorpse)
	Return true
EndFunction

Bool Function RouteActivator(ObjectReference akLoot, PWAL:Looting:LootEffectScript akEffectContext)
	ObjectReference akLooterRef

	If akLoot == None
		Return false
	EndIf

	akLooterRef = akEffectContext.theLooterRef
	If akLooterRef == None
		akLooterRef = akEffectContext.GetPlayerRef()
	EndIf

	akLoot.Activate(akLooterRef, false)
	LogDebug("LootProcessor", "Activator routed: " + akLoot)
	Return true
EndFunction

Bool Function RouteSpellActivation(ObjectReference akLoot, PWAL:Looting:LootEffectScript akEffectContext)
	Spell akLootSpell
	ObjectReference akPlayerRef
	Actor akPlayerActor

	If akLoot == None
		Return false
	EndIf

	akLootSpell = akEffectContext.ActiveLootSpell
	If akLootSpell == None
		LogWarn("LootProcessor", "RouteSpellActivation failed: ActiveLootSpell is None.")
		Return false
	EndIf

	akPlayerRef = akEffectContext.GetPlayerRef()
	akPlayerActor = akEffectContext.GetPlayerActor()

	If akPlayerRef == None || akPlayerActor == None
		LogWarn("LootProcessor", "RouteSpellActivation failed: player reference or actor is None.")
		Return false
	EndIf

	akLootSpell.RemoteCast(akPlayerRef, akPlayerActor, akLoot)
	LogDebug("LootProcessor", "Spell activation routed: " + akLoot)
	Return true
EndFunction

Bool Function RouteLooseLoot(ObjectReference akLoot, PWAL:Looting:LootEffectScript akEffectContext)
	ObjectReference akDestinationRef
	Form akLootForm
	Int iDestinationCode

	If akLoot == None
		Return false
	EndIf

	If DestinationResolver == None
		LogWarn("LootProcessor", "RouteLooseLoot failed: DestinationResolver property is not filled.")
		Return false
	EndIf

	iDestinationCode = DestinationResolver.ResolveDestinationCode()
	akDestinationRef = DestinationResolver.ResolveDestinationRef(iDestinationCode)
	If akDestinationRef == None
		LogWarn("LootProcessor", "RouteLooseLoot failed: resolved destination ref is None.")
		Return false
	EndIf

	akLootForm = akLoot as Form
	If akLootForm == None
		LogWarn("LootProcessor", "RouteLooseLoot failed: loot reference could not be cast to Form.")
		Return false
	EndIf

	akDestinationRef.AddItem(akLootForm, -1, false)
	LogDebug("LootProcessor", "Loose loot transferred: " + akLoot)
	Return true
EndFunction

; ==============================================================
; Candidate Helpers
; ==============================================================

ObjectReference Function NormalizeCandidateRef(ObjectReference akLoot, PWAL:Looting:LootEffectScript akEffectContext)
	ObjectReference akShipRef

	If akLoot == None
		Return None
	EndIf

	If akEffectContext == None
		Return akLoot
	EndIf

	If !akEffectContext.IsShipContainerMode()
		Return akLoot
	EndIf

	If akEffectContext.SpaceshipInventoryContainer != None
		If akLoot.HasKeyword(akEffectContext.SpaceshipInventoryContainer)
			akShipRef = akLoot.GetCurrentShipRef() as ObjectReference
			If akShipRef != None
				LogDebug("LootProcessor", "Ship container candidate normalized from " + akLoot + " to " + akShipRef)
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