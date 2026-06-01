ScriptName PWAL:Looting:ContainerProcessorScript Extends Quest Hidden

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.0.1
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

; ==============================================================
; Public API
; ==============================================================

Function ProcessContainer(ObjectReference akContainer, PWAL:Looting:LootEffectScript akEffectContext)

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

	If !LootValidation.CanProcessLoot(akContainer, akEffectContext)
		LogDebug("ContainerProcessor", "ProcessContainer skipped: LootValidation rejected container.")
		Return
	EndIf

	If !UnlockingService.EnsureContainerAccess(akContainer, akEffectContext)
		LogDebug("ContainerProcessor", "ProcessContainer skipped: container access could not be established.")
		Return
	EndIf

	If akEffectContext.TakeAllContainers()
		LogDebug("ContainerProcessor", "TakeAllContainers suppressed for quest safety; using filtered container transfer.")
		ProcessFilteredContainerItems(akContainer, None, akEffectContext)
	Else
		ProcessFilteredContainerItems(akContainer, None, akEffectContext)
	EndIf

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

	bTransferOwnership = akEffectContext.IsStealingHostile()

	akContainer.RemoveAllItems(akDestinationRef, false, bTransferOwnership)
	LogDebug("ContainerProcessor", "ProcessTakeAllContainer transferred all contents.")
EndFunction

Function ProcessFilteredContainerItems(ObjectReference akContainer, ObjectReference akDestinationRef, PWAL:Looting:LootEffectScript akEffectContext)
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

	If akContainer == None || akEffectContext == None
		LogWarn("ContainerProcessor", "ProcessFilteredContainerItems aborted: invalid input.")
		Return
	EndIf

	If DestinationResolver == None
		LogError("ContainerProcessor", "ProcessFilteredContainerItems failed: DestinationResolver property is not filled.")
		Return
	EndIf

	akLootingLists = akEffectContext.PWAL_FLST_System_Looting_Lists
	akLootingGlobals = akEffectContext.PWAL_FLST_System_Looting_Globals
	akLootGroupCodes = akEffectContext.PWAL_FLST_System_Loot_GroupCodes

	If akLootingLists == None
		LogWarn("ContainerProcessor", "ProcessFilteredContainerItems aborted: PWAL_FLST_System_Looting_Lists is None.")
		Return
	EndIf

	If akLootingGlobals == None
		LogWarn("ContainerProcessor", "ProcessFilteredContainerItems aborted: PWAL_FLST_System_Looting_Globals is None.")
		Return
	EndIf

	If akLootGroupCodes == None
		LogWarn("ContainerProcessor", "ProcessFilteredContainerItems aborted: PWAL_FLST_System_Loot_GroupCodes is None.")
		Return
	EndIf

	iListSize = akLootingLists.GetSize()
	iGlobalSize = akLootingGlobals.GetSize()
	iCodeSize = akLootGroupCodes.GetSize()

	If iListSize <= 0
		LogDebug("ContainerProcessor", "ProcessFilteredContainerItems skipped: no looting lists configured.")
		Return
	EndIf

	If iGlobalSize <= 0
		LogDebug("ContainerProcessor", "ProcessFilteredContainerItems skipped: no looting globals configured.")
		Return
	EndIf

	If iCodeSize <= 0
		LogDebug("ContainerProcessor", "ProcessFilteredContainerItems skipped: no loot group codes configured.")
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
		LogWarn("ContainerProcessor", "ProcessFilteredContainerItems detected mismatched paired list sizes. Lists=" + (iListSize as String) + " Globals=" + (iGlobalSize as String) + " Codes=" + (iCodeSize as String) + " Using=" + (iMaxSize as String))
	EndIf

	iIndex = 0
	While iIndex < iMaxSize
		akCurrentList = akLootingLists.GetAt(iIndex) as FormList
		akCurrentGlobal = akLootingGlobals.GetAt(iIndex) as GlobalVariable
		akCurrentLootGroupCodeGlobal = akLootGroupCodes.GetAt(iIndex) as GlobalVariable

		If akCurrentList == None
			LogWarn("ContainerProcessor", "ProcessFilteredContainerItems skipped invalid FormList at index " + (iIndex as String))
		ElseIf akCurrentGlobal == None
			LogWarn("ContainerProcessor", "ProcessFilteredContainerItems skipped invalid GlobalVariable at index " + (iIndex as String))
		ElseIf akCurrentLootGroupCodeGlobal == None
			LogWarn("ContainerProcessor", "ProcessFilteredContainerItems skipped invalid LootGroupCode GlobalVariable at index " + (iIndex as String))
		Else
			fGlobalValue = akCurrentGlobal.GetValue()

			If fGlobalValue == 1.0
				iLootGroupCode = akCurrentLootGroupCodeGlobal.GetValueInt()
				iDestinationCode = DestinationResolver.ResolveDestinationCode(iLootGroupCode)
				akCurrentDestinationRef = DestinationResolver.ResolveDestinationRef(iDestinationCode)

				If akCurrentDestinationRef == None
					LogWarn("ContainerProcessor", "ProcessFilteredContainerItems skipped index " + (iIndex as String) + ": destination ref resolved to None. LootGroupCode=" + (iLootGroupCode as String) + " DestinationCode=" + (iDestinationCode as String))
				Else
					LogDebug("ContainerProcessor", "ProcessFilteredContainerItems routing index " + (iIndex as String) + " LootGroupCode=" + (iLootGroupCode as String) + " DestinationCode=" + (iDestinationCode as String))

					akContainer.RemoveItem(akCurrentList as Form, -1, true, akCurrentDestinationRef)
				EndIf
			EndIf
		EndIf

		iIndex += 1
	EndWhile

	LogDebug("ContainerProcessor", "ProcessFilteredContainerItems complete.")
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