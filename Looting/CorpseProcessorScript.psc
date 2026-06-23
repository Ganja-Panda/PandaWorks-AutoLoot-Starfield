ScriptName PWAL:Looting:CorpseProcessorScript Extends Quest Hidden

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.0.2
; Created: 04-10-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: CorpseProcessorScript
; Type: Looting / Corpse Processor Service
; Purpose:
;   Handles corpse-specific loot processing for PWAL.
;
; Responsibilities:
;   - Skip already-looted corpses
;   - Transfer corpse inventory
;   - Support take-all corpse mode
;   - Mark successfully processed corpses as looted
;   - Remove/disable corpse when configured
;
; Non-Responsibilities:
;   - No scanning
;   - No top-level routing
;   - No unlocking
;   - No destination policy ownership
; ==============================================================

Group FrameworkServices_AutoFill
	PWAL:Core:LoggerScript Property Logger Auto Const Mandatory
	PWAL:Looting:DestinationResolverScript Property DestinationResolver Auto Const Mandatory
EndGroup

; ==============================================================
; Public API
; ==============================================================

Function ProcessCorpse(ObjectReference akCorpse, PWAL:Looting:LootEffectScript akEffectContext)
	Actor akCorpseActor

	If akCorpse == None
		LogWarn("CorpseProcessor", "ProcessCorpse aborted: akCorpse is None.")
		Return
	EndIf

	If akEffectContext == None
		LogWarn("CorpseProcessor", "ProcessCorpse aborted: akEffectContext is None.")
		Return
	EndIf

	akCorpseActor = akCorpse as Actor
	If akCorpseActor == None
		Return
	EndIf

	If !akCorpseActor.IsDead()
		Return
	EndIf

	If IsCorpseAlreadyLooted(akCorpse, akEffectContext)
		Return
	EndIf

	ProcessValidatedCorpse(akCorpse, akCorpseActor, akEffectContext)
EndFunction

Function ProcessValidatedCorpse(ObjectReference akCorpse, Actor akCorpseActor, PWAL:Looting:LootEffectScript akEffectContext)
	ObjectReference akDestinationRef
	Bool bIsHumanCorpse
	Bool bTransferSucceeded = false

	If akCorpse == None
		Return
	EndIf

	If akCorpseActor == None
		Return
	EndIf

	If akEffectContext == None
		Return
	EndIf

	If DestinationResolver == None
		LogError("CorpseProcessor", "ProcessCorpse failed: DestinationResolver property is not filled.")
		Return
	EndIf

	; Expose equipped inventory BEFORE transfer, but do not apply replacement skin yet.
	bIsHumanCorpse = akEffectContext.IsHumanRace(akCorpseActor)

	If bIsHumanCorpse
		akCorpseActor.UnequipAll()
		Utility.Wait(0.05) ; Small delay to ensure inventory is updated before transfer.
	EndIf

	If akEffectContext.TakeAllCorpses()
		Int iDestinationCode
		iDestinationCode = DestinationResolver.ResolveDestinationCode(DestinationResolver.LG_CORPSES)

		akDestinationRef = DestinationResolver.ResolveDestinationRef(iDestinationCode)
		If akDestinationRef == None
			LogWarn("CorpseProcessor", "ProcessCorpse aborted: corpse destination ref resolved to None.")
			Return
		EndIf

		bTransferSucceeded = ProcessTakeAllCorpse(akCorpse, akDestinationRef, akEffectContext)
	Else
		bTransferSucceeded = ProcessFilteredCorpseItems(akCorpse, None, akEffectContext)
	EndIf

	If !bTransferSucceeded
		Return
	EndIf

	; Apply corpse skin AFTER transfer so RemoveAllItems/RemoveItem cannot steal it.
	If bIsHumanCorpse
		ApplyHumanCorpseSkin(akCorpseActor, akEffectContext)
	EndIf

	MarkCorpseAsLooted(akCorpse, akEffectContext)

	If akEffectContext.RemoveCorpsesEnabled()
		HandleCorpseCleanup(akCorpse, akEffectContext)
	EndIf
EndFunction

; ==============================================================
; Skin Swap
; ==============================================================

Function ApplyHumanCorpseSkin(Actor akCorpseActor, PWAL:Looting:LootEffectScript akEffectContext)
	Armor akCorpseSkin

	If akCorpseActor == None || akEffectContext == None
		Return
	EndIf

	akCorpseSkin = ResolveHumanCorpseSkin(akCorpseActor, akEffectContext)

	If akCorpseSkin == None
		LogWarn("CorpseProcessor", "ApplyHumanCorpseSkin skipped: no corpse skin resolved.")
		Return
	EndIf

	akCorpseActor.EquipItem(akCorpseSkin as Form, false, false)
	Utility.Wait(0.05) ; Small delay to ensure the skin is applied before any further processing.
EndFunction


Armor Function ResolveHumanCorpseSkin(Actor akCorpseActor, PWAL:Looting:LootEffectScript akEffectContext)
	Form akActorBase

	If akCorpseActor == None || akEffectContext == None
		Return None
	EndIf

	akActorBase = akCorpseActor.GetBaseObject()

	If akActorBase == None
		Return akEffectContext.PWAL_ARMO_Skin_NOTPLAYABLE
	EndIf

	If akEffectContext.PWAL_FLST_Script_Corpses_Dusty != None
		If akEffectContext.PWAL_FLST_Script_Corpses_Dusty.HasForm(akActorBase)
			Return akEffectContext.PWAL_ARMO_Skin_Dusty_NOTPLAYABLE
		EndIf
	EndIf

	If akEffectContext.PWAL_FLST_Script_Corpses_Frozen != None
		If akEffectContext.PWAL_FLST_Script_Corpses_Frozen.HasForm(akActorBase)
			Return akEffectContext.PWAL_ARMO_Skin_Frozen_NOTPLAYABLE
		EndIf
	EndIf

	If akEffectContext.PWAL_FLST_Script_Corpses != None
		If akEffectContext.PWAL_FLST_Script_Corpses.HasForm(akActorBase)
			Return akEffectContext.PWAL_ARMO_Skin_NOTPLAYABLE
		EndIf
	EndIf

	Return akEffectContext.PWAL_ARMO_Skin_NOTPLAYABLE
EndFunction

; ==============================================================
; Processing Paths
; ==============================================================

Bool Function ProcessTakeAllCorpse(ObjectReference akCorpse, ObjectReference akDestinationRef, PWAL:Looting:LootEffectScript akEffectContext)
	Bool bKeepOwnership

	If akCorpse == None || akDestinationRef == None || akEffectContext == None
		Return false
	EndIf

	bKeepOwnership = akEffectContext.IsStealingHostile()

	; abKeepOwnership = bKeepOwnership, abRemoveQuestItems = false
	akCorpse.RemoveAllItems(akDestinationRef, bKeepOwnership, false)

	Return true
EndFunction

Bool Function ProcessFilteredCorpseItems(ObjectReference akCorpse, ObjectReference akDestinationRef, PWAL:Looting:LootEffectScript akEffectContext)
	FormList akCurrentList
	ObjectReference akCurrentDestinationRef
	Int iIndex
	Int iCount
	Int iLootGroupCode
	Int iDestinationCode
	Bool bTransferAttempted = false

	If akCorpse == None || akEffectContext == None
		LogWarn("CorpseProcessor", "ProcessFilteredCorpseItems aborted: invalid input.")
		Return false
	EndIf

	If DestinationResolver == None
		LogError("CorpseProcessor", "ProcessFilteredCorpseItems failed: DestinationResolver property is not filled.")
		Return false
	EndIf

	iCount = akEffectContext.GetCachedLootingListCount()

	If iCount <= 0
		Return false
	EndIf

	iIndex = 0

	While iIndex < iCount
		akCurrentList = akEffectContext.GetCachedLootingList(iIndex)
		iLootGroupCode = akEffectContext.GetCachedLootGroupCode(iIndex)

		If akCurrentList == None
			LogWarn("CorpseProcessor", "ProcessFilteredCorpseItems skipped invalid cached FormList at index " + (iIndex as String))
		ElseIf iLootGroupCode <= 0
			LogWarn("CorpseProcessor", "ProcessFilteredCorpseItems skipped invalid cached LootGroupCode at index " + (iIndex as String))
		Else
			iDestinationCode = DestinationResolver.ResolveDestinationCode(iLootGroupCode)
			akCurrentDestinationRef = DestinationResolver.ResolveDestinationRef(iDestinationCode)

			If akCurrentDestinationRef == None
				LogWarn("CorpseProcessor", "ProcessFilteredCorpseItems skipped index " + (iIndex as String) + ": destination ref resolved to None. LootGroupCode=" + (iLootGroupCode as String) + " DestinationCode=" + (iDestinationCode as String))
			Else
				akCorpse.RemoveItem(akCurrentList as Form, -1, true, akCurrentDestinationRef)
				bTransferAttempted = true
			EndIf
		EndIf

		iIndex += 1
	EndWhile

	Return bTransferAttempted
EndFunction

; ==============================================================
; State Tracking
; ==============================================================

Bool Function IsCorpseAlreadyLooted(ObjectReference akCorpse, PWAL:Looting:LootEffectScript akEffectContext)
	Keyword akLootedKeyword

	If akCorpse == None || akEffectContext == None
		Return false
	EndIf

	akLootedKeyword = akEffectContext.GetCorpseLootedKeyword()
	If akLootedKeyword == None
		Return false
	EndIf

	Return akCorpse.HasKeyword(akLootedKeyword)
EndFunction

Function MarkCorpseAsLooted(ObjectReference akCorpse, PWAL:Looting:LootEffectScript akEffectContext)
	Keyword akLootedKeyword

	If akCorpse == None || akEffectContext == None
		Return
	EndIf

	akLootedKeyword = akEffectContext.GetCorpseLootedKeyword()
	If akLootedKeyword == None
		Return
	EndIf

	If !akCorpse.HasKeyword(akLootedKeyword)
		akCorpse.AddKeyword(akLootedKeyword)
	EndIf
EndFunction

; ==============================================================
; Cleanup
; ==============================================================

Function HandleCorpseCleanup(ObjectReference akCorpse, PWAL:Looting:LootEffectScript akEffectContext)
	Actor akCorpseActor

	If akCorpse == None
		Return
	EndIf

	akCorpseActor = akCorpse as Actor
	If akCorpseActor == None
		Return
	EndIf

	akCorpse.DisableNoWait(true)
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
