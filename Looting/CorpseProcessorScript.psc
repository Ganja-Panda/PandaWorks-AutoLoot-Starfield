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

Function ProcessCorpse(ObjectReference akCorpse, PWAL:Looting:LootEffectScript akEffectContext)
	Actor akCorpseActor
	ObjectReference akDestinationRef

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

	; Preserve old LZP behavior:
	; For human corpses, unequip all worn gear and replace the body
	; with the non-playable naked skin so armor becomes lootable
	; without causing floating heads.
	If akEffectContext.IsHumanRace(akCorpseActor)
		akCorpseActor.UnequipAll()
		akCorpseActor.EquipItem(akEffectContext.PWAL_ARMO_Skin_Naked_NOTPLAYABLE as Form, false, false)
	EndIf

	Utility.Wait(0.1)

	Int iDestinationCode
	iDestinationCode = DestinationResolver.ResolveDestinationCode()
	
	akDestinationRef = DestinationResolver.ResolveDestinationRef(iDestinationCode)
	If akDestinationRef == None
		LogWarn("CorpseProcessor", "ProcessCorpse aborted: destination ref resolved to None.")
		Return
	EndIf

	If akEffectContext.TakeAllCorpses()
		ProcessTakeAllCorpse(akCorpse, akDestinationRef, akEffectContext)
	Else
		ProcessFilteredCorpseItems(akCorpse, akDestinationRef, akEffectContext)
	EndIf

	MarkCorpseAsLooted(akCorpse, akEffectContext)

	If akEffectContext.RemoveCorpsesEnabled()
		HandleCorpseCleanup(akCorpse, akEffectContext)
	EndIf

	LogDebug("CorpseProcessor", "ProcessCorpse complete: " + akCorpse)
EndFunction

; ==============================================================
; Processing Paths
; ==============================================================

Function ProcessTakeAllCorpse(ObjectReference akCorpse, ObjectReference akDestinationRef, PWAL:Looting:LootEffectScript akEffectContext)
	If akCorpse == None || akDestinationRef == None || akEffectContext == None
		Return
	EndIf

	; Preserve old LZP behavior exactly for corpses:
	; take-all corpse transfer does not use hostile ownership transfer.
	akCorpse.RemoveAllItems(akDestinationRef, false, false)
	LogDebug("CorpseProcessor", "ProcessTakeAllCorpse transferred all contents.")
EndFunction

Function ProcessFilteredCorpseItems(ObjectReference akCorpse, ObjectReference akDestinationRef, PWAL:Looting:LootEffectScript akEffectContext)
	FormList akLootingLists
	FormList akLootingGlobals
	FormList akCurrentList
	GlobalVariable akCurrentGlobal
	Float fGlobalValue
	Int iListSize
	Int iGlobalSize
	Int iMaxSize
	Int iIndex

	If akCorpse == None || akDestinationRef == None || akEffectContext == None
		LogWarn("CorpseProcessor", "ProcessFilteredCorpseItems aborted: invalid input.")
		Return
	EndIf

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