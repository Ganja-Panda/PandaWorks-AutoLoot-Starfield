ScriptName PWAL:Looting:ContainerProcessorScript Extends Quest Hidden

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.0.3
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
	Bool bKeepOwnership

	If akContainer == None || akDestinationRef == None || akEffectContext == None
		Return
	EndIf

	bKeepOwnership = akEffectContext.IsStealingHostile()

	; abKeepOwnership = bKeepOwnership, abRemoveQuestItems = true
	akContainer.RemoveAllItems(akDestinationRef, bKeepOwnership, true)

	LogDebug("ContainerProcessor", "ProcessTakeAllContainer transferred all contents.")
EndFunction

Function ProcessFilteredContainerItems(ObjectReference akContainer, ObjectReference akDestinationRef, PWAL:Looting:LootEffectScript akEffectContext)
	FormList akCurrentList
	ObjectReference akCurrentDestinationRef
	Form akBase
	Container akBaseContainer
	Int iIndex
	Int iCount
	Int iLootGroupCode
	Int iDestinationCode
	Int iInventoryBefore
	Int iInventoryAfter
	Int iMovedTotal
	Int iSkippedTotal
	Int iMatched
	Int iMoved

	If akContainer == None || akEffectContext == None
		LogWarn("ContainerProcessor", "ProcessFilteredContainerItems aborted: invalid input.")
		Return
	EndIf

	akBase = akContainer.GetBaseObject()
	akBaseContainer = akBase as Container

	If akBaseContainer == None
		LogWarn("ContainerProcessor", "ProcessFilteredContainerItems rejected non-container base: ref=" + akContainer + " base=" + akBase)
		Return
	EndIf

	If DestinationResolver == None
		LogError("ContainerProcessor", "ProcessFilteredContainerItems failed: DestinationResolver property is not filled.")
		Return
	EndIf

	iCount = akEffectContext.GetCachedLootingListCount()

	If iCount <= 0
		LogDebug("ContainerProcessor", "ProcessFilteredContainerItems skipped: cached looting list is empty.")
		Return
	EndIf

	iInventoryBefore = akContainer.GetItemCount()
	LogDebug("ContainerProcessor", "Transfer begin: source=" + akContainer + " base=" + akBase + " totalItems=" + (iInventoryBefore as String) + " cachedLists=" + (iCount as String))

	iIndex = 0

	While iIndex < iCount
		akCurrentList = akEffectContext.GetCachedLootingList(iIndex)
		iLootGroupCode = akEffectContext.GetCachedLootGroupCode(iIndex)

		If akCurrentList == None
			LogWarn("ContainerProcessor", "ProcessFilteredContainerItems skipped invalid cached FormList at index " + (iIndex as String))
		ElseIf iLootGroupCode <= 0
			LogWarn("ContainerProcessor", "ProcessFilteredContainerItems skipped invalid cached LootGroupCode at index " + (iIndex as String))
		Else
			iDestinationCode = DestinationResolver.ResolveDestinationCodeForEffect(iLootGroupCode, akEffectContext)
			akCurrentDestinationRef = DestinationResolver.ResolveDestinationRef(iDestinationCode)

			If akCurrentDestinationRef == None
				LogWarn("ContainerProcessor", "ProcessFilteredContainerItems skipped index " + (iIndex as String) + ": destination ref resolved to None. LootGroupCode=" + (iLootGroupCode as String) + " DestinationCode=" + (iDestinationCode as String))
			Else
				iMatched = akContainer.GetItemCount(akCurrentList as Form)
				LogDebug("ContainerProcessor", "Category probe: index=" + (iIndex as String) \
					+ " list=" + akCurrentList \
					+ " matched=" + (iMatched as String) \
					+ " lootGroup=" + (iLootGroupCode as String) \
					+ " destinationCode=" + (iDestinationCode as String) \
					+ " destination=" + akCurrentDestinationRef)

				iMoved = akContainer.RemoveItem(akCurrentList as Form, -1, true, akCurrentDestinationRef)
				iMovedTotal += iMoved

				If iMoved <= 0
					iSkippedTotal += iMatched
				EndIf

				LogDebug("ContainerProcessor", "Category result: list=" + akCurrentList \
					+ " matchedBefore=" + (iMatched as String) \
					+ " moved=" + (iMoved as String))
			EndIf
		EndIf

		iIndex += 1
	EndWhile

	iInventoryAfter = akContainer.GetItemCount()
	LogDebug("ContainerProcessor", "Transfer complete: source=" + akContainer \
		+ " before=" + (iInventoryBefore as String) \
		+ " after=" + (iInventoryAfter as String) \
		+ " movedTotal=" + (iMovedTotal as String) \
		+ " skippedMatched=" + (iSkippedTotal as String))
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