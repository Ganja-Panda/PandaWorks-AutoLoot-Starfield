ScriptName PWAL:Looting:UnlockingServiceScript Extends Quest Hidden

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.00
; Created: 04-10-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: UnlockingServiceScript
; Type: Looting / Unlocking Service
; Purpose:
;   Handles container unlock decisions and unlock attempts for PWAL.
;
; Responsibilities:
;   - Determine whether a locked container may be auto-unlocked
;   - Respect auto-unlock settings
;   - Respect skill-check settings
;   - Attempt key-required / digipick-capable unlock paths
;   - Return whether container access is available
;
; Non-Responsibilities:
;   - No scanning
;   - No loot transfer
;   - No destination logic
;   - No ownership mutation
; ==============================================================

; ==============================================================
; Properties
; ==============================================================

Group FrameworkServices_AutoFill
	PWAL:Core:LoggerScript Property Logger Auto Const Mandatory
EndGroup

; ==============================================================
; Public API
; ==============================================================

Bool Function EnsureContainerAccess(ObjectReference akContainer, PWAL:Looting:LootEffectScript akEffectContext)
	If akContainer == None
		LogWarn("UnlockingService", "EnsureContainerAccess aborted: akContainer is None.")
		Return false
	EndIf

	If akEffectContext == None
		LogWarn("UnlockingService", "EnsureContainerAccess aborted: akEffectContext is None.")
		Return false
	EndIf

	If !akContainer.IsLocked()
		Return true
	EndIf

	If !akEffectContext.CanAutoUnlock()
		Return false
	EndIf

	TryUnlock(akContainer, akEffectContext)

	If akContainer.IsLocked()
		Return false
	EndIf

	Return true
EndFunction

; ==============================================================
; Unlock Pipeline
; ==============================================================

Function TryUnlock(ObjectReference akContainer, PWAL:Looting:LootEffectScript akEffectContext)
	Bool bLockSkillCheck
	Bool bIsOwned
	Int iLockLevel
	Int iRequiresKey
	Int iInaccessible

	If akContainer == None || akEffectContext == None
		Return
	EndIf

	bLockSkillCheck = akEffectContext.UseAutoUnlockSkillCheck()
	bIsOwned = akContainer.HasOwner()
	iLockLevel = akContainer.GetLockLevel()

	If akEffectContext.LockLevel_RequiresKey == None || akEffectContext.LockLevel_Inaccessible == None
		LogWarn("UnlockingService", "TryUnlock aborted: required lock level globals are not filled.")
		Return
	EndIf

	iRequiresKey = akEffectContext.LockLevel_RequiresKey.GetValueInt()
	iInaccessible = akEffectContext.LockLevel_Inaccessible.GetValueInt()

	If iLockLevel == iInaccessible
		HandleInaccessibleLock()
	ElseIf iLockLevel == iRequiresKey
		HandleRequiresKey(akContainer, bIsOwned, akEffectContext)
	Else
		HandleDigipickUnlock(akContainer, bIsOwned, bLockSkillCheck, akEffectContext)
	EndIf
EndFunction

Function HandleInaccessibleLock()
EndFunction

Function HandleRequiresKey(ObjectReference akContainer, Bool bIsOwned, PWAL:Looting:LootEffectScript akEffectContext)
	Key akKey

	If akContainer == None || akEffectContext == None
		Return
	EndIf

	akKey = akContainer.GetKey()
	If akKey == None
		Return
	EndIf

	FindKey(akKey, akEffectContext)

	If akEffectContext.GetPlayerRef().GetItemCount(akKey as Form) > 0
		akContainer.Unlock(bIsOwned)
	EndIf
EndFunction

Function HandleDigipickUnlock(ObjectReference akContainer, Bool bIsOwned, Bool bLockSkillCheck, PWAL:Looting:LootEffectScript akEffectContext)
	ObjectReference akPlayerRef

	If akContainer == None || akEffectContext == None
		Return
	EndIf

	akPlayerRef = akEffectContext.GetPlayerRef()
	If akPlayerRef == None
		LogWarn("UnlockingService", "HandleDigipickUnlock aborted: PlayerRef is None.")
		Return
	EndIf

	If akEffectContext.Digipick == None
		LogWarn("UnlockingService", "HandleDigipickUnlock aborted: Digipick property is not filled.")
		Return
	EndIf

	If akPlayerRef.GetItemCount(akEffectContext.Digipick as Form) == 0
		FindDigipick(akEffectContext)
	EndIf

	If akPlayerRef.GetItemCount(akEffectContext.Digipick as Form) > 0
		If !bLockSkillCheck || (bLockSkillCheck && CanUnlock(akContainer, akEffectContext))
			akContainer.Unlock(bIsOwned)

			If !akContainer.IsLocked()
				Game.RewardPlayerXP(10, false)
				akPlayerRef.RemoveItem(akEffectContext.Digipick as Form, 1, false, None)
			EndIf
		EndIf
	EndIf
EndFunction

; ==============================================================
; Search Helpers
; ==============================================================

Function FindDigipick(PWAL:Looting:LootEffectScript akEffectContext)
	ObjectReference[] akSearchLocations
	Int iIndex
	ObjectReference akPlayerRef

	If akEffectContext == None
		Return
	EndIf

	akPlayerRef = akEffectContext.GetPlayerRef()
	If akPlayerRef == None || akEffectContext.Digipick == None
		Return
	EndIf

	akSearchLocations = new ObjectReference[2]
	akSearchLocations[0] = akEffectContext.GetPWALInventoryContainerRef()
	akSearchLocations[1] = akEffectContext.GetLodgeSafeRef()

	iIndex = 0
	While iIndex < akSearchLocations.Length
		If akSearchLocations[iIndex] != None
			If akSearchLocations[iIndex].GetItemCount(akEffectContext.Digipick as Form) > 0
				akSearchLocations[iIndex].RemoveItem(akEffectContext.Digipick as Form, -1, true, akPlayerRef)
				Return
			EndIf
		EndIf
		iIndex += 1
	EndWhile
EndFunction

Function FindKey(Key akKey, PWAL:Looting:LootEffectScript akEffectContext)
	ObjectReference[] akSearchLocations
	Int iIndex
	ObjectReference akPlayerRef

	If akKey == None || akEffectContext == None
		Return
	EndIf

	akPlayerRef = akEffectContext.GetPlayerRef()
	If akPlayerRef == None
		Return
	EndIf

	akSearchLocations = new ObjectReference[2]
	akSearchLocations[0] = akEffectContext.GetPWALInventoryContainerRef()
	akSearchLocations[1] = akEffectContext.GetLodgeSafeRef()

	iIndex = 0
	While iIndex < akSearchLocations.Length
		If akSearchLocations[iIndex] != None
			If akSearchLocations[iIndex].GetItemCount(akKey as Form) > 0
				akSearchLocations[iIndex].RemoveItem(akKey as Form, -1, true, akPlayerRef)
				Return
			EndIf
		EndIf
		iIndex += 1
	EndWhile
EndFunction

; ==============================================================
; Skill Check Helpers
; ==============================================================

Bool Function CanUnlock(ObjectReference akContainer, PWAL:Looting:LootEffectScript akEffectContext)
	Int iLockLevel
	Int[] aiLockLevels
	Bool[] abCanUnlock
	Int iIndex
	ObjectReference akPlayerRef

	If akContainer == None || akEffectContext == None
		Return false
	EndIf

	akPlayerRef = akEffectContext.GetPlayerRef()
	If akPlayerRef == None
		Return false
	EndIf

	If akEffectContext.LockLevel_Novice == None || akEffectContext.LockLevel_Advanced == None || akEffectContext.LockLevel_Expert == None || akEffectContext.LockLevel_Master == None
		LogWarn("UnlockingService", "CanUnlock aborted: one or more lock level globals are not filled.")
		Return false
	EndIf

	If akEffectContext.PWAL_PERK_CND_LockCheck_Advanced == None || akEffectContext.PWAL_PERK_CND_LockCheck_Expert == None || akEffectContext.PWAL_PERK_CND_LockCheck_Master == None
		LogWarn("UnlockingService", "CanUnlock aborted: one or more lock condition forms are not filled.")
		Return false
	EndIf

	iLockLevel = akContainer.GetLockLevel()

	aiLockLevels = new Int[4]
	aiLockLevels[0] = akEffectContext.LockLevel_Novice.GetValueInt()
	aiLockLevels[1] = akEffectContext.LockLevel_Advanced.GetValueInt()
	aiLockLevels[2] = akEffectContext.LockLevel_Expert.GetValueInt()
	aiLockLevels[3] = akEffectContext.LockLevel_Master.GetValueInt()

	abCanUnlock = new Bool[4]
	abCanUnlock[0] = true
	abCanUnlock[1] = akEffectContext.PWAL_PERK_CND_LockCheck_Advanced.Istrue(akPlayerRef, None)
	abCanUnlock[2] = akEffectContext.PWAL_PERK_CND_LockCheck_Expert.Istrue(akPlayerRef, None)
	abCanUnlock[3] = akEffectContext.PWAL_PERK_CND_LockCheck_Master.Istrue(akPlayerRef, None)

	iIndex = 0
	While iIndex < aiLockLevels.Length
		If iLockLevel == aiLockLevels[iIndex]
			Return abCanUnlock[iIndex]
		EndIf
		iIndex += 1
	EndWhile

	Return false
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
