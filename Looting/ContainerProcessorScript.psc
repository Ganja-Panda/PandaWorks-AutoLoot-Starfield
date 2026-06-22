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
		Return
	EndIf

	If !UnlockingService.EnsureContainerAccess(akContainer, akEffectContext)
		Return
	EndIf

	ProcessFilteredContainerItems(akContainer, None, akEffectContext)
EndFunction

; ==============================================================
; Processing Paths
; ==============================================================

Function ProcessFilteredContainerItems(ObjectReference akContainer, ObjectReference akDestinationRef, PWAL:Looting:LootEffectScript akEffectContext)
	Form akBase
	Container akBaseContainer
	FormList akCurrentList
	ObjectReference akCurrentDestinationRef
	Int iIndex
	Int iCount
	Int iLootGroupCode
	Int iDestinationCode

	If akContainer == None || akEffectContext == None
		LogWarn("ContainerProcessor", "ProcessFilteredContainerItems aborted: invalid input.")
		Return
	EndIf

	akBase = akContainer.GetBaseObject()
	akBaseContainer = akBase as Container

	If akEffectContext.IsShipInteriorMode() || akEffectContext.IsShipContainerMode()
		LogWarn("ContainerProcessor", "TEMP_SHIPLOCKER_DIAG processing ship container ref=" + akContainer + " base=" + akBase + " baseIsContainer=" + ((akBaseContainer != None) as String))
	EndIf

	If akBaseContainer == None
		If !IsNormalizedShipInventorySource(akContainer, akEffectContext)
			LogWarn("ContainerProcessor", "ProcessFilteredContainerItems rejected non-container base: ref=" + akContainer + " base=" + akBase)
			Return
		EndIf

		If akEffectContext.IsShipInteriorMode() || akEffectContext.IsShipContainerMode()
			LogWarn("ContainerProcessor", "TEMP_SHIPLOCKER_DIAG allowed normalized ship inventory source ref=" + akContainer + " base=" + akBase)
		EndIf
	EndIf

	If DestinationResolver == None
		LogError("ContainerProcessor", "ProcessFilteredContainerItems failed: DestinationResolver property is not filled.")
		Return
	EndIf

	iCount = akEffectContext.GetCachedLootingListCount()

	If iCount <= 0
		Return
	EndIf

	iIndex = 0

	While iIndex < iCount
		akCurrentList = akEffectContext.GetCachedLootingList(iIndex)
		iLootGroupCode = akEffectContext.GetCachedLootGroupCode(iIndex)

		If akCurrentList == None
			LogWarn("ContainerProcessor", "ProcessFilteredContainerItems skipped invalid cached FormList at index " + (iIndex as String))
		ElseIf iLootGroupCode <= 0
			LogWarn("ContainerProcessor", "ProcessFilteredContainerItems skipped invalid cached LootGroupCode at index " + (iIndex as String))
		Else
			iDestinationCode = DestinationResolver.ResolveDestinationCode(iLootGroupCode)
			akCurrentDestinationRef = DestinationResolver.ResolveDestinationRef(iDestinationCode)

			If akCurrentDestinationRef == None
				LogWarn("ContainerProcessor", "ProcessFilteredContainerItems skipped index " + (iIndex as String) + ": destination ref resolved to None. LootGroupCode=" + (iLootGroupCode as String) + " DestinationCode=" + (iDestinationCode as String))
			Else
				akContainer.RemoveItem(akCurrentList as Form, -1, true, akCurrentDestinationRef)
			EndIf
		EndIf

		iIndex += 1
	EndWhile
EndFunction

; ==============================================================
; Internal Helpers
; ==============================================================

Bool Function IsNormalizedShipInventorySource(ObjectReference akContainer, PWAL:Looting:LootEffectScript akEffectContext)
	SpaceshipReference akShipRef

	If akContainer == None || akEffectContext == None
		Return false
	EndIf

	If !akEffectContext.IsShipInteriorMode()
		Return false
	EndIf

	akShipRef = akContainer as SpaceshipReference
	Return akShipRef != None
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
