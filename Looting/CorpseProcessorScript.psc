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

Group SafetyKeywords_AutoFill
	Keyword Property PWAL_KYWD_NotLootable Auto Const Mandatory
EndGroup

; ==============================================================
; Public API
; ==============================================================

Function ProcessCorpse(ObjectReference akCorpse, PWAL:Looting:LootEffectScript akEffectContext)
	Actor akCorpseActor
	ObjectReference akDestinationRef
	Bool bIsHumanCorpse

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

	; Expose equipped inventory BEFORE transfer, but do not apply replacement skin yet.
	bIsHumanCorpse = akEffectContext.IsHumanRace(akCorpseActor)

	If bIsHumanCorpse
		akCorpseActor.UnequipAll()
		Utility.Wait(0.01)
	EndIf

	If akEffectContext.TakeAllCorpses()
		Int iDestinationCode
		iDestinationCode = DestinationResolver.ResolveDestinationCode(DestinationResolver.LG_CORPSES)
		LogDebug("CorpseProcessor", "Resolved corpse destination code " + (iDestinationCode as String) + " for take-all corpse contents.")

		akDestinationRef = DestinationResolver.ResolveDestinationRef(iDestinationCode)
		If akDestinationRef == None
			LogWarn("CorpseProcessor", "ProcessCorpse aborted: corpse destination ref resolved to None.")
			Return
		EndIf

		ProcessTakeAllCorpse(akCorpse, akDestinationRef, akEffectContext)
	Else
		ProcessFilteredCorpseItems(akCorpse, None, akEffectContext)
	EndIf

	; Apply corpse skin AFTER transfer so RemoveAllItems/RemoveItem cannot steal it.
	If bIsHumanCorpse
		ApplyHumanCorpseSkin(akCorpseActor, akEffectContext)
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

Function ProcessTakeAllCorpse(ObjectReference akCorpse, ObjectReference akDestinationRef, PWAL:Looting:LootEffectScript akEffectContext)
	If akCorpse == None || akDestinationRef == None || akEffectContext == None
		Return
	EndIf

	akCorpse.RemoveAllItems(akDestinationRef, false, false)
	LogDebug("CorpseProcessor", "ProcessTakeAllCorpse transferred all contents.")
EndFunction

Bool Function IsNotLootableForm(Form akItem)
	If akItem == None
		Return false
	EndIf

	If PWAL_KYWD_NotLootable == None
		Return false
	EndIf

	Return akItem.HasKeyword(PWAL_KYWD_NotLootable)
EndFunction

Function ProcessFilteredCorpseItems(ObjectReference akCorpse, ObjectReference akDestinationRef, PWAL:Looting:LootEffectScript akEffectContext)
	FormList akLootingLists
	FormList akLootingGlobals
	FormList akLootGroupCodes
	FormList akCurrentList
	GlobalVariable akCurrentGlobal
	GlobalVariable akCurrentLootGroupCodeGlobal
	ObjectReference akCurrentDestinationRef
	Float fGlobalValue
	Int iListSize
	Int iGlobalSize
	Int iCodeSize
	Int iMaxSize
	Int iIndex
	Int iLootGroupCode
	Int iDestinationCode

	If akCorpse == None || akEffectContext == None
		LogWarn("CorpseProcessor", "ProcessFilteredCorpseItems aborted: invalid input.")
		Return
	EndIf

	If DestinationResolver == None
		LogError("CorpseProcessor", "ProcessFilteredCorpseItems failed: DestinationResolver property is not filled.")
		Return
	EndIf

	akLootingLists = akEffectContext.PWAL_FLST_System_Looting_Lists
	akLootingGlobals = akEffectContext.PWAL_FLST_System_Looting_Globals
	akLootGroupCodes = akEffectContext.PWAL_FLST_System_Loot_GroupCodes

	If akLootingLists == None
		LogWarn("CorpseProcessor", "ProcessFilteredCorpseItems aborted: PWAL_FLST_System_Looting_Lists is None.")
		Return
	EndIf

	If akLootingGlobals == None
		LogWarn("CorpseProcessor", "ProcessFilteredCorpseItems aborted: PWAL_FLST_System_Looting_Globals is None.")
		Return
	EndIf

	If akLootGroupCodes == None
		LogWarn("CorpseProcessor", "ProcessFilteredCorpseItems aborted: PWAL_FLST_System_Loot_GroupCodes is None.")
		Return
	EndIf

	iListSize = akLootingLists.GetSize()
	iGlobalSize = akLootingGlobals.GetSize()
	iCodeSize = akLootGroupCodes.GetSize()

	If iListSize <= 0
		LogDebug("CorpseProcessor", "ProcessFilteredCorpseItems skipped: no looting lists configured.")
		Return
	EndIf

	If iGlobalSize <= 0
		LogDebug("CorpseProcessor", "ProcessFilteredCorpseItems skipped: no looting globals configured.")
		Return
	EndIf

	If iCodeSize <= 0
		LogDebug("CorpseProcessor", "ProcessFilteredCorpseItems skipped: no loot group codes configured.")
		Return
	EndIf

	iMaxSize = iListSize

	If iGlobalSize < iMaxSize
		iMaxSize = iGlobalSize
	EndIf

	If iCodeSize < iMaxSize
		iMaxSize = iCodeSize
	EndIf

	If iMaxSize < iListSize || iMaxSize < iGlobalSize || iMaxSize < iCodeSize
		LogWarn("CorpseProcessor", "ProcessFilteredCorpseItems detected mismatched paired list sizes. Lists=" + (iListSize as String) + " Globals=" + (iGlobalSize as String) + " Codes=" + (iCodeSize as String) + " Using=" + (iMaxSize as String))
	EndIf

	iIndex = 0
	While iIndex < iMaxSize
		akCurrentList = akLootingLists.GetAt(iIndex) as FormList
		akCurrentGlobal = akLootingGlobals.GetAt(iIndex) as GlobalVariable
		akCurrentLootGroupCodeGlobal = akLootGroupCodes.GetAt(iIndex) as GlobalVariable

		If akCurrentList == None
			LogWarn("CorpseProcessor", "ProcessFilteredCorpseItems skipped invalid FormList at index " + (iIndex as String))
		ElseIf akCurrentGlobal == None
			LogWarn("CorpseProcessor", "ProcessFilteredCorpseItems skipped invalid GlobalVariable at index " + (iIndex as String))
		ElseIf akCurrentLootGroupCodeGlobal == None
			LogWarn("CorpseProcessor", "ProcessFilteredCorpseItems skipped invalid LootGroupCode GlobalVariable at index " + (iIndex as String))
		Else
			fGlobalValue = akCurrentGlobal.GetValue()

			If fGlobalValue == 1.0
				iLootGroupCode = akCurrentLootGroupCodeGlobal.GetValueInt()
				iDestinationCode = DestinationResolver.ResolveDestinationCode(iLootGroupCode)
				akCurrentDestinationRef = DestinationResolver.ResolveDestinationRef(iDestinationCode)

				If akCurrentDestinationRef == None
					LogWarn("CorpseProcessor", "ProcessFilteredCorpseItems skipped index " + (iIndex as String) + ": destination ref resolved to None. LootGroupCode=" + (iLootGroupCode as String) + " DestinationCode=" + (iDestinationCode as String))
				Else
					LogDebug("CorpseProcessor", "ProcessFilteredCorpseItems routing index " + (iIndex as String) + " LootGroupCode=" + (iLootGroupCode as String) + " DestinationCode=" + (iDestinationCode as String))

					Int j = 0
					Int iEntryCount = akCurrentList.GetSize()

					While j < iEntryCount
						Form akEntry = akCurrentList.GetAt(j)

						If akEntry != None
							If IsNotLootableForm(akEntry)
								LogDebug("CorpseProcessor", "ProcessFilteredCorpseItems skipped not-lootable form: " + akEntry)
							Else
								akCorpse.RemoveItem(akEntry, -1, true, akCurrentDestinationRef)
							EndIf
						EndIf

						j += 1
					EndWhile
				EndIf
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