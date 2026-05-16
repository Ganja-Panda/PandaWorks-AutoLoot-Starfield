ScriptName PWAL:Looting:CorpseProcessorScript Extends Quest Hidden

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.00
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

Group QuestItems_AutoFill
	FormList Property PWAL_FLST_System_QuestItems Auto Const Mandatory
EndGroup

; ==============================================================
; Public API
; ==============================================================

Function ProcessCorpse(ObjectReference akCorpse, PWAL:Looting:LootEffectScript akEffectContext)
	Actor akCorpseActor
	ObjectReference akDestinationRef
	ObjectReference akPlayerRef

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
		LogDebug("CorpseProcessor", "ProcessCorpse skipped: candidate is not an Actor.")
		Return
	EndIf

	If !akCorpseActor.IsDead()
		LogDebug("CorpseProcessor", "ProcessCorpse skipped: actor is not dead.")
		Return
	EndIf

	If IsCorpseAlreadyLooted(akCorpse, akEffectContext)
		LogDebug("CorpseProcessor", "ProcessCorpse skipped: corpse already marked looted.")
		Return
	EndIf

	If DestinationResolver == None
		LogError("CorpseProcessor", "ProcessCorpse failed: DestinationResolver property is not filled.")
		Return
	EndIf

	If akEffectContext.IsHumanRace(akCorpseActor)
		ApplyHumanCorpseSkin(akCorpseActor, akEffectContext)
	EndIf

	Utility.Wait(0.1)

	Int iDestinationCode
	iDestinationCode = DestinationResolver.ResolveDestinationCode()
	LogDebug("CorpseProcessor", "Resolved destination code " + (iDestinationCode as String) + " for corpse contents.")
	
	akDestinationRef = DestinationResolver.ResolveDestinationRef(iDestinationCode)
	If akDestinationRef == None
		LogWarn("CorpseProcessor", "ProcessCorpse aborted: destination ref resolved to None.")
		Return
	EndIf

	akPlayerRef = akEffectContext.GetPlayerRef()
	If akPlayerRef == None
		akPlayerRef = Game.GetPlayer()
	EndIf

	If akPlayerRef == None
		LogWarn("CorpseProcessor", "ProcessCorpse aborted: PlayerRef resolved to None.")
		Return
	EndIf

	If akEffectContext.TakeAllCorpses()
		ProcessTakeAllCorpse(akCorpse, akDestinationRef, akPlayerRef, akEffectContext)
	Else
		ProcessFilteredCorpseItems(akCorpse, akDestinationRef, akPlayerRef, akEffectContext)
	EndIf

	MarkCorpseAsLooted(akCorpse, akEffectContext)

	If akEffectContext.RemoveCorpsesEnabled()
		HandleCorpseCleanup(akCorpse, akEffectContext)
	EndIf

	LogDebug("CorpseProcessor", "ProcessCorpse complete: " + akCorpse)
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

	akCorpseActor.UnequipAll()
	akCorpseActor.EquipItem(akCorpseSkin as Form, false, false)

	LogDebug("CorpseProcessor", "Applied human corpse skin: " + akCorpseSkin)
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

Function ProcessTakeAllCorpse(ObjectReference akCorpse, ObjectReference akDestinationRef, ObjectReference akPlayerRef, PWAL:Looting:LootEffectScript akEffectContext)
	If akCorpse == None || akDestinationRef == None || akPlayerRef == None || akEffectContext == None
		Return
	EndIf

	; Quest items must always go directly to the player before bulk transfer.
	ProcessQuestItemsFromCorpse(akCorpse, akPlayerRef)

	; Preserve old LZP behavior exactly for corpses:
	; take-all corpse transfer does not use hostile ownership transfer.
	akCorpse.RemoveAllItems(akDestinationRef, false, false)
	LogDebug("CorpseProcessor", "ProcessTakeAllCorpse transferred all non-quest contents.")
EndFunction

Function ProcessFilteredCorpseItems(ObjectReference akCorpse, ObjectReference akDestinationRef, ObjectReference akPlayerRef, PWAL:Looting:LootEffectScript akEffectContext)
	FormList akLootingLists
	FormList akLootingGlobals
	FormList akCurrentList
	GlobalVariable akCurrentGlobal
	Float fGlobalValue
	Int iListSize
	Int iGlobalSize
	Int iMaxSize
	Int iIndex

	If akCorpse == None || akDestinationRef == None || akPlayerRef == None || akEffectContext == None
		LogWarn("CorpseProcessor", "ProcessFilteredCorpseItems aborted: invalid input.")
		Return
	EndIf

	; Quest items must always go to the player, regardless of filter state.
	ProcessQuestItemsFromCorpse(akCorpse, akPlayerRef)
	akLootingLists = akEffectContext.PWAL_FLST_System_Looting_Lists
	akLootingGlobals = akEffectContext.PWAL_FLST_System_Looting_Globals

	If akLootingLists == None
		LogWarn("CorpseProcessor", "ProcessFilteredCorpseItems aborted: PWAL_FLST_System_Looting_Lists is None.")
		Return
	EndIf

	If akLootingGlobals == None
		LogWarn("CorpseProcessor", "ProcessFilteredCorpseItems aborted: PWAL_FLST_System_Looting_Globals is None.")
		Return
	EndIf

	iListSize = akLootingLists.GetSize()
	iGlobalSize = akLootingGlobals.GetSize()

	If iListSize <= 0
		LogDebug("CorpseProcessor", "ProcessFilteredCorpseItems skipped: no looting lists configured.")
		Return
	EndIf

	If iGlobalSize <= 0
		LogDebug("CorpseProcessor", "ProcessFilteredCorpseItems skipped: no looting globals configured.")
		Return
	EndIf

	iMaxSize = iListSize
	If iGlobalSize < iMaxSize
		iMaxSize = iGlobalSize
		LogWarn("CorpseProcessor", "ProcessFilteredCorpseItems detected mismatched paired list sizes. Using smaller size: " + iMaxSize)
	EndIf

	iIndex = 0
	While iIndex < iMaxSize
		akCurrentList = akLootingLists.GetAt(iIndex) as FormList
		akCurrentGlobal = akLootingGlobals.GetAt(iIndex) as GlobalVariable

		If akCurrentList == None
			LogWarn("CorpseProcessor", "ProcessFilteredCorpseItems skipped invalid FormList at index " + iIndex)
		ElseIf akCurrentGlobal == None
			LogWarn("CorpseProcessor", "ProcessFilteredCorpseItems skipped invalid GlobalVariable at index " + iIndex)
		Else
			fGlobalValue = akCurrentGlobal.GetValue()

			If fGlobalValue == 1.0
				Int j = 0
				Int iEntryCount = akCurrentList.GetSize()

				While j < iEntryCount
					Form akEntry = akCurrentList.GetAt(j)

					If akEntry != None
						akCorpse.RemoveItem(akEntry, -1, true, akDestinationRef)
					EndIf

					j += 1
				EndWhile
			EndIf
		EndIf

		iIndex += 1
	EndWhile

	LogDebug("CorpseProcessor", "ProcessFilteredCorpseItems complete.")
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
; Internal Helpers
; ==============================================================

Function ProcessQuestItemsFromCorpse(ObjectReference akCorpse, ObjectReference akPlayerRef)
	If akCorpse == None || akPlayerRef == None
		Return
	EndIf

	If PWAL_FLST_System_QuestItems == None
		LogWarn("CorpseProcessor", "ProcessQuestItemsFromCorpse skipped: PWAL_FLST_System_QuestItems is None.")
		Return
	EndIf

	akCorpse.RemoveItem(PWAL_FLST_System_QuestItems as Form, -1, false, akPlayerRef)

	LogDebug("CorpseProcessor", "ProcessQuestItemsFromCorpse routed quest items directly to player.")
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

	LogDebug("CorpseProcessor", "HandleCorpseCleanup disabled corpse.")
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