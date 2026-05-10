ScriptName PWAL:Looting:ContainerProcessorScript Extends Quest Hidden

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.00
; Created: 04-10-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: ContainerProcessorScript
; Type: Looting / Container Processor Service
; Purpose:
;   Handles container-specific loot processing for PWAL.
;
; Responsibilities:
;   - Skip already-looted containers
;   - Attempt unlock via UnlockingServiceScript when needed
;   - Transfer filtered or full contents depending on settings
;   - Mark successfully processed containers as looted
;
; Non-Responsibilities:
;   - No scanning
;   - No top-level routing
;   - No corpse handling
;   - No destination policy ownership
; ==============================================================

Group FrameworkServices_AutoFill
	PWAL:Core:LoggerScript Property Logger Auto Const Mandatory
	PWAL:Looting:LootValidationScript Property LootValidation Auto Const Mandatory
	PWAL:Looting:DestinationResolverScript Property DestinationResolver Auto Const Mandatory
	PWAL:Looting:UnlockingServiceScript Property UnlockingService Auto Const Mandatory
EndGroup

Function ProcessContainer(ObjectReference akContainer, PWAL:Looting:LootEffectScript akEffectContext)
	ObjectReference akDestinationRef
	Int iDestinationCode

	If akContainer == None
		LogWarn("ContainerProcessor", "ProcessContainer aborted: akContainer is None.")
		Return
	EndIf

	If akEffectContext == None
		LogWarn("ContainerProcessor", "ProcessContainer aborted: akEffectContext is None.")
		Return
	EndIf

	If LootValidation == None
		LogError("ContainerProcessor", "ProcessContainer failed: LootValidation property is not filled.")
		Return
	EndIf

	If DestinationResolver == None
		LogError("ContainerProcessor", "ProcessContainer failed: DestinationResolver property is not filled.")
		Return
	EndIf

	If UnlockingService == None
		LogError("ContainerProcessor", "ProcessContainer failed: UnlockingService property is not filled.")
		Return
	EndIf

	If IsContainerAlreadyLooted(akContainer, akEffectContext)
		LogDebug("ContainerProcessor", "ProcessContainer skipped: container already marked looted.")
		Return
	EndIf

	If !LootValidation.CanProcessLoot(akContainer, akEffectContext)
		LogDebug("ContainerProcessor", "ProcessContainer skipped: LootValidation rejected container.")
		Return
	EndIf

	If !UnlockingService.EnsureContainerAccess(akContainer, akEffectContext)
		LogDebug("ContainerProcessor", "ProcessContainer skipped: container access could not be established.")
		Return
	EndIf

	iDestinationCode = DestinationResolver.ResolveDestinationCode()
	akDestinationRef = DestinationResolver.ResolveDestinationRef(iDestinationCode)
	If akDestinationRef == None
		LogWarn("ContainerProcessor", "ProcessContainer aborted: destination ref resolved to None.")
		Return
	EndIf

	If akEffectContext.TakeAllContainers()
		ProcessTakeAllContainer(akContainer, akDestinationRef, akEffectContext)
	Else
		ProcessFilteredContainerItems(akContainer, akDestinationRef, akEffectContext)
	EndIf

	MarkContainerAsLooted(akContainer, akEffectContext)
	LogDebug("ContainerProcessor", "ProcessContainer complete: " + akContainer)
EndFunction

; ==============================================================
; Processing Paths
; ==============================================================

Function ProcessTakeAllContainer(ObjectReference akContainer, ObjectReference akDestinationRef, PWAL:Looting:LootEffectScript akEffectContext)
	Bool bTransferOwnership

	If akContainer == None || akDestinationRef == None || akEffectContext == None
		Return
	EndIf

	; Preserve the old working behavior:
	; transfer everything, using the hostile-steal flag as the transfer ownership mode.
	bTransferOwnership = akEffectContext.IsStealingHostile()

	akContainer.RemoveAllItems(akDestinationRef, false, bTransferOwnership)
	LogDebug("ContainerProcessor", "ProcessTakeAllContainer transferred all contents.")
EndFunction

Function ProcessFilteredContainerItems(ObjectReference akContainer, ObjectReference akDestinationRef, PWAL:Looting:LootEffectScript akEffectContext)
	FormList akLootingLists
	FormList akLootingGlobals
	FormList akCurrentList
	GlobalVariable akCurrentGlobal
	Float fGlobalValue
	Int iListSize
	Int iGlobalSize
	Int iMaxSize
	Int iIndex

	If akContainer == None || akDestinationRef == None || akEffectContext == None
		LogWarn("ContainerProcessor", "ProcessFilteredContainerItems aborted: invalid input.")
		Return
	EndIf

	akLootingLists = akEffectContext.PWAL_FLST_System_Looting_Lists
	akLootingGlobals = akEffectContext.PWAL_FLST_System_Looting_Globals

	If akLootingLists == None
		LogWarn("ContainerProcessor", "ProcessFilteredContainerItems aborted: PWAL_FLST_System_Looting_Lists is None.")
		Return
	EndIf

	If akLootingGlobals == None
		LogWarn("ContainerProcessor", "ProcessFilteredContainerItems aborted: PWAL_FLST_System_Looting_Globals is None.")
		Return
	EndIf

	iListSize = akLootingLists.GetSize()
	iGlobalSize = akLootingGlobals.GetSize()

	If iListSize <= 0
		LogDebug("ContainerProcessor", "ProcessFilteredContainerItems skipped: no looting lists configured.")
		Return
	EndIf

	If iGlobalSize <= 0
		LogDebug("ContainerProcessor", "ProcessFilteredContainerItems skipped: no looting globals configured.")
		Return
	EndIf

	iMaxSize = iListSize
	If iGlobalSize < iMaxSize
		iMaxSize = iGlobalSize
		LogWarn("ContainerProcessor", "ProcessFilteredContainerItems detected mismatched paired list sizes. Using smaller size: " + iMaxSize)
	EndIf

	iIndex = 0
	While iIndex < iMaxSize
		akCurrentList = akLootingLists.GetAt(iIndex) as FormList
		akCurrentGlobal = akLootingGlobals.GetAt(iIndex) as GlobalVariable

		If akCurrentList == None
			LogWarn("ContainerProcessor", "ProcessFilteredContainerItems skipped invalid FormList at index " + iIndex)
		ElseIf akCurrentGlobal == None
			LogWarn("ContainerProcessor", "ProcessFilteredContainerItems skipped invalid GlobalVariable at index " + iIndex)
		Else
			fGlobalValue = akCurrentGlobal.GetValue()

			If fGlobalValue == 1.0
				; Preserve old LZP behavior:
				; remove every item matching the enabled category list into the destination.
				akContainer.RemoveItem(akCurrentList as Form, -1, true, akDestinationRef)
			EndIf
		EndIf

		iIndex += 1
	EndWhile

	LogDebug("ContainerProcessor", "ProcessFilteredContainerItems complete.")
EndFunction

; ==============================================================
; State Tracking
; ==============================================================

Bool Function IsContainerAlreadyLooted(ObjectReference akContainer, PWAL:Looting:LootEffectScript akEffectContext)
	Keyword akLootedKeyword

	If akContainer == None || akEffectContext == None
		Return false
	EndIf

	akLootedKeyword = akEffectContext.GetContainerLootedKeyword()
	If akLootedKeyword == None
		Return false
	EndIf

	Return akContainer.HasKeyword(akLootedKeyword)
EndFunction

Function MarkContainerAsLooted(ObjectReference akContainer, PWAL:Looting:LootEffectScript akEffectContext)
	Keyword akLootedKeyword

	If akContainer == None || akEffectContext == None
		Return
	EndIf

	akLootedKeyword = akEffectContext.GetContainerLootedKeyword()
	If akLootedKeyword == None
		Return
	EndIf

	If !akContainer.HasKeyword(akLootedKeyword)
		akContainer.AddKeyword(akLootedKeyword)
	EndIf
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