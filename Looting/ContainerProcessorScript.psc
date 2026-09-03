ScriptName PWAL:Looting:ContainerProcessorScript Extends Quest Hidden

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.0.2
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

	ProcessValidatedContainer(akContainer, akEffectContext)
EndFunction

Function ProcessValidatedContainer(ObjectReference akContainer, PWAL:Looting:LootEffectScript akEffectContext)
	If akContainer == None
		Return
	EndIf

	If akEffectContext == None
		Return
	EndIf

	If DestinationResolver == None
		LogError("ContainerProcessor", "ProcessValidatedContainer failed: DestinationResolver property is not filled.")
		Return
	EndIf

	If UnlockingService == None
		LogError("ContainerProcessor", "ProcessValidatedContainer failed: UnlockingService property is not filled.")
		Return
	EndIf

	; Laundering must happen before unlocking or transferring can report a crime.
	If !PrepareContainerOwnership(akContainer, akEffectContext)
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

Bool Function PrepareContainerOwnership(ObjectReference akContainer, PWAL:Looting:LootEffectScript akEffectContext)
	If akContainer == None || akEffectContext == None
		Return false
	EndIf

	If !akEffectContext.CanSteal()
		Return true
	EndIf

	If akEffectContext.IsStealingHostile()
		Return true
	EndIf

	If !LootValidation.IsOwned(akContainer, akEffectContext)
		Return true
	EndIf

	; Normalized spaceship references must never have ownership changed merely to access their inventory.
	If IsNormalizedShipInventorySource(akContainer, akEffectContext)
		LogWarn("ContainerProcessor", "PrepareContainerOwnership skipped normalized ship inventory source; spaceship ownership was not changed.")
		Return false
	EndIf

	; Non-hostile stealing fails closed when ownership cannot be laundered safely.
	If akEffectContext.PlayerFaction == None
		LogWarn("ContainerProcessor", "PrepareContainerOwnership failed: PlayerFaction is None.")
		Return false
	EndIf

	akContainer.SetActorOwner(None, true)
	akContainer.SetActorRefOwner(None, true)
	akContainer.SetFactionOwner(akEffectContext.PlayerFaction, true)
	Return true
EndFunction

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
